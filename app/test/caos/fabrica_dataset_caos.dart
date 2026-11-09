// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fixalog/core/constantes/versao_legal.g.dart';
import 'package:fixalog/core/models/local/app_config_record.dart';
import 'package:fixalog/core/models/local/identity_record.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';
import 'package:fixalog/core/services/autenticacao_nuvem_service.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/services/providers.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';
import 'package:fixalog/core/services/sincronizador_nuvem_service.dart';
import 'package:fixalog/features/feedback/services/servico_fila_feedback.dart';
import 'package:fixalog/features/identity/viewmodels/identity_form_view_model.dart';
import 'package:fixalog/features/media/services/servico_galeria_dispositivo.dart';
import 'package:fixalog/features/media/services/video_transcoder_service.dart';
import 'package:fixalog/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/crypto_service_fake.dart';
import '../fakes/servico_fila_feedback_fake.dart';
import '../fakes/servico_galeria_dispositivo_fake.dart';
import '../fakes/video_transcoder_service_fake.dart';
import 'motor_robo_caotico.dart';
import 'receita_crash_robo.dart';

/// Fábrica determinística de dados iniciais (`normal` e `toxico`) para sessões do Robô Caótico.
abstract final class FabricaDatasetCaos {
  static const String _yamlProtocoloMinimo = '''
protocolo:
  id: bolt_maintenance
  nome: "Manutenção de Proteções Fixas"
  versao: "1.0.0"
  blocos:
    - id: route_identification
      titulo: "Identificação da Via"
      steps:
        - id: s1
          conteudos:
            - id: route_name
              campo_simples:
                label: "Nome da via"
                tipo: TEXT
                obrigatorio: true
''';

