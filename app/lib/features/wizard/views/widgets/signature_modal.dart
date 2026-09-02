import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

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

  Future<void> _save() async {
    if (_controller.isEmpty) {
      Navigator.pop(context, null);
      return;
    }

    final Uint8List? signatureBytes = await _controller.toPngBytes();
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
            child: Column(
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double canvasWidth;
                        if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
                          canvasWidth = constraints.maxWidth;
                        } else {
                          canvasWidth = (dialogWidth - 32).clamp(200.0, 500.0);
                        }
                        return SizedBox(
                          width: canvasWidth,
                          height: 200,
                          child: Signature(
                            controller: _controller,
                            width: canvasWidth,
                            height: 200,
                            backgroundColor: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _clear,
                      child: const Text('LIMPAR', style: TextStyle(color: Colors.white54)),
                    ),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('SALVAR ASSINATURA', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
