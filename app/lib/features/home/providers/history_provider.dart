import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:app/core/models/local/submission_record.dart';
import 'package:app/features/identity/viewmodels/identity_form_view_model.dart' show isarProvider;

class HistoryRepository {
  final Isar? _isar;

  HistoryRepository(this._isar);

  Stream<List<SubmissionRecord>> watchHistory() async* {
    if (_isar == null) yield [];
    try {
      yield* _isar!.collection<SubmissionRecord>().where().watch(fireImmediately: true).map((records) {
        records.sort((a, b) => b.dataInclusao.compareTo(a.dataInclusao));
        return records;
      });
    } catch (e) {
      // Falha ao acessar isar no ambiente de mock simples que não suporta query builder
      yield [];
    }
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(isarProvider));
});

final historyProvider = StreamProvider<List<SubmissionRecord>>((ref) {
  final repo = ref.watch(historyRepositoryProvider);
  return repo.watchHistory();
});
