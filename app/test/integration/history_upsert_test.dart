import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:app/core/models/local/submission_record.dart';
import 'package:app/features/express_form/viewmodels/express_form_view_model.dart';
import 'package:app/features/pdf_generation/providers/generation_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/core/services/session_bundle_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io';

class MockSessionBundleManager extends Mock implements SessionBundleManager {}
class MockImagePicker extends Mock implements ImagePicker {}

void main() {
  late Isar isar;
  late MockSessionBundleManager mockSessionManager;
  late MockImagePicker mockPicker;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    registerFallbackValue(Uint8List(0));
  });

  setUp(() async {
    isar = await Isar.open(
      [SubmissionRecordSchema],
      directory: '',
      name: 'test_upsert_isar',
    );
    mockSessionManager = MockSessionBundleManager();
    mockPicker = MockImagePicker();
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  test('Deve atualizar (Upsert) o mesmo SubmissionRecord em vez de duplicar', () async {
    final sessionId = 'test-session-uuid-123';
    final viewModel = ExpressFormViewModel(
      picker: mockPicker,
      sessionManager: mockSessionManager,
      isar: isar,
    );

    // Mockar retornos do SessionManager
    when(() => mockSessionManager.saveManifest(
          sessionId: any(named: 'sessionId'),
          binarypb: any(named: 'binarypb'),
        )).thenAnswer((_) async => throw UnimplementedError('Mocked out'));

    when(() => mockSessionManager.saveManifestJson(
          sessionId: any(named: 'sessionId'),
          jsonStr: any(named: 'jsonStr'),
        )).thenAnswer((_) async => throw UnimplementedError('Mocked out'));

    when(() => mockSessionManager.getMediaFilePath(
          sessionId: any(named: 'sessionId'),
          mediaUuid: any(named: 'mediaUuid'),
          extension: any(named: 'extension'),
        )).thenAnswer((_) async => '/mock/path/registro.binarypb');

    // 1. Simula salvamento do formulário expresso (Criação inicial)
    // Precisamos mockar os manifestos pois o viewModel tenta salvá-los, mas para este teste
    // podemos apenas ignorar a parte de gravação de arquivos e focar no Isar, chamando
    // o código correspondente diretamente, ou usando a função saveSession original com mocks que não quebram.
    // Vamos usar a lógica real, então vamos ajustar os mocks para não lançarem erro.
    when(() => mockSessionManager.saveManifest(
          sessionId: any(named: 'sessionId'),
          binarypb: any(named: 'binarypb'),
        )).thenAnswer((_) async => File('dummy_manifest.pb'));
    when(() => mockSessionManager.saveManifestJson(
          sessionId: any(named: 'sessionId'),
          jsonStr: any(named: 'jsonStr'),
        )).thenAnswer((_) async => File('dummy_manifest.json'));

    // Mock para que a chamada real funcione e salve no banco (atribuindo a session ID)
    // Wait, ExpressFormViewModel.saveSession creates a new uuid se `currentSessionId` for null.
    // E então retorna a UUID.
    final generatedSessionId = await viewModel.saveSession();

    // Simula uma re-edição chamando saveSession novamente (o viewModel já tem a sessionId configurada internamente após o primeiro save).
    // Antes da correção, isso duplicaria o registro no banco porque salva um novo SubmissionRecord com a mesma sessionId.
    final regeneratedSessionId = await viewModel.saveSession();
    expect(regeneratedSessionId, generatedSessionId);

    // Verifica que 1 registro foi mantido (Upsert funcionou)
    var records = await isar.submissionRecords.where().findAll();
    expect(records.length, 1);
  });
}
