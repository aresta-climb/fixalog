import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/models/proto/protos/wizard.pb.dart';
import 'package:app/core/models/proto/protos/registro.pb.dart';
import 'package:app/features/wizard/controllers/wizard_state_controller.dart';
import 'package:app/core/services/session_bundle_manager.dart';
import 'package:app/features/identity/viewmodels/identity_form_view_model.dart' show isarProvider;

class MockSessionBundleManager extends Mock implements SessionBundleManager {}

void main() {
  late MockSessionBundleManager mockSessionManager;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockSessionManager = MockSessionBundleManager();

    // Setup dummy Directory for SessionBundleManager
    final dummyDir = Directory.systemTemp.createTempSync('dummy_session_');
    when(() => mockSessionManager.getSessionDirectory(any()))
        .thenAnswer((_) async => dummyDir);
    
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
        isarProvider.overrideWithValue(null), // Provide null since we're not testing DB writes
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('WizardStateController Persistence & Media Tests', () {
    test('saveMediaAnswerBytes should save original media and store ReferenciaMidia', () async {
      final notifier = container.read(wizardControllerProvider.notifier);
      
      // Load protocol to get a valid sessionId
      notifier.loadProtocol(DefinicaoProtocolo(id: 'test_proto'));
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
      expect(resposta.midia.imagem.hashOriginal, isNotEmpty, reason: 'Deve calcular o hash SHA-256');
      expect(resposta.midia.imagem.tipoOriginal, equals('image/jpg'));

      verify(() => mockSessionManager.saveOriginalMedia(
            sessionId: stateAntes.sessionId,
            mediaUuid: any(named: 'mediaUuid'),
            extension: '.jpg',
            bytes: dummyBytes,
          )).called(1);
    });
    test('saveSession should build Registro and save manifest with yaml_conteudo', () async {
      final notifier = container.read(wizardControllerProvider.notifier);
      
      final rawYaml = 'id: test_proto_2\nversao: 1.0.0';
      notifier.loadProtocol(DefinicaoProtocolo(
        id: 'test_proto_2',
        nome: 'Proto 2',
        versao: '1.0.0',
      ), rawYaml: rawYaml);
      
      final dummyBytes = Uint8List.fromList([1, 2, 3]);
      await notifier.saveMediaAnswerBytes(
        'conteudo_foto_1',
        dummyBytes,
        '.jpg',
        StepCampoSimples_TipoCampo.IMAGE,
      );
      
      final sessionId = await notifier.saveSession();
      expect(sessionId, isNotEmpty);
      
      final captured = verify(() => mockSessionManager.saveManifest(
            sessionId: sessionId,
            binarypb: captureAny(named: 'binarypb'),
          )).captured;

      expect(captured.length, 1);
      final bytes = captured.first as Uint8List;
      final registro = Registro.fromBuffer(bytes);

      expect(registro.idSessao, sessionId);
      expect(registro.idProtocolo, 'test_proto_2');
      expect(registro.yamlConteudo, rawYaml);
    });

    test('loadSession should reconstruct state from binarypb', () async {
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

    test('saveSession on edited session should update manifest preserving same sessionId', () async {
      final notifier = container.read(wizardControllerProvider.notifier);
      final sessionId = 'test_session_id_edit';
      
      final rawYaml = 'id: "test_protocol"\nnome: "Test Protocol"\nversao: "1.0.0"\nblocos:\n  - id: "b1"\n    steps:\n      - conteudos:\n          - id: "c1"\n            campo_simples:\n              tipo: "TEXT"';
      
      final registro = Registro(
        idSessao: sessionId,
        idProtocolo: 'test_protocol',
        versaoProtocolo: '1.0.0',
        yamlConteudo: rawYaml,
      );
      registro.respostas['c1'] = Resposta(texto: 'Old Value');
      
      when(() => mockSessionManager.readManifest(sessionId: sessionId))
          .thenAnswer((_) async => registro.writeToBuffer());
          
      // 1. Carrega sessão pré-existente
      await notifier.loadSession(sessionId);
      
      // 2. Altera resposta
      notifier.answerConteudo('c1', Resposta(texto: 'Updated Value'));
      
      // 3. Salva sessão novamente
      final savedId = await notifier.saveSession();
      expect(savedId, equals(sessionId));
      
      final captured = verify(() => mockSessionManager.saveManifest(
            sessionId: sessionId,
            binarypb: captureAny(named: 'binarypb'),
          )).captured;
          
      final bytes = captured.last as Uint8List;
      final updatedRegistro = Registro.fromBuffer(bytes);
      expect(updatedRegistro.idSessao, sessionId);
      expect(updatedRegistro.respostas['c1']?.texto, 'Updated Value');
    });
  });
}
