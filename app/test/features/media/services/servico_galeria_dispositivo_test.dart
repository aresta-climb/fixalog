// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/features/media/services/servico_galeria_dispositivo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canalGal = MethodChannel('gal');
  late List<MethodCall> chamadasMetodo;

  setUp(() {
    chamadasMetodo = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalGal, (call) async {
      chamadasMetodo.add(call);
      if (call.method == 'requestAccess' || call.method == 'hasAccess') {
        return true;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalGal, null);
  });

  group('ServicoGaleriaDispositivo', () {
    test('salvarFotoNoRoloDaCamera envia putImage sem álbum customizado para o rolo da câmera', () async {
      const servico = ServicoGaleriaDispositivo();
      await servico.salvarFotoNoRoloDaCamera('/tmp/foto_camera.jpg');

      expect(
        chamadasMetodo.map((c) => c.method),
        containsAllInOrder(['requestAccess', 'putImage']),
      );
      final chamadaPutImage = chamadasMetodo.firstWhere((c) => c.method == 'putImage');
      final args = Map<String, dynamic>.from(chamadaPutImage.arguments as Map);
      expect(args['path'], equals('/tmp/foto_camera.jpg'));
      expect(args['album'], isNull);
    });

    test('salvarVideoNoRoloDaCamera envia putVideo sem álbum customizado para o rolo da câmera', () async {
      const servico = ServicoGaleriaDispositivo();
      await servico.salvarVideoNoRoloDaCamera('/tmp/video_camera.mp4');

      expect(
        chamadasMetodo.map((c) => c.method),
        containsAllInOrder(['requestAccess', 'putVideo']),
      );
      final chamadaPutVideo = chamadasMetodo.firstWhere((c) => c.method == 'putVideo');
      final args = Map<String, dynamic>.from(chamadaPutVideo.arguments as Map);
      expect(args['path'], equals('/tmp/video_camera.mp4'));
      expect(args['album'], isNull);
    });

    test('servicoGaleriaDispositivoProvider fornece instância de ServicoGaleriaDispositivo', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final servico = container.read(servicoGaleriaDispositivoProvider);
      expect(servico, isA<ServicoGaleriaDispositivo>());
    });
  });
}
