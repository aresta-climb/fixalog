// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/features/media/widgets/seletor_trecho_video_dialog.dart';

void main() {
  group('SeletorTrechoVideoDialog', () {
    testWidgets('inicializa com janela de 0s a 60s para video de 95s e confirma trecho padrao', (tester) async {
      IntervaloTrechoVideo? resultado;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  resultado = await SeletorTrechoVideoDialog.exibir(
                    context,
                    duracaoTotalSegundos: 95.0,
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Selecionar trecho do vídeo (máx. 60s)'), findsOneWidget);
      expect(find.textContaining('00:00 – 01:00 (60s)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_confirmar_trecho_video')));
      await tester.pumpAndSettle();

      expect(resultado, isNotNull);
      expect(resultado!.inicioSegundos, equals(0.0));
      expect(resultado!.duracaoSegundos, equals(60.0));
      expect(resultado!.fimSegundos, equals(60.0));
    });

    testWidgets('desloca janela automaticamente mantendo no maximo 60s ao ajustar controles', (tester) async {
      IntervaloTrechoVideo? resultado;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeletorTrechoVideoDialog(
              duracaoTotalSegundos: 100.0,
              aoConfirmar: (trecho) => resultado = trecho,
            ),
          ),
        ),
      );

      final rangeSlider = tester.widget<RangeSlider>(find.byType(RangeSlider));
      // Usuário move o fim para 85s -> início deve acompanhar para 25s (janela máxima de 60s)
      rangeSlider.onChanged!(const RangeValues(0.0, 85.0));
      await tester.pump();

      expect(find.textContaining('00:25 – 01:25 (60s)'), findsOneWidget);

      // Usuário reduz o início para 10s -> fim acompanha para 70s
      final rangeSliderAtualizado = tester.widget<RangeSlider>(find.byType(RangeSlider));
      rangeSliderAtualizado.onChanged!(const RangeValues(10.0, 85.0));
      await tester.pump();

      expect(find.textContaining('00:10 – 01:10 (60s)'), findsOneWidget);

      // Usuário tenta colapsar intervalo para 0s -> garante mínimo de 1s
      final rangeSliderColapsado = tester.widget<RangeSlider>(find.byType(RangeSlider));
      rangeSliderColapsado.onChanged!(const RangeValues(20.0, 20.0));
      await tester.pump();
      expect(find.textContaining('00:20 – 00:21 (1s)'), findsOneWidget);

      // Usuário escolhe trecho menor que 60s (20s a 50s = 30s)
      final rangeSliderCurto = tester.widget<RangeSlider>(find.byType(RangeSlider));
      rangeSliderCurto.onChanged!(const RangeValues(20.0, 50.0));
      await tester.pump();

      expect(find.textContaining('00:20 – 00:50 (30s)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_confirmar_trecho_video')));
      await tester.pump();

      expect(resultado, isNotNull);
      expect(resultado!.inicioSegundos, equals(20.0));
      expect(resultado!.duracaoSegundos, equals(30.0));
    });

    testWidgets('retorna null quando o usuario cancela a selecao', (tester) async {
      IntervaloTrechoVideo? resultado = const IntervaloTrechoVideo(
        inicioSegundos: 0,
        duracaoSegundos: 10,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  resultado = await SeletorTrechoVideoDialog.exibir(
                    context,
                    duracaoTotalSegundos: 90.0,
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_cancelar_trecho_video')));
      await tester.pumpAndSettle();

      expect(resultado, isNull);
    });
  });
}
