// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:yaml/yaml.dart';
import '../models/local/app_config_record.dart';
import '../models/local/identity_record.dart';
import '../models/local/submission_record.dart';
import '../models/proto/protos/registro.pb.dart';
import 'epub_packager_service.dart';

/// Serviço central de persistência local em SQLite (`sqflite`) do Fixalog.
///
/// Gerencia as tabelas `configuracao_app`, `identidade` e `submissoes`,
/// oferecendo execução tanto em arquivo físico (produção) quanto em banco
/// `:memory:` real via `databaseFactoryFfiNoIsolate` (testes unitários e de widget).
class BancoDadosLocal {
  // ── Constantes SQL pré-compiladas em tempo de compilação ──────────────────

  /// Nome da tabela de configurações e aceite jurídico.
  static const String tabelaConfiguracaoApp = 'configuracao_app';

  /// Nome da tabela de identidade do perito/mantenedor.
  static const String tabelaIdentidade = 'identidade';

  /// Nome da tabela de submissões (manutenções e materiais).
  static const String tabelaSubmissoes = 'submissoes';

  /// DDL de criação da tabela `configuracao_app`.
  static const String sqlCriarTabelaConfiguracaoApp = '''
    CREATE TABLE configuracao_app (
      id INTEGER PRIMARY KEY,
      versao_termos_aceita INTEGER NOT NULL DEFAULT 0,
      data_hora_aceite_termos TEXT
    )
  ''';

  /// DDL de criação da tabela `identidade`.
  static const String sqlCriarTabelaIdentidade = '''
    CREATE TABLE identidade (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT NOT NULL,
      clube_associacao TEXT NOT NULL,
      data_registro TEXT NOT NULL
    )
  ''';

  /// DDL de criação da tabela `submissoes`.
  static const String sqlCriarTabelaSubmissoes = '''
    CREATE TABLE submissoes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      id_sessao TEXT NOT NULL UNIQUE,
      id_protocolo TEXT NOT NULL,
      nome_protocolo TEXT NOT NULL,
      titulo_exibicao TEXT NOT NULL,
      tipo_registro TEXT NOT NULL,
      data_inclusao TEXT NOT NULL,
      data_ultima_selecao TEXT,
      hash_assinatura TEXT NOT NULL,
      pdf_path TEXT NOT NULL,
      protobuf_path TEXT NOT NULL,
      enviado_nuvem INTEGER NOT NULL DEFAULT 0,
      status TEXT NOT NULL
    )
  ''';

  /// Query para listar todas as configurações do app.
  static const String sqlListarConfiguracoes =
      'SELECT * FROM configuracao_app';

  /// Query parametrizada para buscar configuração pelo ID.
  static const String sqlObterConfiguracaoPorId =
      'SELECT * FROM configuracao_app WHERE id = ? LIMIT 1';

  /// Query para listar identidades ordenadas por ID crescente.
  static const String sqlListarIdentidades =
      'SELECT * FROM identidade ORDER BY id ASC';

  /// Query leve para verificar existência de identidade cadastrada.
  static const String sqlPossuiIdentidade =
      'SELECT id FROM identidade LIMIT 1';

  /// Query para obter a identidade principal cadastrada.
  static const String sqlObterIdentidadeAtual =
      'SELECT * FROM identidade ORDER BY id ASC LIMIT 1';

  /// Query para listar todas as submissões ordenadas por data de inclusão decrescente.
  static const String sqlListarSubmissoes =
      'SELECT * FROM submissoes ORDER BY data_inclusao DESC';

  /// Query parametrizada para buscar submissão pelo `id_sessao`.
  static const String sqlObterSubmissaoPorIdSessao =
      'SELECT * FROM submissoes WHERE id_sessao = ? LIMIT 1';

  /// Query parametrizada para buscar submissão pelo `protobuf_path`.
  static const String sqlObterSubmissaoPorProtobufPath =
      'SELECT * FROM submissoes WHERE protobuf_path = ? LIMIT 1';

