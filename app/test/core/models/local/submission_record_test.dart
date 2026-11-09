// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';

void main() {
  late BancoDadosLocal banco;

  setUp(() async {
    banco = await BancoDadosLocal.abrirEmMemoria();
  });

  tearDown(() async {
    await banco.fechar();
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

      await banco.salvarSubmissao(record);

      final retrieved = await banco.obterSubmissaoPorIdSessao('session-123');

      expect(retrieved, isNotNull);
      expect(retrieved!.protobufPath, '/path/to/registro.binarypb');
      expect(retrieved.status, equals(SubmissionStatus.emProgresso));
      expect(retrieved.isEmProgresso, isTrue);
      expect(retrieved.isGerado, isFalse);
      expect(retrieved.tipoRegistro, equals(SubmissionTipoRegistro.manutencao));
      expect(retrieved.isManutencao, isTrue);
      expect(retrieved.isMaterial, isFalse);
      expect(retrieved.enviadoNuvem, isFalse);
    });

    test('Deve permitir definir status como GERADO, enviadoNuvem true e validar getters', () async {
      final record = SubmissionRecord()
        ..idSessao = 'session-456'
        ..idProtocolo = 'proto-1'
        ..nomeProtocolo = 'Protocolo Concluído'
        ..dataInclusao = DateTime.now()
        ..hashAssinatura = 'hash123'
        ..pdfPath = '/path/to/pdf.pdf'
        ..epubPath = '/path/to/relatorio.epub'
        ..protobufPath = '/path/to/registro.binarypb'
        ..status = SubmissionStatus.gerado
        ..enviadoNuvem = true;

      await banco.salvarSubmissao(record);

      final retrieved = await banco.obterSubmissaoPorIdSessao('session-456');

      expect(retrieved, isNotNull);
      expect(retrieved!.status, equals(SubmissionStatus.gerado));
      expect(retrieved.epubPath, equals('/path/to/relatorio.epub'));
      expect(retrieved.protobufPath, equals('/path/to/registro.binarypb'));
      expect(retrieved.isGerado, isTrue);
      expect(retrieved.isEmProgresso, isFalse);
      expect(retrieved.enviadoNuvem, isTrue);
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

    test('Deve persistir e recuperar tipoRegistro MATERIAL, tituloExibicao e dataUltimaSelecao', () async {
      final dataSelecao = DateTime(2026, 11, 1, 14, 30);
      final record = SubmissionRecord()
        ..idSessao = 'mat-001'
        ..idProtocolo = 'cadastro_material'
        ..nomeProtocolo = 'Cadastro de Material de Manutenção'
        ..tipoRegistro = SubmissionTipoRegistro.material
        ..tituloExibicao = 'Kit Parabolt 3/8 + Chapeleta Bonier'
        ..dataUltimaSelecao = dataSelecao
        ..status = SubmissionStatus.gerado
        ..pdfPath = '/path/to/mat.epub'
        ..protobufPath = '/path/to/mat.binarypb';

      await banco.salvarSubmissao(record);

      final retrieved = await banco.obterSubmissaoPorIdSessao('mat-001');

      expect(retrieved, isNotNull);
      expect(retrieved!.tipoRegistro, equals(SubmissionTipoRegistro.material));
      expect(retrieved.isMaterial, isTrue);
      expect(retrieved.isManutencao, isFalse);
      expect(retrieved.tituloExibicao, equals('Kit Parabolt 3/8 + Chapeleta Bonier'));
      expect(retrieved.dataUltimaSelecao, equals(dataSelecao));
    });
  });
}
