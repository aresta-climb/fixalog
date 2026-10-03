// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:isar_community/isar.dart';

import 'package:fixalog/core/models/proto/protos/wizard.pb.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/features/wizard/controllers/wizard_state_controller.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';
import 'package:fixalog/features/identity/viewmodels/identity_form_view_model.dart' show isarProvider;

class MockSessionBundleManager extends Mock implements SessionBundleManager {}

void main() {
  late MockSessionBundleManager mockSessionManager;
  late ProviderContainer container;
  late Isar isar;
  late Directory tempDir;

  setUpAll(() async {
    registerFallbackValue(Uint8List(0));
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    mockSessionManager = MockSessionBundleManager();
    tempDir = await Directory.systemTemp.createTemp('wizard_isar_test');

    isar = await Isar.open(
      [SubmissionRecordSchema],
      directory: tempDir.path,
    );

    when(() => mockSessionManager.getSessionDirectory(any()))
        .thenAnswer((_) async => tempDir);
    
    when(() => mockSessionManager.saveOriginalMedia(
          sessionId: any(named: 'sessionId'),
          mediaUuid: any(named: 'mediaUuid'),
          extension: any(named: 'extension'),
          bytes: any(named: 'bytes'),
        )).thenAnswer((_) async => File('dummy_path'));
        
    when(() => mockSessionManager.saveManifest(
          sessionId: any(named: 'sessionId'),
          binarypb: any(named: 'binarypb'),
        )).thenAnswer((_) async => File('dummy_path'));

    container = ProviderContainer(
      overrides: [
        sessionBundleManagerProvider.overrideWithValue(mockSessionManager),
        isarProvider.overrideWithValue(isar),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await isar.close(deleteFromDisk: true);
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

      final stateDepois = container.read(wizardControllerProvider);
      final resposta = stateDepois.answers['conteudo_foto_1'];
      
      expect(resposta, isNotNull);
      expect(resposta!.hasMidia(), isTrue);
      expect(resposta.midia.hasImagem(), isTrue);
      expect(resposta.midia.imagem.hashOriginal, isNotEmpty);
      expect(resposta.midia.imagem.tipoOriginal, equals('image/jpg'));

      verify(() => mockSessionManager.saveOriginalMedia(
            sessionId: stateAntes.sessionId,
            mediaUuid: any(named: 'mediaUuid'),
            extension: '.jpg',
            bytes: dummyBytes,
          )).called(1);

      // Verifica se o auto-save gravou no Isar como EM_PROGRESSO
      final isarRecord = await isar.submissionRecords.where().idSessaoEqualTo(stateAntes.sessionId).findFirst();
      expect(isarRecord, isNotNull);
      expect(isarRecord!.status, equals(SubmissionStatus.emProgresso));
      expect(isarRecord.isEmProgresso, isTrue);
    });

    test('answerConteudo deve disparar auto-save e registrar status EM_PROGRESSO no Isar', () async {
      final notifier = container.read(wizardControllerProvider.notifier);
      
      notifier.loadProtocol(DefinicaoProtocolo(id: 'proto_auto', nome: 'Auto Save Proto'));
      final sessionId = container.read(wizardControllerProvider).sessionId;

      notifier.answerConteudo('campo_texto', Resposta(texto: 'Texto Preenchido'));
      await notifier.flushAutoSave();

      verify(() => mockSessionManager.saveManifest(
            sessionId: sessionId,
            binarypb: captureAny(named: 'binarypb'),
          )).called(greaterThanOrEqualTo(1));

      final record = await isar.submissionRecords.where().idSessaoEqualTo(sessionId).findFirst();
      expect(record, isNotNull);
      expect(record!.status, equals(SubmissionStatus.emProgresso));
    });

    test('Modificar resposta em sessão anteriormente GERADA deve transicionar status de volta para EM_PROGRESSO', () async {
      final sessionId = 'sessao_gerada_123';
      
      // Cria registro pré-existente no Isar com status GERADO
      await isar.writeTxn(() async {
        await isar.submissionRecords.put(
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
      });

      final rawYaml = 'id: "proto_gerado"\nnome: "Proto Gerado"\nversao: "1.0.0"\nblocos:\n  - id: "b1"\n    steps:\n      - conteudos:\n          - id: "c1"\n            campo_simples:\n              tipo: "TEXT"';
      final registro = Registro(
        idSessao: sessionId,
        idProtocolo: 'proto_gerado',
        versaoProtocolo: '1.0.0',
        yamlConteudo: rawYaml,
      );
      registro.respostas['c1'] = Resposta(texto: 'Valor Original');
      
      when(() => mockSessionManager.readManifest(sessionId: sessionId))
          .thenAnswer((_) async => registro.writeToBuffer());

      final notifier = container.read(wizardControllerProvider.notifier);
      await notifier.loadSession(sessionId);

      // Verifica que carregou o valor original
      expect(container.read(wizardControllerProvider).answers['c1']?.texto, 'Valor Original');

      // Modifica o campo
      notifier.answerConteudo('c1', Resposta(texto: 'Valor Modificado'));
      await notifier.flushAutoSave();

      // Verifica que no Isar o status transicionou para EM_PROGRESSO
      final updatedRecord = await isar.submissionRecords.where().idSessaoEqualTo(sessionId).findFirst();
      expect(updatedRecord, isNotNull);
      expect(updatedRecord!.status, equals(SubmissionStatus.emProgresso));
      expect(updatedRecord.isEmProgresso, isTrue);
    });

    test('Abrir sessão GERADA e sair sem modificar respostas NÃO deve alterar status nem apagar pdfPath', () async {
      final sessionId = 'sessao_gerada_sem_edicao';
      
      await isar.writeTxn(() async {
        await isar.submissionRecords.put(
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
      });

      final rawYaml = 'id: "proto_gerado"\nnome: "Proto Gerado"\nversao: "1.0.0"\nblocos:\n  - id: "b1"\n    steps:\n      - conteudos:\n          - id: "c1"\n            campo_simples:\n              tipo: "TEXT"';
      final registro = Registro(
        idSessao: sessionId,
        idProtocolo: 'proto_gerado',
        versaoProtocolo: '1.0.0',
        yamlConteudo: rawYaml,
      );
      registro.respostas['c1'] = Resposta(texto: 'Valor Intacto');
      
      when(() => mockSessionManager.readManifest(sessionId: sessionId))
          .thenAnswer((_) async => registro.writeToBuffer());

      final notifier = container.read(wizardControllerProvider.notifier);
      await notifier.loadSession(sessionId);

      // Usuário apenas navega pelos steps sem modificar respostas
      notifier.goToStep(0);

      // Executa flush de auto-save (como ocorre ao sair da tela no PopScope)
      await notifier.flushAutoSave();

      // Registro no Isar DEVE continuar GERADO com o mesmo pdfPath
      final record = await isar.submissionRecords.where().idSessaoEqualTo(sessionId).findFirst();
      expect(record, isNotNull);
      expect(record!.status, equals(SubmissionStatus.gerado));
      expect(record.isGerado, isTrue);
      expect(record.pdfPath, equals('/caminho/relatorio_gerado.pdf'));
    });

    test('loadSession deve reconstruir o estado a partir do binarypb', () async {
      final notifier = container.read(wizardControllerProvider.notifier);
      final sessionId = 'test_session_id';
      
      final rawYaml = 'id: "test_protocol"\nnome: "Test Protocol"\nversao: "1.0.0"\nblocos:\n  - id: "b1"\n    steps:\n      - conteudos:\n          - id: "c1"\n            campo_simples:\n              tipo: "TEXT"';
      
      final registro = Registro(
        idSessao: sessionId,
        idProtocolo: 'test_protocol',
        versaoProtocolo: '1.0.0',
        yamlConteudo: rawYaml,
      );
      registro.respostas['c1'] = Resposta(texto: 'Restored Text');
      
      when(() => mockSessionManager.readManifest(sessionId: sessionId))
          .thenAnswer((_) async => registro.writeToBuffer());
          
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
