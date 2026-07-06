import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/home/views/home_screen.dart';
import 'package:app/features/home/providers/history_provider.dart';
import 'package:app/features/identity/viewmodels/identity_form_view_model.dart';
import 'package:app/core/models/local/identity_record.dart';

// Helper que envolve o widget numa árvore mínima com providers mockados.
Widget _buildTestApp({IdentityRecord? identity}) {
  return ProviderScope(
    overrides: [
      currentIdentityProvider.overrideWith(
        (ref) async => identity ?? IdentityRecord(),
      ),
      historyProvider.overrideWith(
        (ref) => Stream.value([]),
      ),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  group('HomeScreen Shell Tests', () {
    testWidgets('Exibe o bottom navigation bar com os três itens', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Novo Protocolo'), findsOneWidget);
      expect(find.text('Histórico'), findsOneWidget);
      expect(find.text('Configurações'), findsOneWidget);
    });

    testWidgets('Navegar para aba Configurações exibe o conteúdo correto', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.text('Configurações'));
      await tester.pumpAndSettle();

      expect(find.text('Configurações'), findsWidgets);
    });

    testWidgets('Inicia na aba "Novo Protocolo" por padrão', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // A seção de protocolos está visível na aba inicial
      expect(find.text('NOVO REGISTRO DE MANUTENÇÃO'), findsOneWidget);
      // A seção de histórico NÃO está na árvore enquanto a aba 0 está ativa
      expect(find.text('HISTÓRICO RECENTE'), findsNothing);
    });

    testWidgets('Trocar para aba Histórico exibe o conteúdo correto', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Toca no item "Histórico" no bottom bar
      await tester.tap(find.text('Histórico'));
      await tester.pumpAndSettle();

      // Título específico da aba de histórico
      expect(find.text('Histórico'), findsWidgets);
      expect(find.text('LOGS TOTAIS'), findsOneWidget);
    });

    testWidgets('Voltar para aba Novo Protocolo após navegar', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Vai para Histórico
      await tester.tap(find.text('Histórico'));
      await tester.pumpAndSettle();

      // Volta para Novo Protocolo
      await tester.tap(find.text('Novo Protocolo'));
      await tester.pumpAndSettle();

      expect(find.text('NOVO REGISTRO DE MANUTENÇÃO'), findsOneWidget);
    });
  });
}