  /// Popula o [banco] SQLite em memória e o diretório de sessões do [sessionManager]
  /// com o perfil [dataset] solicitado (`normal` ou `toxico`).
  static Future<IdentityRecord> popularBanco({
    required BancoDadosLocal banco,
    required SessionBundleManager sessionManager,
    required TipoDatasetCaos dataset,
  }) async {
    final config = AppConfigRecord()
      ..id = 1
      ..acceptedTermsVersion = kVersaoLegal
      ..dataHoraAceiteTermos = DateTime.utc(2026, 11, 9, 10, 0)
      ..idiomaPreferido = 'pt';
    await banco.salvarConfiguracao(config);

    final identidade = IdentityRecord()
      ..nome = dataset == TipoDatasetCaos.normal
          ? 'Renato Escalador Silva'
          : 'Renato 🧗‍♂️ Escalador — التقرير الفني — 保守点検 (*_~`|\\)'
      ..clubeAssociacao = dataset == TipoDatasetCaos.normal
          ? 'FEMESP / Aresta'
          : 'Clube Extremo & Associação Internacional <script>alert(1)</script>'
      ..dataRegistro = DateTime.utc(2026, 11, 9, 10, 5);
    await banco.salvarIdentidade(identidade);

    if (dataset == TipoDatasetCaos.normal) {
      await _criarSubmissao(
        banco: banco,
        sessionManager: sessionManager,
        idSessao: 'mat-normal-01',
        idProtocolo: 'material_registration',
        nomeProtocolo: 'Cadastro de Material',
        tituloExibicao: 'Chapeleta Inox 316L Bonier',
        tipoRegistro: SubmissionTipoRegistro.material,
        status: SubmissionStatus.gerado,
        dataInclusao: DateTime.utc(2026, 11, 1, 9, 0),
      );
      await _criarSubmissao(
        banco: banco,
        sessionManager: sessionManager,
        idSessao: 'manut-normal-01',
        idProtocolo: 'bolt_maintenance',
        nomeProtocolo: 'Manutenção de Proteções Fixas',
        tituloExibicao: 'Via Paredão Sul — P2',
        tipoRegistro: SubmissionTipoRegistro.manutencao,
        status: SubmissionStatus.gerado,
        dataInclusao: DateTime.utc(2026, 11, 5, 14, 30),
      );
      await _criarSubmissao(
        banco: banco,
        sessionManager: sessionManager,
        idSessao: 'rascunho-normal-01',
        idProtocolo: 'bolt_maintenance',
        nomeProtocolo: 'Manutenção de Proteções Fixas',
        tituloExibicao: 'Rascunho Setor Leste',
        tipoRegistro: SubmissionTipoRegistro.manutencao,
        status: SubmissionStatus.emProgresso,
        dataInclusao: DateTime.utc(2026, 11, 8, 16, 0),
      );
    } else {
      await _criarSubmissao(
        banco: banco,
        sessionManager: sessionManager,
        idSessao: 'mat-toxico-01',
        idProtocolo: 'material_registration',
        nomeProtocolo: 'Cadastro de Material',
        tituloExibicao:
            'Chapeleta 🧗‍♂️ Titânio Grau 5 — صيانة — チタンボルト 100% #1',
        tipoRegistro: SubmissionTipoRegistro.material,
        status: SubmissionStatus.gerado,
        dataInclusao: DateTime.utc(2026, 11, 2, 8, 0),
      );
      await _criarSubmissao(
        banco: banco,
        sessionManager: sessionManager,
        idSessao: 'mat-toxico-02',
        idProtocolo: 'material_registration',
        nomeProtocolo: 'Cadastro de Material',
        tituloExibicao: 'Parabolt Químico M12x150mm ${'X' * 90}',
        tipoRegistro: SubmissionTipoRegistro.material,
        status: SubmissionStatus.gerado,
        dataInclusao: DateTime.utc(2026, 11, 3, 11, 0),
      );
      await _criarSubmissao(
        banco: banco,
        sessionManager: sessionManager,
        idSessao: 'manut-toxico-01',
        idProtocolo: 'bolt_maintenance',
        nomeProtocolo: 'Manutenção de Proteções Fixas',
        tituloExibicao:
            'Via Árabe/Japonês — فحص المرساة — アンカー点検 (**Markdown**)',
        tipoRegistro: SubmissionTipoRegistro.manutencao,
        status: SubmissionStatus.gerado,
        dataInclusao: DateTime.utc(2026, 11, 6, 15, 0),
      );
      await _criarSubmissao(
        banco: banco,
        sessionManager: sessionManager,
        idSessao: 'rascunho-toxico-01',
        idProtocolo: 'bolt_maintenance',
        nomeProtocolo: 'Manutenção de Proteções Fixas',
        tituloExibicao: 'Rascunho Tóxico 🪨⚡🔥❄️💧',
        tipoRegistro: SubmissionTipoRegistro.manutencao,
        status: SubmissionStatus.emProgresso,
        dataInclusao: DateTime.utc(2026, 11, 9, 9, 30),
      );
    }

    return identidade;
  }

  static Future<void> _criarSubmissao({
    required BancoDadosLocal banco,
    required SessionBundleManager sessionManager,
    required String idSessao,
    required String idProtocolo,
    required String nomeProtocolo,
    required String tituloExibicao,
    required String tipoRegistro,
    required String status,
    required DateTime dataInclusao,
  }) async {
    final regPb = Registro(
      idSessao: idSessao,
      idProtocolo: idProtocolo,
      versaoProtocolo: '1.0.0',
      yamlConteudo: _yamlProtocoloMinimo,
      respostas: [
        MapEntry('route_name', Resposta(texto: tituloExibicao)),
      ],
    );
    final arquivoYaml = await sessionManager.salvarRegistroSessao(
      sessionId: idSessao,
      registro: regPb,
    );
    var epubPath = '';
    var pdfPath = '';
    if (status == SubmissionStatus.gerado) {
      final arqEpub = File(
        await sessionManager.getEpubFilePath(sessionId: idSessao),
      )..writeAsStringSync('epub fake deterministico');
      final arqPdf = File(
        await sessionManager.getReportFilePath(sessionId: idSessao),
      )..writeAsStringSync('pdf fake deterministico');
      epubPath = arqEpub.path;
      pdfPath = arqPdf.path;
    }

    final record = SubmissionRecord()
      ..idSessao = idSessao
      ..idProtocolo = idProtocolo
      ..nomeProtocolo = nomeProtocolo
      ..tituloExibicao = tituloExibicao
      ..tipoRegistro = tipoRegistro
      ..dataInclusao = dataInclusao
      ..hashAssinatura = 'sha256-$idSessao'
      ..epubPath = epubPath
      ..pdfPath = pdfPath
      ..protobufPath = arquivoYaml.path
      ..status = status;

    await banco.salvarSubmissao(record);
  }
}

