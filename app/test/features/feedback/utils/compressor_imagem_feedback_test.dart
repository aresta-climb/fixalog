// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/features/feedback/utils/compressor_imagem_feedback.dart';

import '../../../fakes/registro_logger_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CompressorImagemFeedback — Compressão WebP e Fallback PNG', () {
    test(
      'comprimirParaWebp retorna formato webp quando compressão nativa produz bytes válidos',
      () async {
        final loggerFake = RegistroLoggerFake();
        final compressor = CompressorImagemFeedback(
          logger: loggerFake,
          compressaoNativa: (
            bytes, {
            required quality,
            required minWidth,
            required minHeight,
          }) async {
            expect(quality, equals(80));
            expect(minWidth, equals(1080));
            expect(minHeight, equals(1920));
            return Uint8List.fromList([10, 20, 30]);
          },
        );

        final resultado = await compressor.comprimirParaWebp(
          Uint8List.fromList([1, 2, 3, 4, 5]),
        );

        expect(resultado.formato, equals('webp'));
        expect(resultado.extensao, equals('webp'));
        expect(resultado.tipoMime, equals('image/webp'));
        expect(resultado.bytes, equals(Uint8List.fromList([10, 20, 30])));
        expect(loggerFake.avisosRegistrados, isEmpty);
      },
    );

    test(
      'comprimirParaWebp aplica fallback gracioso para png quando entrada é vazia, retorno é vazio ou canal nativo falha',
      () async {
        final loggerFake = RegistroLoggerFake();

        // 1. Entrada vazia retorna imediatamente png sem acionar canal nativo
        final compressorPadrao = CompressorImagemFeedback(logger: loggerFake);
        final vazio = await compressorPadrao.comprimirParaWebp(Uint8List(0));
        expect(vazio.formato, equals('png'));
        expect(vazio.extensao, equals('png'));
        expect(vazio.tipoMime, equals('image/png'));
        expect(vazio.bytes, isEmpty);

        // 2. Retorno vazio do compressor nativo faz fallback para bytes originais em png
        final compressorRetornoVazio = CompressorImagemFeedback(
          logger: loggerFake,
          compressaoNativa: (
            bytes, {
            required quality,
            required minWidth,
            required minHeight,
          }) async => Uint8List(0),
        );
        final originais = Uint8List.fromList([137, 80, 78, 71]);
        final fallbackVazio =
            await compressorRetornoVazio.comprimirParaWebp(originais);
        expect(fallbackVazio.formato, equals('png'));
        expect(fallbackVazio.bytes, equals(originais));

        // 3. Canal nativo padrão sem implementação em ambiente de teste faz fallback e registra aviso
        final fallbackPadrao =
            await compressorPadrao.comprimirParaWebp(originais);
        expect(fallbackPadrao.formato, equals('png'));
        expect(fallbackPadrao.bytes, equals(originais));
        expect(loggerFake.avisosRegistrados, hasLength(1));
      },
    );
  });
}
