// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';

import 'package:fixalog/core/services/classificador_dispositivo.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('fixalog_meminfo_test_');
    ClassificadorDispositivo.resetarParaTestes();
  });

  tearDown(() {
    ClassificadorDispositivo.resetarParaTestes();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ClassificadorDispositivo — Faixas de Memória e Teto de ImageCache', () {
    test(
      'classifica dispositivos de baixo (<= 3 GB -> 50 MB), médio (4-6 GB -> 100 MB) e alto porte (>= 8 GB -> 150 MB)',
      () {
        final baixo = ClassificadorDispositivo.instancia.classificar(
          ramTotalMb: 3072,
        );
        expect(baixo.tierDispositivo, equals('baixo'));
        expect(baixo.ramGb, equals('3'));
        expect(baixo.limiteCacheImagensBytes, equals(50 * 1024 * 1024));
        expect(ClassificadorDispositivo.instancia.tierDispositivo, equals('baixo'));
        expect(ClassificadorDispositivo.instancia.ramGb, equals('3'));
        expect(
          ClassificadorDispositivo.instancia.limiteCacheImagensBytes,
          equals(50 * 1024 * 1024),
        );

        final medio = ClassificadorDispositivo.instancia.classificar(
          ramTotalMb: 6144,
        );
        expect(medio.tierDispositivo, equals('medio'));
        expect(medio.ramGb, equals('6'));
        expect(medio.limiteCacheImagensBytes, equals(100 * 1024 * 1024));

        final alto = ClassificadorDispositivo.instancia.classificar(
          ramTotalMb: 8192,
        );
        expect(alto.tierDispositivo, equals('alto'));
        expect(alto.ramGb, equals('8'));
        expect(alto.limiteCacheImagensBytes, equals(150 * 1024 * 1024));
      },
    );

    test(
      'lê MemTotal de arquivo no formato /proc/meminfo e retorna perfil desconhecido (100 MB) quando ausente ou inválido',
      () {
        final arqValido = File('${tempDir.path}/meminfo_8gb')
          ..writeAsStringSync('MemTotal:       8388608 kB\nMemFree: 1024 kB\n');
        final perfilLido = ClassificadorDispositivo.instancia.classificar(
          caminhoMeminfo: arqValido.path,
        );
        expect(perfilLido.tierDispositivo, equals('alto'));
        expect(perfilLido.ramGb, equals('8'));

        final arqInvalido = File('${tempDir.path}/meminfo_invalido')
          ..writeAsStringSync('Sem cabecalho de memoria\n');
        final perfilInvalido = ClassificadorDispositivo.instancia.classificar(
          caminhoMeminfo: arqInvalido.path,
        );
        expect(perfilInvalido.tierDispositivo, equals('desconhecido'));
        expect(perfilInvalido.ramGb, equals('0'));
        expect(perfilInvalido.limiteCacheImagensBytes, equals(100 * 1024 * 1024));

        final perfilInexistente = ClassificadorDispositivo.instancia.classificar(
          caminhoMeminfo: '${tempDir.path}/nao_existe',
        );
        expect(perfilInexistente.tierDispositivo, equals('desconhecido'));
      },
    );

    test(
      'configurarGestaoMemoria aplica o limite calculado ou explícito no PaintingBinding.instance.imageCache',
      () {
        ClassificadorDispositivo.configurarGestaoMemoria(ramTotalMb: 2048);
        expect(
          PaintingBinding.instance.imageCache.maximumSizeBytes,
          equals(50 * 1024 * 1024),
        );

        ClassificadorDispositivo.configurarGestaoMemoria(
          tamanhoMaximoBytes: 75 * 1024 * 1024,
        );
        expect(
          PaintingBinding.instance.imageCache.maximumSizeBytes,
          equals(75 * 1024 * 1024),
        );
      },
    );
  });
}