/// Ambiente autocontido que monta o aplicativo completo (`FixalogApp`) sobre SQLite `:memory:`
/// e Fakes determinísticos para execução do [MotorRoboCaotico].
class AmbienteAppCaos {
  /// Diretório temporário para pacotes de sessão durante a execução do robô.
  final Directory diretorioTemporario;

  /// Instância ativa do banco SQLite em memória.
  BancoDadosLocal? bancoAtivo;

  /// Fake de criptografia ECDSA P-256 e X.509 em memória.
  final CryptoServiceFake cryptoServiceFake = CryptoServiceFake();

  /// Fake de galeria e câmera em memória.
  final ServicoGaleriaDispositivoFake galeriaFake =
      ServicoGaleriaDispositivoFake();

  /// Fake de transcodificação de vídeo em memória.
  final VideoTranscoderServiceFake videoTranscoderFake =
      VideoTranscoderServiceFake();

  /// Fake da fila de feedback offline.
  final ServicoFilaFeedbackFake filaFeedbackFake = ServicoFilaFeedbackFake();

  /// Indica se a conectividade simulada está ativa.
  bool estaOnline = true;

  /// Contador de eventos de sincronização disparados pelo robô.
  int eventosSyncDisparados = 0;

  AmbienteAppCaos._(this.diretorioTemporario);

  /// Inicializa um novo [AmbienteAppCaos] criando seu diretório temporário isolado.
  static Future<AmbienteAppCaos> inicializar() async {
    final dir = await Directory.systemTemp.createTemp('fixalog_caos_');
    return AmbienteAppCaos._(dir);
  }

  /// Monta o aplicativo completo (`FixalogApp`) populado com o [dataset] solicitado.
  Future<void> montarApp(
    WidgetTester tester,
    TipoDatasetCaos dataset,
  ) async {
    late BancoDadosLocal banco;
    late SessionBundleManager sessionManager;
    late IdentityRecord identidade;

    const sessaoOidc = SessaoUsuarioNuvem(
      userId: 'usr-caos-01',
      email: 'perito.caos@fixalog.app',
      provedor: ProvedorOidc.google,
      nomeCompleto: 'Renato Escalador Silva',
      clubeAssociacao: 'FEMESP / Aresta',
      jwtSupabase: 'jwt-supabase-caos',
      atestadoOidcJwt: 'jwt-oidc-caos',
      fingerprintChavePublica: 'fp-chave-publica-caos',
    );

    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'fixalog_sessao_nuvem_json': jsonEncode(sessaoOidc.paraMapa()),
    });

    await tester.runAsync(() async {
      await bancoAtivo?.fechar();
      banco = await BancoDadosLocal.abrirEmMemoria();
      bancoAtivo = banco;
      sessionManager = SessionBundleManager(
        baseDirectoryGetter: () async => diretorioTemporario,
      );
      await cryptoServiceFake.generateAndStoreKeysIfNeeded();
      identidade = await FabricaDatasetCaos.popularBanco(
        banco: banco,
        sessionManager: sessionManager,
        dataset: dataset,
      );
    });

    final autenticacaoService = AutenticacaoNuvemService(
      cryptoService: cryptoServiceFake,
      autenticadorOidc: (provedor, rawNonce) async => CredencialOidcBruta(
        userId: sessaoOidc.userId,
        email: sessaoOidc.email,
        provedor: provedor,
        nomeCompleto: sessaoOidc.nomeCompleto,
        clubeAssociacao: sessaoOidc.clubeAssociacao,
        jwtSupabase: sessaoOidc.jwtSupabase,
        idTokenOidc: 'id-token-caos',
      ),
      provedorTokenAppCheck: () async => 'appcheck-token-caos',
      sincronizadorPerfilRemoto: (nome, clube) async {},
    );

    final sincronizadorService = SincronizadorNuvemService(
      banco: banco,
      autenticacaoService: autenticacaoService,
      clienteHttp: _ClienteHttpNuvemCaosFake(ambiente: this),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bancoDadosLocalProvider.overrideWithValue(banco),
          cryptoServiceProvider.overrideWithValue(cryptoServiceFake),
          autenticacaoNuvemServiceProvider
              .overrideWithValue(autenticacaoService),
          sincronizadorNuvemServiceProvider
              .overrideWithValue(sincronizadorService),
          sessionBundleManagerProvider.overrideWithValue(sessionManager),
          servicoGaleriaDispositivoProvider.overrideWithValue(galeriaFake),
          videoTranscoderServiceProvider.overrideWithValue(videoTranscoderFake),
          servicoFilaFeedbackProvider.overrideWithValue(filaFeedbackFake),
          hasIdentityProvider.overrideWith((ref) async => true),
          currentIdentityProvider.overrideWith((ref) async => identidade),
        ],
        child: const FixalogApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Cria uma instância do [MotorRoboCaotico] acoplada a este ambiente.
  MotorRoboCaotico criarMotor({
    required WidgetTester tester,
    Directory? diretorioSaidaReceitas,
    bool reportarAoSentry = false,
    int maxTentativasShrinking = 25,
  }) {
    return MotorRoboCaotico(
      tester: tester,
      montarCenario: (dataset) => montarApp(tester, dataset),
      diretorioSaidaReceitas: diretorioSaidaReceitas,
      reportarAoSentry: reportarAoSentry,
      maxTentativasShrinking: maxTentativasShrinking,
      aoDispararEventoSync: () async {
        eventosSyncDisparados++;
      },
      aoAlternarConectividade: () async {
        estaOnline = !estaOnline;
      },
    );
  }

  /// Fecha o banco em memória ativo e remove o diretório temporário.
  Future<void> limpar() async {
    await bancoAtivo?.fechar();
    bancoAtivo = null;
    if (diretorioTemporario.existsSync()) {
      await diretorioTemporario.delete(recursive: true);
    }
  }
}

