// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:typed_data';

import 'package:fixalog/core/models/local/feedback_record.dart';
import 'package:fixalog/features/feedback/services/servico_fila_feedback.dart';

import 'registro_logger_fake.dart';

/// Fake determinístico em memória de [ServicoFilaFeedback] para testes de widget e integração.
class ServicoFilaFeedbackFake extends ServicoFilaFeedback {
  /// Lista ordenada de todos os feedbacks enfileirados durante o teste.
  final List<FeedbackRecord> feedbacksEnfileirados = <FeedbackRecord>[];

  /// Quantidade de vezes que [processarFilaPendentes] foi invocado.
  int chamadasProcessarFila = 0;

  /// Quando verdadeiro, simula falha ao enfileirar feedback.
  bool simularErroAoEnfileirar;

  ServicoFilaFeedbackFake({
    this.simularErroAoEnfileirar = false,
  }) : super(
          banco: null,
          logger: RegistroLoggerFake(),
        );

  @override
  Future<FeedbackRecord> enfileirarEDespacharFeedback({
    required String mensagem,
    required Uint8List capturaTela,
    String categoria = 'aplicativo',
    Map<String, Object?>? metadadosExtras,
    bool despacharImediatamente = true,
  }) async {
    if (simularErroAoEnfileirar) {
      throw StateError('Falha simulada no ServicoFilaFeedbackFake');
    }
    final record = FeedbackRecord(
      id: feedbacksEnfileirados.length + 1,
      idFeedback: 'fb-fake-${feedbacksEnfileirados.length + 1}',
      mensagem: mensagem,
      categoria: categoria,
      caminhoImagem: capturaTela.isEmpty
          ? ''
          : '/fake/feedback_${feedbacksEnfileirados.length + 1}.webp',
      metadadosJson: '{"fake":true}',
      dataCriacao: DateTime.utc(2026, 11, 9, 12, 0),
      enviado: despacharImediatamente,
    );
    feedbacksEnfileirados.add(record);
    if (despacharImediatamente) {
      await processarFilaPendentes();
    }
    return record;
  }

  @override
  Future<int> processarFilaPendentes() async {
    chamadasProcessarFila++;
    return feedbacksEnfileirados.length;
  }

  /// Limpa os registros acumulados em memória.
  void limpar() {
    feedbacksEnfileirados.clear();
    chamadasProcessarFila = 0;
  }
}
