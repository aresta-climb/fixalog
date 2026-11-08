// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fixalog/core/models/local/app_config_record.dart';
import 'package:fixalog/core/models/local/identity_record.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/services/epub_packager_service.dart';

void main() {
  group('BancoDadosLocal', () {
    test('bancoDadosLocalProvider retorna nulo por padrao quando nao sobrescrito', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(bancoDadosLocalProvider), isNull);
    });

    test('gerencia configuracao, identidade e submissoes (sync e async) em memoria', () async {
      final banco = await BancoDadosLocal.abrirEmMemoria();
      addTearDown(() async => await banco.fechar());

      expect(banco.isOpen, isTrue);
      expect(banco.obterConfiguracaoSync(), isNull);
      expect(await banco.obterConfiguracao(), isNull);
      expect(await banco.possuiIdentidade(), isFalse);
      expect(await banco.obterIdentidadeAtual(), isNull);

      final config = AppConfigRecord(
        id: 1,
        acceptedTermsVersion: 2,
        dataHoraAceiteTermos: DateTime(2026, 11, 2, 9, 0),
      );
      await banco.salvarConfiguracao(config);
      expect(banco.obterConfiguracaoSync()!.versaoTermosAceita, equals(2));
      expect((await banco.obterConfiguracao())!.versaoTermosAceita, equals(2));

      final idRecord = IdentityRecord()
        ..nome = 'Ana Escaladora'
        ..clubeAssociacao = 'FEMERJ'
        ..dataRegistro = DateTime(2026, 11, 2, 10, 0);
      await banco.salvarIdentidade(idRecord);
      expect(await banco.possuiIdentidade(), isTrue);
      // Atualiza a mesma identidade
      idRecord.nome = 'Ana Silva';
      await banco.salvarIdentidade(idRecord);
      expect((await banco.obterIdentidadeAtual())!.nome, equals('Ana Silva'));

      // Submissões e stream reativo
      final emissoes = <List<SubmissionRecord>>[];
      final sub = banco.observarSubmissoes().listen(emissoes.add);
      addTearDown(sub.cancel);
      await Future<void>.delayed(Duration.zero);
      expect(emissoes.last, isEmpty);

      final s1 = SubmissionRecord()
        ..idSessao = 'sess-1'
        ..idProtocolo = 'manutencao_ferragens'
        ..nomeProtocolo = 'Manutenção'
        ..tituloExibicao = 'Via Sul'
        ..dataInclusao = DateTime(2026, 11, 1)
        ..protobufPath = '/tmp/sess-1/registro.binarypb';
      await banco.salvarSubmissao(s1);
      // Atualiza s1 sem passar id explícito (reaproveita id pelo idSessao)
      final s1Atualizado = SubmissionRecord()
        ..idSessao = 'sess-1'
        ..idProtocolo = 'manutencao_ferragens'
        ..nomeProtocolo = 'Manutenção'
        ..tituloExibicao = 'Via Sul Atualizada'
        ..dataInclusao = DateTime(2026, 11, 1)
        ..protobufPath = '/tmp/sess-1/relatorio.epub'
        ..status = SubmissionStatus.gerado;
      await banco.salvarSubmissao(s1Atualizado);

      expect(
        banco.obterSubmissaoPorIdSessaoSync('sess-1')?.tituloExibicao,
        equals('Via Sul Atualizada'),
      );
      expect(
        (await banco.obterSubmissaoPorProtobufPath('/tmp/sess-1/relatorio.epub'))
            ?.idSessao,
        equals('sess-1'),
      );
      expect(
        await banco.obterSubmissaoPorProtobufPath('/inexistente'),
        isNull,
      );
      expect(await banco.obterSubmissaoPorIdSessao('inexistente'), isNull);

      // Operação salvarSubmissaoSync (novo e atualização)
      final s2 = SubmissionRecord()
        ..idSessao = 'sess-2'
        ..idProtocolo = 'cadastro_material'
        ..tipoRegistro = SubmissionTipoRegistro.material
        ..dataInclusao = DateTime(2026, 11, 2);
      banco.salvarSubmissaoSync(s2);
      s2.tituloExibicao = 'Chapeleta Inox';
      final s2SemId = SubmissionRecord()
        ..idSessao = 'sess-2'
        ..tituloExibicao = 'Chapeleta Inox 316L'
        ..dataInclusao = DateTime(2026, 11, 2);
      banco.salvarSubmissaoSync(s2SemId);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final todosSync = banco.listarSubmissoesSync();
      expect(todosSync.length, equals(2));
      expect(todosSync.first.idSessao, equals('sess-2'));

      await banco.deletarSubmissao(s1Atualizado.id);
      expect(await banco.obterSubmissaoPorIdSessao('sess-1'), isNull);

      await banco.deletarSubmissaoPorIdSessao('sess-2');
      expect(await banco.listarSubmissoes(), isEmpty);
    });

    test('abrirEmArquivo carrega dados existentes, limpa default.isar e reindexa sessoes do disco', () async {
      sqfliteFfiInit();
      final tempDir = await Directory.systemTemp.createTemp('banco_local_test_');
      addTearDown(() async {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      // Cria arquivos legados do Isar que devem ser removidos
      final isarLegado = File(p.join(tempDir.path, 'default.isar'))
        ..writeAsStringSync('legado');
      final isarLock = File(p.join(tempDir.path, 'default.isar.lock'))
        ..writeAsStringSync('lock');

      // 1) Sessão em progresso com registro.binarypb e título via_nome
      final dirSessao1 = Directory(
        p.join(tempDir.path, 'sessoes', 'sessao-rascunho'),
      )..createSync(recursive: true);
      final reg1 = Registro(
        idSessao: 'sessao-rascunho',
        idProtocolo: 'manutencao_ferragens',
        utcTimestampInicio: Int64(
          DateTime(2026, 10, 10, 8, 0).millisecondsSinceEpoch ~/ 1000,
        ),
        yamlConteudo: 'id: manutencao_ferragens\nnome: Manutenção de Ferragens\n',
      );
      reg1.respostas['via_nome'] = Resposta(texto: 'Via Diedro Sul');
      File(p.join(dirSessao1.path, 'registro.binarypb'))
          .writeAsBytesSync(reg1.writeToBuffer());

      // 2) Sessão gerada de material extraída diretamente de relatorio.epub (sem registro.binarypb solto) e com PDF
      final dirSessao2 = Directory(
        p.join(tempDir.path, 'sessoes', 'sessao-material-epub'),
      )..createSync(recursive: true);
      final reg2 = Registro(
        idSessao: 'sessao-material-epub',
        idProtocolo: 'cadastro_material',
      );
      final epubBytes = EpubPackagerService().empacotarEpub(
        idSessao: 'sessao-material-epub',
        idProtocolo: 'cadastro_material',
        xhtmlConteudo: '<html xmlns="http://www.w3.org/1999/xhtml"><body></body></html>',
        cssConteudo: '',
        binarypb: reg2.writeToBuffer(),
        signaturesXml: '<Signature/>',
      );
      File(p.join(dirSessao2.path, 'relatorio.epub'))
          .writeAsBytesSync(epubBytes);
      File(p.join(dirSessao2.path, 'fixalog_sessao-material-epub.pdf'))
          .writeAsStringSync('%PDF-1.4');

      // 3) Diretório vazio e diretório com arquivo corrompido (devem ser ignorados com segurança)
      Directory(p.join(tempDir.path, 'sessoes', 'sessao-vazia'))
          .createSync(recursive: true);
      final dirCorrompida = Directory(
        p.join(tempDir.path, 'sessoes', 'sessao-corrompida'),
      )..createSync(recursive: true);
      File(p.join(dirCorrompida.path, 'relatorio.epub'))
          .writeAsBytesSync([1, 2, 3]);

      final banco1 = await BancoDadosLocal.abrirEmArquivo(
        tempDir.path,
        factory: databaseFactoryFfiNoIsolate,
      );

      expect(isarLegado.existsSync(), isFalse);
      expect(isarLock.existsSync(), isFalse);

      final sub1 = await banco1.obterSubmissaoPorIdSessao('sessao-rascunho');
      expect(sub1, isNotNull);
      expect(sub1!.nomeProtocolo, equals('Manutenção de Ferragens'));
      expect(sub1.tituloExibicao, equals('Via Diedro Sul'));
      expect(sub1.status, equals(SubmissionStatus.emProgresso));
      expect(sub1.isManutencao, isTrue);

      final sub2 = await banco1.obterSubmissaoPorIdSessao('sessao-material-epub');
      expect(sub2, isNotNull);
      expect(sub2!.status, equals(SubmissionStatus.gerado));
      expect(sub2.isMaterial, isTrue);
      expect(sub2.pdfPath, endsWith('fixalog_sessao-material-epub.pdf'));

      await banco1.salvarConfiguracao(
        AppConfigRecord(id: 1, acceptedTermsVersion: 4, idiomaPreferido: 'fr'),
      );
      await banco1.fechar();

      // Reabre o banco no mesmo diretório usando a factory global padrão para validar _carregarCachesIniciais com dados prévios
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfiNoIsolate;
      final banco2 = await BancoDadosLocal.abrirEmArquivo(tempDir.path);
      expect(banco2.obterConfiguracaoSync()?.versaoTermosAceita, equals(4));
      expect(banco2.obterConfiguracaoSync()?.idiomaPreferido, equals('fr'));
      expect(banco2.listarSubmissoesSync().length, equals(2));
      await banco2.fechar();
    });

    test('migra banco existente da versao 1 sem coluna idioma_preferido adicionando a coluna de forma transparente', () async {
      sqfliteFfiInit();
      final tempDir = await Directory.systemTemp.createTemp('banco_migra_v1_');
      addTearDown(() async {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      final caminhoBanco = p.join(tempDir.path, 'fixalog.db');
      final dbLegado = await databaseFactoryFfiNoIsolate.openDatabase(
        caminhoBanco,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute('''
              CREATE TABLE configuracao_app (
                id INTEGER PRIMARY KEY,
                versao_termos_aceita INTEGER NOT NULL DEFAULT 0,
                data_hora_aceite_termos TEXT
              )
            ''');
            await db.execute(BancoDadosLocal.sqlCriarTabelaIdentidade);
            await db.execute(BancoDadosLocal.sqlCriarTabelaSubmissoes);
            await db.rawInsert(
              'INSERT INTO configuracao_app (id, versao_termos_aceita, data_hora_aceite_termos) VALUES (1, 7, ?)',
              ['2026-11-01T10:00:00.000'],
            );
          },
          singleInstance: false,
        ),
      );
      await dbLegado.close();

      final bancoMigrado = await BancoDadosLocal.abrirEmArquivo(
        tempDir.path,
        factory: databaseFactoryFfiNoIsolate,
      );
      addTearDown(() async => await bancoMigrado.fechar());

      final config = bancoMigrado.obterConfiguracaoSync();
      expect(config, isNotNull);
      expect(config!.versaoTermosAceita, equals(7));
      expect(config.idiomaPreferido, isNull);

      config.idiomaPreferido = 'de';
      await bancoMigrado.salvarConfiguracao(config);
      expect((await bancoMigrado.obterConfiguracao())?.idiomaPreferido, equals('de'));
    });
  });
}
