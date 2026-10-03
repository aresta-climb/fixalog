// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:test/test.dart';
import 'package:atualizador_legal/atualizador_versao_legal.dart';

void main() {
  late Directory diretorioTemporario;
  late String caminhoDocs;
  late String arquivoTermos;
  late String arquivoPolitica;
  late String arquivoSaida;

  setUp(() async {
    diretorioTemporario = await Directory.systemTemp.createTemp('teste_legal_');
    caminhoDocs = '${diretorioTemporario.path}/public/docs';
    await Directory(caminhoDocs).create(recursive: true);

    arquivoTermos = '$caminhoDocs/termos-de-uso-fixlog.md';
    arquivoPolitica = '$caminhoDocs/politica-de-privacidade-fixlog.md';
    arquivoSaida = '${diretorioTemporario.path}/lib/core/constantes/versao_legal.g.dart';

    await File(arquivoTermos).writeAsString('Conteudo inicial dos termos fixlog');
    await File(arquivoPolitica).writeAsString('Conteudo inicial da politica fixlog');
  });

  tearDown(() async {
    if (await diretorioTemporario.exists()) {
      await diretorioTemporario.delete(recursive: true);
    }
  });

  test('Gera arquivo inicial com kVersaoLegal = 1 quando arquivo de saida nao existe', () async {
    final atualizador = AtualizadorVersaoLegal(
      caminhoRepositorio: diretorioTemporario.path,
      caminhoArquivoSaida: arquivoSaida,
    );

    final atualizou = await atualizador.verificarEAtualizar();

    expect(atualizou, isTrue);
    expect(File(arquivoSaida).existsSync(), isTrue);

    final conteudo = await File(arquivoSaida).readAsString();
    expect(conteudo, contains('const int kVersaoLegal = 1;'));
    expect(conteudo, contains('kDataUltimaAtualizacaoLegal'));
    expect(conteudo, contains('kHashesLegais'));
    expect(conteudo, contains('termos-de-uso-fixlog.md'));
    expect(conteudo, contains('politica-de-privacidade-fixlog.md'));
  });

  test('Retorna false e nao altera arquivo quando hashes sao identicos', () async {
    final atualizador = AtualizadorVersaoLegal(
      caminhoRepositorio: diretorioTemporario.path,
      caminhoArquivoSaida: arquivoSaida,
    );

    await atualizador.verificarEAtualizar();
    final conteudoPrimeiraExecucao = await File(arquivoSaida).readAsString();

    final atualizouNovamente = await atualizador.verificarEAtualizar();
    expect(atualizouNovamente, isFalse);

    final conteudoSegundaExecucao = await File(arquivoSaida).readAsString();
    expect(conteudoSegundaExecucao, equals(conteudoPrimeiraExecucao));
  });

  test('Incrementa kVersaoLegal quando o conteudo dos termos de uso e modificado', () async {
    final atualizador = AtualizadorVersaoLegal(
      caminhoRepositorio: diretorioTemporario.path,
      caminhoArquivoSaida: arquivoSaida,
    );

    await atualizador.verificarEAtualizar();

    // Modifica termos
    await File(arquivoTermos).writeAsString('Conteudo alterado dos termos');

    final atualizouAposMudanca = await atualizador.verificarEAtualizar();
    expect(atualizouAposMudanca, isTrue);

    final conteudoNovo = await File(arquivoSaida).readAsString();
    expect(conteudoNovo, contains('const int kVersaoLegal = 2;'));
  });

  test('Incrementa kVersaoLegal quando o conteudo da politica de privacidade e modificado', () async {
    final atualizador = AtualizadorVersaoLegal(
      caminhoRepositorio: diretorioTemporario.path,
      caminhoArquivoSaida: arquivoSaida,
    );

    await atualizador.verificarEAtualizar();

    // Modifica politica
    await File(arquivoPolitica).writeAsString('Nova secao de privacidade');

    final atualizouAposMudanca = await atualizador.verificarEAtualizar();
    expect(atualizouAposMudanca, isTrue);

    final conteudoNovo = await File(arquivoSaida).readAsString();
    expect(conteudoNovo, contains('const int kVersaoLegal = 2;'));
  });

  test('Retorna false e registra erro quando arquivos de termos nao existem', () async {
    await File(arquivoTermos).delete();

    final atualizador = AtualizadorVersaoLegal(
      caminhoRepositorio: diretorioTemporario.path,
      caminhoArquivoSaida: arquivoSaida,
    );

    final atualizou = await atualizador.verificarEAtualizar();
    expect(atualizou, isFalse);
    expect(File(arquivoSaida).existsSync(), isFalse);
  });

  test('Trata erro ao ler arquivo de saida com encoding invalido e regera com sucesso', () async {
    final file = File(arquivoSaida);
    await file.parent.create(recursive: true);
    await file.writeAsBytes([0xFF, 0xFE, 0xFD]);

    final atualizador = AtualizadorVersaoLegal(
      caminhoRepositorio: diretorioTemporario.path,
      caminhoArquivoSaida: arquivoSaida,
    );

    final atualizou = await atualizador.verificarEAtualizar();
    expect(atualizou, isTrue);
  });
}
