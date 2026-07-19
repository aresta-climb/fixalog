import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:app/core/models/local/submission_record.dart';

void main() {
  late Isar isar;
  late Directory tempDir;

  setUp(() async {
    // Isar is already initialized in tests via a mock or temporary directory.
    tempDir = await Directory.systemTemp.createTemp('isar_test');
    
    // We must ensure the Isar core is downloaded if testing natively.
    // For unit tests without flutter test environment, Isar.open might need core library.
    // Assuming Isar is mocked or we can just test the model fields.
    await Isar.initializeIsarCore(download: true);
    
    isar = await Isar.open(
      [SubmissionRecordSchema],
      directory: tempDir.path,
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('SubmissionRecord', () {
    test('Should save and retrieve protobufPath (replacing yamlPath)', () async {
      final record = SubmissionRecord()
        ..idSessao = 'session-123'
        ..idProtocolo = 'proto-1'
        ..nomeProtocolo = 'Protocolo Teste'
        ..dataInclusao = DateTime.now()
        ..hashAssinatura = 'hash123'
        ..pdfPath = '/path/to/pdf.pdf'
        ..protobufPath = '/path/to/registro.binarypb'
        ..enviadoNuvem = false;

      await isar.writeTxn(() async {
        await isar.submissionRecords.put(record);
      });

      final retrieved = await isar.submissionRecords.where().idSessaoEqualTo('session-123').findFirst();
      
      expect(retrieved, isNotNull);
      expect(retrieved!.protobufPath, '/path/to/registro.binarypb');
      // Ensure yamlPath doesn't exist by accessing protobufPath
      // if yamlPath existed, we wouldn't test its absence directly, but it should not compile.
    });
  });
}
