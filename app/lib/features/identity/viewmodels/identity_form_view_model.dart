// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:async';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/resolvedor_idioma.dart';
import '../../../core/models/local/identity_record.dart';
import '../../../core/services/autenticacao_nuvem_service.dart';
import '../../../core/services/crypto_service.dart';
import '../../../core/services/providers.dart';
import '../../../core/services/registro_logger.dart';
import '../../../core/services/servico_telemetria.dart';
import '../repositories/identity_repository.dart';

class IdentityFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final SessaoUsuarioNuvem? sessaoNuvem;
  final String? nomeSugerido;
  final String? clubeSugerido;
  final bool atualizarNomeNoAresta;

  IdentityFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.sessaoNuvem,
    this.nomeSugerido,
    this.clubeSugerido,
    this.atualizarNomeNoAresta = true,
  });

  IdentityFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    SessaoUsuarioNuvem? sessaoNuvem,
    String? nomeSugerido,
    String? clubeSugerido,
    bool? atualizarNomeNoAresta,
  }) {
    return IdentityFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      sessaoNuvem: sessaoNuvem ?? this.sessaoNuvem,
      nomeSugerido: nomeSugerido ?? this.nomeSugerido,
      clubeSugerido: clubeSugerido ?? this.clubeSugerido,
      atualizarNomeNoAresta:
          atualizarNomeNoAresta ?? this.atualizarNomeNoAresta,
    );
  }
}

class IdentityFormViewModel extends StateNotifier<IdentityFormState> {
  final IdentityRepository _repository;
  final CryptoService _cryptoService;
  final AutenticacaoNuvemService _autenticacaoService;
  final RegistroLogger _logger;

  IdentityFormViewModel(
    this._repository,
    this._cryptoService, [
    AutenticacaoNuvemService? autenticacaoService,
    RegistroLogger? logger,
  ])  : _autenticacaoService =
            autenticacaoService ??
            AutenticacaoNuvemService(cryptoService: _cryptoService),
        _logger = logger ?? RegistroLogger.instancia,
        super(IdentityFormState());

  /// Carrega uma sessão OIDC já existente e a identidade local persistida quando a tela é aberta,
  /// reiniciando flags transitórias de submissão anterior (`isSuccess` e `errorMessage`).
  Future<void> carregarSessaoExistente() async {
    final sessao = await _autenticacaoService.obterSessaoAtual();
    final identidadeLocal = await _repository.getCurrentIdentity();
    final nomeSessao = sessao?.nomeCompleto.trim() ?? '';
    final clubeSessao = sessao?.clubeAssociacao.trim() ?? '';
    final clubeLocal = identidadeLocal?.clubeAssociacao ?? '';
    state = state.copyWith(
      isSuccess: false,
      errorMessage: null,
      sessaoNuvem: sessao,
      nomeSugerido: nomeSessao.isNotEmpty ? nomeSessao : identidadeLocal?.nome,
      clubeSugerido: clubeSessao.isNotEmpty
          ? clubeSessao
          : (clubeLocal == 'N/A' ? '' : clubeLocal),
    );
  }

  /// Define se a atualização do Nome Completo deve também sincronizar `autor_nome_publico` no Aresta Climb.
  void definirAtualizarNomeNoAresta(bool valor) {
    state = state.copyWith(atualizarNomeNoAresta: valor);
  }

  /// Encerra a sessão OIDC atual e retorna o formulário para a Etapa 1 (escolha de conta Google/Apple).
  Future<void> trocarConta() async {
    await _autenticacaoService.encerrarSessao();
    unawaited(
      ServicoTelemetria.instancia.registrarAcaoConfiguracoes('logout_oidc'),
    );
    state = IdentityFormState(
      atualizarNomeNoAresta: state.atualizarNomeNoAresta,
    );
  }

