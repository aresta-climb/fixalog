// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/core/l10n/generated/app_localizations.dart';
import 'package:fixalog/core/l10n/resolvedor_idioma.dart';
import 'package:fixalog/core/models/local/app_config_record.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';

void main() {
  group('ResolvedorIdioma — Resolução e Metadados dos 7 Idiomas', () {
    test('expõe exatamente os 7 idiomas suportados com metadados e direção RTL apenas para Árabe', () {
      expect(ResolvedorIdioma.idiomasSuportados, hasLength(7));
      expect(
        ResolvedorIdioma.localesSuportados.map((l) => l.languageCode).toList(),
        equals(['pt', 'en', 'es', 'fr', 'de', 'ar', 'ja']),
      );

      final arabe = ResolvedorIdioma.obterOpcaoPorCodigo('ar');
      expect(arabe.codigo, equals('ar'));
      expect(arabe.nomeNativo, equals('العربية'));
      expect(arabe.ehRtl, isTrue);
      expect(arabe.locale, equals(const Locale('ar')));

      final portugues = ResolvedorIdioma.obterOpcaoPorCodigo('pt');
      expect(portugues.ehRtl, isFalse);
      expect(portugues.nomeNativo, equals('Português'));

      final desconhecido = ResolvedorIdioma.obterOpcaoPorCodigo('zh');
      expect(desconhecido.codigo, equals('en'));
      expect(ResolvedorIdioma.obterOpcaoPorCodigo(null).codigo, equals('en'));
    });

    test('prioriza idiomaPreferidoSalvo válido sobre o locale do sistema', () {
      final resolvido = ResolvedorIdioma.resolver(
        idiomaPreferidoSalvo: 'JA',
        localeSistema: const Locale('pt', 'BR'),
      );
      expect(resolvido, equals(const Locale('ja')));
    });

    test('adota o idioma do sistema operacional quando suportado e sem preferência salva', () {
      for (final codigo in ['pt', 'en', 'es', 'fr', 'de', 'ar', 'ja']) {
        final resolvido = ResolvedorIdioma.resolver(
          idiomaPreferidoSalvo: null,
          localeSistema: Locale(codigo, 'XX'),
        );
        expect(resolvido, equals(Locale(codigo)));
      }
    });

    test('faz fallback para Inglês (en) quando idioma salvo e idioma do sistema não são suportados', () {
      expect(
        ResolvedorIdioma.resolver(
          idiomaPreferidoSalvo: null,
          localeSistema: const Locale('zh', 'CN'),
        ),
        equals(const Locale('en')),
      );
      expect(
        ResolvedorIdioma.resolver(
          idiomaPreferidoSalvo: 'ru',
          localeSistema: const Locale('ko', 'KR'),
        ),
        equals(const Locale('en')),
      );
      expect(
        ResolvedorIdioma.resolver(
          idiomaPreferidoSalvo: '   ',
          localeSistema: null,
        ),
        equals(const Locale('en')),
      );
    });

    test('obterTraducoes retorna instância de AppLocalizations para qualquer locale suportado ou fallback en', () {
      final l10nPt = ResolvedorIdioma.obterTraducoes(const Locale('pt'));
      final l10nJa = ResolvedorIdioma.obterTraducoes(const Locale('ja'));
      final l10nFallback = ResolvedorIdioma.obterTraducoes(const Locale('it'));

      expect(l10nPt.comumSim, equals('Sim'));
      expect(l10nJa.comumSim, equals('はい'));
      expect(l10nFallback.comumSim, equals('Yes'));
      expect(ResolvedorIdioma.obterTraducoes(null).comumSim, equals('Yes'));
    });
  });

  group('idiomaAtivoProvider — Sincronização com BancoDadosLocal', () {
    test('inicializa com preferência salva no SQLite e persiste trocas de idioma preservando versão dos termos', () async {
      final banco = await BancoDadosLocal.abrirEmMemoria();
      addTearDown(() async => await banco.fechar());

      await banco.salvarConfiguracao(
        AppConfigRecord(
          id: 1,
          acceptedTermsVersion: 5,
          idiomaPreferido: 'es',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          bancoDadosLocalProvider.overrideWithValue(banco),
          localeSistemaProvider.overrideWithValue(const Locale('pt', 'BR')),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(idiomaAtivoProvider), equals(const Locale('es')));

      await container.read(idiomaAtivoProvider.notifier).selecionarIdioma('ar');
      expect(container.read(idiomaAtivoProvider), equals(const Locale('ar')));

      final configSalva = await banco.obterConfiguracao(1);
      expect(configSalva, isNotNull);
      expect(configSalva!.idiomaPreferido, equals('ar'));
      expect(configSalva.versaoTermosAceita, equals(5));
    });

    test('cria registro de configuração no SQLite ao selecionar idioma quando o banco ainda estava vazio', () async {
      final banco = await BancoDadosLocal.abrirEmMemoria();
      addTearDown(() async => await banco.fechar());

      final container = ProviderContainer(
        overrides: [
          bancoDadosLocalProvider.overrideWithValue(banco),
          localeSistemaProvider.overrideWithValue(const Locale('fr', 'FR')),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(idiomaAtivoProvider), equals(const Locale('fr')));

      await container.read(idiomaAtivoProvider.notifier).selecionarIdioma('de');
      expect(container.read(idiomaAtivoProvider), equals(const Locale('de')));
      expect(banco.obterConfiguracaoSync()?.idiomaPreferido, equals('de'));
    });

    test('opera em memória mesmo quando bancoDadosLocalProvider é nulo e usa locale padrão da plataforma', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final localeInicial = container.read(idiomaAtivoProvider);
      expect(
        ResolvedorIdioma.ehSuportado(localeInicial.languageCode),
        isTrue,
      );

      await container.read(idiomaAtivoProvider.notifier).selecionarIdioma('ja');
      expect(container.read(idiomaAtivoProvider), equals(const Locale('ja')));
    });

    testWidgets(
      'obterLocaleEfetivo e obterTraducoesContexto usam pt em MaterialApp mínimo sem delegates e idiomaAtivoProvider quando há delegates ou preferência',
      (tester) async {
        late Locale localeObtido;
        late AppLocalizations l10nObtida;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, _) {
                  localeObtido = ResolvedorIdioma.obterLocaleEfetivo(context, ref);
                  l10nObtida = ResolvedorIdioma.obterTraducoesContexto(context, ref);
                  return Text(l10nObtida.comumSim);
                },
              ),
            ),
          ),
        );

        expect(localeObtido, equals(const Locale('pt')));
        expect(l10nObtida.comumSim, equals('Sim'));

        // Quando delegates estão configurados ou idioma é selecionado, usa o idioma ativo
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              localeSistemaProvider.overrideWithValue(const Locale('de', 'DE')),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: ResolvedorIdioma.localesSuportados,
              home: Consumer(
                builder: (context, ref, _) {
                  localeObtido = ResolvedorIdioma.obterLocaleEfetivo(context, ref);
                  l10nObtida = ResolvedorIdioma.obterTraducoesContexto(context, ref);
                  return Text(l10nObtida.comumSim);
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(localeObtido, equals(const Locale('de')));
        expect(l10nObtida.comumSim, equals('Ja'));
      },
    );
  });
}
