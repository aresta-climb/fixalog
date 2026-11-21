// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fixalog/core/services/autenticacao_nuvem_service.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/smoke_ci/configuracao_smoke_ci.dart';
import 'package:fixalog/core/smoke_ci/main_smoke_ci.dart' as smoke_entry;
import '../../../tool/release_tools/servidor_smoke_ci.dart';
import '../../fakes/media_compressor_service_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canalSecureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  const canalPathProvider = MethodChannel('plugins.flutter.io/path_provider');

  group('main_smoke_ci', () {
    late Directory tempDir;
    late BancoDadosLocal banco;
    ServidorSmokeCi? servidor;
    late String urlOriginal;
    HttpOverrides? overridesOriginais;
    late Map<String, String> cofreMemoria;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      overridesOriginais = HttpOverrides.current;
      HttpOverrides.global = null;
      urlOriginal = AutenticacaoNuvemService.urlSupabaseAtiva;
      cofreMemoria = <String, String>{};
      tempDir = await Directory.systemTemp.createTemp('main_smoke_ci_test_');
      banco = await BancoDadosLocal.abrirEmMemoria();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canalSecureStorage, (call) async {
        final args = (call.arguments as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};
        final key = args['key'] as String?;
        if (call.method == 'read') return key != null ? cofreMemoria[key] : null;
        if (call.method == 'write' && key != null) {
          cofreMemoria[key] = (args['value'] as String?) ?? '';
        }
        if (call.method == 'delete' && key != null) cofreMemoria.remove(key);
        return null;
      });

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canalPathProvider, (call) async {
        return tempDir.path;
      });
    });

    tearDown(() async {
      HttpOverrides.global = overridesOriginais;
      AutenticacaoNuvemService.urlSupabaseAtiva = urlOriginal;
      const canalSmoke = MethodChannel(ConfiguracaoSmokeCi.nomeCanalPadrao);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canalSecureStorage, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canalPathProvider, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canalSmoke, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        AutenticacaoNuvemService.canalAutenticacaoNativa,
        null,
      );
      await servidor?.encerrar();
      await banco.fechar();
      try {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    test('deve montar FixalogApp, capturar erros globais quando acionados e concluir jornada via canal nativo', () async {
      servidor = await ServidorSmokeCi.iniciar(tokenEsperado: 'tok-boot-1');
      const canalSmoke = MethodChannel(ConfiguracaoSmokeCi.nomeCanalPadrao);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canalSmoke, (_) async {
        return <String, dynamic>{
          'ativo': true,
          'servidorUrl': servidor!.uriLocalHost.toString(),
          'token': 'tok-boot-1',
        };
      });

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
              servidor!.uriLocalHost.replace(path: '/__smoke__/oidc-token'),
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

      final futuroRelatorio = servidor!.aguardarRelatorio(
        timeout: const Duration(seconds: 15),
      );

      Widget? widgetMontado;
      final montadorOriginal = smoke_entry.montadorAppPadraoSmoke;
      final agendadorOriginal = smoke_entry.agendadorPosQuadroSmoke;
      addTearDown(() {
        smoke_entry.montadorAppPadraoSmoke = montadorOriginal;
        smoke_entry.agendadorPosQuadroSmoke = agendadorOriginal;
      });

      // Exercita o agendador padrão registrando o callback de quadro e acionando-o
      smoke_entry.agendadorPosQuadroSmoke((_) {});

      smoke_entry.montadorAppPadraoSmoke = (widget) {
        widgetMontado = widget;
      };
      smoke_entry.agendadorPosQuadroSmoke = (cb) => cb(Duration.zero);

      final resultado = await smoke_entry.inicializarAplicativoSmokeCi(
        provedorDiretorioBase: () async => tempDir,
        provedorBanco: (_) async => banco,
        mediaServiceOverride: MediaCompressorServiceFake(diretorioSaida: tempDir),
        geradorVideoOverride: (f) => f.writeAsBytes(<int>[0, 0, 0, 0x18]),
      );

      expect(widgetMontado, isNotNull);
      expect(resultado.sucesso, isTrue, reason: resultado.erros.join('\n'));
      final relatorio = await futuroRelatorio;
      expect(relatorio['sucesso'], isTrue);

      // Exercita o entrypoint main() diretamente com SQLite em arquivo temporário
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfiNoIsolate;
      await smoke_entry.main();

      // Verifica que os tratadores globais de erro instalados permanecem funcionais
      FlutterError.onError?.call(
        FlutterErrorDetails(exception: Exception('erro_flutter_teste')),
      );
      final tratado = PlatformDispatcher.instance.onError?.call(
        Exception('erro_plataforma_teste'),
        StackTrace.current,
      );
      expect(tratado, isTrue);
    });
  });
}
