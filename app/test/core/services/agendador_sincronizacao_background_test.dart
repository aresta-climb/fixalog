// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:fixalog/core/models/local/feedback_record.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/core/services/agendador_sincronizacao_background.dart';
import 'package:fixalog/core/services/autenticacao_nuvem_service.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/services/sincronizador_nuvem_service.dart';
import 'package:fixalog/features/feedback/services/servico_fila_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import '../../fakes/crypto_service_fake.dart';
import 'autenticacao_nuvem_service_fake.dart';
import 'sincronizador_nuvem_service_fake.dart';

Uint8List _criarEpubMinimo() {
  final archive = Archive();
  final bytes = utf8.encode('<html><body>Laudo</body></html>');
  archive.addFile(ArchiveFile('OEBPS/relatorio.xhtml', bytes.length, bytes));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  late Directory tempDir;
  late BancoDadosLocal banco;
  late AutenticacaoNuvemServiceFake auth;
  late ClienteHttpFixalogNuvemFake clienteNuvem;
  late SincronizadorNuvemService sincronizadorNuvem;
  late ServicoFilaFeedback servicoFeedback;
  int chamadasFeedbackHttp = 0;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('fixalog_agendador_bg_test_');
    banco = await BancoDadosLocal.abrirEmMemoria();
    auth = AutenticacaoNuvemServiceFake(crypto: CryptoServiceFake());
    await auth.entrarComProvedorOidc(ProvedorOidc.google);
    clienteNuvem = ClienteHttpFixalogNuvemFake();
    sincronizadorNuvem = SincronizadorNuvemService(
      banco: banco,
      autenticacaoService: auth,
      clienteHttp: clienteNuvem,
    );
    chamadasFeedbackHttp = 0;
    servicoFeedback = ServicoFilaFeedback(
      banco: banco,
      autenticacaoService: auth,
      obterDiretorioSuporte: () async => tempDir,
      urlEdgeFunction: 'https://fixalog.app/feedback',
      clienteHttp: MockClient((req) async {
        chamadasFeedbackHttp++;
        return http.Response('{"ok":true}', 200);
      }),
    );
  });

  tearDown(() async {
    await banco.fechar();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('AgendadorSincronizacaoBackground', () {
    test('Aborta instantaneamente em Modo Avião sem realizar chamadas HTTP e aplica backoff', () async {
      final epubFile = File(p.join(tempDir.path, 'pendente.epub'))
        ..writeAsBytesSync(_criarEpubMinimo());
      await banco.salvarSubmissao(
        SubmissionRecord()
          ..idSessao = 's_aviao'
          ..idProtocolo = 'manutencao_ferragens'
          ..nomeProtocolo = 'Via Offline'
          ..tipoRegistro = SubmissionTipoRegistro.manutencao
          ..status = SubmissionStatus.gerado
          ..epubPath = epubFile.path
          ..enviadoNuvem = false,
      );

      final agendador = AgendadorSincronizacaoBackground(
        banco: banco,
        sincronizadorNuvem: sincronizadorNuvem,
        servicoFilaFeedback: servicoFeedback,
        verificadorRedeAtiva: () async => false,
        intervalosBackoff: const [
          Duration(milliseconds: 20),
          Duration(milliseconds: 40),
        ],
      );
      addTearDown(agendador.cancelarTimer);

      final executou = await agendador.executarCicloSeNecessario();
      expect(executou, isFalse);
      // Nenhuma requisição HTTP foi disparada em Modo Avião
      expect(clienteNuvem.ordemIdsEnviados, isEmpty);
      expect(chamadasFeedbackHttp, equals(0));
      expect(agendador.timerAtivo, isTrue);
      expect(agendador.indiceBackoffAtual, equals(1));
    });

    test('Processa filas pendentes de laudos e feedbacks quando há rede e desliga timer ao zerar fila', () async {
      final epubFile = File(p.join(tempDir.path, 'laudo_ok.epub'))
        ..writeAsBytesSync(_criarEpubMinimo());
      await banco.salvarSubmissao(
        SubmissionRecord()
          ..idSessao = 's_sync_bg'
          ..idProtocolo = 'manutencao_ferragens'
          ..nomeProtocolo = 'Via Online'
          ..tipoRegistro = SubmissionTipoRegistro.manutencao
          ..status = SubmissionStatus.gerado
          ..epubPath = epubFile.path
          ..enviadoNuvem = false,
      );
      await banco.inserirFeedback(
        FeedbackRecord(
          idFeedback: 'fb_1',
          mensagem: 'Feedback pendente',
          categoria: 'aplicativo',
          caminhoImagem: '',
          metadadosJson: '{}',
          dataCriacao: DateTime.utc(2026, 11, 9),
          enviado: false,
        ),
      );

      bool redeAtiva = true;
      final agendador = AgendadorSincronizacaoBackground(
        banco: banco,
        sincronizadorNuvem: sincronizadorNuvem,
        servicoFilaFeedback: servicoFeedback,
        verificadorRedeAtiva: () async => redeAtiva,
        intervalosBackoff: const [Duration(milliseconds: 15)],
      );
      addTearDown(agendador.cancelarTimer);

      // Se falhar na primeira tentativa HTTP, mantém timer ativo para retry com backoff
      clienteNuvem.deveLancarErroRede = true;
      final execucoesConcorrentes = await Future.wait([
        agendador.iniciarMonitoramento(),
        agendador.executarCicloSeNecessario(),
      ]);
      expect(execucoesConcorrentes, contains(true));
      expect(agendador.timerAtivo, isTrue);

      // Restaura rede e aguarda o timer periódico processar e zerar a fila
      clienteNuvem.deveLancarErroRede = false;
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(clienteNuvem.ordemIdsEnviados, contains('s_sync_bg'));
      expect(chamadasFeedbackHttp, equals(1));
      expect(await agendador.possuiItensPendentes(), isFalse);
      expect(agendador.timerAtivo, isFalse);
      expect(agendador.indiceBackoffAtual, equals(0));

      // Com fila vazia, aoRetomarAplicativo retorna imediatamente sem ligar timer
      await agendador.aoRetomarAplicativo();
      expect(agendador.timerAtivo, isFalse);
    });

    test('Valida verificador de interface de rede padrão, ausência de banco e provider Riverpod', () async {
      final resultadoInterface =
          await AgendadorSincronizacaoBackground.verificarInterfaceRedeAtivaPadrao();
      expect(resultadoInterface, isA<bool>());

      final semBanco = AgendadorSincronizacaoBackground(
        banco: null,
        sincronizadorNuvem: sincronizadorNuvem,
        servicoFilaFeedback: servicoFeedback,
      );
      expect(await semBanco.possuiItensPendentes(), isFalse);
      expect(await semBanco.executarCicloSeNecessario(), isFalse);

      final container = ProviderContainer(
        overrides: [bancoDadosLocalProvider.overrideWithValue(banco)],
      );
      addTearDown(container.dispose);
      expect(
        container.read(agendadorSincronizacaoBackgroundProvider),
        isA<AgendadorSincronizacaoBackground>(),
      );
    });
  });
}