class _ClienteHttpNuvemCaosFake implements ClienteHttpFixalogNuvem {
  final AmbienteAppCaos ambiente;

  const _ClienteHttpNuvemCaosFake({required this.ambiente});

  @override
  Future<int> enviarVersaoEpub({
    required String idSessao,
    required Uint8List epubBytes,
    required String jwtSupabase,
    required String tokenAppCheck,
  }) async {
    if (!ambiente.estaOnline) {
      throw const SocketException('Sem conexão simulada no robô caótico');
    }
    return 200;
  }

  @override
  Future<StatusLaudoRemoto> consultarStatusLaudo({
    required String idSessao,
    String? sha256,
    required String jwtSupabase,
    required String tokenAppCheck,
  }) async {
    if (!ambiente.estaOnline) {
      throw const SocketException('Sem conexão simulada no robô caótico');
    }
    return StatusLaudoRemoto(
      idSessao: idSessao,
      sha256: sha256,
      jaEnviado: true,
      versao: 1,
      statusModeracao: 'ativo',
      chunksRecebidos: const [0],
    );
  }

  @override
  Future<RespostaChunkLaudoRemoto> enviarChunkEpub({
    required String idSessao,
    required String sha256,
    required int index,
    required int total,
    required Uint8List chunkBytes,
    required String jwtSupabase,
    required String tokenAppCheck,
  }) async {
    if (!ambiente.estaOnline) {
      throw const SocketException('Sem conexão simulada no robô caótico');
    }
    return const RespostaChunkLaudoRemoto(
      statusHttp: 200,
      finalizado: true,
      jaEnviado: true,
      versao: 1,
      statusModeracao: 'ativo',
      chunksRecebidos: [0],
    );
  }

  @override
  Future<List<MetadadosLaudoRemoto>> listarLaudosConta({
    required String jwtSupabase,
    required String tokenAppCheck,
  }) async {
    if (!ambiente.estaOnline) {
      throw const SocketException('Sem conexão simulada no robô caótico');
    }
    return const [];
  }

  @override
  Future<Uint8List?> baixarEpubPublico({required String idSessao}) async {
    return null;
  }
}
