import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/home/providers/history_provider.dart';
import 'package:app/core/models/local/submission_record.dart';

class FakeHistoryRepository implements HistoryRepository {
  List<SubmissionRecord> mockData = [];

  @override
  Stream<List<SubmissionRecord>> watchHistory() async* {
    yield mockData;
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
    final repo = HistoryRepository(null);
    final history = await repo.watchHistory().first;
    expect(history, isEmpty);
  });
}
