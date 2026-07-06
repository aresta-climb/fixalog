import 'dart:io';
import 'package:app/features/pdf_generation/models/generation_media.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/features/pdf_generation/providers/generation_provider.dart';
import 'package:app/features/pdf_generation/services/pdf_draft_service.dart';
import 'package:app/features/media/services/media_compressor_service.dart';
import 'package:app/features/pdf_generation/services/generation_recovery_service.dart';

import 'package:isar_community/isar.dart';
import 'package:app/core/models/local/submission_record.dart';

class MockPdfDraftService extends Mock implements PdfDraftService {}
class MockMediaCompressorService extends Mock implements MediaCompressorService {}
class MockGenerationRecoveryService extends Mock implements GenerationRecoveryService {}

class FakeSubmissionCollection extends Fake implements IsarCollection<SubmissionRecord> {
  int putCalls = 0;
  SubmissionRecord? lastSavedRecord;

  @override
  Future<int> put(SubmissionRecord object) async {
    putCalls++;
    lastSavedRecord = object;
    return 1;
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
  late GenerationNotifier notifier;

  setUp(() {
    mockDraftService = MockPdfDraftService();
    mockMediaService = MockMediaCompressorService();
    mockRecoveryService = MockGenerationRecoveryService();

    notifier = GenerationNotifier(
      mockDraftService,
      mockMediaService,
      mockRecoveryService,
      FakeIsar(),
    );
    
    registerFallbackValue(File(''));
  });

  test('Deve interpolar a string do draftPath corretamente e não conter \$ literal', () async {
    // Arrange
    final fakeWorkspace = Directory('/fake/workspace');
    when(() => mockRecoveryService.getWorkspaceDir()).thenAnswer((_) async => fakeWorkspace);
    when(() => mockRecoveryService.markAsProcessing(any())).thenAnswer((_) async {});
    
    // Configura o mock do drawDraft para não falhar e apenas capturar os argumentos.
    when(() => mockDraftService.drawDraft(any(), any(), any()))
        .thenAnswer((_) async => File('/fake/workspace/draft.pdf'));

    // Act
    // Vamos chamar o startGeneration. Como ele vai falhar no rust_api.generateSealedReport,
    // não precisamos nos preocupar se a Promise finalizar com erro,
    // só queremos validar o argumento que foi passado para o drawDraft.
    await notifier.startGeneration('Teste', [], '/output.pdf');

    // Assert
    // Verifica se drawDraft foi chamado com o path CORRETO,
    // sem o $ escapado. O correto é '/fake/workspace/draft.pdf'.
    verify(() => mockDraftService.drawDraft('Teste', [], '/fake/workspace/draft.pdf')).called(1);
    
    // Se o draftPath ainda estiver errado ('\${workspace.path}/draft.pdf'),
    // o verify falhará (Fase Red do TDD).
  });

  test('Deve processar todas as mídias e garantir que as imagens saiam com formato .jpg (Fase Red)', () async {
    // Arrange
    final fakeWorkspace = Directory('/fake/workspace');
    when(() => mockRecoveryService.getWorkspaceDir()).thenAnswer((_) async => fakeWorkspace);
    when(() => mockRecoveryService.markAsProcessing(any())).thenAnswer((_) async {});
    when(() => mockDraftService.drawDraft(any(), any(), any()))
        .thenAnswer((_) async => File('/fake/workspace/draft.pdf'));

    when(() => mockMediaService.compressImage(any(), any()))
        .thenAnswer((inv) async => inv.positionalArguments[0] as File);

    final medias = [
      GenerationMedia(file: File('image1.png'), description: 'Legenda 1'),
      GenerationMedia(file: File('image2.HEIC')),
    ];

    // Act
    await notifier.startGeneration('Teste', medias, '/output.pdf');

    // Assert
    final captured = verify(() => mockMediaService.compressImage(any(), captureAny())).captured;
    expect(captured.length, 2);
    
    expect((captured[0] as String).endsWith('.jpg'), isTrue, reason: 'O formato final de compressão de imagens DEVE ser obrigatoriamente .jpg');
    expect((captured[1] as String).endsWith('.jpg'), isTrue, reason: 'O formato final de compressão de imagens DEVE ser obrigatoriamente .jpg');
    
    // Verifica se os descriptions chegaram ao drawDraft
    final drawDraftCaptured = verify(() => mockDraftService.drawDraft('Teste', captureAny(), '/fake/workspace/draft.pdf')).captured;
    final capturedMedias = drawDraftCaptured.first as List<GenerationMedia>;
    expect(capturedMedias[0].description, 'Legenda 1');
  });

  test('Deve garantir que o arquivo final seja criado no outputPath (Fase Red)', () async {
    // Arrange
    final fakeWorkspace = Directory.systemTemp.createTempSync('workspace');
    when(() => mockRecoveryService.getWorkspaceDir()).thenAnswer((_) async => fakeWorkspace);
    when(() => mockRecoveryService.markAsProcessing(any())).thenAnswer((_) async {});
    
    final fakeDraft = File('${fakeWorkspace.path}/draft.pdf');
    await fakeDraft.writeAsString('draft fake');
    when(() => mockDraftService.drawDraft(any(), any(), any())).thenAnswer((_) async => fakeDraft);
    
    when(() => mockMediaService.compressImage(any(), any()))
        .thenAnswer((_) async => File(''));

    final outPath = '${fakeWorkspace.path}/output_final.pdf';

    // Act
    await notifier.startGeneration('Teste', [GenerationMedia(file: File('/input.jpg'))], outPath);

    // Assert
    final exists = await File(outPath).exists();
    expect(exists, isTrue, reason: 'O arquivo final de output deve ser fisicamente gerado no disco');
    
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
    
    when(() => mockMediaService.compressImage(any(), any()))
        .thenAnswer((_) async => File(''));

    final outPath = '${fakeWorkspace.path}/output_final.pdf';
    
    final fakeIsar = FakeIsar();
    notifier = GenerationNotifier(
      mockDraftService,
      mockMediaService,
      mockRecoveryService,
      fakeIsar,
    );

    // Act
    await notifier.startGeneration('Teste Protocolo', [GenerationMedia(file: File('/input.jpg'))], outPath);

    // Assert
    expect(fakeIsar.fakeCollection.putCalls, 1, reason: 'Deve chamar o put no IsarCollection<SubmissionRecord> exatamente 1 vez');
    final savedRecord = fakeIsar.fakeCollection.lastSavedRecord!;
    expect(savedRecord.nomeProtocolo, 'Teste Protocolo');
    expect(savedRecord.pdfPath, outPath);
    expect(savedRecord.idSessao, isNotEmpty);
    
    fakeWorkspace.deleteSync(recursive: true);
  });
}

