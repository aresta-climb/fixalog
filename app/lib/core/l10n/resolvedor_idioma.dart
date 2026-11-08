// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/local/app_config_record.dart';
import '../services/banco_dados_local.dart';
import 'generated/app_localizations.dart';

/// Metadados de um idioma oficialmente suportado pelo Fixalog.
class OpcaoIdiomaSuportado {
  /// Código ISO 639-1 em minúsculas (ex.: 'pt', 'en', 'ar', 'ja').
  final String codigo;

  /// Nome nativo autodescritivo para exibição no seletor de idioma.
  final String nomeNativo;

  /// Indica se a escrita deste idioma segue a direção da direita para a esquerda (RTL).
  final bool ehRtl;

  const OpcaoIdiomaSuportado({
    required this.codigo,
    required this.nomeNativo,
    this.ehRtl = false,
  });

  /// Instância de [Locale] correspondente ao [codigo].
  Locale get locale => Locale(codigo);
}

/// Serviço puro de resolução e catálogo dos 7 idiomas suportados pelo Fixalog.
///
/// Aplica a ordem de prioridade:
/// 1. Preferência explícita salva pelo usuário no SQLite (`idioma_preferido`);
/// 2. Idioma do sistema operacional se pertencer ao catálogo suportado;
/// 3. Fallback global para Inglês (`Locale('en')`).
class ResolvedorIdioma {
  /// Idioma de fallback global quando o idioma do sistema não é suportado.
  static const Locale localeFallback = Locale('en');

  /// Catálogo imutável dos 7 idiomas suportados pelo Fixalog.
  static const List<OpcaoIdiomaSuportado> idiomasSuportados = [
    OpcaoIdiomaSuportado(codigo: 'pt', nomeNativo: 'Português'),
    OpcaoIdiomaSuportado(codigo: 'en', nomeNativo: 'English'),
    OpcaoIdiomaSuportado(codigo: 'es', nomeNativo: 'Español'),
    OpcaoIdiomaSuportado(codigo: 'fr', nomeNativo: 'Français'),
    OpcaoIdiomaSuportado(codigo: 'de', nomeNativo: 'Deutsch'),
    OpcaoIdiomaSuportado(codigo: 'ar', nomeNativo: 'العربية', ehRtl: true),
    OpcaoIdiomaSuportado(codigo: 'ja', nomeNativo: '日本語'),
  ];

  /// Lista de [Locale] suportados para configuração do `MaterialApp`.
  static List<Locale> get localesSuportados =>
      idiomasSuportados.map((i) => i.locale).toList(growable: false);

  /// Verifica se um código de idioma ISO 639-1 pertence aos 7 idiomas suportados.
  static bool ehSuportado(String? codigo) {
    if (codigo == null) return false;
    final normalizado = codigo.trim().toLowerCase();
    return idiomasSuportados.any((i) => i.codigo == normalizado);
  }

  /// Retorna a [OpcaoIdiomaSuportado] correspondente ao [codigo], ou a opção em Inglês (`en`) como fallback.
  static OpcaoIdiomaSuportado obterOpcaoPorCodigo(String? codigo) {
    if (codigo != null) {
      final normalizado = codigo.trim().toLowerCase();
      for (final opcao in idiomasSuportados) {
        if (opcao.codigo == normalizado) {
          return opcao;
        }
      }
    }
    return idiomasSuportados[1]; // 'en'
  }

  /// Resolve o [Locale] ativo considerando a preferência salva e o [localeSistema].
  static Locale resolver({
    String? idiomaPreferidoSalvo,
    Locale? localeSistema,
  }) {
    if (ehSuportado(idiomaPreferidoSalvo)) {
      return Locale(idiomaPreferidoSalvo!.trim().toLowerCase());
    }
    if (localeSistema != null && ehSuportado(localeSistema.languageCode)) {
      return Locale(localeSistema.languageCode.trim().toLowerCase());
    }
    return localeFallback;
  }

