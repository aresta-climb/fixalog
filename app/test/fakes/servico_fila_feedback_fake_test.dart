// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'servico_fila_feedback_fake.dart';

void main() {
  group('ServicoFilaFeedbackFake — Contrato Determinístico em Memória', () {
    test(
      'armazena feedbacks enfileirados em memória, contabiliza despachos, simula falha e limpa estado',
      () async {
        final fake = ServicoFilaFeedbackFake();

        final rec1 = await fake.enfileirarEDespacharFeedback(
          mensagem: 'Feedback 1',
          capturaTela: Uint8List.fromList([1, 2, 3]),
          categoria: 'protocolo',
        );
        expect(rec1.idFeedback, equals('fb-fake-1'));
        expect(rec1.caminhoImagem, equals('/fake/feedback_1.webp'));
        expect(fake.feedbacksEnfileirados, hasLength(1));
        expect(fake.chamadasProcessarFila, equals(1));

        final rec2 = await fake.enfileirarEDespacharFeedback(
          mensagem: 'Feedback 2 sem imagem',
          capturaTela: Uint8List(0),
          despacharImediatamente: false,
        );
        expect(rec2.caminhoImagem, isEmpty);
        expect(fake.feedbacksEnfileirados, hasLength(2));
        expect(fake.chamadasProcessarFila, equals(1));

        fake.limpar();
        expect(fake.feedbacksEnfileirados, isEmpty);
        expect(fake.chamadasProcessarFila, equals(0));

        fake.simularErroAoEnfileirar = true;
        await expectLater(
          fake.enfileirarEDespacharFeedback(
            mensagem: 'Deve falhar',
            capturaTela: Uint8List(0),
          ),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}
