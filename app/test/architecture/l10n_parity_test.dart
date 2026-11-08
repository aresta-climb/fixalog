// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import 'package:fixalog/core/l10n/generated/app_localizations.dart';
import 'package:fixalog/core/models/proto/protos/wizard.pb.dart';
import 'package:fixalog/core/services/protocol_parser.dart';

void main() {
  const idiomasEsperados = ['pt', 'en', 'es', 'fr', 'de', 'ar', 'ja'];

  group('Paridade de Localização (.arb)', () {
    test(
      'todos os 7 arquivos .arb possuem exatamente o mesmo conjunto de chaves e placeholders do template app_pt.arb',
      () {
        final dirArb = Directory('lib/core/l10n/arb');
        expect(
          dirArb.existsSync(),
          isTrue,
          reason: 'O diretório lib/core/l10n/arb deve existir.',
        );

        final arquivoBase = File('lib/core/l10n/arb/app_pt.arb');
        expect(
          arquivoBase.existsSync(),
          isTrue,
          reason: 'O arquivo template app_pt.arb deve existir.',
        );

        final mapaBase =
            jsonDecode(arquivoBase.readAsStringSync()) as Map<String, dynamic>;
        final chavesBase =
            mapaBase.keys.where((k) => !k.startsWith('@')).toSet();
        expect(chavesBase, isNotEmpty);

        final regexPlaceholder = RegExp(r'\{([a-zA-Z0-9_]+)\}');

        for (final locale in idiomasEsperados) {
          final arquivo = File('lib/core/l10n/arb/app_$locale.arb');
          expect(
            arquivo.existsSync(),
            isTrue,
            reason: 'Arquivo app_$locale.arb não encontrado.',
          );

          final mapa =
              jsonDecode(arquivo.readAsStringSync()) as Map<String, dynamic>;
          expect(
            mapa['@@locale'],
            equals(locale),
            reason: 'O campo @@locale em app_$locale.arb deve ser "$locale".',
          );

          final chavesIdioma =
              mapa.keys.where((k) => !k.startsWith('@')).toSet();

          final faltantes = chavesBase.difference(chavesIdioma);
          final excedentes = chavesIdioma.difference(chavesBase);

          expect(
            faltantes,
            isEmpty,
            reason:
                'Chaves ausentes em app_$locale.arb: ${faltantes.join(', ')}',
          );
          expect(
            excedentes,
            isEmpty,
            reason:
                'Chaves excedentes em app_$locale.arb: ${excedentes.join(', ')}',
          );

          for (final chave in chavesBase) {
            final valorBase = mapaBase[chave] as String;
            final valorTraduzido = mapa[chave] as String;
            expect(
              valorTraduzido.trim(),
              isNotEmpty,
              reason:
                  'A chave "$chave" está vazia em app_$locale.arb.',
            );

            final placeholdersBase = regexPlaceholder.allMatches(valorBase)
                .map((m) => m.group(1)!)
                .toSet();
            final placeholdersTraduzido =
                regexPlaceholder.allMatches(valorTraduzido)
                    .map((m) => m.group(1)!)
                    .toSet();

            expect(
              placeholdersTraduzido,
              equals(placeholdersBase),
              reason:
                  'Placeholders divergentes na chave "$chave" em app_$locale.arb.',
            );
          }
        }
      },
    );

    test(
      'código Dart gerado em lib/core/l10n/generated/ implementa todas as chaves de app_pt.arb nos 7 idiomas e lookupAppLocalizations instancia todos sem erro',
      () {
        final arquivoBase = File('lib/core/l10n/arb/app_pt.arb');
        final mapaBase =
            jsonDecode(arquivoBase.readAsStringSync()) as Map<String, dynamic>;
        final chavesBase =
            mapaBase.keys.where((k) => !k.startsWith('@')).toSet();

        final arqContrato = File(
          'lib/core/l10n/generated/app_localizations.dart',
        );
        expect(
          arqContrato.existsSync(),
          isTrue,
          reason:
              'Arquivo gerado app_localizations.dart ausente. Execute flutter gen-l10n.',
        );
        final codigoContrato = arqContrato.readAsStringSync();
        for (final chave in chavesBase) {
          expect(
            RegExp('String (get )?$chave\\b').hasMatch(codigoContrato),
            isTrue,
            reason:
                'A chave "$chave" do .arb não foi gerada em app_localizations.dart. Execute flutter gen-l10n.',
          );
        }

        for (final locale in idiomasEsperados) {
          final arqGeradoIdioma = File(
            'lib/core/l10n/generated/app_localizations_$locale.dart',
          );
          expect(
            arqGeradoIdioma.existsSync(),
            isTrue,
            reason:
                'Arquivo gerado app_localizations_$locale.dart ausente. Execute flutter gen-l10n.',
          );
          final codigoIdioma = arqGeradoIdioma.readAsStringSync();

          for (final chave in chavesBase) {
            expect(
              RegExp('String (get )?$chave\\b').hasMatch(codigoIdioma),
              isTrue,
              reason:
                  'A chave "$chave" não está implementada em app_localizations_$locale.dart. Execute flutter gen-l10n.',
            );
          }

          final instancia = lookupAppLocalizations(Locale(locale));
          expect(instancia.localeName, equals(locale));
          expect(instancia.appTitulo.trim(), isNotEmpty);
        }
      },
    );
  });

  group('Paridade dos Documentos Legais Multilíngues', () {
    test(
      'todos os 7 idiomas possuem termos-de-uso-fixalog.md (com link canônico #privacy-policy) e politica-de-privacidade-fixalog.md',
      () {
        for (final locale in idiomasEsperados) {
          final arqTermos = File(
            'legal/repo/public/docs/$locale/termos-de-uso-fixalog.md',
          );
          final arqPolitica = File(
            'legal/repo/public/docs/$locale/politica-de-privacidade-fixalog.md',
          );

          expect(
            arqTermos.existsSync(),
            isTrue,
            reason:
                'Arquivo de Termos de Uso ausente para o idioma "$locale".',
          );
          expect(
            arqPolitica.existsSync(),
            isTrue,
            reason:
                'Arquivo de Política de Privacidade ausente para o idioma "$locale".',
          );

          final conteudoTermos = arqTermos.readAsStringSync().trim();
          final conteudoPolitica = arqPolitica.readAsStringSync().trim();

          expect(conteudoTermos, isNotEmpty);
          expect(
            conteudoTermos,
            contains('(#privacy-policy)'),
            reason:
                'O arquivo de Termos em "$locale" deve conter o link canônico (#privacy-policy).',
          );
          expect(conteudoPolitica, isNotEmpty);
        }
      },
    );
  });

  group('Paridade dos Dicionários de Protocolos YAML (i18n)', () {
    test(
      'todos os 5 protocolos estruturais em assets/protocols/ possuem dicionários completos nos 7 idiomas para blocos, conteúdos, ramos, tipos de ação e opções',
      () {
        final dirProtocolos = Directory('assets/protocols');
        final arquivosEstruturais = dirProtocolos
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.yaml'))
            .toList();

        expect(arquivosEstruturais.length, greaterThanOrEqualTo(5));

        for (final arqProto in arquivosEstruturais) {
          final proto = ProtocolParser.fromYaml(arqProto.readAsStringSync());
          final idProto = proto.id;

          final idsBlocos = proto.blocos.map((b) => b.id).toSet();
          final idsConteudos = <String>{};
          final idsRamos = <String>{};
          final idsTiposAcao = <String>{};
          final valoresOpcoes = <String>{};

          void inspecionarSteps(List<Step> steps) {
            for (final step in steps) {
              for (final c in step.conteudos) {
                idsConteudos.add(c.id);
                final tipo = c.whichTipo();
                if (tipo == ConteudoStep_Tipo.campoSimples) {
                  for (final op in c.campoSimples.opcoes) {
                    valoresOpcoes.add(op.valor);
                  }
                } else if (tipo == ConteudoStep_Tipo.selecaoRamo) {
                  for (final r in c.selecaoRamo.ramos) {
                    idsRamos.add(r.id);
                    inspecionarSteps(r.steps);
                  }
                } else if (tipo == ConteudoStep_Tipo.listaAcoes) {
                  for (final t in c.listaAcoes.tiposDisponiveis) {
                    idsTiposAcao.add(t.id);
                    inspecionarSteps(t.steps);
                  }
                }
              }
            }
          }

          for (final bloco in proto.blocos) {
            inspecionarSteps(bloco.steps);
          }

          for (final locale in idiomasEsperados) {
            final arqI18n = File(
              'assets/protocols/i18n/$locale/$idProto.yaml',
            );
            expect(
              arqI18n.existsSync(),
              isTrue,
              reason:
                  'Dicionário de protocolo ausente: assets/protocols/i18n/$locale/$idProto.yaml',
            );

            final docI18n = loadYaml(arqI18n.readAsStringSync()) as YamlMap;
            final protoI18n = docI18n['protocolo'] as YamlMap?;
            expect(
              protoI18n?['nome']?.toString().trim(),
              isNotEmpty,
              reason: 'protocolo.nome ausente em $locale/$idProto.yaml',
            );

            final blocosI18n = (docI18n['blocos'] as YamlMap?) ?? YamlMap();
            for (final bid in idsBlocos) {
              final bMap = blocosI18n[bid] as YamlMap?;
              expect(
                bMap?['titulo']?.toString().trim(),
                isNotEmpty,
                reason:
                    'Bloco "$bid" sem título traduzido em $locale/$idProto.yaml',
              );
            }

            final conteudosI18n =
                (docI18n['conteudos'] as YamlMap?) ?? YamlMap();
            for (final cid in idsConteudos) {
              final cMap = conteudosI18n[cid] as YamlMap?;
              expect(
                cMap,
                isNotNull,
                reason:
                    'Conteúdo "$cid" ausente em $locale/$idProto.yaml',
              );
              final texto =
                  (cMap!['label'] ?? cMap['titulo'])?.toString().trim() ?? '';
              expect(
                texto,
                isNotEmpty,
                reason:
                    'Conteúdo "$cid" sem label/titulo em $locale/$idProto.yaml',
              );
            }

            final ramosI18n = (docI18n['ramos'] as YamlMap?) ?? YamlMap();
            for (final rid in idsRamos) {
              final rMap = ramosI18n[rid] as YamlMap?;
              expect(
                rMap?['label']?.toString().trim(),
                isNotEmpty,
                reason:
                    'Ramo "$rid" sem label traduzido em $locale/$idProto.yaml',
              );
            }

            final tiposI18n = (docI18n['tipos_acao'] as YamlMap?) ?? YamlMap();
            for (final tid in idsTiposAcao) {
              final tMap = tiposI18n[tid] as YamlMap?;
              expect(
                tMap?['label']?.toString().trim(),
                isNotEmpty,
                reason:
                    'Tipo de ação "$tid" sem label traduzido em $locale/$idProto.yaml',
              );
            }

            final opcoesI18n = (docI18n['opcoes'] as YamlMap?) ?? YamlMap();
            for (final valOp in valoresOpcoes) {
              final opMap = opcoesI18n[valOp] as YamlMap?;
              expect(
                opMap?['label']?.toString().trim(),
                isNotEmpty,
                reason:
                    'Opção "$valOp" sem label traduzido em $locale/$idProto.yaml',
              );
            }

            // Verifica que o ProtocolParser gera a árvore completa do protocolo localizada
            // sem nenhum título, label ou corpo vazio para este idioma.
            final protoTraduzido = ProtocolParser.fromYaml(
              arqProto.readAsStringSync(),
              codigoIdioma: locale,
            );
            expect(protoTraduzido.nome.trim(), isNotEmpty);
            for (final b in protoTraduzido.blocos) {
              expect(
                b.nome.trim(),
                isNotEmpty,
                reason: 'Bloco "${b.id}" gerou nome vazio em $locale/$idProto',
              );
              for (final s in b.steps) {
                for (final c in s.conteudos) {
                  if (c.whichTipo() == ConteudoStep_Tipo.instrucao) {
                    expect(
                      c.instrucao.titulo.trim(),
                      isNotEmpty,
                      reason:
                          'Instrução "${c.id}" gerou título vazio em $locale/$idProto',
                    );
                    expect(
                      c.instrucao.corpo.trim(),
                      isNotEmpty,
                      reason:
                          'Instrução "${c.id}" gerou corpo vazio em $locale/$idProto',
                    );
                  } else if (c.whichTipo() == ConteudoStep_Tipo.campoSimples) {
                    expect(
                      c.campoSimples.label.trim(),
                      isNotEmpty,
                      reason:
                          'Campo "${c.id}" gerou label vazio em $locale/$idProto',
                    );
                  }
                }
              }
            }
          }
        }
      },
    );
  });
}
