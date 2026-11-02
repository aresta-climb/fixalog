// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter_test/flutter_test.dart';
import 'servico_galeria_dispositivo_fake.dart';

void main() {
  group('ServicoGaleriaDispositivoFake', () {
    test('registra caminhos de fotos e vídeos salvos em memória', () async {
      final fake = ServicoGaleriaDispositivoFake();

      await fake.salvarFotoNoRoloDaCamera('/tmp/foto_1.jpg');
      await fake.salvarVideoNoRoloDaCamera('/tmp/video_1.mp4');

      expect(fake.fotosSalvas, equals(['/tmp/foto_1.jpg']));
      expect(fake.videosSalvos, equals(['/tmp/video_1.mp4']));
    });

    test('lança exceção determinística quando simularFalha está ativo', () async {
      final fake = ServicoGaleriaDispositivoFake(simularFalha: true);

      await expectLater(
        fake.salvarFotoNoRoloDaCamera('/tmp/foto_erro.jpg'),
        throwsException,
      );
      await expectLater(
        fake.salvarVideoNoRoloDaCamera('/tmp/video_erro.mp4'),
        throwsException,
      );
      expect(fake.fotosSalvas, isEmpty);
      expect(fake.videosSalvos, isEmpty);
    });
  });
}
