// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fixalog/core/models/local/identity_record.dart';
import 'package:fixalog/core/services/autenticacao_nuvem_service.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/services/crypto_service.dart';
import 'package:fixalog/core/services/gravador_breadcrumbs.dart';
import 'package:fixalog/core/services/servico_telemetria.dart';
import 'package:fixalog/features/feedback/services/servico_fila_feedback.dart';
import 'package:fixalog/features/feedback/utils/compressor_imagem_feedback.dart';

import '../../../core/services/autenticacao_nuvem_service_fake.dart';
import '../../../fakes/registro_logger_fake.dart';

void main() {
  group('ServicoFilaFeedback — Enfileiramento SQLite, Envio Multipart e Limpeza', () {
    late BancoDadosLocal banco;
    late Directory tempDir;
    late RegistroLoggerFake loggerFake;
    late AutenticacaoNuvemServiceFake authFake;
    late CompressorImagemFeedback compressorDeterministico;

    setUp(() async {
      banco = await BancoDadosLocal.abrirEmMemoria();
      tempDir = await Directory.systemTemp.createTemp('fila_feedback_test_');
      loggerFake = RegistroLoggerFake();
      authFake = AutenticacaoNuvemServiceFake(
        crypto: CryptoService(),
        tokenAppCheckRetornado: 'token_app_check_teste_123',
        sessaoArmazenada: const SessaoUsuarioNuvem(
          userId: 'usr_teste_001',
          email: 'renato@aresta.com',
          provedor: ProvedorOidc.google,
          nomeCompleto: 'Renato Auditor',
          clubeAssociacao: 'FEMERJ',
          jwtSupabase: 'jwt_123',
          atestadoOidcJwt: 'oidc_123',
          fingerprintChavePublica: 'fp_123',
        ),
      );
      compressorDeterministico = CompressorImagemFeedback(
        logger: loggerFake,
        compressaoNativa: (
          bytes, {
          required quality,
          required minWidth,
          required minHeight,
        }) async => Uint8List.fromList([82, 73, 70, 70]),
      );
    });

    tearDown(() async {
      await banco.fechar();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'enfileirarEDespacharFeedback persiste no SQLite, transmite via HTTP multipart com X-Firebase-AppCheck e remove imagem após HTTP 200',
      () async {
        await banco.salvarIdentidade(
          IdentityRecord()
            ..nome = 'Renato Auditor'
            ..clubeAssociacao = 'FEMERJ'
            ..dataRegistro = DateTime.utc(2026, 11, 9),
        );

        String? headerAppCheckRecebido;
        String? descricaoRecebida;
        String? categoriaRecebida;
        Map<String, dynamic>? metadadosRecebidos;
        String? nomeArquivoRecebido;

        final mockClient = MockClient((http.Request request) async {
          headerAppCheckRecebido = request.headers['X-Firebase-AppCheck'];
          final bodyTexto = utf8.decode(request.bodyBytes, allowMalformed: true);
          if (bodyTexto.contains('Inconsistência no Bloco 3')) {
            descricaoRecebida = 'Inconsistência no Bloco 3';
          }
          if (bodyTexto.contains('protocolo')) {
            categoriaRecebida = 'protocolo';
          }
          if (bodyTexto.contains('screenshot.webp')) {
            nomeArquivoRecebido = 'screenshot.webp';
          }
          final matchMeta = RegExp(r'\{"app":"fixalog".*\}').firstMatch(bodyTexto);
          if (matchMeta != null) {
            metadadosRecebidos =
                jsonDecode(matchMeta.group(0)!) as Map<String, dynamic>;
          }
          return http.Response('{"ok":true}', 200);
        });

        final servico = ServicoFilaFeedback(
          banco: banco,
          autenticacaoService: authFake,
          compressorImagem: compressorDeterministico,
          logger: loggerFake,
          clienteHttp: mockClient,
          obterDiretorioSuporte: () async => tempDir,
          geradorIdFeedback: () => 'fb-sucesso-001',
          urlEdgeFunction: 'https://edge.fixalog.test/functions/v1/app-feedback',
        );

        GravadorBreadcrumbs.resetarParaTestes();
        await ServicoTelemetria.instancia.registrarNavegacaoAba('configuracoes');

        final registro = await servico.enfileirarEDespacharFeedback(
          mensagem: 'Inconsistência no Bloco 3',
          capturaTela: Uint8List.fromList([1, 2, 3, 4]),
          categoria: 'protocolo',
          metadadosExtras: {'id_protocolo': 'manutencao_ferragens'},
        );

        expect(registro.idFeedback, equals('fb-sucesso-001'));
        expect(headerAppCheckRecebido, equals('token_app_check_teste_123'));
        expect(descricaoRecebida, equals('Inconsistência no Bloco 3'));
        expect(categoriaRecebida, equals('protocolo'));
        expect(nomeArquivoRecebido, equals('screenshot.webp'));
        expect(metadadosRecebidos?['autor_nome'], equals('Renato Auditor'));
        expect(metadadosRecebidos?['clube'], equals('FEMERJ'));
        expect(
          metadadosRecebidos?['id_protocolo'],
          equals('manutencao_ferragens'),
        );
        final breadcrumbsAnexados =
            metadadosRecebidos?['breadcrumbs'] as List<dynamic>?;
        expect(breadcrumbsAnexados, isNotNull);
        expect(breadcrumbsAnexados, isNotEmpty);
        expect(
          (breadcrumbsAnexados!.first as Map<String, dynamic>)['evento'],
          equals('navegar_aba'),
        );

        // Após confirmação HTTP 200, a fila pendente no SQLite deve estar vazia e o arquivo de imagem removido
        expect(await banco.listarFeedbacksPendentes(), isEmpty);
        expect(File(registro.caminhoImagem).existsSync(), isFalse);
      },
    );

    test(
      'mantém registro pendente e arquivo de imagem quando offline (SocketException) ou HTTP 500, rebaixando falha de rede para logAviso',
      () async {
        var modoFalha = 'offline';
        final mockClient = MockClient((http.Request request) async {
          if (modoFalha == 'offline') {
            throw const SocketException('Sem sinal na parede');
          }
          if (modoFalha == 'erro_500') {
            return http.Response('Erro interno', 500);
          }
          if (modoFalha == 'erro_inesperado') {
            throw StateError('Falha interna de serialização');
          }
          return http.Response('{"ok":true}', 201);
        });

        // Compressor que faz fallback para PNG para testar também o envio de screenshot.png
        final compressorPng = CompressorImagemFeedback(
          logger: loggerFake,
          compressaoNativa: (
            bytes, {
            required quality,
            required minWidth,
            required minHeight,
          }) async => Uint8List(0),
        );

        final servico = ServicoFilaFeedback(
          banco: banco,
          autenticacaoService: authFake,
          compressorImagem: compressorPng,
          logger: loggerFake,
          clienteHttp: mockClient,
          obterDiretorioSuporte: () async => tempDir,
          geradorIdFeedback: () => 'fb-offline-002',
        );

        final registro = await servico.enfileirarEDespacharFeedback(
          mensagem: 'Relato sem rede na falésia',
          capturaTela: Uint8List.fromList([137, 80, 78, 71]),
          categoria: 'aplicativo',
        );

        // Continua pendente no SQLite e com imagem PNG preservada no disco
        final pendentes = await banco.listarFeedbacksPendentes();
        expect(pendentes, hasLength(1));
        expect(pendentes.single.idFeedback, equals('fb-offline-002'));
        expect(registro.caminhoImagem, endsWith('.png'));
        expect(File(registro.caminhoImagem).existsSync(), isTrue);
        expect(loggerFake.errosRegistrados, isEmpty);
        expect(
          loggerFake.avisosRegistrados,
          contains(contains('Falha ao despachar feedback (fb-offline-002)')),
        );

        // Tentativa com HTTP 500 mantém na fila e registra aviso
        modoFalha = 'erro_500';
        expect(await servico.processarFilaPendentes(), equals(0));
        expect(await banco.listarFeedbacksPendentes(), hasLength(1));

        // Erro não-rede (StateError) registra logError e mantém na fila
        modoFalha = 'erro_inesperado';
        expect(await servico.processarFilaPendentes(), equals(0));
        expect(loggerFake.errosRegistrados, hasLength(1));

        // Recuperação de sinal envia o item pendente e limpa o arquivo
        modoFalha = 'ok';
        expect(await servico.processarFilaPendentes(), equals(1));
        expect(await banco.listarFeedbacksPendentes(), isEmpty);
        expect(File(registro.caminhoImagem).existsSync(), isFalse);
      },
    );

    test(
      'trata captura de tela vazia, banco nulo e provider Riverpod com segurança',
      () async {
        final mockClient = MockClient((_) async => http.Response('OK', 200));
        final servicoSemBanco = ServicoFilaFeedback(
          banco: null,
          autenticacaoService: authFake,
          compressorImagem: compressorDeterministico,
          logger: loggerFake,
          clienteHttp: mockClient,
          obterDiretorioSuporte: () async => tempDir,
        );

        final reg = await servicoSemBanco.enfileirarEDespacharFeedback(
          mensagem: 'Feedback sem imagem e sem banco',
          capturaTela: Uint8List(0),
          despacharImediatamente: false,
        );
        expect(reg.caminhoImagem, isEmpty);
        expect(await servicoSemBanco.processarFilaPendentes(), equals(0));
        expect(await servicoSemBanco.enviarItemFeedback(reg), isTrue);

        final container = ProviderContainer(
          overrides: [
            bancoDadosLocalProvider.overrideWithValue(banco),
          ],
        );
        addTearDown(container.dispose);
        expect(container.read(servicoFilaFeedbackProvider), isA<ServicoFilaFeedback>());
      },
    );
  });
}
