// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:crypto/crypto.dart';

/// Utilitário responsável por monitorar alterações nos documentos legais
/// em `public/docs/` e atualizar a versão compilada em `versao_legal.g.dart`.
class AtualizadorVersaoLegal {
  final String caminhoRepositorio;
  final String caminhoArquivoSaida;

  const AtualizadorVersaoLegal({
    required this.caminhoRepositorio,
    required this.caminhoArquivoSaida,
  });

  /// Verifica os hashes atuais e gera/incrementa o arquivo de saída se houver alterações.
  Future<bool> verificarEAtualizar() async {
    final arquivoSaida = File(caminhoArquivoSaida);
    final arquivoTermos = File('$caminhoRepositorio/public/docs/termos-de-uso-fixalog.md');
    final arquivoPolitica = File('$caminhoRepositorio/public/docs/politica-de-privacidade-fixalog.md');

    if (!await arquivoTermos.exists() || !await arquivoPolitica.exists()) {
      stderr.writeln('Erro: Documentos legais do Fixalog não encontrados em $caminhoRepositorio/public/docs/.');
      return false;
    }

    final hashTermosAtual = sha256.convert(await arquivoTermos.readAsBytes()).toString();
    final hashPoliticaAtual = sha256.convert(await arquivoPolitica.readAsBytes()).toString();

    int versaoAnterior = 0;
    String hashTermosAnterior = '';
    String hashPoliticaAnterior = '';

    if (await arquivoSaida.exists()) {
      try {
        final conteudoExistente = await arquivoSaida.readAsString();

        final matchVersao = RegExp(r"const int kVersaoLegal = (\d+);").firstMatch(conteudoExistente);
        if (matchVersao != null) {
          versaoAnterior = int.parse(matchVersao.group(1)!);
        }

        final matchTermos = RegExp(r"'termos-de-uso-fixalog\.md': '([^']+)'").firstMatch(conteudoExistente);
        if (matchTermos != null) {
          hashTermosAnterior = matchTermos.group(1)!;
        }

        final matchPolitica = RegExp(r"'politica-de-privacidade-fixalog\.md': '([^']+)'").firstMatch(conteudoExistente);
        if (matchPolitica != null) {
          hashPoliticaAnterior = matchPolitica.group(1)!;
        }
      } catch (e) {
        stderr.writeln('Aviso ao ler arquivo anterior: $e');
      }
    }

    final houveAlteracao = (hashTermosAtual != hashTermosAnterior) ||
        (hashPoliticaAtual != hashPoliticaAnterior);

    if (houveAlteracao || versaoAnterior == 0) {
      final novaVersao = versaoAnterior == 0 ? 1 : versaoAnterior + 1;
      final dataIso = DateTime.now().toIso8601String().split('T')[0];

      final conteudoGerado = '''// GERADO AUTOMATICAMENTE. NÃO EDITE.
// Atualizado pelo pacote ferramentas/atualizador_legal

const int kVersaoLegal = $novaVersao;
const String kDataUltimaAtualizacaoLegal = '$dataIso';

const Map<String, String> kHashesLegais = {
  'termos-de-uso-fixalog.md': '$hashTermosAtual',
  'politica-de-privacidade-fixalog.md': '$hashPoliticaAtual',
};
''';

      if (!arquivoSaida.parent.existsSync()) {
        arquivoSaida.parent.createSync(recursive: true);
      }

      await arquivoSaida.writeAsString(conteudoGerado);
      return true;
    }

    return false;
  }
}
