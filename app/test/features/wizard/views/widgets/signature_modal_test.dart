import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/wizard/views/widgets/signature_modal.dart';
import 'package:signature/signature.dart';

void main() {
  group('SignatureModal Widget Tests (TDD)', () {
    testWidgets('Deve renderizar os componentes da assinatura digital corretamente', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignatureModal(),
          ),
        ),
      );

      expect(find.text('ASSINATURA DIGITAL'), findsOneWidget);
      expect(find.byType(Signature), findsOneWidget);
      expect(find.text('LIMPAR'), findsOneWidget);
      expect(find.text('SALVAR ASSINATURA'), findsOneWidget);
    });

    testWidgets('Deve permitir desenhar no canvas sem lançar exceção de render box', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignatureModal(),
          ),
        ),
      );

      final signatureFinder = find.byType(Signature);
      expect(signatureFinder, findsOneWidget);

      // Simula traçado no canvas de assinatura
      final center = tester.getCenter(signatureFinder);
      await tester.dragFrom(center, const Offset(30, 30));
      await tester.pumpAndSettle();

      // Não deve lançar erro
      expect(tester.takeException(), isNull);
    });

    testWidgets('Botão LIMPAR deve limpar o traço sem erros', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignatureModal(),
          ),
        ),
      );

      final signatureFinder = find.byType(Signature);
      await tester.dragFrom(tester.getCenter(signatureFinder), const Offset(20, 20));
      await tester.pumpAndSettle();

      await tester.tap(find.text('LIMPAR'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Salvar sem assinatura retorna nulo e fecha o diálogo', (tester) async {
      Uint8List? resultado;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  resultado = await showDialog<Uint8List>(
                    context: context,
                    builder: (_) => const SignatureModal(),
                  );
                },
                child: const Text('ABRIR'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      expect(find.text('ASSINATURA DIGITAL'), findsOneWidget);

      await tester.tap(find.text('SALVAR ASSINATURA'));
      await tester.pumpAndSettle();

      expect(find.text('ASSINATURA DIGITAL'), findsNothing);
      expect(resultado, isNull);
    });

    testWidgets('Deve renderizar sem exceção mesmo sob restrições infinitas (UnconstrainedBox)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UnconstrainedBox(
              child: SignatureModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ASSINATURA DIGITAL'), findsOneWidget);
      final signatureFinder = find.byType(Signature);
      expect(signatureFinder, findsOneWidget);

      final signatureWidget = tester.widget<Signature>(signatureFinder);
      expect(signatureWidget.width, isNotNull);
      expect(signatureWidget.width!.isFinite, isTrue);
      expect(signatureWidget.width!, greaterThan(0));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Deve suportar redimensionamento e transições de viewInsets sem crash de layout', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(context: context, builder: (_) => const SignatureModal()),
                child: const Text('ABRIR'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      // Simula teclado abrindo e fechando (alteração de viewInsets)
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();

      final signatureFinder = find.byType(Signature);
      expect(signatureFinder, findsOneWidget);

      final center = tester.getCenter(signatureFinder);
      await tester.dragFrom(center, const Offset(20, 20));
      await tester.pumpAndSettle();

      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
      });
    });
  });
}
