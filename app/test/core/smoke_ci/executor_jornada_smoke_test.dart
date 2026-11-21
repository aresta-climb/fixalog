// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixalog/core/services/autenticacao_nuvem_service.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/smoke_ci/configuracao_smoke_ci.dart';
import 'package:fixalog/core/smoke_ci/executor_jornada_smoke.dart';
import '../../../tool/release_tools/servidor_smoke_ci.dart';
import '../../fakes/crypto_service_fake.dart';
import '../../fakes/media_compressor_service_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canalSecureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  group('ExecutorJornadaSmoke', () {
    late Directory tempDir;
    late BancoDadosLocal banco;
    ServidorSmokeCi? servidor;
    late String urlSupabaseOriginal;
    HttpOverrides? overridesOriginais;
    late Map<String, String> cofreEmMemoria;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      overridesOriginais = HttpOverrides.current;
      HttpOverrides.global = null;
      cofreEmMemoria = <String, String>{};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canalSecureStorage, (call) async {
        final args = (call.arguments as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};
        final key = args['key'] as String?;
        switch (call.method) {
          case 'read':
            return key != null ? cofreEmMemoria[key] : null;
          case 'write':
            if (key != null) {
              cofreEmMemoria[key] = (args['value'] as String?) ?? '';
            }
            return null;
          case 'delete':
            if (key != null) cofreEmMemoria.remove(key);
            return null;
          case 'deleteAll':
            cofreEmMemoria.clear();
            return null;
          default:
            return null;
        }
      });
      urlSupabaseOriginal = AutenticacaoNuvemService.urlSupabaseAtiva;
      tempDir = await Directory.systemTemp.createTemp('executor_smoke_test_');
      banco = await BancoDadosLocal.abrirEmMemoria();
    });

    tearDown(() async {
      HttpOverrides.global = overridesOriginais;
      AutenticacaoNuvemService.urlSupabaseAtiva = urlSupabaseOriginal;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canalSecureStorage, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        AutenticacaoNuvemService.canalAutenticacaoNativa,
        null,
      );
      await servidor?.encerrar();
      await banco.fechar();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    void instalarPonteNativaOidcParaServidor(Uri uriServidor) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        AutenticacaoNuvemService.canalAutenticacaoNativa,
        (call) async {
          final args = (call.arguments as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};
          final rawNonce = (args['rawNonce'] as String?) ?? '';
          final nonceHash = sha256.convert(utf8.encode(rawNonce)).toString();
          final client = HttpClient();
          try {
            final req = await client.postUrl(
              uriServidor.replace(path: '/__smoke__/oidc-token'),
            );
            req.headers.contentType = ContentType.json;
            req.add(utf8.encode(jsonEncode(<String, dynamic>{
              'nonceHash': nonceHash,
              'provedor': 'google',
            })));
            final res = await req.close();
            final corpo = await utf8.decoder.bind(res).join();
            return jsonDecode(corpo) as Map<String, dynamic>;
          } finally {
            client.close(force: true);
          }
        },
      );
    }

    test('deve concluir jornada pericial ponta a ponta e entregar relatório de sucesso ao servidor local', () async {
      servidor = await ServidorSmokeCi.iniciar(tokenEsperado: 'tok-jornada-ok');
      instalarPonteNativaOidcParaServidor(servidor!.uriLocalHost);

      final config = ConfiguracaoSmokeCi.validar(
        servidorUrl: servidor!.uriLocalHost.toString(),
        token: 'tok-jornada-ok',
      );
      final crypto = CryptoServiceFake();
      final media = MediaCompressorServiceFake(diretorioSaida: tempDir);

      final futuroRelatorio = servidor!.aguardarRelatorio(
        timeout: const Duration(seconds: 15),
      );

      final executor = ExecutorJornadaSmoke(
        config: config,
        diretorioBase: tempDir,
        banco: banco,
        cryptoService: crypto,
        mediaService: media,
        geradorVideoSintetico: (arquivoDestino) async {
          await arquivoDestino.writeAsBytes(<int>[0, 0, 0, 0x18, 0x66, 0x74, 0x79, 0x70]);
        },
      );

      final resultado = await executor.executar();
      final relatorioRemoto = await futuroRelatorio;

      expect(resultado.sucesso, isTrue, reason: resultado.erros.join('\n'));
      expect(relatorioRemoto['sucesso'], isTrue);
      expect(
        relatorioRemoto['etapas'],
        equals(<String>[
          'termos_legais',
          'identidade_oidc_ecdsa',
          'preparacao_midias',
          'geracao_epub3_assinado',
          'extracao_relatorio',
        ]),
      );
      expect(relatorioRemoto['erros'], isEmpty);
      final metricas = relatorioRemoto['metricas'] as Map<String, dynamic>;
      expect(metricas['epubBytes'] as int, greaterThan(0));
      expect(metricas['possuiAssinaturaXmlDsig'], isTrue);
    });

    test('deve reportar falha ao servidor quando o login OIDC ou uma etapa falhar', () async {
      servidor = await ServidorSmokeCi.iniciar(tokenEsperado: 'tok-falha');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        AutenticacaoNuvemService.canalAutenticacaoNativa,
        (_) async => null,
      );

      final config = ConfiguracaoSmokeCi.validar(
        servidorUrl: servidor!.uriLocalHost.toString(),
        token: 'tok-falha',
      );
      final futuroRelatorio = servidor!.aguardarRelatorio(
        timeout: const Duration(seconds: 10),
      );

      final executor = ExecutorJornadaSmoke(
        config: config,
        diretorioBase: tempDir,
        banco: banco,
        cryptoService: CryptoServiceFake(),
        mediaService: MediaCompressorServiceFake(diretorioSaida: tempDir),
      );
      executor.registrarErroAssincrono('Exceção assíncrona simulada');

      final resultado = await executor.executar();
      final relatorioRemoto = await futuroRelatorio;

      expect(resultado.sucesso, isFalse);
      expect(relatorioRemoto['sucesso'], isFalse);
      expect((relatorioRemoto['erros'] as List<dynamic>).length, greaterThanOrEqualTo(2));
    });

    test('deve reportar falha quando mídia obrigatória WebP ou certificado X.509 faltar na geração', () async {
      servidor = await ServidorSmokeCi.iniciar(tokenEsperado: 'tok-midia-ausente');
      instalarPonteNativaOidcParaServidor(servidor!.uriLocalHost);
      final config = ConfiguracaoSmokeCi.validar(
        servidorUrl: servidor!.uriLocalHost.toString(),
        token: 'tok-midia-ausente',
      );

      // Caso A: compressão de imagem falha -> foto_smoke.webp ausente no EPUB
      final resSemFoto = await ExecutorJornadaSmoke(
        config: config,
        diretorioBase: tempDir,
        banco: banco,
        mediaService: MediaCompressorServiceFake(
          diretorioSaida: tempDir,
          falharCompressaoImagem: true,
        ),
        geradorVideoSintetico: (f) => f.writeAsBytes(<int>[1, 2]),
      ).executar();
      expect(resSemFoto.sucesso, isFalse);
      expect(resSemFoto.erros.join('\n'), contains('foto_smoke.webp'));

      // Caso B: geração falha dentro do GenerationNotifier por erro de chaves
      final cryptoComFalhaTardia = _CryptoFalhaNaGeracaoEpub();
      final resErroGeracao = await ExecutorJornadaSmoke(
        config: config,
        diretorioBase: tempDir,
        banco: banco,
        cryptoService: cryptoComFalhaTardia,
        mediaService: MediaCompressorServiceFake(diretorioSaida: tempDir),
        geradorVideoSintetico: (f) => f.writeAsBytes(<int>[1, 2]),
      ).executar();
      expect(resErroGeracao.sucesso, isFalse);
      expect(resErroGeracao.erros.join('\n'), contains('Falha ao gerar EPUB 3 assinado'));

      // Caso C: submitIdentity sem certificado X.509 válido
      final resSemCert = await ExecutorJornadaSmoke(
        config: config,
        diretorioBase: tempDir,
        banco: banco,
        cryptoService: _CryptoSemCertificadoX509(),
      ).executar();
      expect(resSemCert.sucesso, isFalse);
      expect(resSemCert.erros.join('\n'), contains('certificado X.509 ausente'));
    });

    test('deve gerar artefatos binários sintéticos PNG, PDF e vídeo FFmpeg válidos e falhar quando FFmpeg falhar', () async {
      final png = ExecutorJornadaSmoke.gerarBytesPngSintetico();
      expect(png.sublist(0, 4), equals(<int>[0x89, 0x50, 0x4E, 0x47]));

      final pdf = ExecutorJornadaSmoke.gerarBytesPdfSintetico();
      final pdfTexto = latin1.decode(pdf);
      expect(pdfTexto, startsWith('%PDF-1.4'));
      expect(pdfTexto.trimRight(), endsWith('%%EOF'));

      final videoOk = File('${tempDir.path}/sintetico_ok.mp4');
      await ExecutorJornadaSmoke.gerarVideoSinteticoPadrao(
        videoOk,
        executadorFfmpeg: (cmd) async {
          expect(cmd, contains(videoOk.path));
          await videoOk.writeAsBytes(<int>[1, 2, 3, 4]);
          return true;
        },
      );
      expect(videoOk.existsSync(), isTrue);

      final videoFalha = File('${tempDir.path}/sintetico_erro.mp4');
      await expectLater(
        ExecutorJornadaSmoke.gerarVideoSinteticoPadrao(
          videoFalha,
          executadorFfmpeg: (_) async => false,
        ),
        throwsStateError,
      );
    });
  });
}

class _CryptoSemCertificadoX509 extends CryptoServiceFake {
  @override
  Future<String?> obterCertificadoX509Pem() async => null;
}

class _CryptoFalhaNaGeracaoEpub extends CryptoServiceFake {
  int _leiturasChavePrivada = 0;

  @override
  Future<String> getPrivateKeyPem() async {
    _leiturasChavePrivada++;
    if (_leiturasChavePrivada >= 1) {
      throw Exception('Falha simulada ao ler chave privada na assinatura XML-DSig');
    }
    return super.getPrivateKeyPem();
  }
}
