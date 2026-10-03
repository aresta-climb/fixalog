// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:atualizador_legal/atualizador_versao_legal.dart';

Future<void> main(List<String> argumentos) async {
  final caminhoRepositorio = argumentos.isNotEmpty
      ? argumentos[0]
      : Platform.script.resolve('../../app/legal/repo').toFilePath();

  final caminhoArquivoSaida = argumentos.length > 1
      ? argumentos[1]
      : Platform.script.resolve('../../app/lib/core/constantes/versao_legal.g.dart').toFilePath();

  final atualizador = AtualizadorVersaoLegal(
    caminhoRepositorio: caminhoRepositorio,
    caminhoArquivoSaida: caminhoArquivoSaida,
  );

  stdout.writeln('Verificando integridade dos termos legais...');
  final atualizado = await atualizador.verificarEAtualizar();

  if (atualizado) {
    stdout.writeln('Sucesso: versao_legal.g.dart atualizado com sucesso.');
  } else {
    stdout.writeln('Nenhuma alteracao detectada nos termos. Versao inalterada.');
  }
}
