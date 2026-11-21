// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../constantes/versao_legal.g.dart';
import '../models/local/app_config_record.dart';
import '../models/proto/protos/registro.pb.dart';
import '../services/autenticacao_nuvem_service.dart';
import '../services/banco_dados_local.dart';
import '../services/crypto_service.dart';
import '../services/epub_document_builder.dart';
import '../services/epub_extrator_service.dart';
import '../services/epub_packager_service.dart';
import '../services/session_bundle_manager.dart';
import '../services/xml_dsig_signer.dart';
import '../../features/identity/repositories/identity_repository.dart';
import '../../features/identity/viewmodels/identity_form_view_model.dart';
import '../../features/media/services/media_compressor_service.dart';
import '../../features/media/services/video_transcoder_service.dart';
import '../../features/pdf_generation/providers/generation_provider.dart';
import '../../features/pdf_generation/services/generation_recovery_service.dart';
import 'configuracao_smoke_ci.dart';

/// Resultado consolidado da execução da jornada de smoke test pós-build.
class ResultadoJornadaSmoke {
  /// Indica se todas as etapas concluíram sem falhas nem exceções assíncronas.
  final bool sucesso;

  /// Lista ordenada de etapas concluídas durante a jornada.
  final List<String> etapas;

  /// Mensagens de erro capturadas durante a jornada.
  final List<String> erros;

  /// Métricas quantitativas e evidências estruturais da execução.
  final Map<String, dynamic> metricas;

  const ResultadoJornadaSmoke({
    required this.sucesso,
    required this.etapas,
    required this.erros,
    required this.metricas,
  });

  /// Converte o resultado para o payload JSON esperado por `/__smoke__/relatorio`.
  Map<String, dynamic> paraJson({required String token}) {
    return <String, dynamic>{
      'token': token,
      'sucesso': sucesso,
      'etapas': etapas,
      'erros': erros,
      'metricas': metricas,
    };
  }
}

/// Conduz a jornada funcional pós-build completa do Fixalog contra o servidor loopback do CI.
///
/// Exercita persistência SQLite nativa, geração de chaves ECDSA no `FlutterSecureStorage`,
/// autenticação OIDC pelo `MethodChannel` nativo, emissão de certificado X.509, compressão
/// de imagem WebP, transcodificação de vídeo H.264 (`FFmpegKit`), rasterização de PDF,
/// assinatura digital XML-DSig do pacote EPUB 3 e extração local do relatório.
class ExecutorJornadaSmoke {
  final ConfiguracaoSmokeCi config;
  final Directory diretorioBase;
  final BancoDadosLocal banco;
  final CryptoService cryptoService;
  final MediaCompressorService mediaService;
  final Future<void> Function(File arquivoDestino) geradorVideoSintetico;
  final List<String> _errosAssincronos = <String>[];

  ExecutorJornadaSmoke({
    required this.config,
    required this.diretorioBase,
    required this.banco,
    CryptoService? cryptoService,
    MediaCompressorService? mediaService,
    Future<void> Function(File arquivoDestino)? geradorVideoSintetico,
  }) : cryptoService = cryptoService ?? CryptoService(),
       mediaService = mediaService ?? MediaCompressorService(),
       geradorVideoSintetico =
           geradorVideoSintetico ?? gerarVideoSinteticoPadrao;

  /// Registra falhas assíncronas capturadas em tratadores globais (`FlutterError` / `PlatformDispatcher`).
  void registrarErroAssincrono(String descricao) {
    _errosAssincronos.add(descricao);
  }

