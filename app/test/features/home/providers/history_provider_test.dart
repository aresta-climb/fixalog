// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/features/home/providers/history_provider.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';

void main() {
  late BancoDadosLocal banco;
  late Directory tempDir;
  late SessionBundleManager sessionManager;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('history_prov_test');
    banco = await BancoDadosLocal.abrirEmMemoria();
    sessionManager = SessionBundleManager(baseDirectoryGetter: () async => tempDir);
  });

  tearDown(() async {
    await banco.fechar();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  test('historyProvider retorna registros ordenados decrescente e separa manutenções de materiais', () async {
    final hoje = DateTime(2026, 11, 1, 12, 0);
    await banco.salvarSubmissao(
      SubmissionRecord()
        ..idSessao = 'manut-antiga'
        ..idProtocolo = 'manutencao_ferragens'
        ..nomeProtocolo = 'Manutenção Antiga'
        ..tipoRegistro = SubmissionTipoRegistro.manutencao
        ..dataInclusao = hoje.subtract(const Duration(days: 2)),
    );
    await banco.salvarSubmissao(
      SubmissionRecord()
        ..idSessao = 'mat-1'
        ..idProtocolo = 'cadastro_material'
        ..nomeProtocolo = 'Cadastro de Material'
        ..tituloExibicao = 'Chapeleta Bonier Inox 316L'
        ..tipoRegistro = SubmissionTipoRegistro.material
        ..dataInclusao = hoje.subtract(const Duration(days: 1)),
    );
    await banco.salvarSubmissao(
      SubmissionRecord()
        ..idSessao = 'manut-nova'
        ..idProtocolo = 'manutencao_ferragens'
        ..nomeProtocolo = 'Manutenção Nova'
        ..tipoRegistro = SubmissionTipoRegistro.manutencao
        ..dataInclusao = hoje,
    );

    final container = ProviderContainer(
      overrides: [
        bancoDadosLocalProvider.overrideWithValue(banco),
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

  test('HistoryRepository watchHistory() e deleteRecord() tratam banco nulo com seguranca', () async {
    final repo = HistoryRepository(null, sessionManager);
    final history = await repo.watchHistory().first;
    expect(history, isEmpty);
    await repo.deleteRecord(SubmissionRecord()..idSessao = 's1');
  });

  test('HistoryRepository deleteRecord() apaga do SQLite (por id e por idSessao), remove arquivos gerados e deleta o SessionBundle', () async {
    final repo = HistoryRepository(banco, sessionManager);

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

    await banco.salvarSubmissao(record);

    await repo.deleteRecord(record);

    final restante = await banco.obterSubmissaoPorIdSessao('sessao_99');
    expect(restante, isNull);
    expect(relatorioPdf.existsSync(), isFalse);
    expect(relatorioEpub.existsSync(), isFalse);

    // Exclusão quando id == 0 (usa idSessao)
    final recordSemId = SubmissionRecord()..idSessao = 'sessao_sem_id';
    await banco.salvarSubmissao(recordSemId);
    recordSemId.id = 0;
    await repo.deleteRecord(recordSemId);
    expect(await banco.obterSubmissaoPorIdSessao('sessao_sem_id'), isNull);
  });

  test('HistoryRepository deleteRecord() exclui relatório legado com .epub irmão de pdfPath, artefato de assinatura e caminhos ausentes sem erro', () async {
    final repo = HistoryRepository(banco, sessionManager);

    final relatorioPdf = File('${tempDir.path}/relatorio_antigo.pdf')..writeAsStringSync('pdf legado');
    final relatorioEpubIrmao = File('${tempDir.path}/relatorio_antigo.epub')..writeAsStringSync('epub legado');
    final dirSessao = await sessionManager.getSessionDirectory('sessao_legada_assinatura');
    final arqAssinaturaLegada = File('${dirSessao.path}/assinatura_uuid_original.png')
      ..writeAsBytesSync([137, 80, 78, 71]);
    final arqManifesto = File('${dirSessao.path}/registro.binarypb')
      ..writeAsBytesSync([1, 2, 3]);

    final recordComIrmao = SubmissionRecord()
      ..idSessao = 'sessao_legada_assinatura'
      ..pdfPath = relatorioPdf.path
      ..protobufPath = arqManifesto.path;

    final recordComArquivosAusentes = SubmissionRecord()
      ..idSessao = 'sessao_arquivos_ausentes'
      ..pdfPath = '${tempDir.path}/nao_existe.pdf'
      ..protobufPath = '${tempDir.path}/nao_existe.epub';

    await banco.salvarSubmissao(recordComIrmao);
    await banco.salvarSubmissao(recordComArquivosAusentes);

    await repo.deleteRecord(recordComIrmao);
    await repo.deleteRecord(recordComArquivosAusentes);

    expect(await banco.listarSubmissoes(), isEmpty);
    expect(relatorioPdf.existsSync(), isFalse);
    expect(relatorioEpubIrmao.existsSync(), isFalse);
    expect(arqAssinaturaLegada.existsSync(), isFalse);
    expect(dirSessao.existsSync(), isFalse);
  });
}
