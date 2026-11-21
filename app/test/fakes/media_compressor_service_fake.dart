// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'dart:typed_data';
import 'package:fixalog/core/services/session_bundle_manager.dart';
import 'package:fixalog/features/media/services/media_compressor_service.dart';

/// Biblioteca `test-only` determinística de [MediaCompressorService] em memória/disco temporário,
/// evitando acoplamento a codecs nativos de sistema operacional em testes unitários e de fluxo.
class MediaCompressorServiceFake extends MediaCompressorService {
  final Directory diretorioSaida;
  final bool falharCompressaoImagem;
  final bool falharTranscodificacaoVideo;
  final int quantidadePaginasPdfPadrao;
  final List<String> fotosSolicitadas = <String>[];
  final List<String> videosSolicitados = <String>[];
  final List<String> documentosSolicitados = <String>[];

  MediaCompressorServiceFake({
    required this.diretorioSaida,
    this.falharCompressaoImagem = false,
    this.falharTranscodificacaoVideo = false,
    this.quantidadePaginasPdfPadrao = 1,
  });

  @override
  Future<File?> comprimirImagemSessao({
    required SessionBundleManager sessionManager,
    required String sessionId,
    required String mediaUuid,
  }) async {
    fotosSolicitadas.add(mediaUuid);
    if (falharCompressaoImagem) {
      return null;
    }
    final arquivo = File('${diretorioSaida.path}/$mediaUuid.webp');
    await arquivo.parent.create(recursive: true);
    await arquivo.writeAsBytes(Uint8List.fromList(<int>[0x52, 0x49, 0x46, 0x46, 1, 2, 3]));
    return arquivo;
  }

  @override
  Future<({File? video, File? poster})> transcodificarVideoSessao({
    required SessionBundleManager sessionManager,
    required String sessionId,
    required String mediaUuid,
    double? inicioSegundos,
    double? duracaoSegundos,
  }) async {
    videosSolicitados.add(mediaUuid);
    if (falharTranscodificacaoVideo) {
      return (video: null, poster: null);
    }
    final video = File('${diretorioSaida.path}/$mediaUuid.mp4');
    final poster = File('${diretorioSaida.path}/${mediaUuid}_poster.jpg');
    await video.parent.create(recursive: true);
    await video.writeAsBytes(Uint8List.fromList(<int>[0, 0, 0, 0x18, 0x66, 0x74, 0x79, 0x70]));
    await poster.writeAsBytes(Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xD9]));
    return (video: video, poster: poster);
  }

  @override
  Future<List<File>> rasterizarDocumentoPdfSessao({
    required SessionBundleManager sessionManager,
    required String sessionId,
    required String mediaUuid,
    double dpi = 150.0,
  }) async {
    documentosSolicitados.add(mediaUuid);
    final paginas = <File>[];
    for (var i = 1; i <= quantidadePaginasPdfPadrao; i++) {
      final pagina = File('${diretorioSaida.path}/${mediaUuid}_p$i.webp');
      await pagina.parent.create(recursive: true);
      await pagina.writeAsBytes(Uint8List.fromList(<int>[0x52, 0x49, 0x46, 0x46, i]));
      paginas.add(pagina);
    }
    return paginas;
  }
}
