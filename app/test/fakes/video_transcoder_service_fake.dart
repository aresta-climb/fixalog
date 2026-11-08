// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:fixalog/features/media/services/video_transcoder_service.dart';

/// Registro de uma chamada de transcodificação capturada pelo [VideoTranscoderServiceFake].
class ChamadaTranscodificacaoFake {
  final String caminhoEntrada;
  final String caminhoSaida;
  final double? inicioSegundos;
  final double? duracaoSegundos;

  const ChamadaTranscodificacaoFake({
    required this.caminhoEntrada,
    required this.caminhoSaida,
    this.inicioSegundos,
    this.duracaoSegundos,
  });
}

/// Fake determinístico em memória de [VideoTranscoderService] para testes unitários e de widget.
class VideoTranscoderServiceFake extends VideoTranscoderService {
  /// Mapa de durações simuladas por caminho de arquivo (ou padrão [duracaoPadraoSegundos]).
  final Map<String, double> duracoesPorCaminho = {};

  /// Duração retornada por [obterDuracaoSegundos] quando o caminho não está em [duracoesPorCaminho].
  double? duracaoPadraoSegundos;

  /// Quando `true`, simula falha nas chamadas de transcodificação e poster frame.
  bool simularFalha;

  /// Lista de todas as chamadas realizadas a [transcodificarVideo].
  final List<ChamadaTranscodificacaoFake> chamadasTranscodificacao = [];

  VideoTranscoderServiceFake({
    this.duracaoPadraoSegundos = 30.0,
    this.simularFalha = false,
  }) : super(
          executador: (_) async => true,
          inspetorDuracao: (_) async => 30.0,
        );

  @override
  Future<double?> obterDuracaoSegundos(File arquivoVideo) async {
    if (!arquivoVideo.existsSync()) {
      return null;
    }
    return duracoesPorCaminho[arquivoVideo.path] ?? duracaoPadraoSegundos;
  }

  @override
  Future<File?> transcodificarVideo({
    required File arquivoEntrada,
    required String caminhoSaida,
    double? inicioSegundos,
    double? duracaoSegundos,
  }) async {
    if (!arquivoEntrada.existsSync() || simularFalha) {
      return null;
    }
    chamadasTranscodificacao.add(
      ChamadaTranscodificacaoFake(
        caminhoEntrada: arquivoEntrada.path,
        caminhoSaida: caminhoSaida,
        inicioSegundos: inicioSegundos,
        duracaoSegundos: duracaoSegundos,
      ),
    );
    final arquivoSaida = File(caminhoSaida);
    arquivoSaida.parent.createSync(recursive: true);
    arquivoSaida.writeAsBytesSync(const <int>[0, 0, 0, 24, 102, 116, 121, 112]);
    return arquivoSaida;
  }

  @override
  Future<File?> extrairPosterFrame({
    required File arquivoEntrada,
    required String caminhoSaida,
    double tempoSegundos = 0.5,
  }) async {
    if (!arquivoEntrada.existsSync() || simularFalha) {
      return null;
    }
    final arquivoPoster = File(caminhoSaida);
    arquivoPoster.parent.createSync(recursive: true);
    arquivoPoster.writeAsBytesSync(const <int>[0xFF, 0xD8, 0xFF, 0xD9]);
    return arquivoPoster;
  }
}
