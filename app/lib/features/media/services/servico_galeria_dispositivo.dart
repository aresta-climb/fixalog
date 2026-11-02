// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';

/// Serviço de fronteira responsável por salvar cópias de fotos e vídeos capturados
/// pela câmera diretamente no rolo da câmera do dispositivo (sem criar álbum separado).
class ServicoGaleriaDispositivo {
  /// Cria uma instância de [ServicoGaleriaDispositivo].
  const ServicoGaleriaDispositivo();

  /// Salva a foto localizada em [caminhoArquivo] diretamente no rolo da câmera do dispositivo.
  Future<void> salvarFotoNoRoloDaCamera(String caminhoArquivo) async {
    await Gal.putImage(caminhoArquivo);
  }

  /// Salva o vídeo localizado em [caminhoArquivo] diretamente no rolo da câmera do dispositivo.
  Future<void> salvarVideoNoRoloDaCamera(String caminhoArquivo) async {
    await Gal.putVideo(caminhoArquivo);
  }
}

/// Provedor Riverpod para o [ServicoGaleriaDispositivo].
final servicoGaleriaDispositivoProvider =
    Provider<ServicoGaleriaDispositivo>((ref) {
  return const ServicoGaleriaDispositivo();
});
