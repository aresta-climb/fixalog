// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/features/identity/viewmodels/identity_form_view_model.dart' show isarProvider;
import 'package:fixalog/core/services/session_bundle_manager.dart';
import 'dart:io';

/// Repositório central para gerenciar o Histórico de Registros Expresso já concluídos.
///
/// Encapsula o acesso aos bancos de dados locais (`Isar`) e orquestra operações
/// que envolvem múltiplas camadas, como deleção de arquivos no sistema de arquivos.
class HistoryRepository {
  final Isar? _isar;
  final SessionBundleManager _sessionManager;

  HistoryRepository(this._isar, this._sessionManager);

  /// Retorna um Stream reagindo a mudanças no banco de dados Isar.
  /// 
  /// Os registros (`SubmissionRecord`) são sempre emitidos em ordem decrescente
  /// pela data de inclusão, permitindo que a UI (HistoryScreen) reflita adições e deleções em tempo real.
  Stream<List<SubmissionRecord>> watchHistory() async* {
    if (_isar == null) yield [];
    try {
      yield* _isar!.collection<SubmissionRecord>().where().watch(fireImmediately: true).map((records) {
        records.sort((a, b) => b.dataInclusao.compareTo(a.dataInclusao));
        return records;
      });
    } catch (e) {
      yield [];
    }
  }

  /// Exclui um registro do histórico permanentemente.
  ///
  /// Realiza as seguintes operações em cadeia para garantir ausência de lixo no dispositivo:
  /// 1. Verifica a existência e exclui o PDF renderizado no diretório de Documentos.
  /// 2. Remove a entidade `SubmissionRecord` do banco Isar de forma atômica.
  /// 3. Deleta completamente o Session Bundle (`/sessoes/<sessionId>/`), incluindo as fotos/vídeos associados.
  Future<void> deleteRecord(SubmissionRecord record) async {
    if (_isar == null) return;
    
    // 2. Apagar o PDF
    if (record.pdfPath.isNotEmpty) {
      final pdfFile = File(record.pdfPath);
      if (await pdfFile.exists()) {
        await pdfFile.delete();
      }
    }

    // 3. Apagar do Isar
    await _isar.writeTxn(() async {
      await _isar.collection<SubmissionRecord>().delete(record.id);
    });

    // 4. Deletar o Session Bundle
    await _sessionManager.deleteSessionBundle(record.idSessao);
  }
}

/// Provider para acesso ao repositório de histórico na árvore de dependências.
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(isarProvider), SessionBundleManager());
});

/// Provider auxiliar que expõe diretamente a stream de histórico pronta para a UI.
final historyProvider = StreamProvider<List<SubmissionRecord>>((ref) {
  return ref.watch(historyRepositoryProvider).watchHistory();
});