  /// Executa todas as etapas da jornada e posta o relatório final ao servidor local de smoke.
  Future<ResultadoJornadaSmoke> executar() async {
    final etapas = <String>[];
    final erros = <String>[];
    final metricas = <String, dynamic>{};
    final cronometro = Stopwatch()..start();

    AutenticacaoNuvemService.urlSupabaseAtiva = config.uriBase.toString();

    try {
      // 1. Aceite dos Termos Legais no SQLite
      await banco.salvarConfiguracao(
        AppConfigRecord(
          id: 1,
          acceptedTermsVersion: kVersaoLegal,
          dataHoraAceiteTermos: DateTime.now(),
          idiomaPreferido: 'pt',
        ),
      );
      await banco.obterConfiguracao(1);
      etapas.add('termos_legais');

      // 2. Geração de Chave ECDSA + Login OIDC Nativo + Certificado X.509
      final repoIdentidade = SqliteIdentityRepository(banco);
      final servicoAuth = AutenticacaoNuvemService(
        cryptoService: cryptoService,
      );
      final vmIdentidade = IdentityFormViewModel(
        repoIdentidade,
        cryptoService,
        servicoAuth,
      );
      late IdentityFormState estadoIdentidade;
      final cancelarEscutaId = vmIdentidade.addListener((s) {
        estadoIdentidade = s;
      });

      await vmIdentidade.autenticarComProvedor(ProvedorOidc.google);
      if (estadoIdentidade.sessaoNuvem == null ||
          estadoIdentidade.errorMessage != null) {
        cancelarEscutaId();
        throw StateError(
          'Falha na autenticação OIDC nativa: ${estadoIdentidade.errorMessage}',
        );
      }

      await vmIdentidade.submitIdentity(
        'Mantenedor Smoke CI',
        'Aresta Climb',
        exigirAutenticacaoOidc: true,
      );
      cancelarEscutaId();
      final certPem = await cryptoService.obterCertificadoX509Pem();
      if (!estadoIdentidade.isSuccess ||
          certPem == null ||
          !certPem.contains('BEGIN CERTIFICATE')) {
        throw StateError(
          'Identidade ou certificado X.509 ausente após submitIdentity.',
        );
      }
      etapas.add('identidade_oidc_ecdsa');

      // 3. Preparação da Sessão com Foto PNG, Vídeo MP4 e Documento PDF
      const idSessao = 'smoke_sessao_ci';
      final sessionManager = SessionBundleManager(
        baseDirectoryGetter: () async => diretorioBase,
      );
      final caminhoFotoOrig = await sessionManager.getMediaFilePath(
        sessionId: idSessao,
        mediaUuid: 'foto_smoke_original',
        extension: '.png',
      );
      final arqFoto = File(caminhoFotoOrig);
      await arqFoto.parent.create(recursive: true);
      await arqFoto.writeAsBytes(gerarBytesPngSintetico());

      final caminhoVideoOrig = await sessionManager.getMediaFilePath(
        sessionId: idSessao,
        mediaUuid: 'video_smoke_original',
        extension: '.mp4',
      );
      final arqVideo = File(caminhoVideoOrig);
      await arqVideo.parent.create(recursive: true);
      await geradorVideoSintetico(arqVideo);

      final caminhoDocOrig = await sessionManager.getMediaFilePath(
        sessionId: idSessao,
        mediaUuid: 'doc_smoke_original',
        extension: '.pdf',
      );
      final arqDoc = File(caminhoDocOrig);
      await arqDoc.parent.create(recursive: true);
      await arqDoc.writeAsBytes(gerarBytesPdfSintetico());

      final yamlProtocolo = await rootBundle.loadString(
        'assets/protocols/registro_expresso.yaml',
      );
      final registro = Registro()
        ..idProtocolo = 'express_log'
        ..yamlConteudo = yamlProtocolo
        ..respostas['route_name'] = (Resposta()..texto = 'Vistoria Smoke CI')
        ..respostas['foto'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..imagem = (ArquivoImagem()..uuid = 'foto_smoke')))
        ..respostas['video'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..video = (ArquivoVideo()..uuid = 'video_smoke')))
        ..respostas['documento'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..documento = (ArquivoDocumento()..uuid = 'doc_smoke')));

      await sessionManager.saveManifest(
        sessionId: idSessao,
        binarypb: Uint8List.fromList(registro.writeToBuffer()),
      );
      etapas.add('preparacao_midias');

      // 4. Geração e Assinatura XML-DSig do Container EPUB 3
      final notifier = GenerationNotifier(
        mediaService,
        GenerationRecoveryService(),
        sessionManager,
        banco,
        const EpubDocumentBuilder(),
        EpubPackagerService(),
        XmlDsigSigner(),
        cryptoService,
      );
      late GenerationState estadoGeracao;
      final cancelarEscutaGen = notifier.addListener((s) {
        estadoGeracao = s;
      });
      final caminhoEpub = '${diretorioBase.path}/relatorio_smoke_ci.epub';
      await notifier.startGeneration(
        'Vistoria Smoke CI',
        caminhoEpub,
        sessionId: idSessao,
      );
      cancelarEscutaGen();

      if (estadoGeracao.hasError ||
          !estadoGeracao.isComplete ||
          estadoGeracao.epubPath == null) {
        throw StateError(
          'Falha ao gerar EPUB 3 assinado: ${estadoGeracao.errorMessage}',
        );
      }

      final arqEpub = File(estadoGeracao.epubPath!);
      final epubBytes = await arqEpub.readAsBytes();
      final zip = ZipDecoder().decodeBytes(epubBytes);
      final mapaEntradas = <String, ArchiveFile>{
        for (final f in zip) f.name: f,
      };
      for (final obrigatorio in const <String>[
        'META-INF/signatures.xml',
        'OEBPS/relatorio.xhtml',
        'OEBPS/midias/foto_smoke.webp',
        'OEBPS/midias/video_smoke.mp4',
        'OEBPS/midias/video_smoke_poster.jpg',
        'OEBPS/midias/doc_smoke.pdf',
        'OEBPS/midias/doc_smoke_p1.webp',
      ]) {
        final item = mapaEntradas[obrigatorio];
        if (item == null || item.size <= 0) {
          throw StateError(
            'Artefato obrigatório ausente ou vazio no EPUB gerado: $obrigatorio',
          );
        }
      }
      final xmlAssinatura = utf8.decode(
        mapaEntradas['META-INF/signatures.xml']!.content as List<int>,
      );
      metricas['epubBytes'] = epubBytes.length;
      metricas['possuiAssinaturaXmlDsig'] =
          xmlAssinatura.contains('SignatureValue') &&
          xmlAssinatura.contains('X509Certificate');
      etapas.add('geracao_epub3_assinado');

      // 5. Extração local do Relatório para Renderização XHTML
      await EpubExtratorService(
        obterDiretorioTemporario: () async => diretorioBase,
      ).extrairEpub(caminhoEpub: arqEpub.path);
      etapas.add('extracao_relatorio');
    } catch (e, st) {
      erros.add('$e\n$st');
    }

    erros.addAll(_errosAssincronos);
    cronometro.stop();
    metricas['duracaoMs'] = cronometro.elapsedMilliseconds;

    final resultado = ResultadoJornadaSmoke(
      sucesso: erros.isEmpty && metricas['possuiAssinaturaXmlDsig'] == true,
      etapas: etapas,
      erros: erros,
      metricas: metricas,
    );

    await _enviarRelatorioHttp(resultado);
    return resultado;
  }

  Future<void> _enviarRelatorioHttp(ResultadoJornadaSmoke resultado) async {
    final client = HttpClient();
    try {
      final req = await client.postUrl(config.construirUriRelatorio());
      req.headers.contentType = ContentType.json;
      req.add(utf8.encode(jsonEncode(resultado.paraJson(token: config.token))));
      final res = await req.close();
      await res.drain<void>();
    } finally {
      client.close(force: true);
    }
  }

  /// Gera um vídeo MP4 curto (1 segundo, 320x240) usando o `FFmpegKit` nativo embarcado.
  static Future<void> gerarVideoSinteticoPadrao(
    File destino, {
    ExecutadorFfmpeg executadorFfmpeg = VideoTranscoderService.executarFfmpeg,
  }) async {
    final ok = await executadorFfmpeg(
      '-f lavfi -i color=c=orange:s=320x240:r=15:d=1 '
      '-f lavfi -i anullsrc=r=44100:cl=mono -t 1 '
      '-c:v mpeg4 -pix_fmt yuv420p -c:a aac -b:a 64k -y "${destino.absolute.path}"',
    );
    if (!ok || !destino.existsSync() || destino.lengthSync() == 0) {
      throw StateError(
        'FFmpegKit nativo falhou ao sintetizar vídeo de entrada em ${destino.path}.',
      );
    }
  }

  /// Gera em memória uma imagem PNG RGB 64x64 válida (CRC32 + DEFLATE nativos).
  static Uint8List gerarBytesPngSintetico({
    int largura = 64,
    int altura = 64,
  }) {
    final scanlines = BytesBuilder(copy: false);
    for (var y = 0; y < altura; y++) {
      scanlines.addByte(0); // filtro None
      for (var x = 0; x < largura; x++) {
        scanlines.add(<int>[0xFF, 0x6B, 0x00]); // Laranja Fixalog
      }
    }
    final comprimido = zlib.encode(scanlines.takeBytes());

    final ihdr = ByteData(13)
      ..setUint32(0, largura)
      ..setUint32(4, altura)
      ..setUint8(8, 8) // bit depth 8
      ..setUint8(9, 2) // color type RGB
      ..setUint8(10, 0)
      ..setUint8(11, 0)
      ..setUint8(12, 0);

    final saida = BytesBuilder(copy: false)
      ..add(const <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
      ..add(_montarChunkPng('IHDR', ihdr.buffer.asUint8List()))
      ..add(_montarChunkPng('IDAT', Uint8List.fromList(comprimido)))
      ..add(_montarChunkPng('IEND', Uint8List(0)));
    return saida.takeBytes();
  }

  static Uint8List _montarChunkPng(String tipo, Uint8List dados) {
    final tipoBytes = ascii.encode(tipo);
    final cabecalhoTamanho = ByteData(4)..setUint32(0, dados.length);
    final crcInput = BytesBuilder(copy: false)
      ..add(tipoBytes)
      ..add(dados);
    final crcValor = getCrc32(crcInput.takeBytes());
    final rodapeCrc = ByteData(4)..setUint32(0, crcValor);

    final chunk = BytesBuilder(copy: false)
      ..add(cabecalhoTamanho.buffer.asUint8List())
      ..add(tipoBytes)
      ..add(dados)
      ..add(rodapeCrc.buffer.asUint8List());
    return chunk.takeBytes();
  }

  /// Gera um documento PDF 1.4 mínimo de 1 página com offsets `xref` exatos para rasterização PDFium.
  static Uint8List gerarBytesPdfSintetico() {
    final buffer = StringBuffer('%PDF-1.4\n');
    final offsets = <int>[];

    void escreverObjeto(String corpoObj) {
      offsets.add(latin1.encode(buffer.toString()).length);
      buffer.write('$corpoObj\n');
    }

    escreverObjeto('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj');
    escreverObjeto('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj');
    escreverObjeto(
      '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] '
      '/Contents 4 0 R >>\nendobj',
    );
    const stream = '0.95 0.42 0.0 rg 20 20 160 160 re f';
    escreverObjeto(
      '4 0 obj\n<< /Length ${stream.length} >>\nstream\n$stream\nendstream\nendobj',
    );

    final xrefOffset = latin1.encode(buffer.toString()).length;
    buffer.writeln('xref');
    buffer.writeln('0 ${offsets.length + 1}');
    buffer.writeln('0000000000 65535 f ');
    for (final off in offsets) {
      buffer.writeln('${off.toString().padLeft(10, '0')} 00000 n ');
    }
    buffer.writeln('trailer');
    buffer.writeln('<< /Size ${offsets.length + 1} /Root 1 0 R >>');
    buffer.writeln('startxref');
    buffer.writeln('$xrefOffset');
    buffer.write('%%EOF\n');

    return latin1.encode(buffer.toString());
  }
}
