// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';

// Mock path_provider
class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String path;
  FakePathProviderPlatform(this.path);
  
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
  
  // Note: PathProviderPlatform uses getApplicationDocumentsPath() in its interface,
  // but path_provider library exposes getApplicationDocumentsDirectory() which calls getApplicationDocumentsPath() internally.
}

void main() {
  late SessionBundleManager manager;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fixalog_test');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    manager = SessionBundleManager();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('SessionBundleManager', () {
    test('getSessionDirectory should return correct path and create directory if not exists', () async {
      final sessionId = 'test-session-123';
      final dir = await manager.getSessionDirectory(sessionId);

      expect(dir.path, contains('sessoes'));
      expect(dir.path, contains(sessionId));
      expect(dir.existsSync(), isTrue);
    });

    test('saveOriginalMedia should save with _original suffix', () async {
      final sessionId = 'session-456';
      final mediaUuid = 'media-789';
      final bytes = Uint8List.fromList([1, 2, 3]);

      final file = await manager.saveOriginalMedia(
        sessionId: sessionId,
        mediaUuid: mediaUuid,
        extension: '.jpg',
        bytes: bytes,
      );

      expect(file.path, endsWith('${mediaUuid}_original.jpg'));
      expect(file.existsSync(), isTrue);
      expect(file.readAsBytesSync(), equals(bytes));
    });

    test('saveCompressedMedia should save without suffix', () async {
      final sessionId = 'session-456';
      final mediaUuid = 'media-789';
      final bytes = Uint8List.fromList([4, 5, 6]);

      final file = await manager.saveCompressedMedia(
        sessionId: sessionId,
        mediaUuid: mediaUuid,
        extension: '.jpg',
        bytes: bytes,
      );

      expect(file.path, endsWith('$mediaUuid.jpg'));
      expect(file.existsSync(), isTrue);
      expect(file.readAsBytesSync(), equals(bytes));
    });

    test('saveManifest should save registro.binarypb', () async {
      final sessionId = 'session-456';
      final bytes = Uint8List.fromList([7, 8, 9]);

      final file = await manager.saveManifest(
        sessionId: sessionId,
        binarypb: bytes,
      );

      expect(file.path, endsWith('registro.binarypb'));
      expect(file.existsSync(), isTrue);
      expect(file.readAsBytesSync(), equals(bytes));
    });

    test('deleteSessionBundle should delete directory and all contents', () async {
      final sessionId = 'session-to-delete';
      
      // Setup some files
      await manager.saveManifest(sessionId: sessionId, binarypb: Uint8List.fromList([1]));
      final dir = await manager.getSessionDirectory(sessionId);
      expect(dir.existsSync(), isTrue);

      // Act
      await manager.deleteSessionBundle(sessionId);

      // Assert
      expect(dir.existsSync(), isFalse);
    });

    test('getReportFilePath should return correct format fixalog_<uuid>.pdf', () async {
      final sessionId = 'b4b1a2-c3d4-4e5f-a6b7-8c9d0e1f2g3h';
      
      final reportPath = await manager.getReportFilePath(sessionId: sessionId);
      
      expect(reportPath, contains('sessoes'));
      expect(reportPath, endsWith('fixalog_b4b1a2-c3d4-4e5f-a6b7-8c9d0e1f2g3h.pdf'));
    });

    test('copiarArquivosMidiaSessao copia midias originais e pre-processadas ignorando manifestos, temporarios e relatorios finais', () async {
      const idOrigem = 'sessao-origem';
      const idDestino = 'sessao-destino';
      final dirOrigem = await manager.getSessionDirectory(idOrigem);

      // Mídias que devem ser copiadas
      File('${dirOrigem.path}/foto1_original.jpg').writeAsBytesSync([1, 2, 3]);
      File('${dirOrigem.path}/foto1.webp').writeAsBytesSync([4, 5, 6]);
      File('${dirOrigem.path}/foto1_thumb.jpg').writeAsBytesSync([7, 8, 9]);
      File('${dirOrigem.path}/vid1_original.mp4').writeAsBytesSync([10, 11]);
      File('${dirOrigem.path}/vid1.mp4').writeAsBytesSync([12, 13]);
      File('${dirOrigem.path}/vid1_poster.jpg').writeAsBytesSync([14, 15]);
      File('${dirOrigem.path}/doc1_original.pdf').writeAsBytesSync([16, 17]);
      File('${dirOrigem.path}/doc1_p1.webp').writeAsBytesSync([18, 19]);
      File('${dirOrigem.path}/doc1_p1_thumb.jpg').writeAsBytesSync([20, 21]);

      // Arquivos que NÃO devem ser copiados
      File('${dirOrigem.path}/registro.binarypb').writeAsBytesSync([99]);
      File('${dirOrigem.path}/registro.json').writeAsStringSync('{}');
      File('${dirOrigem.path}/foto2.webp.tmp').writeAsBytesSync([88]);
      File('${dirOrigem.path}/fixalog_$idOrigem.pdf').writeAsBytesSync([77]);
      File('${dirOrigem.path}/fixalog_$idOrigem.epub').writeAsBytesSync([66]);
      File('${dirOrigem.path}/relatorio.epub').writeAsBytesSync([55]);

      await manager.copiarArquivosMidiaSessao(
        idSessaoOrigem: idOrigem,
        idSessaoDestino: idDestino,
      );

      final dirDestino = await manager.getSessionDirectory(idDestino);
      expect(File('${dirDestino.path}/foto1_original.jpg').readAsBytesSync(), equals([1, 2, 3]));
      expect(File('${dirDestino.path}/foto1.webp').readAsBytesSync(), equals([4, 5, 6]));
      expect(File('${dirDestino.path}/foto1_thumb.jpg').readAsBytesSync(), equals([7, 8, 9]));
      expect(File('${dirDestino.path}/vid1_original.mp4').readAsBytesSync(), equals([10, 11]));
      expect(File('${dirDestino.path}/vid1.mp4').readAsBytesSync(), equals([12, 13]));
      expect(File('${dirDestino.path}/vid1_poster.jpg').readAsBytesSync(), equals([14, 15]));
      expect(File('${dirDestino.path}/doc1_original.pdf').readAsBytesSync(), equals([16, 17]));
      expect(File('${dirDestino.path}/doc1_p1.webp').readAsBytesSync(), equals([18, 19]));
      expect(File('${dirDestino.path}/doc1_p1_thumb.jpg').readAsBytesSync(), equals([20, 21]));

      expect(File('${dirDestino.path}/registro.binarypb').existsSync(), isFalse);
      expect(File('${dirDestino.path}/registro.json').existsSync(), isFalse);
      expect(File('${dirDestino.path}/foto2.webp.tmp').existsSync(), isFalse);
      expect(File('${dirDestino.path}/fixalog_$idOrigem.pdf').existsSync(), isFalse);
      expect(File('${dirDestino.path}/fixalog_$idOrigem.epub').existsSync(), isFalse);
      expect(File('${dirDestino.path}/relatorio.epub').existsSync(), isFalse);
    });
  });
}
