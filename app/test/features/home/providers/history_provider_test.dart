// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:fixalog/features/home/providers/history_provider.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';
import 'package:fixalog/features/identity/viewmodels/identity_form_view_model.dart' show isarProvider;

void main() {
  late Isar isar;
  late Directory tempDir;
  late SessionBundleManager sessionManager;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('history_prov_test');
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open(
      [SubmissionRecordSchema],
      directory: tempDir.path,
    );
    sessionManager = SessionBundleManager(baseDirectoryGetter: () async => tempDir);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  test('historyProvider retorna registros ordenados decrescente e separa manutenções de materiais', () async {
    final hoje = DateTime(2026, 11, 1, 12, 0);
    await isar.writeTxn(() async {
      await isar.submissionRecords.putAll([
        SubmissionRecord()
          ..idSessao = 'manut-antiga'
          ..idProtocolo = 'manutencao_ferragens'
          ..nomeProtocolo = 'Manutenção Antiga'
          ..tipoRegistro = SubmissionTipoRegistro.manutencao
          ..dataInclusao = hoje.subtract(const Duration(days: 2)),
        SubmissionRecord()
          ..idSessao = 'mat-1'
          ..idProtocolo = 'cadastro_material'
          ..nomeProtocolo = 'Cadastro de Material'
          ..tituloExibicao = 'Chapeleta Bonier Inox 316L'
          ..tipoRegistro = SubmissionTipoRegistro.material
          ..dataInclusao = hoje.subtract(const Duration(days: 1)),
        SubmissionRecord()
          ..idSessao = 'manut-nova'
          ..idProtocolo = 'manutencao_ferragens'
          ..nomeProtocolo = 'Manutenção Nova'
          ..tipoRegistro = SubmissionTipoRegistro.manutencao
          ..dataInclusao = hoje,
      ]);
    });

    final container = ProviderContainer(
      overrides: [
        isarProvider.overrideWithValue(isar),
      ],
    );
    addTearDown(container.dispose);

    final todos = await container.read(historyProvider.future);
    expect(todos.map((r) => r.idSessao).toList(), equals(['manut-nova', 'mat-1', 'manut-antiga']));

    final manutencoes = container.read(historyManutencoesProvider).valueOrNull ?? [];
    expect(manutencoes.map((r) => r.idSessao).toList(), equals(['manut-nova', 'manut-antiga']));

    final materiais = container.read(historyMateriaisProvider).valueOrNull ?? [];
    expect(materiais.map((r) => r.idSessao).toList(), equals(['mat-1']));
    expect(materiais.first.tituloExibicao, equals('Chapeleta Bonier Inox 316L'));
  });

  test('HistoryRepository watchHistory() retorna lista vazia quando Isar é nulo', () async {
    final repo = HistoryRepository(null, sessionManager);
    final history = await repo.watchHistory().first;
    expect(history, isEmpty);
  });

  test('HistoryRepository deleteRecord() apaga do Isar, remove arquivos gerados e deleta o SessionBundle', () async {
    final repo = HistoryRepository(isar, sessionManager);

    final relatorioPdf = File('${tempDir.path}/report.pdf')..writeAsStringSync('pdf bytes');
    final relatorioEpub = File('${tempDir.path}/report.epub')..writeAsStringSync('epub bytes');
    await sessionManager.saveManifest(
      sessionId: 'sessao_99',
      binarypb: File(relatorioPdf.path).readAsBytesSync(),
    );

    final record = SubmissionRecord()
      ..idSessao = 'sessao_99'
      ..pdfPath = relatorioPdf.path
      ..protobufPath = relatorioEpub.path;

    await isar.writeTxn(() async {
      await isar.submissionRecords.put(record);
    });

    await repo.deleteRecord(record);

    final restante = await isar.submissionRecords.where().idSessaoEqualTo('sessao_99').findFirst();
    expect(restante, isNull);
    expect(relatorioPdf.existsSync(), isFalse);
    expect(relatorioEpub.existsSync(), isFalse);
  });
}
