import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:app/core/models/local/submission_record.dart';
import 'package:app/features/express_form/viewmodels/express_form_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/core/services/session_bundle_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:app/core/models/proto/registro.pb.dart';

class MockSessionBundleManager extends Mock implements SessionBundleManager {}
class MockImagePicker extends Mock implements ImagePicker {}

void main() {
  late Isar isar;
  late MockSessionBundleManager mockSessionManager;
  late MockImagePicker mockPicker;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(ImageSource.camera);
  });

  setUp(() async {
    isar = await Isar.open(
      [SubmissionRecordSchema],
      directory: '',
      name: 'test_reopen_isar',
    );
    mockSessionManager = MockSessionBundleManager();
    mockPicker = MockImagePicker();
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  test('Deve salvar e carregar corretamente a descrição e caminho original da foto', () async {
    final sessionId = 'test-session-uuid-456';
    final viewModel = ExpressFormViewModel(
      picker: mockPicker,
      sessionManager: mockSessionManager,
      isar: isar,
    );

    // Mockar criação de arquivos dummy
    final tempDir = Directory.systemTemp.createTempSync();
    final dummyPhoto = File('${tempDir.path}/dummy.jpg')..writeAsBytesSync([1,2,3]);

    when(() => mockSessionManager.saveManifest(
          sessionId: any(named: 'sessionId'),
          binarypb: any(named: 'binarypb'),
        )).thenAnswer((invocation) async {
          final bytes = invocation.namedArguments[#binarypb] as List<int>;
          final f = File('${tempDir.path}/manifest.pb');
          await f.writeAsBytes(bytes);
          return f;
        });

    when(() => mockSessionManager.saveManifestJson(
          sessionId: any(named: 'sessionId'),
          jsonStr: any(named: 'jsonStr'),
        )).thenAnswer((_) async => File('${tempDir.path}/manifest.json'));

    when(() => mockSessionManager.readManifest(sessionId: any(named: 'sessionId')))
        .thenAnswer((invocation) async {
          final f = File('${tempDir.path}/manifest.pb');
          return f.readAsBytes();
        });

    when(() => mockSessionManager.saveOriginalMedia(
          sessionId: any(named: 'sessionId'),
          mediaUuid: any(named: 'mediaUuid'),
          extension: any(named: 'extension'),
          bytes: any(named: 'bytes'),
        )).thenAnswer((_) async => File('${tempDir.path}/photo.jpg'));

    when(() => mockSessionManager.getMediaFilePath(
          sessionId: any(named: 'sessionId'),
          mediaUuid: any(named: 'mediaUuid'),
          extension: any(named: 'extension'),
        )).thenAnswer((invocation) async {
          final uuid = invocation.namedArguments[#mediaUuid] as String;
          final ext = invocation.namedArguments[#extension] as String;
          if (uuid == 'registro' && ext == '.binarypb') {
             return '${tempDir.path}/manifest.pb';
          }
          return '${tempDir.path}/$uuid$ext';
        });

    // Configura o ViewModel com um dado preenchido pelo usuário
    // Como não há método `addEntry` puro, vamos modificar a list `state` diretamente simulando o adicionar
    // ou simulando um pick:
    when(() => mockPicker.pickImage(
          source: any(named: 'source'),
          imageQuality: any(named: 'imageQuality'),
        )).thenAnswer((_) async => XFile(dummyPhoto.path));

    await viewModel.takePhoto();
    
    // Atualiza a descrição
    viewModel.updateDescription(0, 'Testando descrição do buraco');

    // Salvar sessão
    final savedSessionId = await viewModel.saveSession();

    // Instancia um ViewModel LIMPO para simular abertura
    final viewModelLoad = ExpressFormViewModel(
      picker: mockPicker,
      sessionManager: mockSessionManager,
      isar: isar,
    );

    await viewModelLoad.loadSession(savedSessionId);

    expect(viewModelLoad.state.length, 1);
    expect(viewModelLoad.state.first.description, 'Testando descrição do buraco');
    expect(viewModelLoad.state.first.mediaPath, contains('_original.jpg'));
  });
}
