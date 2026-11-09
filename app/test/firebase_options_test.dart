// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/firebase_options.dart';

void main() {
  group('DefaultFirebaseOptions — Configuração do Projeto Firebase Fixalog', () {
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test(
      'retorna credenciais do projeto fixalog para Android e iOS e lança UnsupportedError em plataformas desktop',
      () {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final opcoesAndroid = DefaultFirebaseOptions.currentPlatform;
        expect(opcoesAndroid.projectId, equals('fixalog'));
        expect(opcoesAndroid.storageBucket, equals('fixalog.firebasestorage.app'));

        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final opcoesIos = DefaultFirebaseOptions.currentPlatform;
        expect(opcoesIos.projectId, equals('fixalog'));
        expect(opcoesIos.iosBundleId, equals('com.arestaclimb.fixalog'));

        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        expect(
          () => DefaultFirebaseOptions.currentPlatform,
          throwsA(isA<UnsupportedError>()),
        );

        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        expect(
          () => DefaultFirebaseOptions.currentPlatform,
          throwsA(isA<UnsupportedError>()),
        );

        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        expect(
          () => DefaultFirebaseOptions.currentPlatform,
          throwsA(isA<UnsupportedError>()),
        );

        debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
        expect(
          () => DefaultFirebaseOptions.currentPlatform,
          throwsA(isA<UnsupportedError>()),
        );
      },
    );
  });
}
