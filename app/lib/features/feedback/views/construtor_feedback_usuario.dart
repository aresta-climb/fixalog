// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:feedback/feedback.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/resolvedor_idioma.dart';

/// Construtor customizado para o painel inferior do `BetterFeedback`,
/// adaptado ao tema escuro do Fixalog e traduzido nos 7 idiomas suportados.
Widget construtorFeedbackUsuario(
  BuildContext context,
  OnSubmit onSubmit,
  ScrollController? scrollController,
) {
  return FormularioFeedbackFixalog(
    onSubmit: onSubmit,
    scrollController: scrollController,
  );
}

/// Formulário interativo de envio de relato in-app com seleção de categoria e descrição.
class FormularioFeedbackFixalog extends ConsumerStatefulWidget {
  final OnSubmit onSubmit;
  final ScrollController? scrollController;

  const FormularioFeedbackFixalog({
    super.key,
    required this.onSubmit,
    required this.scrollController,
  });

  @override
  ConsumerState<FormularioFeedbackFixalog> createState() =>
      _FormularioFeedbackFixalogState();
}

class _FormularioFeedbackFixalogState
    extends ConsumerState<FormularioFeedbackFixalog> {
  late final TextEditingController _controller;
  String _categoriaSelecionada = 'aplicativo';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ResolvedorIdioma.obterLocaleEfetivo(context, ref);
    final l10n = ResolvedorIdioma.obterTraducoes(locale);

    const corDestaque = Color(0xFFFF6B00);
    const corFundoCampo = Color(0xFF1A1C1E);

    return Container(
      color: const Color(0xFF121416),
      child: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          controller: widget.scrollController,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.feedbackTituloSheet,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                key: const Key('seletor_categoria_feedback'),
                segments: [
                  ButtonSegment<String>(
                    value: 'protocolo',
                    label: Text(l10n.feedbackCategoriaProtocolo),
                    icon: const Icon(Icons.assignment_outlined, size: 16),
                  ),
                  ButtonSegment<String>(
                    value: 'aplicativo',
                    label: Text(l10n.feedbackCategoriaAplicativo),
                    icon: const Icon(Icons.phone_android_rounded, size: 16),
                  ),
                ],
                selected: {_categoriaSelecionada},
                onSelectionChanged: (novaSelecao) {
                  setState(() {
                    _categoriaSelecionada = novaSelecao.first;
                  });
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  backgroundColor:
                      WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return corDestaque;
                    }
                    return corFundoCampo;
                  }),
                  foregroundColor:
                      WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.black;
                    }
                    return Colors.white70;
                  }),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('campo_texto_feedback'),
                controller: _controller,
                maxLines: 2,
                minLines: 1,
                textInputAction: TextInputAction.done,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                cursorColor: corDestaque,
                decoration: InputDecoration(
                  hintText: l10n.feedbackHintDescricao,
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: corFundoCampo,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: corDestaque,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.feedbackAvisoOffline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, valor, _) {
                  final textoLimpo = valor.text.trim();
                  final habilitado = textoLimpo.isNotEmpty;

                  return ElevatedButton(
                    key: const Key('botao_enviar_feedback_sheet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: corDestaque,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor:
                          corDestaque.withValues(alpha: 0.35),
                      disabledForegroundColor:
                          Colors.black.withValues(alpha: 0.5),
                      minimumSize: const Size(double.infinity, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: habilitado
                        ? () {
                            widget.onSubmit(
                              textoLimpo,
                              extras: <String, dynamic>{
                                'categoria': _categoriaSelecionada,
                              },
                            );
                          }
                        : null,
                    child: Text(
                      l10n.feedbackBotaoEnviar,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
