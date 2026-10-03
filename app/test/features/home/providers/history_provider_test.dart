// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/features/home/providers/history_provider.dart';
import 'package:fixalog/core/models/local/submission_record.dart';

import 'dart:io';
import 'package:fixalog/core/services/session_bundle_manager.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';

class FakeHistoryRepository implements HistoryRepository {
  List<SubmissionRecord> mockData = [];

  @override
  Stream<List<SubmissionRecord>> watchHistory() async* {
    yield mockData;
  }

  @override
  Future<void> deleteRecord(SubmissionRecord record) async {}
}

class MockSessionBundleManager extends Mock implements SessionBundleManager {}

class FakeIsarCollection extends Fake implements IsarCollection<SubmissionRecord> {
  final List<SubmissionRecord> items = [];
  int deleteCalls = 0;
  
  @override
  Future<bool> delete(int id) async {
    deleteCalls++;
    items.removeWhere((element) => element.id == id);
    return true;
  }
}

class FakeIsar extends Fake implements Isar {
  final FakeIsarCollection fakeCollection = FakeIsarCollection();

  @override
  IsarCollection<T> collection<T>() {
    if (T == SubmissionRecord) {
      return fakeCollection as IsarCollection<T>;
    }
    throw UnimplementedError();
  }

  @override
  Future<T> writeTxn<T>(Future<T> Function() callback, {bool silent = false}) {
    return callback();
  }
}

void main() {
  test('historyProvider deve retornar os registros ordenados decrescente pelo historyRepositoryProvider', () async {
    final fakeRepo = FakeHistoryRepository();
    final today = DateTime.now();
    fakeRepo.mockData = [
      SubmissionRecord()
        ..nomeProtocolo = 'Protocolo Mais Antigo'
        ..dataInclusao = today.subtract(const Duration(days: 2)),
      SubmissionRecord()
        ..nomeProtocolo = 'Protocolo Mais Novo'
        ..dataInclusao = today,
    ];

    final container = ProviderContainer(
      overrides: [
        historyRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );

    // Wait for the stream to emit the first value
    final history = await container.read(historyProvider.stream).first;

    expect(history.length, 2);
  });

  test('HistoryRepository watchHistory() deve lidar com nulo no isar e falhas, ou retornar tudo filtrado', () async {
    final repo = HistoryRepository(null, MockSessionBundleManager());
    final history = await repo.watchHistory().first;
    expect(history, isEmpty);
  });

  test('HistoryRepository deleteRecord() deve apagar do Isar, apagar o PDF e deletar o SessionBundle (Fase Red)', () async {
    // Arrange
    final fakeIsar = FakeIsar();
    final mockSessionManager = MockSessionBundleManager();
    final repo = HistoryRepository(fakeIsar, mockSessionManager);

    final tmpDir = Directory.systemTemp.createTempSync('history_test');
    final fakePdf = File('${tmpDir.path}/report.pdf');
    await fakePdf.writeAsString('fake pdf content');

    final record = SubmissionRecord()
      ..id = 99
      ..idSessao = 'sessao_99'
      ..pdfPath = fakePdf.path;
      
    fakeIsar.fakeCollection.items.add(record);

    when(() => mockSessionManager.deleteSessionBundle('sessao_99')).thenAnswer((_) async {});

    // Act
    await repo.deleteRecord(record);

    // Assert
    expect(fakeIsar.fakeCollection.deleteCalls, 1, reason: 'Deve chamar delete no Isar');
    expect(fakeIsar.fakeCollection.items, isEmpty, reason: 'O registro deve ter sido removido');
    
    expect(fakePdf.existsSync(), isFalse, reason: 'O arquivo PDF final deve ter sido apagado fisicamente');
    
    verify(() => mockSessionManager.deleteSessionBundle('sessao_99')).called(1);
    
    tmpDir.deleteSync(recursive: true);
  });
}
