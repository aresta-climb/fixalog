// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'video_transcoder_service_fake.dart';

void main() {
  late Directory tempDir;
  late File videoEntrada;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('video_fake_test_');
    videoEntrada = File('${tempDir.path}/entrada.mp4');
    await videoEntrada.writeAsBytes(<int>[1, 2, 3, 4]);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('VideoTranscoderServiceFake', () {
    test('retorna duracao padrao ou especifica por caminho e null para arquivo inexistente', () async {
      final fake = VideoTranscoderServiceFake(duracaoPadraoSegundos: 45.0);
      expect(await fake.obterDuracaoSegundos(videoEntrada), equals(45.0));

      fake.duracoesPorCaminho[videoEntrada.path] = 95.0;
      expect(await fake.obterDuracaoSegundos(videoEntrada), equals(95.0));

      expect(
        await fake.obterDuracaoSegundos(File('${tempDir.path}/nao_existe.mp4')),
        isNull,
      );
    });

    test('grava arquivo de saida e registra parametros de corte ao transcodificar com sucesso', () async {
      final fake = VideoTranscoderServiceFake();
      final saidaPath = '${tempDir.path}/saida.mp4';

      final resultado = await fake.transcodificarVideo(
        arquivoEntrada: videoEntrada,
        caminhoSaida: saidaPath,
        inicioSegundos: 12.5,
        duracaoSegundos: 60.0,
      );

      expect(resultado, isNotNull);
      expect(await resultado!.exists(), isTrue);
      expect(fake.chamadasTranscodificacao, hasLength(1));
      expect(fake.chamadasTranscodificacao.first.inicioSegundos, equals(12.5));
      expect(fake.chamadasTranscodificacao.first.duracaoSegundos, equals(60.0));
    });

    test('extrai poster frame valido e respeita simularFalha', () async {
      final fake = VideoTranscoderServiceFake();
      final posterPath = '${tempDir.path}/poster.jpg';

      final poster = await fake.extrairPosterFrame(
        arquivoEntrada: videoEntrada,
        caminhoSaida: posterPath,
      );
      expect(poster, isNotNull);
      expect(await poster!.exists(), isTrue);

      fake.simularFalha = true;
      expect(
        await fake.transcodificarVideo(
          arquivoEntrada: videoEntrada,
          caminhoSaida: '${tempDir.path}/falha.mp4',
        ),
        isNull,
      );
      expect(
        await fake.extrairPosterFrame(
          arquivoEntrada: videoEntrada,
          caminhoSaida: '${tempDir.path}/falha.jpg',
        ),
        isNull,
      );
    });
  });
}