  /// Autentica com Google ou Apple vinculando o `nonce` OpenPubkey da chave
  /// pública ECDSA local (gerada ou restaurada do cofre do SO) ao `id_token` OIDC.
  Future<void> autenticarComProvedor(
    ProvedorOidc provedor, {
    Locale locale = const Locale('pt'),
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final sessao = await _autenticacaoService.entrarComProvedorOidc(provedor);
      unawaited(
        ServicoTelemetria.instancia.registrarAcaoConfiguracoes(
          'login_oidc',
          detalhe: provedor.valor,
        ),
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        sessaoNuvem: sessao,
        nomeSugerido: sessao.nomeCompleto,
        clubeSugerido: sessao.clubeAssociacao,
      );
    } on ExcecaoAutenticacaoCancelada {
      state = state.copyWith(isLoading: false, errorMessage: null);
    } catch (e, stackTrace) {
      final l10n = ResolvedorIdioma.obterTraducoes(locale);
      final semRede = RegistroLogger.isFalhaConexaoOuTimeout(e);
      if (semRede) {
        _logger.logAviso(
          'Falha de conexão durante autenticação OIDC (${provedor.valor}): $e',
        );
      } else {
        _logger.logError(
          'Falha na autenticação OIDC (${provedor.valor})',
          error: e,
          stackTrace: stackTrace,
        );
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: semRede
            ? l10n.identidadeErroSemConexaoOidc
            : l10n.identidadeErroLoginOidc,
      );
    }
  }

  /// Salva a identidade local, sincroniza Nome e Clube com a conta autenticada
  /// e atualiza o certificado X.509 mantendo o mesmo par de chaves ECDSA.
  Future<void> submitIdentity(
    String nome,
    String clube, {
    bool exigirAutenticacaoOidc = false,
    Locale locale = const Locale('pt'),
  }) async {
    if (nome.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Atenção. O nome não pode estar vazio.',
      );
      return;
    }

    if (exigirAutenticacaoOidc && state.sessaoNuvem == null) {
      final sessaoSalva = await _autenticacaoService.obterSessaoAtual();
      if (sessaoSalva == null) {
        state = state.copyWith(
          errorMessage: 'Autentique-se com Google ou Apple antes de continuar.',
        );
        return;
      }
      state = state.copyWith(sessaoNuvem: sessaoSalva);
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _cryptoService.generateAndStoreKeysIfNeeded();

      final nomeLimpo = nome.trim();
      final clubeLimpo = clube.trim();
      await _autenticacaoService.atualizarPerfilConta(
        nomeCompleto: nomeLimpo,
        clubeAssociacao: clubeLimpo,
        atualizarNomeNoAresta: state.atualizarNomeNoAresta,
      );

      final identity = IdentityRecord()
        ..id = 1
        ..nome = nomeLimpo
        ..clubeAssociacao = clubeLimpo.isEmpty ? 'N/A' : clubeLimpo
        ..dataRegistro = DateTime.now();

      await _repository.saveIdentity(identity);
      unawaited(
        ServicoTelemetria.instancia.registrarSalvarIdentidade(
          possuiClube: clubeLimpo.isNotEmpty,
        ),
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, stackTrace) {
      final l10n = ResolvedorIdioma.obterTraducoes(locale);
      _logger.logError(
        'Falha ao registrar identidade local e certificado X.509',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: l10n.identidadeErroSalvarGenerico,
      );
    }
  }
}

final identityFormViewModelProvider =
    StateNotifierProvider<IdentityFormViewModel, IdentityFormState>((ref) {
      final repository = ref.watch(identityRepositoryProvider);
      final cryptoService = ref.watch(cryptoServiceProvider);
      final autenticacaoService = ref.watch(autenticacaoNuvemServiceProvider);
      return IdentityFormViewModel(
        repository,
        cryptoService,
        autenticacaoService,
      );
    });

final hasIdentityProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(identityRepositoryProvider);
  final autenticacaoService = ref.watch(autenticacaoNuvemServiceProvider);
  final possuiLocal = await repository.hasIdentity();
  if (!possuiLocal) {
    return false;
  }
  final sessaoOidc = await autenticacaoService.obterSessaoAtual();
  return sessaoOidc != null;
});

final currentIdentityProvider = FutureProvider<IdentityRecord?>((ref) async {
  final repository = ref.watch(identityRepositoryProvider);
  return await repository.getCurrentIdentity();
});