  /// Statement parametrizado para remover submissão pelo ID primário.
  static const String sqlDeletarSubmissaoPorId =
      'DELETE FROM submissoes WHERE id = ?';

  /// Statement parametrizado para remover submissão pelo `id_sessao`.
  static const String sqlDeletarSubmissaoPorIdSessao =
      'DELETE FROM submissoes WHERE id_sessao = ?';

  /// Statement parametrizado para inserir ou atualizar configuração do app.
  static const String sqlSalvarConfiguracao = '''
    INSERT OR REPLACE INTO configuracao_app (
      id, versao_termos_aceita, data_hora_aceite_termos
    ) VALUES (?, ?, ?)
  ''';

  /// Statement parametrizado para inserir ou atualizar identidade do perito.
  static const String sqlSalvarIdentidade = '''
    INSERT OR REPLACE INTO identidade (
      id, nome, clube_associacao, data_registro
    ) VALUES (?, ?, ?, ?)
  ''';

  /// Statement parametrizado para inserir ou atualizar submissão.
  static const String sqlSalvarSubmissao = '''
    INSERT OR REPLACE INTO submissoes (
      id, id_sessao, id_protocolo, nome_protocolo, titulo_exibicao,
      tipo_registro, data_inclusao, data_ultima_selecao, hash_assinatura,
      pdf_path, protobuf_path, enviado_nuvem, status
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''';

  final Database _db;
  final Map<int, AppConfigRecord> _configCache = {};
  final List<IdentityRecord> _identidadesCache = [];
  final Map<String, SubmissionRecord> _submissoesPorSessao = {};
  int _proximoIdSubmissao = 1;
  final StreamController<List<SubmissionRecord>> _historicoController =
      StreamController<List<SubmissionRecord>>.broadcast();

  BancoDadosLocal._(this._db);

  /// Indica se a conexão SQLite subjacente encontra-se aberta.
  bool get isOpen => _db.isOpen;

  /// Abre o banco SQLite em arquivo no [caminhoDiretorio] informado e sincroniza
  /// automaticamente eventuais sessões existentes em `sessoes/` no disco.
  static Future<BancoDadosLocal> abrirEmArquivo(
    String caminhoDiretorio, {
    DatabaseFactory? factory,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    final caminhoBanco = p.join(caminhoDiretorio, 'fixalog.db');
    final db = await dbFactory.openDatabase(
      caminhoBanco,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _criarTabelas,
        singleInstance: false,
      ),
    );
    final instancia = BancoDadosLocal._(db);
    await instancia._carregarCachesIniciais();
    await instancia.sincronizarSessoesDoDisco(Directory(caminhoDiretorio));
    return instancia;
  }

