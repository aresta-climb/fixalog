// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/core/services/autenticacao_nuvem_service.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/services/sincronizador_nuvem_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import '../../fakes/crypto_service_fake.dart';
import '../../fakes/registro_logger_fake.dart';
import 'autenticacao_nuvem_service_fake.dart';
import 'sincronizador_nuvem_service_fake.dart';

Uint8List _criarZipEpubTeste({
  List<String> idsMateriaisAninhados = const [],
  List<int>? binarypbBytes,
}) {
  final archive = Archive();
  final xhtml = utf8.encode('<html><body>Teste</body></html>');
  archive.addFile(ArchiveFile('OEBPS/relatorio.xhtml', xhtml.length, xhtml));
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
    );
  });

  tearDown(() async {
    await banco.fechar();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('SincronizadorNuvemService — Fila de Upload, Versionamento e Restauração', () {
    test('obterUrlCompartilhamentoPublico retorna URL canônica https://fixalog.app/v/<id>', () {
      expect(
        SincronizadorNuvemService.obterUrlCompartilhamentoPublico('sessao_123'),
        equals('https://fixalog.app/v/sessao_123'),
      );
      final metaPadrao = MetadadosLaudoRemoto.deJson({});
      expect(metaPadrao.idSessao, isEmpty);
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

    test('sincronizarPendentes processa fila ordenada e cria nova versão quando laudo é re-editado', () async {
      final epub1 = File(p.join(tempDir.path, 's_v1.epub'))
        ..writeAsBytesSync(_criarZipEpubTeste());

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

      // Remove o pendente com falha e simula re-edição de s_versionado
      await banco.deletarSubmissaoPorIdSessao('s_falha_sem_arquivo');
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
  });
}
