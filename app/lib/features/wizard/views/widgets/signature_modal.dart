// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io' show zlib;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

/// Modal para coleta de assinatura manuscrita digital em tela.
///
/// Utiliza [Signature] para renderização interativa e exporta os pontos
/// diretamente em formato PNG determinístico em memória, evitando travamentos
/// de GPU (`Picture.toImage` / `drawPaint`) em dispositivos móveis e testes.
class SignatureModal extends StatefulWidget {
  const SignatureModal({super.key});

  @override
  State<SignatureModal> createState() => _SignatureModalState();
}

class _SignatureModalState extends State<SignatureModal> {
  late final SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save({required Size tamanhoCanvas}) async {
    if (_controller.isEmpty) {
      Navigator.pop(context, null);
      return;
    }

    final largura = tamanhoCanvas.width.round().clamp(200, 600);
    final altura = tamanhoCanvas.height.round().clamp(120, 300);
    final signatureBytes = _gerarPngDosPontos(
      pontos: _controller.points,
      largura: largura,
      altura: altura,
    );
    if (mounted) {
      Navigator.pop(context, signatureBytes);
    }
  }

  void _clear() {
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = (screenWidth - 48).clamp(280.0, 500.0);

    return Dialog(
      backgroundColor: const Color(0xFF181A1C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 280,
          maxWidth: 500,
        ),
        child: SizedBox(
          width: dialogWidth,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double canvasWidth;
                if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
                  canvasWidth = constraints.maxWidth;
                } else {
                  canvasWidth = (dialogWidth - 32).clamp(200.0, 500.0);
                }
                const double canvasHeight = 200.0;
                final tamanhoCanvas = Size(canvasWidth, canvasHeight);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'ASSINATURA DIGITAL',
                      style: TextStyle(
                        color: Color(0xFFFF6B00),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        child: GestureDetector(
                          key: const Key('canvas_assinatura'),
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragUpdate: (_) {},
                          onVerticalDragUpdate: (_) {},
                          child: SizedBox(
                            width: canvasWidth,
                            height: canvasHeight,
                            child: Signature(
                              controller: _controller,
                              width: canvasWidth,
                              height: canvasHeight,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _clear,
                          child: const Text(
                            'LIMPAR',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _save(tamanhoCanvas: tamanhoCanvas),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B00),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'SALVAR ASSINATURA',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Rasteriza os pontos do [SignatureController] em um buffer RGB (fundo branco,
/// traço preto) e codifica como PNG válido em memória.
Uint8List _gerarPngDosPontos({
  required List<Point> pontos,
  required int largura,
  required int altura,
}) {
  final stride = 1 + largura * 3;
  final raw = Uint8List(altura * stride);
  raw.fillRange(0, raw.length, 255);
  for (var y = 0; y < altura; y++) {
    raw[y * stride] = 0;
  }

  void pintarPonto(int px, int py) {
    for (var dy = -1; dy <= 1; dy++) {
      final y = py + dy;
      if (y < 0 || y >= altura) continue;
      for (var dx = -1; dx <= 1; dx++) {
        final x = px + dx;
        if (x < 0 || x >= largura) continue;
        final idx = y * stride + 1 + x * 3;
        raw[idx] = 0;
        raw[idx + 1] = 0;
        raw[idx + 2] = 0;
      }
    }
  }

  void pintarSegmento(Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final passos = math.max(dx.abs(), dy.abs()).ceil().clamp(1, 2000);
    for (var i = 0; i <= passos; i++) {
      final t = i / passos;
      final x = (a.dx + dx * t).round();
      final y = (a.dy + dy * t).round();
      pintarPonto(x, y);
    }
  }

  for (var i = 0; i < pontos.length; i++) {
    final atual = pontos[i];
    if (i > 0 && atual.type == PointType.move) {
      pintarSegmento(pontos[i - 1].offset, atual.offset);
    } else {
      pintarPonto(atual.offset.dx.round(), atual.offset.dy.round());
    }
  }

  final comprimido = Uint8List.fromList(zlib.encode(raw));
  final builder = BytesBuilder(copy: false);
  builder.add(const [137, 80, 78, 71, 13, 10, 26, 10]);

  final ihdr = ByteData(13)
    ..setUint32(0, largura)
    ..setUint32(4, altura)
    ..setUint8(8, 8)
    ..setUint8(9, 2)
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  _adicionarChunkPng(builder, 'IHDR', ihdr.buffer.asUint8List());
  _adicionarChunkPng(builder, 'IDAT', comprimido);
  _adicionarChunkPng(builder, 'IEND', Uint8List(0));

  return builder.toBytes();
}

void _adicionarChunkPng(BytesBuilder out, String tipo, Uint8List dados) {
  final lenBytes = ByteData(4)..setUint32(0, dados.length);
  out.add(lenBytes.buffer.asUint8List());
  final tipoBytes = Uint8List.fromList(tipo.codeUnits);
  out.add(tipoBytes);
  out.add(dados);

  final crcInput = Uint8List(tipoBytes.length + dados.length)
    ..setRange(0, tipoBytes.length, tipoBytes)
    ..setRange(tipoBytes.length, tipoBytes.length + dados.length, dados);
  final crc = _calcularCrc32(crcInput);
  final crcBytes = ByteData(4)..setUint32(0, crc);
  out.add(crcBytes.buffer.asUint8List());
}

int _calcularCrc32(Uint8List bytes) {
  var crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc ^= b;
    for (var i = 0; i < 8; i++) {
      if ((crc & 1) != 0) {
        crc = (crc >>> 1) ^ 0xEDB88320;
      } else {
        crc = crc >>> 1;
      }
    }
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
