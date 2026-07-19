import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/features/express_form/viewmodels/express_form_view_model.dart';

import 'dart:io';
import 'dart:typed_data';
import 'package:app/core/services/session_bundle_manager.dart';
import 'package:app/core/models/proto/registro.pb.dart';
import 'package:app/features/identity/viewmodels/identity_form_view_model.dart' show isarProvider;
import 'package:isar_community/isar.dart';

class MockImagePicker extends Mock implements ImagePicker {}

class MockXFile extends Mock implements XFile {}

class MockSessionBundleManager extends Mock implements SessionBundleManager {}

class FakeIsar extends Fake implements Isar {
  @override
  Future<T> writeTxn<T>(Future<T> Function() callback, {bool silent = false}) async {
    return await callback();
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  late MockImagePicker mockPicker;
  late MockSessionBundleManager mockSessionManager;
  late FakeIsar mockIsar;
  late ExpressFormViewModel viewModel;

  setUp(() {
    mockPicker = MockImagePicker();
    mockSessionManager = MockSessionBundleManager();
    mockIsar = FakeIsar();
    viewModel = ExpressFormViewModel(
      picker: mockPicker,
      sessionManager: mockSessionManager,
    );
  });

  group('ExpressFormViewModel', () {
    test('Initial state is empty', () {
      expect(viewModel.state, isEmpty);
    });

    test('takePhoto should add an entry with mediaPath if photo is taken', () async {
      final mockFile = MockXFile();
      when(() => mockFile.path).thenReturn('/tmp/foto.jpg');
      
      when(
        () =>
            mockPicker.pickImage(source: ImageSource.camera, imageQuality: 70),
      ).thenAnswer((_) async => mockFile);

      await viewModel.takePhoto();

      expect(viewModel.state.length, 1);
      expect(viewModel.state.first.mediaPath, '/tmp/foto.jpg');
      expect(viewModel.state.first.description, isEmpty);
      expect(viewModel.state.first.isVideo, isFalse);
    });

    test('takePhoto should do nothing if photo is null (cancelled)', () async {
      when(
        () =>
            mockPicker.pickImage(source: ImageSource.camera, imageQuality: 70),
      ).thenAnswer((_) async => null);

      await viewModel.takePhoto();

      expect(viewModel.state, isEmpty);
    });

    test('updateDescription should update description if index is valid', () {
      viewModel.state = [
        ExpressEntry(mediaPath: '/tmp/foto1.jpg'),
      ];

      viewModel.updateDescription(0, 'Nova descrição');

      expect(viewModel.state[0].description, 'Nova descrição');
    });

    test('updateDescription should do nothing if index is invalid', () {
      viewModel.state = [
        ExpressEntry(mediaPath: '/tmp/foto1.jpg'),
      ];

      viewModel.updateDescription(1, 'Nova descrição');

      expect(viewModel.state[0].description, isEmpty);
    });

    test('removeEntry should remove entry if index is valid', () {
      viewModel.state = [
        ExpressEntry(mediaPath: '/tmp/foto1.jpg'),
        ExpressEntry(mediaPath: '/tmp/foto2.jpg'),
      ];

      viewModel.removeEntry(0);

      expect(viewModel.state.length, 1);
      expect(viewModel.state[0].mediaPath, '/tmp/foto2.jpg');
    });

    test('removeEntry should do nothing if index is invalid', () {
      viewModel.state = [
        ExpressEntry(mediaPath: '/tmp/foto1.jpg'),
      ];

      viewModel.removeEntry(1);

      expect(viewModel.state.length, 1);
    });

    test('copyWith on ExpressEntry with no parameters returns same values', () {
      final entry = ExpressEntry(
        mediaPath: '/tmp/foto1.jpg',
        description: 'Test',
        isVideo: true,
      );
      final copy = entry.copyWith();

      expect(copy.mediaPath, '/tmp/foto1.jpg');
      expect(copy.description, 'Test');
      expect(copy.isVideo, true);
    });

    test('generateManifest should convert state to RegistroManutencao protobuf', () {
      viewModel.state = [
        ExpressEntry(mediaPath: '/tmp/foto1.jpg', description: 'Desc 1', isVideo: false),
        ExpressEntry(mediaPath: '/tmp/vid1.mp4', description: 'Desc 2', isVideo: true),
      ];
      
      final manifest = viewModel.generateManifest('session-123');
      
      expect(manifest.idSessao, 'session-123');
      expect(manifest.acoes.length, 2);
      expect(manifest.acoes[0].outro.descricao, 'Desc 1');
      expect(manifest.acoes[0].outro.foto.imagem.tipoOriginal, 'image/jpeg');
      expect(manifest.acoes[1].outro.descricao, 'Desc 2');
      expect(manifest.acoes[1].outro.video.video.tipoOriginal, 'video/mp4');
    });

    test('loadSession should parse binarypb and restore state', () async {
      final manifest = RegistroManutencao(idSessao: 'session-123');
      final acao = AcaoManutencao(
        outro: DetalheAcaoCustomizada(
          descricao: 'Carregado',
          foto: ReferenciaMidia(
            imagem: ArquivoImagem(
              uuid: 'img-123',
              tipoOriginal: 'image/jpeg',
              hashOriginal: 'hash',
              tipoComprimido: 'image/jpeg',
              hashComprimido: 'hash2',
              versaoCompressao: 1,
            ),
          ),
        ),
      );
      manifest.acoes.add(acao);
      
      when(() => mockSessionManager.readManifest(sessionId: 'session-123'))
          .thenAnswer((_) async => manifest.writeToBuffer());
          
      when(() => mockSessionManager.getMediaFilePath(sessionId: 'session-123', mediaUuid: 'img-123', extension: '.jpg'))
          .thenAnswer((_) async => '/mock/session-123/img-123.jpg');

      await viewModel.loadSession('session-123');

      expect(viewModel.state.length, 1);
      expect(viewModel.state[0].description, 'Carregado');
      expect(viewModel.state[0].mediaPath, '/mock/session-123/img-123.jpg');
      expect(viewModel.state[0].uuid, 'img-123');
    });

    test('saveSession should generate hashes, save original media, and save json manifest', () async {
      // Mock File reads - wait, since File is used directly inside the view model,
      // testing file reads is tricky unless we mock it or create a real file.
      // Let's create a real temporary file.
      final tempDir = Directory.systemTemp.createTempSync('express_test');
      final tempFile = File('${tempDir.path}/test_image.jpg');
      await tempFile.writeAsBytes([1, 2, 3]);

      viewModel.state = [
        ExpressEntry(mediaPath: tempFile.path, description: 'Test Hash', isVideo: false),
      ];

      when(() => mockSessionManager.saveOriginalMedia(
        sessionId: any(named: 'sessionId'),
        mediaUuid: any(named: 'mediaUuid'),
        extension: any(named: 'extension'),
        bytes: any(named: 'bytes'),
      )).thenAnswer((_) async => File(''));

      when(() => mockSessionManager.saveManifest(
        sessionId: any(named: 'sessionId'),
        binarypb: any(named: 'binarypb'),
      )).thenAnswer((_) async => File(''));

      when(() => mockSessionManager.saveManifestJson(
        sessionId: any(named: 'sessionId'),
        jsonStr: any(named: 'jsonStr'),
      )).thenAnswer((_) async => File(''));

      when(() => mockSessionManager.getMediaFilePath(
        sessionId: any(named: 'sessionId'),
        mediaUuid: any(named: 'mediaUuid'),
        extension: any(named: 'extension'),
      )).thenAnswer((_) async => '/mock/path.pb');

      final sessionId = await viewModel.saveSession();

      // Validate that saveManifestJson was called
      final captured = verify(() => mockSessionManager.saveManifestJson(
        sessionId: sessionId,
        jsonStr: captureAny(named: 'jsonStr'),
      )).captured;
      
      final jsonStr = captured.first as String;
      expect(jsonStr, contains('039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81')); // sha256 of [1,2,3]

      // Cleanup
      tempDir.deleteSync(recursive: true);
    });
  });

  group('Dependency Injection', () {
    test('expressFormViewModelProvider injects dependencies correctly', () {
      final container = ProviderContainer(
        overrides: [
          sessionBundleManagerProvider.overrideWithValue(mockSessionManager),
          isarProvider.overrideWithValue(mockIsar),
        ],
      );

      final vm = container.read(expressFormViewModelProvider.notifier);
      
      // We can't access private fields easily, but we can verify it doesn't crash on loadSession
      // when sessionManager is not null. 
      // If it's null, loadSession returns early. Let's mock a crash or just see if it proceeds.
      when(() => mockSessionManager.readManifest(sessionId: 'test-session'))
          .thenThrow(Exception('Injected correctly!'));

      expect(
        () => vm.loadSession('test-session'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Injected correctly!'))),
      );
    });
  });
}
