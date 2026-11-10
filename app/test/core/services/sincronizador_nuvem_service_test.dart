// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/core/services/autenticacao_nuvem_service.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/services/gerenciador_notificacao_upload_laudo.dart';
import 'package:fixalog/core/services/sincronizador_nuvem_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import '../../fakes/crypto_service_fake.dart';
import '../../fakes/plugin_notificacoes_locais_fake.dart';
import '../../fakes/registro_logger_fake.dart';
import 'autenticacao_nuvem_service_fake.dart';
import 'sincronizador_nuvem_service_fake.dart';

Uint8List _criarZipEpubTeste({
  List<String> idsMateriaisAninhados = const [],
  List<int>? binarypbBytes,
  String? xhtmlCustomizado,
  int bytesExtrasPadding = 0,
}) {
  final archive = Archive();
  final xhtml = utf8.encode(
    xhtmlCustomizado ??
        '<html><head><title>Manutenção de Ferragens</title></head>'
            '<body><h1>Manutenção de Ferragens</h1><h2>Via Paredão Sul</h2>'
            '<p>Mantenedor: Renato Escalador (FEMERJ)</p>'
            '<img src="midias/f1.webp"/><video src="midias/v1.mp4"></video>'
            '</body></html>',
  );
  archive.addFile(ArchiveFile('OEBPS/relatorio.xhtml', xhtml.length, xhtml));
  if (bytesExtrasPadding > 0) {
    final padding = Uint8List(bytesExtrasPadding);
    archive.addFile(
      ArchiveFile('OEBPS/midias/padding.bin', padding.length, padding),
    );
  }
  if (binarypbBytes != null) {
    archive.addFile(
      ArchiveFile(
        'OEBPS/dados/registro.binarypb',
        binarypbBytes.length,
        binarypbBytes,
      ),
    );
  }
  for (final idMat in idsMateriaisAninhados) {
    archive.addFile(
      ArchiveFile(
        'OEBPS/materiais/$idMat/relatorio.xhtml',
        xhtml.length,
        xhtml,
      ),
    );
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  late Directory tempDir;
  late BancoDadosLocal banco;
  late CryptoServiceFake crypto;
  late AutenticacaoNuvemServiceFake auth;
  late ClienteHttpFixalogNuvemFake clienteHttp;
  late SincronizadorNuvemService sincronizador;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('fixalog_sync_nuvem_test_');
    banco = await BancoDadosLocal.abrirEmMemoria();
    crypto = CryptoServiceFake();
    auth = AutenticacaoNuvemServiceFake(crypto: crypto);
    await auth.entrarComProvedorOidc(ProvedorOidc.google);
    clienteHttp = ClienteHttpFixalogNuvemFake();
    sincronizador = SincronizadorNuvemService(
      banco: banco,
      autenticacaoService: auth,
      clienteHttp: clienteHttp,
      intervaloPollingModeracao: const Duration(milliseconds: 5),
    );
  });

  tearDown(() async {
    await banco.fechar();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('SincronizadorNuvemService — Fila de Upload Retomável, Versionamento e Restauração', () {
    test('obterUrlCompartilhamentoPublico, calcularSha256Hex e construirResumoCompartilhamento geram metadados ricos', () {
      expect(
        SincronizadorNuvemService.obterUrlCompartilhamentoPublico('sessao_123'),
        equals('https://fixalog.app/v/sessao_123'),
      );
      final metaPadrao = MetadadosLaudoRemoto.deJson({});
      expect(metaPadrao.idSessao, isEmpty);

      final hash = SincronizadorNuvemService.calcularSha256Hex(
        Uint8List.fromList(utf8.encode('fixalog')),
      );
      expect(hash.length, equals(64));

      final epubBytes = _criarZipEpubTeste();
      final resumo = SincronizadorNuvemService.construirResumoCompartilhamento(
        idSessao: 'sessao_123',
        titulo: 'Via Paredão Sul',
        epubBytes: epubBytes,
      );
      expect(resumo, contains('Manutenção de Ferragens'));
      expect(resumo, contains('Via Paredão Sul'));
      expect(resumo, contains('https://fixalog.app/v/sessao_123'));

      final resumoFallback =
          SincronizadorNuvemService.construirResumoCompartilhamento(
            idSessao: 'sessao_fallback',
            titulo: 'Relatório Técnico',
            epubBytes: Uint8List.fromList([1, 2, 3]),
          );
      expect(resumoFallback, contains('https://fixalog.app/v/sessao_fallback'));
    });

    test('Envia materiais referenciados antes do laudo de manutenção e marca enviadoNuvem=true no SQLite', () async {
      final epubMat = File(p.join(tempDir.path, 'mat_1.epub'))
        ..writeAsBytesSync(_criarZipEpubTeste());
      final epubManut = File(p.join(tempDir.path, 'manut_1.epub'))
        ..writeAsBytesSync(
          _criarZipEpubTeste(idsMateriaisAninhados: ['mat_1']),
        );

      await banco.salvarSubmissao(
        SubmissionRecord()
          ..idSessao = 'manut_1'
          ..idProtocolo = 'manutencao_ferragens'
          ..nomeProtocolo = 'Via Principal'
          ..tipoRegistro = SubmissionTipoRegistro.manutencao
          ..status = SubmissionStatus.gerado
          ..epubPath = epubManut.path
          ..protobufPath = '/tmp/manut_1/registro.binarypb'
          ..enviadoNuvem = false,
      );
      await banco.salvarSubmissao(
        SubmissionRecord()
          ..idSessao = 'mat_1'
          ..idProtocolo = 'material_registration'
          ..nomeProtocolo = 'Chumbador Inox 316L'
          ..tipoRegistro = SubmissionTipoRegistro.material
          ..status = SubmissionStatus.gerado
          ..epubPath = epubMat.path
          ..protobufPath = '/tmp/mat_1/registro.binarypb'
          ..enviadoNuvem = false,
      );

      final regManut = await banco.obterSubmissaoPorIdSessao('manut_1');
      final enviado = await sincronizador.enviarSubmissao(regManut!);
      expect(enviado, isTrue);

      // Material deve ter sido enviado ANTES da manutenção!
      expect(clienteHttp.ordemIdsEnviados, equals(['mat_1', 'manut_1']));
      expect(
        (await banco.obterSubmissaoPorIdSessao('mat_1'))?.enviadoNuvem,
        isTrue,
      );
      expect(
        (await banco.obterSubmissaoPorIdSessao('manut_1'))?.enviadoNuvem,
        isTrue,
      );
    });

    test('Upload retomável em blocos pula chunks já recebidos e ignora upload se sha256 já foi enviado', () async {
      final bytesGrandes = _criarZipEpubTeste(bytesExtrasPadding: 1500);
      final sha256Hex = SincronizadorNuvemService.calcularSha256Hex(
        bytesGrandes,
      );
      final epubFile = File(p.join(tempDir.path, 'retomavel.epub'))
        ..writeAsBytesSync(bytesGrandes);

      // Configura tamanho de bloco pequeno (128 bytes) para exercitar múltiplos chunks
      final syncBlocos = SincronizadorNuvemService(
        banco: banco,
        autenticacaoService: auth,
        clienteHttp: clienteHttp,
        tamanhoBlocoBytes: 128,
        intervaloPollingModeracao: const Duration(milliseconds: 5),
      );

      // Pré-popula o chunk 0 no servidor para simular retomada a partir do chunk 1
      await clienteHttp.enviarChunkEpub(
        idSessao: 's_retomavel',
        sha256: sha256Hex,
        index: 0,
        total: (bytesGrandes.length / 128).ceil(),
        chunkBytes: bytesGrandes.sublist(0, 128),
        jwtSupabase: 'jwt',
        tokenAppCheck: 'appcheck',
      );
      clienteHttp.indicesChunksEnviados.clear();

      final rec = SubmissionRecord()
        ..idSessao = 's_retomavel'
        ..idProtocolo = 'manutencao_ferragens'
        ..nomeProtocolo = 'Via Retomável'
        ..tipoRegistro = SubmissionTipoRegistro.manutencao
        ..status = SubmissionStatus.gerado
        ..epubPath = epubFile.path
        ..enviadoNuvem = false;
      await banco.salvarSubmissao(rec);

      final eventosProgresso = <ProgressoPublicacaoLaudo>[];
      final sub = syncBlocos
          .observarProgresso('s_retomavel')
          .listen(eventosProgresso.add);
      addTearDown(sub.cancel);

      // Dispara 2 chamadas concorrentes para validar deduplicação single-flight
      final resultados = await Future.wait([
        syncBlocos.enviarSubmissao(rec),
        syncBlocos.enviarSubmissao(rec),
      ]);
      expect(resultados, equals([true, true]));
      // Chunk 0 não deve ter sido reenviado!
      expect(clienteHttp.indicesChunksEnviados, isNot(contains(0)));
      expect(clienteHttp.indicesChunksEnviados, contains(1));
      expect(syncBlocos.obterProgressoAtual('s_retomavel')?.fracaoBlocos, 1.0);
      expect(eventosProgresso, isNotEmpty);

      // Se tentar enviar novamente o mesmo sha256 já finalizado, pula envio de chunks
      clienteHttp.indicesChunksEnviados.clear();
      rec.enviadoNuvem = false;
      await banco.salvarSubmissao(rec);
      expect(await syncBlocos.enviarSubmissao(rec), isTrue);
      expect(clienteHttp.indicesChunksEnviados, isEmpty);
    });

    test('publicarEAguardarLiberacao bloqueia enquanto status_moderacao == em_analise e libera quando ativo', () async {
      final bytes = _criarZipEpubTeste();
      final epubFile = File(p.join(tempDir.path, 'mod.epub'))
        ..writeAsBytesSync(bytes);
      final rec = SubmissionRecord()
        ..idSessao = 's_mod'
        ..idProtocolo = 'manutencao_ferragens'
        ..nomeProtocolo = 'Via Moderada'
        ..tipoRegistro = SubmissionTipoRegistro.manutencao
        ..status = SubmissionStatus.gerado
        ..epubPath = epubFile.path
        ..enviadoNuvem = false;
      await banco.salvarSubmissao(rec);

      // Simula que o servidor mantém em_analise nas 2 primeiras consultas pós-upload e depois aprova
      clienteHttp.consultasEmAnaliseAntesDeAtivar['s_mod'] = 2;

      final etapasObservadas = <EtapaPublicacaoLaudo>[];
      final resultado = await sincronizador.publicarEAguardarLiberacao(
        idSessao: 's_mod',
        epubPath: epubFile.path,
        aoProgredir: (p) => etapasObservadas.add(p.etapa),
      );

      expect(resultado.etapa, equals(EtapaPublicacaoLaudo.concluidoAtivo));
      expect(
        etapasObservadas,
        contains(EtapaPublicacaoLaudo.aguardandoVerificacaoServidor),
      );
      expect(etapasObservadas.last, equals(EtapaPublicacaoLaudo.concluidoAtivo));

      // Quando dispositivo está sem internet, retorna EtapaPublicacaoLaudo.semInternet
      clienteHttp.deveLancarErroRede = true;
      final resOffline = await sincronizador.publicarEAguardarLiberacao(
        idSessao: 's_mod',
        epubPath: epubFile.path,
      );
      expect(resOffline.etapa, equals(EtapaPublicacaoLaudo.semInternet));

      // Quando servidor rejeita o laudo na moderação, retorna rejeitadoOuFalha
      clienteHttp.deveLancarErroRede = false;
      clienteHttp.statusModeracaoForcadoPorSessao['s_mod'] = 'rejeitado';
      final resRejeitado = await sincronizador.publicarEAguardarLiberacao(
        idSessao: 's_mod',
      );
      expect(resRejeitado.etapa, equals(EtapaPublicacaoLaudo.rejeitadoOuFalha));

      // Quando estoura maxTentativasPollingModeracao ainda em_analise e sem sessão prévia
      await auth.encerrarSessao();
      clienteHttp.statusModeracaoForcadoPorSessao.remove('s_mod');
      clienteHttp.consultasEmAnaliseAntesDeAtivar['s_mod'] = 10;
      final syncCurto = SincronizadorNuvemService(
        banco: banco,
        autenticacaoService: auth,
        clienteHttp: clienteHttp,
        intervaloPollingModeracao: const Duration(milliseconds: 1),
        maxTentativasPollingModeracao: 1,
      );
      final resTimeout = await syncCurto.publicarEAguardarLiberacao(
        idSessao: 's_mod',
      );
      expect(resTimeout.etapa, equals(EtapaPublicacaoLaudo.rejeitadoOuFalha));

      // E quando falha durante o envio inicial dentro de publicarEAguardarLiberacao
      final recNaoEnviado = SubmissionRecord()
        ..idSessao = 's_mod_falha_envio'
        ..idProtocolo = 'manutencao_ferragens'
        ..nomeProtocolo = 'Via Falha'
        ..tipoRegistro = SubmissionTipoRegistro.manutencao
        ..status = SubmissionStatus.gerado
        ..epubPath = '';
      await banco.salvarSubmissao(recNaoEnviado);
      final resFalhaEnvio = await syncCurto.publicarEAguardarLiberacao(
        idSessao: 's_mod_falha_envio',
      );
      expect(resFalhaEnvio.etapa, equals(EtapaPublicacaoLaudo.semInternet));
    });

    test('sincronizarPendentes processa fila ordenada e cria nova versão quando laudo é re-editado com novo sha256', () async {
      final epub1 = File(p.join(tempDir.path, 's_v1.epub'))
        ..writeAsBytesSync(_criarZipEpubTeste(xhtmlCustomizado: '<html>v1</html>'));

      final rec = SubmissionRecord()
        ..idSessao = 's_versionado'
        ..idProtocolo = 'manutencao_ferragens'
        ..nomeProtocolo = 'Via v1'
        ..tipoRegistro = SubmissionTipoRegistro.manutencao
        ..dataInclusao = DateTime.utc(2026, 11, 8, 12)
        ..status = SubmissionStatus.gerado
        ..protobufPath = epub1.path
        ..enviadoNuvem = false;
      await banco.salvarSubmissao(rec);

      final recMat = SubmissionRecord()
        ..idSessao = 's_mat_pendente'
        ..idProtocolo = 'material_registration'
        ..nomeProtocolo = 'Material Pendente'
        ..tipoRegistro = SubmissionTipoRegistro.material
        ..dataInclusao = DateTime.utc(2026, 11, 8, 13)
        ..status = SubmissionStatus.gerado
        ..epubPath = epub1.path
        ..enviadoNuvem = false;
      await banco.salvarSubmissao(recMat);

      final recFalha = SubmissionRecord()
        ..idSessao = 's_falha_sem_arquivo'
        ..idProtocolo = 'manutencao_ferragens'
        ..nomeProtocolo = 'Sem Arquivo'
        ..tipoRegistro = SubmissionTipoRegistro.manutencao
        ..dataInclusao = DateTime.utc(2026, 11, 8, 14)
        ..status = SubmissionStatus.gerado
        ..epubPath = ''
        ..protobufPath = ''
        ..enviadoNuvem = false;
      await banco.salvarSubmissao(recFalha);

      final res1 = await sincronizador.sincronizarPendentes();
      expect(res1.enviados, equals(2));
      expect(res1.falhas, equals(1));
      expect(res1.idsEnviados, equals(['s_mat_pendente', 's_versionado']));
      expect(
        clienteHttp.versoesRecebidasPorSessao['s_versionado']?.length,
        equals(1),
      );

      // Remove o pendente com falha e simula re-edição de s_versionado com novo conteúdo/sha256
      await banco.deletarSubmissaoPorIdSessao('s_falha_sem_arquivo');
      epub1.writeAsBytesSync(
        _criarZipEpubTeste(xhtmlCustomizado: '<html>v2 editado</html>'),
      );
      final salvo = (await banco.obterSubmissaoPorIdSessao('s_versionado'))!;
      salvo.enviadoNuvem = false;
      await banco.salvarSubmissao(salvo);

      final res2 = await sincronizador.sincronizarPendentes();
      expect(res2.enviados, equals(1));
      expect(
        clienteHttp.versoesRecebidasPorSessao['s_versionado']?.length,
        equals(2),
      );
    });

    test('restaurarRelatoriosDaConta baixa pacotes .epub e extrai registro.binarypb para o banco local', () async {
      final epubRemoto = _criarZipEpubTeste(binarypbBytes: [10, 20, 30]);
      clienteHttp.epubsPublicosPorSessao['remoto_1'] = epubRemoto;
      clienteHttp.laudosRemotosConta.add(
        MetadadosLaudoRemoto.deJson({
          'id_sessao': 'remoto_1',
          'categoria': 'MATERIAL',
          'id_protocolo': 'material_registration',
          'titulo': 'Parabolt Restaurado',
          'versao_atual': 1,
          'atualizado_em': '2026-11-08T12:00:00Z',
        }),
      );

      final qtd = await sincronizador.restaurarRelatoriosDaConta(
        diretorioBase: tempDir,
      );
      expect(qtd, equals(1));

      final restaurado = await banco.obterSubmissaoPorIdSessao('remoto_1');
      expect(restaurado, isNotNull);
      expect(restaurado!.enviadoNuvem, isTrue);
      expect(restaurado.tituloExibicao, equals('Parabolt Restaurado'));
      expect(restaurado.epubPath, endsWith('relatorio.epub'));
      expect(restaurado.protobufPath, endsWith('registro.binarypb'));
      expect(
        File(
          p.join(tempDir.path, 'sessoes', 'remoto_1', 'registro.binarypb'),
        ).existsSync(),
        isTrue,
      );

      // Segunda chamada ignora pois já está restaurado e enviadoNuvem=true
      expect(
        await sincronizador.restaurarRelatoriosDaConta(diretorioBase: tempDir),
        equals(0),
      );
    });

    test('Trata ausência de banco, ausência de sessão OIDC, falha HTTP e ClienteHttpFixalogNuvemPadrao com servidor local', () async {
      final semBanco = SincronizadorNuvemService(
        banco: null,
        autenticacaoService: auth,
        clienteHttp: clienteHttp,
      );
      expect((await semBanco.sincronizarPendentes()).enviados, equals(0));
      expect(
        await semBanco.restaurarRelatoriosDaConta(diretorioBase: tempDir),
        equals(0),
      );

      await auth.encerrarSessao();
      expect((await sincronizador.sincronizarPendentes()).enviados, equals(0));
      expect(
        await sincronizador.restaurarRelatoriosDaConta(diretorioBase: tempDir),
        equals(0),
      );

      // Testa ClienteHttpFixalogNuvemPadrao com HttpServer local em memória
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((HttpRequest req) async {
        if (req.method == 'GET' &&
            req.uri.path == '/api/v1/laudos/srv_1/status') {
          req.response.statusCode = 200;
          req.response.write(
            jsonEncode({
              'id_sessao': 'srv_1',
              'sha256': req.uri.queryParameters['sha256'],
              'ja_enviado': false,
              'versao': null,
              'status_moderacao': null,
              'chunks_recebidos': [0],
            }),
          );
          await req.response.close();
          return;
        }
        if (req.method == 'PUT' &&
            req.uri.path == '/api/v1/laudos/srv_1/chunk') {
          await req.drain<void>();
          req.response.statusCode = 201;
          req.response.write(
            jsonEncode({
              'id_sessao': 'srv_1',
              'sha256': req.uri.queryParameters['sha256'],
              'finalizado': true,
              'ja_enviado': true,
              'versao': 1,
              'status_moderacao': 'ativo',
              'chunks_recebidos': [],
            }),
          );
          await req.response.close();
          return;
        }
        if (req.method == 'PUT' && req.uri.path.startsWith('/api/v1/laudos/')) {
          await req.drain<void>();
          req.response.statusCode = 201;
          await req.response.close();
          return;
        }
        if (req.method == 'GET' && req.uri.path == '/api/v1/laudos') {
          req.response.statusCode = 200;
          req.response.write(
            jsonEncode({
              'laudos': [
                {
                  'id_sessao': 'srv_1',
                  'categoria': 'MANUTENCAO',
                  'id_protocolo': 'manutencao_ferragens',
                  'titulo': 'Do Servidor',
                  'versao_atual': 1,
                  'atualizado_em': '2026-11-08T00:00:00Z',
                },
              ],
            }),
          );
          await req.response.close();
          return;
        }
        if (req.method == 'GET' && req.uri.path == '/v/srv_1/epub') {
          req.response.statusCode = 200;
          req.response.add([1, 2, 3]);
          await req.response.close();
          return;
        }
        req.response.statusCode = 404;
        await req.response.close();
      });

      final clienteReal = ClienteHttpFixalogNuvemPadrao(
        urlBase: 'http://127.0.0.1:${server.port}',
      );
      final statusSrv = await clienteReal.consultarStatusLaudo(
        idSessao: 'srv_1',
        sha256: 'hash1',
        jwtSupabase: 'jwt',
        tokenAppCheck: 'appcheck',
      );
      expect(statusSrv.jaEnviado, isFalse);
      expect(statusSrv.chunksRecebidos, equals([0]));

      final resChunkSrv = await clienteReal.enviarChunkEpub(
        idSessao: 'srv_1',
        sha256: 'hash1',
        index: 1,
        total: 2,
        chunkBytes: Uint8List.fromList([4, 5, 6]),
        jwtSupabase: 'jwt',
        tokenAppCheck: 'appcheck',
      );
      expect(resChunkSrv.finalizado, isTrue);
      expect(resChunkSrv.versao, equals(1));

      expect(
        await clienteReal.enviarVersaoEpub(
          idSessao: 'srv_1',
          epubBytes: Uint8List.fromList([1, 2, 3]),
          jwtSupabase: 'jwt',
          tokenAppCheck: 'appcheck',
        ),
        equals(201),
      );
      expect(
        (await clienteReal.listarLaudosConta(
          jwtSupabase: 'jwt',
          tokenAppCheck: 'appcheck',
        )).length,
        equals(1),
      );
      expect(await clienteReal.baixarEpubPublico(idSessao: 'srv_1'), isNotNull);
      expect(await clienteReal.baixarEpubPublico(idSessao: '404'), isNull);

      final container = ProviderContainer(
        overrides: [bancoDadosLocalProvider.overrideWithValue(banco)],
      );
      addTearDown(container.dispose);
      expect(
        container.read(sincronizadorNuvemServiceProvider),
        isA<SincronizadorNuvemService>(),
      );

      // Valida registro de falha de rede em enviarSubmissao e restaurarRelatoriosDaConta
      await auth.entrarComProvedorOidc(ProvedorOidc.google);
      final loggerFake = RegistroLoggerFake();
      clienteHttp.deveLancarErroRede = true;
      final syncComLogger = SincronizadorNuvemService(
        banco: banco,
        autenticacaoService: auth,
        clienteHttp: clienteHttp,
        logger: loggerFake,
      );
      final epubFalha = File(p.join(tempDir.path, 'falha_rede.epub'))
        ..writeAsBytesSync(_criarZipEpubTeste());
      final recRede = SubmissionRecord()
        ..idSessao = 's_erro_rede'
        ..idProtocolo = 'manutencao_ferragens'
        ..nomeProtocolo = 'Via Offline'
        ..tipoRegistro = SubmissionTipoRegistro.manutencao
        ..status = SubmissionStatus.gerado
        ..epubPath = epubFalha.path;
      expect(await syncComLogger.enviarSubmissao(recRede), isFalse);
      expect(
        await syncComLogger.restaurarRelatoriosDaConta(diretorioBase: tempDir),
        equals(0),
      );
      expect(
        loggerFake.avisosRegistrados.length + loggerFake.errosRegistrados.length,
        equals(2),
      );
    });

    test(
      'realiza mock gracioso local em enviarSubmissao, publicarEAguardarLiberacao e restaurarRelatoriosDaConta quando em modo de desenvolvimento sem token real do App Check',
      () async {
        final loggerMockDev = RegistroLoggerFake();
        auth.tokenAppCheckRetornado =
            AutenticacaoNuvemService.tokenAppCheckFallbackLocal;
        // Mesmo com erro de rede forçado no cliente HTTP, o mock gracioso não deve tocar na rede
        clienteHttp.deveLancarErroRede = true;

        final syncDevSemAppCheck = SincronizadorNuvemService(
          banco: banco,
          autenticacaoService: auth,
          clienteHttp: clienteHttp,
          logger: loggerMockDev,
          emModoDesenvolvimento: true,
        );

        final epubDev = File(p.join(tempDir.path, 'dev_mock.epub'))
          ..writeAsBytesSync(_criarZipEpubTeste());
        final recDev = SubmissionRecord()
          ..idSessao = 'sessao_dev_mock'
          ..idProtocolo = 'manutencao_ferragens'
          ..nomeProtocolo = 'Manutenção Mock Dev'
          ..tipoRegistro = SubmissionTipoRegistro.manutencao
          ..status = SubmissionStatus.gerado
          ..enviadoNuvem = false
          ..epubPath = epubDev.path;
        await banco.salvarSubmissao(recDev);

        final resultadoPublicacao =
            await syncDevSemAppCheck.publicarEAguardarLiberacao(
              idSessao: 'sessao_dev_mock',
              epubPath: epubDev.path,
            );
        expect(
          resultadoPublicacao.etapa,
          equals(EtapaPublicacaoLaudo.concluidoAtivo),
        );

        // Exercita publicarEAguardarLiberacao com sessão avulsa ainda não persistida no banco
        final resultadoAvulso =
            await syncDevSemAppCheck.publicarEAguardarLiberacao(
              idSessao: 'sessao_avulsa_dev',
              epubPath: epubDev.path,
            );
        expect(
          resultadoAvulso.etapa,
          equals(EtapaPublicacaoLaudo.concluidoAtivo),
        );

        final salvoNoBanco = await banco.obterSubmissaoPorIdSessao(
          'sessao_dev_mock',
        );
        expect(salvoNoBanco?.enviadoNuvem, isTrue);
        expect(
          loggerMockDev.infosRegistrados,
          contains(contains('📝 [DEBUG MOCK] Upload de laudo concluído localmente')),
        );

        final restauradosDev = await syncDevSemAppCheck
            .restaurarRelatoriosDaConta(diretorioBase: tempDir);
        expect(restauradosDev, equals(0));
        expect(
          loggerMockDev.infosRegistrados,
          contains(
            contains('📝 [DEBUG MOCK] Restauração de relatórios concluída localmente'),
          ),
        );

        // Em modo release (emModoDesenvolvimento: false), não usa mock gracioso e tenta a rede real
        final syncRelease = SincronizadorNuvemService(
          banco: banco,
          autenticacaoService: auth,
          clienteHttp: clienteHttp,
          logger: loggerMockDev,
          emModoDesenvolvimento: false,
        );
        recDev.enviadoNuvem = false;
        expect(await syncRelease.enviarSubmissao(recDev), isFalse);
      },
    );

    test(
      'propaga progresso verificacaoConcluida/verificacaoTotal do D1, aciona notificacao sticky e falha imediatamente em HTTP >= 400 sem ficar em loop',
      () async {
        final pluginNotif = PluginNotificacoesLocaisFake();
        final gerenciadorNotif = GerenciadorNotificacaoUploadLaudo.paraTestes(
          plugin: pluginNotif,
        );
        final syncComNotif = SincronizadorNuvemService(
          banco: banco,
          autenticacaoService: auth,
          clienteHttp: clienteHttp,
          gerenciadorNotificacao: gerenciadorNotif,
          intervaloPollingModeracao: const Duration(milliseconds: 5),
        );

        final epubOk = File(p.join(tempDir.path, 'progresso_d1.epub'))
          ..writeAsBytesSync(_criarZipEpubTeste());
        final recOk = SubmissionRecord()
          ..idSessao = 's_progresso_d1'
          ..idProtocolo = 'material_registration'
          ..nomeProtocolo = 'Cadastro de Material'
          ..tituloExibicao = 'Barras Roscadas Inox'
          ..tipoRegistro = SubmissionTipoRegistro.material
          ..status = SubmissionStatus.gerado
          ..epubPath = epubOk.path
          ..enviadoNuvem = false;
        await banco.salvarSubmissao(recOk);

        clienteHttp.consultasEmAnaliseAntesDeAtivar['s_progresso_d1'] = 2;
        final progressos = <ProgressoPublicacaoLaudo>[];
        final resOk = await syncComNotif.publicarEAguardarLiberacao(
          idSessao: 's_progresso_d1',
          epubPath: epubOk.path,
          aoProgredir: progressos.add,
        );

        expect(resOk.etapa, equals(EtapaPublicacaoLaudo.concluidoAtivo));
        expect(resOk.fracaoVerificacao, equals(1.0));
        expect(resOk.fracaoCombinada, equals(1.0));
        expect(
          progressos.any(
            (p) =>
                p.etapa ==
                    EtapaPublicacaoLaudo.aguardandoVerificacaoServidor &&
                p.verificacaoTotal >= 2,
          ),
          isTrue,
        );
        // Notificação sticky iniciada e depois substituída por notificação de conclusão
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(pluginNotif.androidFake!.servicosIniciados, isNotEmpty);
        expect(
          pluginNotif.notificacoesExibidas.last.corpo,
          contains('Toque para abrir o laudo e compartilhar'),
        );

        // Testa erro HTTP 400 real em ClienteHttpFixalogNuvemPadrao (consultarStatusLaudo e enviarChunkEpub)
        final serverErro = await HttpServer.bind(
          InternetAddress.loopbackIPv4,
          0,
        );
        addTearDown(serverErro.close);
        serverErro.listen((HttpRequest req) async {
          await req.drain<void>();
          req.response.statusCode = 400;
          req.response.write(
            jsonEncode({
              'erro':
                  'O claim nonce do atestado_oidc_jwt não corresponde ao hash SHA-256 da chave pública ECDSA.',
            }),
          );
          await req.response.close();
        });

        final clienteHttpErro = ClienteHttpFixalogNuvemPadrao(
          urlBase: 'http://127.0.0.1:${serverErro.port}',
        );
        await expectLater(
          clienteHttpErro.consultarStatusLaudo(
            idSessao: 's_400',
            sha256: 'abc',
            jwtSupabase: 'jwt',
            tokenAppCheck: 'appcheck',
          ),
          throwsA(
            isA<ExcecaoApiFixalogNuvem>().having(
              (e) => e.statusCode,
              'statusCode',
              400,
            ),
          ),
        );
        await expectLater(
          clienteHttpErro.enviarChunkEpub(
            idSessao: 's_400',
            sha256: 'abc',
            index: 0,
            total: 1,
            chunkBytes: Uint8List.fromList([1, 2, 3]),
            jwtSupabase: 'jwt',
            tokenAppCheck: 'appcheck',
          ),
          throwsA(
            isA<ExcecaoApiFixalogNuvem>().having(
              (e) => e.toString(),
              'mensagem',
              contains('nonce'),
            ),
          ),
        );

        // E valida que publicarEAguardarLiberacao retorna rejeitadoOuFalha imediatamente em erro HTTP 400 no chunk
        clienteHttp.erroHttpChunkPorSessao['s_falha_400'] =
            const ExcecaoApiFixalogNuvem(
              400,
              'Assinatura XML-DSig inválida no pacote.',
            );
        final rec400 = SubmissionRecord()
          ..idSessao = 's_falha_400'
          ..idProtocolo = 'manutencao_ferragens'
          ..nomeProtocolo = 'Via Inválida'
          ..tipoRegistro = SubmissionTipoRegistro.manutencao
          ..status = SubmissionStatus.gerado
          ..epubPath = epubOk.path
          ..enviadoNuvem = false;
        await banco.salvarSubmissao(rec400);

        final resFalha400 = await syncComNotif.publicarEAguardarLiberacao(
          idSessao: 's_falha_400',
          epubPath: epubOk.path,
        );
        expect(
          resFalha400.etapa,
          equals(EtapaPublicacaoLaudo.rejeitadoOuFalha),
        );
        expect(
          resFalha400.mensagemErro,
          contains('Assinatura XML-DSig inválida'),
        );

        // E valida erro HTTP 403 direto no consultarStatusLaudo
        clienteHttp.erroHttpPorSessao['s_403_status'] =
            const ExcecaoApiFixalogNuvem(
              403,
              'Apenas a conta proprietária do laudo pode consultar seu status.',
            );
        final resFalha403 = await syncComNotif.publicarEAguardarLiberacao(
          idSessao: 's_403_status',
          epubPath: epubOk.path,
        );
        expect(
          resFalha403.etapa,
          equals(EtapaPublicacaoLaudo.rejeitadoOuFalha),
        );
        expect(
          resFalha403.mensagemErro,
          contains('conta proprietária'),
        );
      },
    );
  });
}
