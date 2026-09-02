import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:fixlog/core/services/session_bundle_manager.dart';

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
  });
}