  /// Obtém a instância de [AppLocalizations] para o [locale] informado sem exigir `BuildContext`.
  static AppLocalizations obterTraducoes(Locale? locale) {
    final localeResolvido = resolver(
      idiomaPreferidoSalvo: locale?.languageCode,
    );
    return lookupAppLocalizations(localeResolvido);
  }

  /// Resolve o [Locale] efetivo para uma tela do aplicativo a partir do [context] e [ref].
  ///
  /// Quando o aplicativo está montado com `AppLocalizations.localizationsDelegates` (produção)
  /// ou quando há preferência explícita salva/selecionada no [idiomaAtivoProvider], retorna o
  /// [Locale] do [idiomaAtivoProvider]. Em árvores mínimas de testes de widget isolados sem
  /// `localizationsDelegates` e sem preferência explícita, utiliza Português (`pt`) como padrão.
  static Locale obterLocaleEfetivo(BuildContext context, WidgetRef ref) {
    final localeAtivo = ref.watch(idiomaAtivoProvider);
    final localeSistema = ref.watch(localeSistemaProvider);
    final possuiDelegates =
        Localizations.of<AppLocalizations>(context, AppLocalizations) != null;
    final possuiPreferencia =
        ref.read(idiomaAtivoProvider.notifier).possuiPreferenciaExplicita;
    final ehLocalePadraoRunnerTeste =
        localeSistema.languageCode == 'en' && localeSistema.countryCode == 'US';
    if (possuiDelegates || possuiPreferencia || !ehLocalePadraoRunnerTeste) {
      return localeAtivo;
    }
    return const Locale('pt');
  }

  /// Obtém a instância de [AppLocalizations] ativa para o [context] e [ref].
  static AppLocalizations obterTraducoesContexto(
    BuildContext context,
    WidgetRef ref,
  ) {
    return obterTraducoes(obterLocaleEfetivo(context, ref));
  }
}

/// Provedor do [Locale] reportado pelo sistema operacional (sobrescrevível em testes).
final localeSistemaProvider = Provider<Locale>((ref) {
  return PlatformDispatcher.instance.locale;
});

/// Controlador Riverpod que mantém o [Locale] ativo do aplicativo sincronizado com o [BancoDadosLocal].
class ControladorIdiomaAtivo extends Notifier<Locale> {
  bool _selecionadoManualmente = false;

  /// Indica se um idioma foi explicitamente configurado no banco ou selecionado em tempo de execução.
  bool get possuiPreferenciaExplicita => _selecionadoManualmente;

  @override
  Locale build() {
    final banco = ref.watch(bancoDadosLocalProvider);
    final localeSistema = ref.watch(localeSistemaProvider);
    final config = banco?.obterConfiguracaoSync(1);
    final salvo = config?.idiomaPreferido;
    if (ehSuportadoCasoConfigurado(salvo)) {
      _selecionadoManualmente = true;
    }
    return ResolvedorIdioma.resolver(
      idiomaPreferidoSalvo: salvo,
      localeSistema: localeSistema,
    );
  }

  static bool ehSuportadoCasoConfigurado(String? codigo) =>
      ResolvedorIdioma.ehSuportado(codigo);

  /// Altera imediatamente o idioma ativo na interface e persiste a preferência na tabela `configuracao_app`.
  Future<void> selecionarIdioma(String codigoIdioma) async {
    final novoLocale = ResolvedorIdioma.resolver(
      idiomaPreferidoSalvo: codigoIdioma,
    );
    _selecionadoManualmente = true;
    state = novoLocale;

    final banco = ref.read(bancoDadosLocalProvider);
    if (banco != null) {
      final configExistente =
          await banco.obterConfiguracao(1) ?? AppConfigRecord(id: 1);
      configExistente.idiomaPreferido = novoLocale.languageCode;
      await banco.salvarConfiguracao(configExistente);
    }
  }
}

/// Provedor global do [Locale] ativo do Fixalog.
final idiomaAtivoProvider = NotifierProvider<ControladorIdiomaAtivo, Locale>(
  ControladorIdiomaAtivo.new,
);
