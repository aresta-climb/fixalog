// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:fixalog/features/media/services/video_transcoder_service.dart';

/// Representa o intervalo de tempo selecionado pelo usuário para corte de um vídeo.
class IntervaloTrechoVideo {
  /// Tempo inicial do corte em segundos.
  final double inicioSegundos;

  /// Duração total do trecho selecionado em segundos (máximo 60s).
  final double duracaoSegundos;

  const IntervaloTrechoVideo({
    required this.inicioSegundos,
    required this.duracaoSegundos,
  });

  /// Tempo final do corte em segundos (`inicioSegundos + duracaoSegundos`).
  double get fimSegundos => inicioSegundos + duracaoSegundos;
}

/// Diálogo modal que permite ao usuário selecionar um período de até 60 segundos
/// quando um vídeo gravado pela câmera ou escolhido da galeria ultrapassa o limite.
class SeletorTrechoVideoDialog extends StatefulWidget {
  final double duracaoTotalSegundos;
  final double limiteMaximoSegundos;
  final ValueChanged<IntervaloTrechoVideo>? aoConfirmar;

  const SeletorTrechoVideoDialog({
    super.key,
    required this.duracaoTotalSegundos,
    this.limiteMaximoSegundos = limiteMaximoDuracaoVideoSegundos,
    this.aoConfirmar,
  });

  /// Exibe o diálogo modal e retorna o [IntervaloTrechoVideo] confirmado ou `null` se cancelado.
  static Future<IntervaloTrechoVideo?> exibir(
    BuildContext context, {
    required double duracaoTotalSegundos,
    double limiteMaximoSegundos = limiteMaximoDuracaoVideoSegundos,
  }) {
    return showDialog<IntervaloTrechoVideo>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SeletorTrechoVideoDialog(
        duracaoTotalSegundos: duracaoTotalSegundos,
        limiteMaximoSegundos: limiteMaximoSegundos,
      ),
    );
  }

  @override
  State<SeletorTrechoVideoDialog> createState() =>
      _SeletorTrechoVideoDialogState();
}

class _SeletorTrechoVideoDialogState extends State<SeletorTrechoVideoDialog> {
  late double _inicio;
  late double _fim;

  @override
  void initState() {
    super.initState();
    _inicio = 0.0;
    _fim = math.min(widget.duracaoTotalSegundos, widget.limiteMaximoSegundos);
  }

  void _atualizarIntervalo(RangeValues novosValores) {
    double novoInicio = novosValores.start.roundToDouble();
    double novoFim = novosValores.end.roundToDouble();

    if (novoFim - novoInicio > widget.limiteMaximoSegundos) {
      if ((novoFim - _fim).abs() >= (novoInicio - _inicio).abs()) {
        novoInicio = novoFim - widget.limiteMaximoSegundos;
      } else {
        novoFim = novoInicio + widget.limiteMaximoSegundos;
      }
    }

    if (novoFim - novoInicio < 1.0) {
      novoFim = math.min(widget.duracaoTotalSegundos, novoInicio + 1.0);
    }

    setState(() {
      _inicio = novoInicio.clamp(0.0, widget.duracaoTotalSegundos);
      _fim = novoFim.clamp(_inicio, widget.duracaoTotalSegundos);
    });
  }

  String _formatarTempo(double segundosTotais) {
    final totalInt = segundosTotais.round();
    final minutos = (totalInt ~/ 60).toString().padLeft(2, '0');
    final segundos = (totalInt % 60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }

  @override
  Widget build(BuildContext context) {
    final duracaoSelecionada = (_fim - _inicio).round();
    final limiteInt = widget.limiteMaximoSegundos.round();

    return AlertDialog(
      title: Text('Selecionar trecho do vídeo (máx. ${limiteInt}s)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'O vídeo possui ${_formatarTempo(widget.duracaoTotalSegundos)}. '
            'Selecione um período de até $limiteInt segundos para incluir no relatório:',
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${_formatarTempo(_inicio)} – ${_formatarTempo(_fim)} (${duracaoSelecionada}s)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          RangeSlider(
            values: RangeValues(_inicio, _fim),
            min: 0.0,
            max: widget.duracaoTotalSegundos,
            onChanged: _atualizarIntervalo,
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('btn_cancelar_trecho_video'),
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('btn_confirmar_trecho_video'),
          onPressed: () {
            final intervalo = IntervaloTrechoVideo(
              inicioSegundos: _inicio,
              duracaoSegundos: _fim - _inicio,
            );
            widget.aoConfirmar?.call(intervalo);
            Navigator.of(context).maybePop(intervalo);
          },
          child: const Text('Confirmar trecho'),
        ),
      ],
    );
  }
}
