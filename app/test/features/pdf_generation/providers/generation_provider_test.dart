import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fixlog/features/pdf_generation/providers/generation_provider.dart';
import 'package:fixlog/features/pdf_generation/services/pdf_draft_service.dart';
import 'package:fixlog/features/media/services/media_compressor_service.dart';
import 'package:fixlog/features/pdf_generation/services/generation_recovery_service.dart';
import 'package:fixlog/core/services/session_bundle_manager.dart';
import 'package:fixlog/core/models/proto/protos/registro.pb.dart';

import 'package:isar_community/isar.dart';
import 'package:fixlog/core/models/local/submission_record.dart';

class MockPdfDraftService extends Mock implements PdfDraftService {}
class MockMediaCompressorService extends Mock implements MediaCompressorService {}
class MockGenerationRecoveryService extends Mock implements GenerationRecoveryService {}
class MockSessionBundleManager extends Mock implements SessionBundleManager {}

class FakeSubmissionCollection extends Fake implements IsarCollection<SubmissionRecord> {
  int putCalls = 0;
  SubmissionRecord? lastSavedRecord;

  @override
  Future<int> put(SubmissionRecord object) async {
    putCalls++;
    lastSavedRecord = object;
    return 1;
  }

  @override
  QueryBuilder<SubmissionRecord, SubmissionRecord, QFilterCondition> filter() {
    // Just return a dummy or throw something that indicates no record
    throw UnsupportedError('Mock filter');
  }
}

class FakeIsar extends Fake implements Isar {
  final FakeSubmissionCollection fakeCollection = FakeSubmissionCollection();

  @override
  IsarCollection<T> collection<T>() {
    if (T == SubmissionRecord) {
      return fakeCollection as IsarCollection<T>;
    }
    throw UnimplementedError();
  }

  @override
  Future<T> writeTxn<T>(Future<T> Function() callback, {bool silent = false}) {
    return callback();
  }
}

void main() {
  late MockPdfDraftService mockDraftService;
  late MockMediaCompressorService mockMediaService;
  late MockGenerationRecoveryService mockRecoveryService;
  late MockSessionBundleManager mockSessionManager;
  late GenerationNotifier notifier;

  setUp(() {
    mockDraftService = MockPdfDraftService();
    mockMediaService = MockMediaCompressorService();
    mockRecoveryService = MockGenerationRecoveryService();
    mockSessionManager = MockSessionBundleManager();

    notifier = GenerationNotifier(
      mockDraftService,
      mockMediaService,
      mockRecoveryService,
      mockSessionManager,
      FakeIsar(),
    );
    
    registerFallbackValue(File(''));
    registerFallbackValue(Registro());
  });

  test('Deve processar manifest e desenhar draft', () async {
    final fakeWorkspace = Directory.systemTemp.createTempSync('workspace');
    when(() => mockRecoveryService.getWorkspaceDir()).thenAnswer((_) async => fakeWorkspace);
    when(() => mockRecoveryService.markAsProcessing(any())).thenAnswer((_) async {});
    
    // Mock SessionBundleManager
    final registro = Registro()..idProtocolo = 'Test Protocol';
    when(() => mockSessionManager.readManifest(sessionId: any(named: 'sessionId')))
        .thenAnswer((_) async => registro.writeToBuffer());
    when(() => mockSessionManager.getMediaFilePath(sessionId: any(named: 'sessionId'), mediaUuid: any(named: 'mediaUuid'), extension: any(named: 'extension')))
        .thenAnswer((_) async => '/fake/workspace/registro.binarypb');
        
    when(() => mockDraftService.drawDraft(any(), any(), any()))
        .thenAnswer((_) async => File('${fakeWorkspace.path}/draft.pdf')..writeAsStringSync('draft'));

    final outPath = '${fakeWorkspace.path}/output.pdf';
    
    // Agora o startGeneration não recebe mídias como lista. Apenas o path.
    await notifier.startGeneration('Teste', outPath, sessionId: '123');

    final drawDraftCaptured = verify(() => mockDraftService.drawDraft(captureAny(), captureAny(), any())).captured;
    final capturedRegistro = drawDraftCaptured[0] as Registro;
    expect(capturedRegistro.idProtocolo, 'Test Protocol');
    
    fakeWorkspace.deleteSync(recursive: true);
  });

  test('Deve gravar um SubmissionRecord no Isar após a geração do PDF', () async {
    // Arrange
    final fakeWorkspace = Directory.systemTemp.createTempSync('workspace');
    when(() => mockRecoveryService.getWorkspaceDir()).thenAnswer((_) async => fakeWorkspace);
    when(() => mockRecoveryService.markAsProcessing(any())).thenAnswer((_) async {});
    
    final fakeDraft = File('${fakeWorkspace.path}/draft.pdf');
    await fakeDraft.writeAsString('draft fake');
    when(() => mockDraftService.drawDraft(any(), any(), any())).thenAnswer((_) async => fakeDraft);
    
    when(() => mockSessionManager.readManifest(sessionId: any(named: 'sessionId')))
        .thenAnswer((_) async => (Registro()..idProtocolo = 'Test Protocol').writeToBuffer());
    when(() => mockSessionManager.getMediaFilePath(sessionId: any(named: 'sessionId'), mediaUuid: any(named: 'mediaUuid'), extension: any(named: 'extension')))
        .thenAnswer((_) async => '/fake/workspace/registro.binarypb');
        
    final outPath = '${fakeWorkspace.path}/output_final.pdf';
    
    final fakeIsar = FakeIsar();
    notifier = GenerationNotifier(
      mockDraftService,
      mockMediaService,
      mockRecoveryService,
      mockSessionManager,
      fakeIsar,
    );

    // Act
    await notifier.startGeneration('Teste Protocolo', outPath, sessionId: '123');

    // Assert
    expect(fakeIsar.fakeCollection.putCalls, 1, reason: 'Deve chamar o put no IsarCollection<SubmissionRecord> exatamente 1 vez');
    final savedRecord = fakeIsar.fakeCollection.lastSavedRecord!;
    expect(savedRecord.nomeProtocolo, 'Teste Protocolo');
    expect(savedRecord.pdfPath, outPath);
    expect(savedRecord.idSessao, isNotEmpty);
    
    fakeWorkspace.deleteSync(recursive: true);
  });
}
