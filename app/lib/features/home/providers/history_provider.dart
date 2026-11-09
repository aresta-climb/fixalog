// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';

/// Repositório central para gerenciar o Histórico de Registros de manutenção e materiais.
///
/// Encapsula o acesso ao banco de dados local SQLite ([BancoDadosLocal]) e orquestra operações
/// que envolvem múltiplas camadas, como deleção de arquivos no sistema de arquivos.
class HistoryRepository {
  final BancoDadosLocal? _banco;
  final SessionBundleManager _sessionManager;

  HistoryRepository(this._banco, this._sessionManager);

  /// Retorna um Stream reagindo a mudanças no banco de dados local SQLite.
  ///
  /// Os registros (`SubmissionRecord`) são sempre emitidos em ordem decrescente
  /// pela data de inclusão, permitindo que a UI (HistoryScreen) reflita adições e deleções em tempo real.
  Stream<List<SubmissionRecord>> watchHistory() async* {
    if (_banco == null) {
      yield [];
      return;
    }
    yield* _banco.observarSubmissoes();
  }

  void _excluirArquivoSeExistir(String caminho) {
    if (caminho.isEmpty) return;
    final arquivo = File(caminho);
    if (arquivo.existsSync()) {
      arquivo.deleteSync();
    }
  }

  /// Exclui um registro do histórico permanentemente.
  ///
  /// Realiza as seguintes operações em cadeia para garantir ausência de lixo no dispositivo:
  /// 1. Verifica a existência e exclui o PDF renderizado, eventual EPUB irmão e manifesto associado.
  /// 2. Remove a entidade `SubmissionRecord` do banco SQLite.
  /// 3. Deleta completamente o Session Bundle (`/sessoes/<sessionId>/`), incluindo as fotos/vídeos associados.
  Future<void> deleteRecord(SubmissionRecord record) async {
    if (_banco == null) return;

    _excluirArquivoSeExistir(record.pdfPath);
    if (record.pdfPath.toLowerCase().endsWith('.pdf')) {
      final caminhoEpubIrmao =
          '${record.pdfPath.substring(0, record.pdfPath.length - 4)}.epub';
      _excluirArquivoSeExistir(caminhoEpubIrmao);
    }
    _excluirArquivoSeExistir(record.epubPath);
    _excluirArquivoSeExistir(record.protobufPath);

    if (record.id > 0) {
      await _banco.deletarSubmissao(record.id);
    } else {
      await _banco.deletarSubmissaoPorIdSessao(record.idSessao);
    }

    await _sessionManager.deleteSessionBundle(record.idSessao);
  }
}

/// Provider para acesso ao repositório de histórico na árvore de dependências.
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(
    ref.watch(bancoDadosLocalProvider),
    ref.watch(sessionBundleManagerProvider),
  );
});

/// Provider auxiliar que expõe diretamente a stream de histórico pronta para a UI.
final historyProvider = StreamProvider<List<SubmissionRecord>>((ref) {
  return ref.watch(historyRepositoryProvider).watchHistory();
});

/// Provider que filtra apenas os registros de manutenções do histórico.
final historyManutencoesProvider = Provider<AsyncValue<List<SubmissionRecord>>>((ref) {
  return ref.watch(historyProvider).whenData(
        (records) => records.where((r) => r.isManutencao).toList(),
      );
});

/// Provider que filtra apenas os registros de materiais do histórico.
final historyMateriaisProvider = Provider<AsyncValue<List<SubmissionRecord>>>((ref) {
  return ref.watch(historyProvider).whenData(
        (records) => records.where((r) => r.isMaterial).toList(),
      );
});
