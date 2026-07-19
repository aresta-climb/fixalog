import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/models/proto/registro.pb.dart';

void main() {
  group('ReferenciaMidia Protobuf Serialization', () {
    test('Should create and serialize ArquivoImagem correctly', () {
      final imagem = ArquivoImagem(
        uuid: '123e4567-e89b-12d3-a456-426614174000',
        tipoOriginal: 'image/jpeg',
        hashOriginal: 'abc123hash',
        tipoComprimido: 'image/webp',
        hashComprimido: 'def456hash',
        versaoCompressao: 1,
      );

      final referencia = ReferenciaMidia(imagem: imagem);

      // Serialize
      final bytes = referencia.writeToBuffer();
      
      // Deserialize
      final decoded = ReferenciaMidia.fromBuffer(bytes);

      expect(decoded.hasImagem(), isTrue);
      expect(decoded.imagem.uuid, '123e4567-e89b-12d3-a456-426614174000');
      expect(decoded.imagem.hashOriginal, 'abc123hash');
      expect(decoded.imagem.versaoCompressao, 1);
    });

    test('Should create and serialize ArquivoVideo correctly', () {
      final video = ArquivoVideo(
        uuid: 'video-uuid-123',
        tipoOriginal: 'video/quicktime',
        hashOriginal: 'v123',
        tipoComprimido: 'video/mp4',
        hashComprimido: 'v456',
        versaoCompressao: 2,
      );

      final referencia = ReferenciaMidia(video: video);

      final bytes = referencia.writeToBuffer();
      final decoded = ReferenciaMidia.fromBuffer(bytes);

      expect(decoded.hasVideo(), isTrue);
      expect(decoded.video.uuid, 'video-uuid-123');
      expect(decoded.video.versaoCompressao, 2);
    });
  });
}