  /// Abre uma instância SQLite isolada em memória (`:memory:`) utilizando
  /// `databaseFactoryFfiNoIsolate`, ideal para testes unitários e de widget.
  static Future<BancoDadosLocal> abrirEmMemoria() async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfiNoIsolate.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _criarTabelas,
        singleInstance: false,
      ),
    );
    final instancia = BancoDadosLocal._(db);
    await instancia._carregarCachesIniciais();
    return instancia;
  }

  static Future<void> _criarTabelas(Database db, int version) async {
    await db.execute(sqlCriarTabelaConfiguracaoApp);
    await db.execute(sqlCriarTabelaIdentidade);
    await db.execute(sqlCriarTabelaSubmissoes);
  }

  Future<void> _carregarCachesIniciais() async {
    final configs = await _db.rawQuery(sqlListarConfiguracoes);
    _configCache.clear();
    for (final linha in configs) {
      final config = AppConfigRecord.fromMap(linha);
      _configCache[config.id] = config;
    }

    final identidades = await _db.rawQuery(sqlListarIdentidades);
    _identidadesCache
      ..clear()
      ..addAll(identidades.map(IdentityRecord.fromMap));

    await listarSubmissoes();
  }

  /// Remove arquivos residuais do Isar (`default.isar` e `default.isar.lock`)
  /// e reconstrói na tabela `submissoes` qualquer sessão presente em `<diretorioBase>/sessoes/`
  /// que ainda não esteja indexada no SQLite.
  Future<void> sincronizarSessoesDoDisco(Directory diretorioBase) async {
    for (final nomeLegado in const ['default.isar', 'default.isar.lock']) {
      final arquivoLegado = File(p.join(diretorioBase.path, nomeLegado));
      if (arquivoLegado.existsSync()) {
        arquivoLegado.deleteSync();
      }
    }

    final dirSessoes = Directory(p.join(diretorioBase.path, 'sessoes'));
    if (!dirSessoes.existsSync()) return;

    final entidades = dirSessoes.listSync().whereType<Directory>().toList();
    for (final dirSessao in entidades) {
      final idSessao = p.basename(dirSessao.path);
      if (_submissoesPorSessao.containsKey(idSessao)) continue;

      final arquivoPb = File(p.join(dirSessao.path, 'registro.binarypb'));
      final arquivoEpub = File(p.join(dirSessao.path, 'relatorio.epub'));
      if (!arquivoPb.existsSync() && !arquivoEpub.existsSync()) continue;

      Registro? registro;
      if (arquivoPb.existsSync()) {
        try {
          registro = Registro.fromBuffer(arquivoPb.readAsBytesSync());
        } catch (_) {}
      }
      if (registro == null && arquivoEpub.existsSync()) {
        try {
          final arquivos = EpubPackagerService().extrairArquivosDeEpubAninhado(
            arquivoEpub.readAsBytesSync(),
          );
          final bytesPb = arquivos['OEBPS/dados/registro.binarypb'];
          if (bytesPb != null) {
            registro = Registro.fromBuffer(bytesPb);
          }
        } catch (_) {}
      }
      if (registro == null) continue;

      final idProtocolo =
          registro.idProtocolo.isNotEmpty ? registro.idProtocolo : idSessao;
      String nomeProtocolo = idProtocolo;
      if (registro.yamlConteudo.isNotEmpty) {
        try {
          final yamlMap = loadYaml(registro.yamlConteudo);
          if (yamlMap is YamlMap && yamlMap['nome'] != null) {
            nomeProtocolo = yamlMap['nome'].toString();
          }
        } catch (_) {}
      }

      String tituloExibicao = '';
      for (final chave in const ['mat_nome', 'via_nome', 'nome_via']) {
        final valor = registro.respostas[chave]?.texto.trim() ?? '';
        if (valor.isNotEmpty) {
          tituloExibicao = valor;
          break;
        }
      }
      if (tituloExibicao.isEmpty) {
        tituloExibicao = nomeProtocolo;
      }

      final ehMaterial = idProtocolo == 'cadastro_material';
      final dataInclusao = registro.utcTimestampInicio > 0
          ? DateTime.fromMillisecondsSinceEpoch(
              registro.utcTimestampInicio.toInt() * 1000,
            )
          : dirSessao.statSync().modified;

      final possuiEpub = arquivoEpub.existsSync();
      final arquivoPdf = File(p.join(dirSessao.path, 'fixalog_$idSessao.pdf'));

      final record = SubmissionRecord()
        ..idSessao = idSessao
        ..idProtocolo = idProtocolo
        ..nomeProtocolo = nomeProtocolo
        ..tituloExibicao = tituloExibicao
        ..tipoRegistro = ehMaterial
            ? SubmissionTipoRegistro.material
            : SubmissionTipoRegistro.manutencao
        ..dataInclusao = dataInclusao
        ..pdfPath = arquivoPdf.existsSync() ? arquivoPdf.path : ''
        ..protobufPath = possuiEpub ? arquivoEpub.path : arquivoPb.path
        ..status =
            possuiEpub ? SubmissionStatus.gerado : SubmissionStatus.emProgresso;

      await salvarSubmissao(record);
    }
  }

  // ── Configuração do App (AppConfigRecord) ─────────────────────────────────

  /// Retorna a configuração armazenada para o [id] de forma síncrona.
  AppConfigRecord? obterConfiguracaoSync([int id = 1]) {
    return _configCache[id];
  }

  /// Consulta a configuração armazenada no SQLite para o [id].
  Future<AppConfigRecord?> obterConfiguracao([int id = 1]) async {
    final linhas = await _db.rawQuery(sqlObterConfiguracaoPorId, [id]);
    if (linhas.isEmpty) return null;
    final config = AppConfigRecord.fromMap(linhas.first);
    _configCache[config.id] = config;
    return config;
  }

  /// Persiste ou atualiza o [config] na tabela `configuracao_app`.
  Future<void> salvarConfiguracao(AppConfigRecord config) async {
    _configCache[config.id] = config;
    final mapa = config.toMap();
    await _db.rawInsert(sqlSalvarConfiguracao, [
      mapa['id'],
      mapa['versao_termos_aceita'],
      mapa['data_hora_aceite_termos'],
    ]);
  }

  // ── Identidade do Perito (IdentityRecord) ─────────────────────────────────

  /// Verifica se existe ao menos um registro de identidade salvo no SQLite.
  Future<bool> possuiIdentidade() async {
    final linhas = await _db.rawQuery(sqlPossuiIdentidade);
    return linhas.isNotEmpty;
  }

  /// Retorna o primeiro registro de identidade cadastrado no SQLite, ou `null`.
  Future<IdentityRecord?> obterIdentidadeAtual() async {
    final linhas = await _db.rawQuery(sqlObterIdentidadeAtual);
    if (linhas.isEmpty) return null;
    return IdentityRecord.fromMap(linhas.first);
  }

  /// Insere ou atualiza um [IdentityRecord] na tabela `identidade`.
  Future<int> salvarIdentidade(IdentityRecord record) async {
    final mapa = record.toMap();
    final idGerado = await _db.rawInsert(sqlSalvarIdentidade, [
      mapa['id'],
      mapa['nome'],
      mapa['clube_associacao'],
      mapa['data_registro'],
    ]);
    record.id = idGerado;
    _identidadesCache.removeWhere((item) => item.id == idGerado);
    _identidadesCache.add(record);
    return idGerado;
  }

  // ── Submissões e Catálogo (SubmissionRecord) ──────────────────────────────

  List<SubmissionRecord> _ordenarPorDataDecrescente(
    Iterable<SubmissionRecord> itens,
  ) {
    final lista = itens.toList();
    lista.sort((a, b) => b.dataInclusao.compareTo(a.dataInclusao));
    return lista;
  }

  void _emitirAtualizacaoHistorico() {
    if (!_historicoController.isClosed) {
      _historicoController.add(
        _ordenarPorDataDecrescente(_submissoesPorSessao.values),
      );
    }
  }

  /// Retorna todas as submissões em memória sincronizadas com o SQLite.
  List<SubmissionRecord> listarSubmissoesSync() {
    return _ordenarPorDataDecrescente(_submissoesPorSessao.values);
  }

  /// Consulta todas as submissões diretamente no SQLite ordenadas pela data de inclusão decrescente.
  Future<List<SubmissionRecord>> listarSubmissoes() async {
    final linhas = await _db.rawQuery(sqlListarSubmissoes);
    final registros = linhas.map(SubmissionRecord.fromMap).toList();
    _submissoesPorSessao.clear();
    for (final reg in registros) {
      _submissoesPorSessao[reg.idSessao] = reg;
      if (reg.id >= _proximoIdSubmissao) {
        _proximoIdSubmissao = reg.id + 1;
      }
    }
    return _ordenarPorDataDecrescente(registros);
  }

  /// Obtém uma submissão pelo [idSessao] de forma síncrona.
  SubmissionRecord? obterSubmissaoPorIdSessaoSync(String idSessao) {
    return _submissoesPorSessao[idSessao];
  }

  /// Consulta uma submissão pelo [idSessao] diretamente no SQLite.
  Future<SubmissionRecord?> obterSubmissaoPorIdSessao(String idSessao) async {
    final linhas = await _db.rawQuery(sqlObterSubmissaoPorIdSessao, [idSessao]);
    if (linhas.isEmpty) return null;
    final record = SubmissionRecord.fromMap(linhas.first);
    _submissoesPorSessao[record.idSessao] = record;
    return record;
  }

  /// Consulta uma submissão pelo [protobufPath] diretamente no SQLite.
  Future<SubmissionRecord?> obterSubmissaoPorProtobufPath(
    String protobufPath,
  ) async {
    final linhas = await _db.rawQuery(
      sqlObterSubmissaoPorProtobufPath,
      [protobufPath],
    );
    if (linhas.isEmpty) return null;
    final record = SubmissionRecord.fromMap(linhas.first);
    _submissoesPorSessao[record.idSessao] = record;
    return record;
  }

  List<Object?> _argumentosSubmissao(SubmissionRecord record) {
    final mapa = record.toMap();
    return [
      mapa['id'],
      mapa['id_sessao'],
      mapa['id_protocolo'],
      mapa['nome_protocolo'],
      mapa['titulo_exibicao'],
      mapa['tipo_registro'],
      mapa['data_inclusao'],
      mapa['data_ultima_selecao'],
      mapa['hash_assinatura'],
      mapa['pdf_path'],
      mapa['protobuf_path'],
      mapa['enviado_nuvem'],
      mapa['status'],
    ];
  }

  /// Insere ou atualiza um [SubmissionRecord] no SQLite (unicidade por `id_sessao`).
  Future<int> salvarSubmissao(SubmissionRecord record) async {
    final existente = _submissoesPorSessao[record.idSessao];
    if (record.id <= 0 && existente != null && existente.id > 0) {
      record.id = existente.id;
    }
    final idGerado = await _db.rawInsert(
      sqlSalvarSubmissao,
      _argumentosSubmissao(record),
    );
    record.id = idGerado;
    if (idGerado >= _proximoIdSubmissao) {
      _proximoIdSubmissao = idGerado + 1;
    }
    _submissoesPorSessao[record.idSessao] = record;
    _emitirAtualizacaoHistorico();
    return idGerado;
  }

  /// Atualiza o cache síncrono e agenda a persistência no SQLite para fluxos síncronos de UI.
  void salvarSubmissaoSync(SubmissionRecord record) {
    final existente = _submissoesPorSessao[record.idSessao];
    if (record.id <= 0) {
      record.id = (existente != null && existente.id > 0)
          ? existente.id
          : _proximoIdSubmissao++;
    }
    _submissoesPorSessao[record.idSessao] = record;
    _emitirAtualizacaoHistorico();
    unawaited(
      _db.rawInsert(sqlSalvarSubmissao, _argumentosSubmissao(record)),
    );
  }

  /// Remove uma submissão pelo seu [id] primário no SQLite.
  Future<void> deletarSubmissao(int id) async {
    _submissoesPorSessao.removeWhere((_, valor) => valor.id == id);
    await _db.rawDelete(sqlDeletarSubmissaoPorId, [id]);
    _emitirAtualizacaoHistorico();
  }

  /// Remove uma submissão pelo seu [idSessao] no SQLite.
  Future<void> deletarSubmissaoPorIdSessao(String idSessao) async {
    _submissoesPorSessao.remove(idSessao);
    await _db.rawDelete(sqlDeletarSubmissaoPorIdSessao, [idSessao]);
    _emitirAtualizacaoHistorico();
  }

  /// Observa continuamente a lista de submissões ordenada por data de inclusão decrescente,
  /// emitindo imediatamente o estado atual do SQLite seguido de cada mutação.
  Stream<List<SubmissionRecord>> observarSubmissoes() async* {
    yield await listarSubmissoes();
    yield* _historicoController.stream;
  }

  /// Fecha o stream reativo e a instância do banco de dados SQLite.
  Future<void> fechar() async {
    await _historicoController.close();
    if (_db.isOpen) {
      await _db.close();
    }
  }
}

/// Provedor global da instância do banco de dados local SQLite.
final bancoDadosLocalProvider = Provider<BancoDadosLocal?>((ref) => null);
