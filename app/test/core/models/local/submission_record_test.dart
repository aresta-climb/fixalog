// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:fixalog/core/models/local/submission_record.dart';

void main() {
  late Isar isar;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('isar_test');
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

  group('SubmissionRecord (TDD)', () {
    test('Deve salvar e recuperar status padrão EM_PROGRESSO', () async {
      final record = SubmissionRecord()
        ..idSessao = 'session-123'
        ..idProtocolo = 'proto-1'
        ..nomeProtocolo = 'Protocolo Teste'
        ..dataInclusao = DateTime.now()
        ..hashAssinatura = 'hash123'
        ..pdfPath = ''
        ..protobufPath = '/path/to/registro.binarypb'
        ..enviadoNuvem = false;

      await isar.writeTxn(() async {
        await isar.submissionRecords.put(record);
      });

      final retrieved = await isar.submissionRecords.where().idSessaoEqualTo('session-123').findFirst();
      
      expect(retrieved, isNotNull);
      expect(retrieved!.protobufPath, '/path/to/registro.binarypb');
      expect(retrieved.status, equals(SubmissionStatus.emProgresso));
      expect(retrieved.isEmProgresso, isTrue);
      expect(retrieved.isGerado, isFalse);
    });

    test('Deve permitir definir status como GERADO e validar getters', () async {
      final record = SubmissionRecord()
        ..idSessao = 'session-456'
        ..idProtocolo = 'proto-1'
        ..nomeProtocolo = 'Protocolo Concluído'
        ..dataInclusao = DateTime.now()
        ..hashAssinatura = 'hash123'
        ..pdfPath = '/path/to/pdf.pdf'
        ..protobufPath = '/path/to/registro.binarypb'
        ..status = SubmissionStatus.gerado
        ..enviadoNuvem = false;

      await isar.writeTxn(() async {
        await isar.submissionRecords.put(record);
      });

      final retrieved = await isar.submissionRecords.where().idSessaoEqualTo('session-456').findFirst();
      
      expect(retrieved, isNotNull);
      expect(retrieved!.status, equals(SubmissionStatus.gerado));
      expect(retrieved.isGerado, isTrue);
      expect(retrieved.isEmProgresso, isFalse);
    });

    test('Compatibilidade retroativa: status vazio com pdfPath presente deve ser considerado GERADO', () {
      final legacyGerado = SubmissionRecord()
        ..status = ''
        ..pdfPath = '/caminho/relatorio.pdf';

      expect(legacyGerado.isGerado, isTrue);
      expect(legacyGerado.isEmProgresso, isFalse);

      final legacyRascunho = SubmissionRecord()
        ..status = ''
        ..pdfPath = '';

      expect(legacyRascunho.isEmProgresso, isTrue);
      expect(legacyRascunho.isGerado, isFalse);
    });
  });
}
