// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../tool/release_tools/smoke_test_pacote.dart';

void main() {
  group('OrquestradorSmokePacote', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('orq_smoke_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    File criarZip(String nome, Map<String, List<int>> entradas) {
      final archive = Archive();
      entradas.forEach((caminho, bytes) {
        archive.addFile(ArchiveFile(caminho, bytes.length, bytes));
      });
      final file = File('${tempDir.path}/$nome');
      file.writeAsBytesSync(ZipEncoder().encode(archive));
      return file;
    }

    Future<void> postarRelatorioFake({
      required Uri uriServidor,
      required String token,
      required bool sucesso,
      List<String> erros = const <String>[],
    }) async {
      final client = HttpClient();
      try {
        final req = await client.postUrl(
          uriServidor.replace(path: '/__smoke__/relatorio'),
        );
        req.headers.contentType = ContentType.json;
        req.add(
          utf8.encode(
            jsonEncode(<String, dynamic>{
              'token': token,
              'sucesso': sucesso,
              'etapas': <String>['termos_legais', 'identidade_oidc_ecdsa'],
              'erros': erros,
              'metricas': <String, dynamic>{'epubBytes': 8192},
            }),
          ),
        );
        final res = await req.close();
        await res.drain<void>();
      } finally {
        client.close(force: true);
      }
    }

    test('deve validar AAB oficial (auditoria + Cold Start) e concluir jornada Android com APK de smoke', () async {
      final aab = criarZip('app-release.aab', <String, List<int>>{
        'base/dex/classes.dex': ascii.encode('dex035'),
        'base/lib/arm64-v8a/libapp.so': ascii.encode('ELF'),
        'base/lib/arm64-v8a/libflutter.so': ascii.encode('ELF'),
        'base/lib/arm64-v8a/libffmpegkit.so': ascii.encode('ELF'),
      });
      final apkSmoke = File('${tempDir.path}/app-smoke.apk')..writeAsBytesSync(<int>[1, 2, 3]);
      final bundletoolJar = File('${tempDir.path}/bundletool.jar')..writeAsBytesSync(<int>[4, 5]);
      final saidaJson = File('${tempDir.path}/evidencia-android.json');
      final comandos = <String>[];

      final orq = OrquestradorSmokePacote(
        tempoEsperaColdStart: const Duration(milliseconds: 20),
        timeoutJornada: const Duration(seconds: 5),
        executorProcesso: (exec, args, {ambiente}) async {
          comandos.add('$exec ${args.join(' ')}');
          if (exec == 'java' && args.contains('build-apks')) {
            final outArg = args.firstWhere((a) => a.startsWith('--output='));
            final outPath = outArg.substring('--output='.length);
            criarZip(
              outPath.split(RegExp(r'[/\\]')).last,
              <String, List<int>>{'universal.apk': <int>[9, 8, 7]},
            ).copySync(outPath);
            return const ResultadoProcessoCli(0, '', '');
          }
          if (exec == 'adb' && args.contains('pidof')) {
            return const ResultadoProcessoCli(0, '4321\n', '');
          }
          if (exec == 'adb' && args.contains('am') && args.contains('--es')) {
            final idxServer = args.indexOf('smoke_server');
            final idxToken = args.indexOf('smoke_token');
            final serverEditado = args[idxServer + 1].replaceAll('10.0.2.2', '127.0.0.1');
            final token = args[idxToken + 1];
            await postarRelatorioFake(
              uriServidor: Uri.parse(serverEditado),
              token: token,
              sucesso: true,
            );
            return const ResultadoProcessoCli(0, 'Status: ok', '');
          }
          return const ResultadoProcessoCli(0, '', '');
        },
      );

      await orq.executarAndroid(
        arquivoAab: aab,
        arquivoApkSmoke: apkSmoke,
        bundletoolJar: bundletoolJar,
        pacote: 'com.arestaclimb.fixalog',
        arquivoSaidaEvidencia: saidaJson,
      );

      expect(saidaJson.existsSync(), isTrue);
      final evidencia = jsonDecode(saidaJson.readAsStringSync()) as Map<String, dynamic>;
      expect(evidencia['coldStartLojaAprovado'], isTrue);
      expect((evidencia['jornadaSmoke'] as Map<String, dynamic>)['sucesso'], isTrue);
      expect(comandos.any((c) => c.contains('--ks=')), isTrue);
      expect(comandos.any((c) => c.contains('pidof com.arestaclimb.fixalog')), isTrue);
    });

    test('deve falhar no Android quando Cold Start do AAB apresentar FATAL EXCEPTION no logcat', () async {
      final aab = criarZip('app-release.aab', <String, List<int>>{
        'base/dex/classes.dex': ascii.encode('dex035'),
        'base/lib/arm64-v8a/libapp.so': ascii.encode('ELF'),
        'base/lib/arm64-v8a/libflutter.so': ascii.encode('ELF'),
        'base/lib/arm64-v8a/libffmpegkit.so': ascii.encode('ELF'),
      });
      final apkSmoke = File('${tempDir.path}/app-smoke.apk')..writeAsBytesSync(<int>[1]);
      final bundletoolJar = File('${tempDir.path}/bundletool.jar')..writeAsBytesSync(<int>[2]);

      final orq = OrquestradorSmokePacote(
        tempoEsperaColdStart: const Duration(milliseconds: 10),
        executorProcesso: (exec, args, {ambiente}) async {
          if (exec == 'java' && args.contains('build-apks')) {
            final outPath = args.firstWhere((a) => a.startsWith('--output=')).substring('--output='.length);
            criarZip('u.apks', <String, List<int>>{'universal.apk': <int>[1]}).copySync(outPath);
            return const ResultadoProcessoCli(0, '', '');
          }
          if (exec == 'adb' && args.contains('logcat') && args.contains('-d')) {
            return const ResultadoProcessoCli(
              0,
              'E/AndroidRuntime: FATAL EXCEPTION: main\nProcess: com.arestaclimb.fixalog',
              '',
            );
          }
          return const ResultadoProcessoCli(0, '4321', '');
        },
      );

      await expectLater(
        orq.executarAndroid(
          arquivoAab: aab,
          arquivoApkSmoke: apkSmoke,
          bundletoolJar: bundletoolJar,
          pacote: 'com.arestaclimb.fixalog',
        ),
        throwsStateError,
      );
    });

    test('deve auditar IPA oficial (codesign + otool) e concluir jornada iOS no Simulator', () async {
      final ipa = criarZip('Runner.ipa', <String, List<int>>{
        'Payload/Runner.app/Runner': ascii.encode('MachO'),
        'Payload/Runner.app/Frameworks/App.framework/App': ascii.encode('MachO'),
        'Payload/Runner.app/Frameworks/Flutter.framework/Flutter': ascii.encode('MachO'),
        'Payload/Runner.app/Frameworks/ffmpegkit.framework/ffmpegkit': ascii.encode('MachO'),
        'Payload/Runner.app/Info.plist': ascii.encode('ITSAppUsesNonExemptEncryption'),
      });
      final appSim = Directory('${tempDir.path}/Runner.app')..createSync();
      final saidaJson = File('${tempDir.path}/evidencia-ios.json');

      final orq = OrquestradorSmokePacote(
        timeoutJornada: const Duration(seconds: 5),
        executorProcesso: (exec, args, {ambiente}) async {
          if (exec == 'xcrun' && args.contains('launch')) {
            final server = ambiente!['SIMCTL_CHILD_ARESTA_SMOKE_SERVER']!;
            final token = ambiente['SIMCTL_CHILD_ARESTA_SMOKE_TOKEN']!;
            await postarRelatorioFake(
              uriServidor: Uri.parse(server),
              token: token,
              sucesso: true,
            );
            return const ResultadoProcessoCli(0, 'com.arestaclimb.fixalog: 999', '');
          }
          return const ResultadoProcessoCli(0, '@rpath/Flutter.framework/Flutter', '');
        },
      );

      await orq.executarIos(
        arquivoIpa: ipa,
        diretorioAppSimulador: appSim,
        pacote: 'com.arestaclimb.fixalog',
        arquivoSaidaEvidencia: saidaJson,
      );

      expect(saidaJson.existsSync(), isTrue);
      final evidencia = jsonDecode(saidaJson.readAsStringSync()) as Map<String, dynamic>;
      expect(evidencia['auditoriaIpaAprovada'], isTrue);
      expect((evidencia['jornadaSmoke'] as Map<String, dynamic>)['sucesso'], isTrue);
    });
  });
}
