// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fixalog/core/models/proto/protos/wizard.pb.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/features/wizard/controllers/wizard_state_controller.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';

void main() {
  late SessionBundleManager sessionManager;
  late ProviderContainer container;
  late BancoDadosLocal banco;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wizard_sqlite_test');
    banco = await BancoDadosLocal.abrirEmMemoria();
    sessionManager = SessionBundleManager(
      baseDirectoryGetter: () async => tempDir,
    );

    container = ProviderContainer(
      overrides: [
        sessionBundleManagerProvider.overrideWithValue(sessionManager),
        bancoDadosLocalProvider.overrideWithValue(banco),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await banco.fechar();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('WizardStateController Persistence & Auto-Save Tests (TDD)', () {
    test('saveMediaAnswerBytes deve salvar mídia original, calcular hash e disparar auto-save', () async {
      final notifier = container.read(wizardControllerProvider.notifier);

      notifier.loadProtocol(DefinicaoProtocolo(id: 'test_proto', nome: 'Proto Teste'));
      final stateAntes = container.read(wizardControllerProvider);
      expect(stateAntes.sessionId, isNotEmpty);

      final dummyBytes = Uint8List.fromList([1, 2, 3]);

      await notifier.saveMediaAnswerBytes(
        'conteudo_foto_1',
        dummyBytes,
        '.jpg',
        StepCampoSimples_TipoCampo.IMAGE,
      );
      await notifier.flushAutoSave();

      final stateDepois = container.read(wizardControllerProvider);
      final resposta = stateDepois.answers['conteudo_foto_1'];

      expect(resposta, isNotNull);
      expect(resposta!.hasMidia(), isTrue);
      expect(resposta.midia.hasImagem(), isTrue);
      expect(resposta.midia.imagem.hashOriginal, isNotEmpty);
      expect(resposta.midia.imagem.tipoOriginal, equals('image/jpg'));

      final dirSessao = await sessionManager.getSessionDirectory(stateAntes.sessionId);
      final arqOriginal = File('${dirSessao.path}/${resposta.midia.imagem.uuid}_original.jpg');
      expect(arqOriginal.existsSync(), isTrue);
      expect(arqOriginal.readAsBytesSync(), equals(dummyBytes));

      // Verifica se o auto-save gravou no banco local como EM_PROGRESSO
      final savedRecord = await banco.obterSubmissaoPorIdSessao(stateAntes.sessionId);
      expect(savedRecord, isNotNull);
      expect(savedRecord!.status, equals(SubmissionStatus.emProgresso));
      expect(savedRecord.isEmProgresso, isTrue);
    });

    test('answerConteudo deve disparar auto-save e registrar status EM_PROGRESSO no banco local', () async {
      final notifier = container.read(wizardControllerProvider.notifier);

      notifier.loadProtocol(DefinicaoProtocolo(id: 'proto_auto', nome: 'Auto Save Proto'));
      final sessionId = container.read(wizardControllerProvider).sessionId;

      notifier.answerConteudo('campo_texto', Resposta(texto: 'Texto Preenchido'));
      await notifier.flushAutoSave();

      final bytesManifest = await sessionManager.readManifest(sessionId: sessionId);
      expect(bytesManifest, isNotEmpty);

      final record = await banco.obterSubmissaoPorIdSessao(sessionId);
      expect(record, isNotNull);
      expect(record!.status, equals(SubmissionStatus.emProgresso));
    });

    test('Modificar resposta em sessão anteriormente GERADA deve transicionar status de volta para EM_PROGRESSO', () async {
      const sessionId = 'sessao_gerada_123';

      // Cria registro pré-existente no banco local com status GERADO
      await banco.salvarSubmissao(
        SubmissionRecord()
          ..idSessao = sessionId
          ..idProtocolo = 'proto_gerado'
          ..nomeProtocolo = 'Proto Gerado'
          ..dataInclusao = DateTime.now()
          ..hashAssinatura = 'hash'
          ..pdfPath = '/caminho/relatorio.pdf'
          ..protobufPath = '${tempDir.path}/registro.binarypb'
          ..status = SubmissionStatus.gerado,
      );

      const rawYaml = 'id: "proto_gerado"\nnome: "Proto Gerado"\nversao: "1.0.0"\nblocos:\n  - id: "b1"\n    steps:\n      - conteudos:\n          - id: "c1"\n            campo_simples:\n              tipo: "TEXT"';
      final registro = Registro(
        idSessao: sessionId,
        idProtocolo: 'proto_gerado',
        versaoProtocolo: '1.0.0',
        yamlConteudo: rawYaml,
      );
      registro.respostas['c1'] = Resposta(texto: 'Valor Original');

      await sessionManager.saveManifest(
        sessionId: sessionId,
        binarypb: registro.writeToBuffer(),
      );

      final notifier = container.read(wizardControllerProvider.notifier);
      await notifier.loadSession(sessionId);

      // Verifica que carregou o valor original
      expect(container.read(wizardControllerProvider).answers['c1']?.texto, 'Valor Original');

      // Modifica o campo
      notifier.answerConteudo('c1', Resposta(texto: 'Valor Modificado'));
      await notifier.flushAutoSave();

      // Verifica que no banco local o status transicionou para EM_PROGRESSO
      final updatedRecord = await banco.obterSubmissaoPorIdSessao(sessionId);
      expect(updatedRecord, isNotNull);
      expect(updatedRecord!.status, equals(SubmissionStatus.emProgresso));
      expect(updatedRecord.isEmProgresso, isTrue);
    });

    test('Abrir sessão GERADA e sair sem modificar respostas NÃO deve alterar status nem apagar pdfPath', () async {
      const sessionId = 'sessao_gerada_sem_edicao';

      await banco.salvarSubmissao(
        SubmissionRecord()
          ..idSessao = sessionId
          ..idProtocolo = 'proto_gerado'
          ..nomeProtocolo = 'Proto Gerado'
          ..dataInclusao = DateTime.now()
          ..hashAssinatura = 'hash'
          ..pdfPath = '/caminho/relatorio_gerado.pdf'
          ..protobufPath = '${tempDir.path}/registro.binarypb'
          ..status = SubmissionStatus.gerado,
      );

      const rawYaml = 'id: "proto_gerado"\nnome: "Proto Gerado"\nversao: "1.0.0"\nblocos:\n  - id: "b1"\n    steps:\n      - conteudos:\n          - id: "c1"\n            campo_simples:\n              tipo: "TEXT"';
      final registro = Registro(
        idSessao: sessionId,
        idProtocolo: 'proto_gerado',
        versaoProtocolo: '1.0.0',
        yamlConteudo: rawYaml,
      );
      registro.respostas['c1'] = Resposta(texto: 'Valor Intacto');

      await sessionManager.saveManifest(
        sessionId: sessionId,
        binarypb: registro.writeToBuffer(),
      );

      final notifier = container.read(wizardControllerProvider.notifier);
      await notifier.loadSession(sessionId);

      // Usuário apenas navega pelos steps sem modificar respostas
      notifier.goToStep(0);

      // Executa flush de auto-save (como ocorre ao sair da tela no PopScope)
      await notifier.flushAutoSave();

      // Registro no banco local DEVE continuar GERADO com o mesmo pdfPath
      final record = await banco.obterSubmissaoPorIdSessao(sessionId);
      expect(record, isNotNull);
      expect(record!.status, equals(SubmissionStatus.gerado));
      expect(record.isGerado, isTrue);
      expect(record.pdfPath, equals('/caminho/relatorio_gerado.pdf'));
    });

    test('loadSession deve reconstruir o estado a partir do binarypb', () async {
      final notifier = container.read(wizardControllerProvider.notifier);
      const sessionId = 'test_session_id';

      const rawYaml = 'id: "test_protocol"\nnome: "Test Protocol"\nversao: "1.0.0"\nblocos:\n  - id: "b1"\n    steps:\n      - conteudos:\n          - id: "c1"\n            campo_simples:\n              tipo: "TEXT"';

      final registro = Registro(
        idSessao: sessionId,
        idProtocolo: 'test_protocol',
        versaoProtocolo: '1.0.0',
        yamlConteudo: rawYaml,
      );
      registro.respostas['c1'] = Resposta(texto: 'Restored Text');

      await sessionManager.saveManifest(
        sessionId: sessionId,
        binarypb: registro.writeToBuffer(),
      );

      await notifier.loadSession(sessionId);

      final state = container.read(wizardControllerProvider);
      expect(state.sessionId, sessionId);
      expect(state.protocol?.id, 'test_protocol');
      expect(state.protocolRawYaml, rawYaml);
      expect(state.answers['c1']?.texto, 'Restored Text');
      expect(state.queue.length, 1);
    });
  });
}
