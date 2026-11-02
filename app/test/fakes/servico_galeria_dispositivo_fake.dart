// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:fixalog/features/media/services/servico_galeria_dispositivo.dart';

/// Fake determinístico em memória de [ServicoGaleriaDispositivo] para testes unitários e de widget.
///
/// Registra os caminhos das fotos e vídeos salvos no rolo da câmera e permite simular
/// falhas determinísticas de permissão ou armazenamento sem tocar no sistema operacional.
class ServicoGaleriaDispositivoFake extends ServicoGaleriaDispositivo {
  /// Lista ordenada dos caminhos de fotos salvas no rolo da câmera durante o teste.
  final List<String> fotosSalvas = [];

  /// Lista ordenada dos caminhos de vídeos salvos no rolo da câmera durante o teste.
  final List<String> videosSalvos = [];

  /// Quando `true`, [salvarFotoNoRoloDaCamera] e [salvarVideoNoRoloDaCamera] lançam exceção determinística.
  bool simularFalha;

  /// Cria uma instância de [ServicoGaleriaDispositivoFake].
  ServicoGaleriaDispositivoFake({this.simularFalha = false});

  @override
  Future<void> salvarFotoNoRoloDaCamera(String caminhoArquivo) async {
    if (simularFalha) {
      throw Exception(
        'Permissão negada ou falha ao salvar foto no rolo da câmera',
      );
    }
    fotosSalvas.add(caminhoArquivo);
  }

  @override
  Future<void> salvarVideoNoRoloDaCamera(String caminhoArquivo) async {
    if (simularFalha) {
      throw Exception(
        'Permissão negada ou falha ao salvar vídeo no rolo da câmera',
      );
    }
    videosSalvos.add(caminhoArquivo);
  }
}
