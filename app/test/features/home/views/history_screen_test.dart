import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/features/home/views/history_screen.dart';
import 'package:app/features/home/providers/history_provider.dart';
import 'package:app/core/models/local/submission_record.dart';
import 'package:app/features/express_form/viewmodels/express_form_view_model.dart';
import 'package:app/features/express_form/views/express_form_screen.dart';

class MockHistoryRepository extends Mock implements HistoryRepository {}

class FakeExpressFormViewModel extends ExpressFormViewModel {
  int loadSessionCalls = 0;
  String? lastLoadedSessionId;

  @override
  Future<void> loadSession(String sessionId) async {
    loadSessionCalls++;
    lastLoadedSessionId = sessionId;
  }
}

void main() {
  late MockHistoryRepository mockHistoryRepo;
  late FakeExpressFormViewModel fakeExpressFormViewModel;

  setUpAll(() {
    registerFallbackValue(SubmissionRecord());
  });

  setUp(() {
    mockHistoryRepo = MockHistoryRepository();
    fakeExpressFormViewModel = FakeExpressFormViewModel();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        historyRepositoryProvider.overrideWithValue(mockHistoryRepo),
        expressFormViewModelProvider.overrideWith((ref) => fakeExpressFormViewModel),
      ],
      child: const MaterialApp(
        home: Scaffold(body: HistoryScreen()),
      ),
    );
  }

  testWidgets('Deve excluir o relatório ao clicar em excluir e confirmar (Fase Red)', (WidgetTester tester) async {
    // Arrange
    final record = SubmissionRecord()
      ..id = 1
      ..idSessao = 'sessao_123'
      ..nomeProtocolo = 'Protocolo Teste'
      ..dataInclusao = DateTime.now();

    when(() => mockHistoryRepo.watchHistory()).thenAnswer((_) => Stream.value([record]));
    when(() => mockHistoryRepo.deleteRecord(any())).thenAnswer((_) async {});

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle(); // Aguarda os dados do stream

    // Abre o menu popup
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Clica em Excluir
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    // Confirma no dialog
    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();

    // Assert
    final captured = verify(() => mockHistoryRepo.deleteRecord(captureAny())).captured;
    expect(captured.length, 1);
    expect((captured[0] as SubmissionRecord).idSessao, 'sessao_123');
  });

  testWidgets('Deve navegar para ExpressFormScreen e carregar a sessão ao clicar em editar (Fase Red)', (WidgetTester tester) async {
    // Arrange
    final record = SubmissionRecord()
      ..id = 1
      ..idSessao = 'sessao_456'
      ..nomeProtocolo = 'Protocolo Teste'
      ..dataInclusao = DateTime.now();

    when(() => mockHistoryRepo.watchHistory()).thenAnswer((_) => Stream.value([record]));

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle(); // Aguarda os dados do stream

    // Abre o menu popup
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Clica em Editar
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    // Assert
    expect(fakeExpressFormViewModel.loadSessionCalls, 1);
    expect(fakeExpressFormViewModel.lastLoadedSessionId, 'sessao_456');
    
    // Verifica se navegou para a ExpressFormScreen
    expect(find.byType(ExpressFormScreen), findsOneWidget);
  });
}
