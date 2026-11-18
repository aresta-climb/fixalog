// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:fixalog/core/services/autenticacao_nuvem_service.dart';
import 'package:fixalog/core/services/crypto_service.dart';

/// Implementação Fake determinística em memória de [AutenticacaoNuvemService]
/// para testes de autenticação OIDC (Google e Apple), OpenPubkey `nonce` e App Check.
class AutenticacaoNuvemServiceFake extends AutenticacaoNuvemService {
  final CryptoService crypto;
  bool deveFalharLogin;
  bool deveCancelarLogin;
  Object? erroCustomizadoLogin;
  bool deveFalharAppCheck;
  String nomeRetornadoOidc;
  String clubeRetornadoOidc;
  String emailRetornadoOidc;
  String userIdRetornadoOidc;
  String tokenAppCheckRetornado;
  SessaoUsuarioNuvem? sessaoArmazenada;
  final List<ProvedorOidc> loginsRealizados = [];
  final List<({String nome, String clube})> perfisAtualizados = [];
  bool ultimoAtualizarNomeNoAresta = true;

  AutenticacaoNuvemServiceFake({
    required this.crypto,
    this.deveFalharLogin = false,
    this.deveCancelarLogin = false,
    this.erroCustomizadoLogin,
    this.deveFalharAppCheck = false,
    this.nomeRetornadoOidc = 'Renato Ferreira',
    this.clubeRetornadoOidc = 'FEMERJ',
    this.emailRetornadoOidc = 'renato@arestaclimb.com',
    this.userIdRetornadoOidc = 'usr_aresta_123',
    this.tokenAppCheckRetornado = 'app_check_token_valido',
    this.sessaoArmazenada,
  }) : super(cryptoService: crypto);

  /// Constrói exclusivamente para testes um JWT OIDC determinístico contendo
  /// o claim `nonce = sha256(rawNonce)` exigido pelo contrato OpenPubkey.
  static String construirIdTokenOidcComNonce({
    required ProvedorOidc provedor,
    required String sub,
    required String email,
    required String nomeCompleto,
    required String rawNonce,
  }) {
    final nonceHash = sha256.convert(utf8.encode(rawNonce)).toString();
    final header = base64Url
        .encode(utf8.encode(jsonEncode({'alg': 'RS256', 'typ': 'JWT'})))
        .replaceAll('=', '');
    final iss = provedor == ProvedorOidc.apple
        ? 'https://appleid.apple.com'
        : 'https://accounts.google.com';
    final payload = base64Url
        .encode(
          utf8.encode(
            jsonEncode({
              'iss': iss,
              'sub': sub,
              'email': email,
              'name': nomeCompleto,
              'nonce': nonceHash,
              'iat': 1762000000,
              'exp': 2077360000,
            }),
          ),
        )
        .replaceAll('=', '');
    return '$header.$payload.assinatura_oidc_${provedor.valor}';
  }

  @override
  Future<SessaoUsuarioNuvem> entrarComProvedorOidc(
    ProvedorOidc provedor,
  ) async {
    if (deveCancelarLogin) {
      throw const ExcecaoAutenticacaoCancelada();
    }
    if (erroCustomizadoLogin != null) {
      throw erroCustomizadoLogin!;
    }
    if (deveFalharLogin) {
      throw const ExcecaoAutenticacaoOidc(
        'Falha simulada na autenticação OIDC.',
        statusCode: 400,
        codigoErroServidor: 'provider_disabled',
      );
    }
    loginsRealizados.add(provedor);
    final rawNonce = await crypto.calcularRawNonceChavePublica();
    final idToken = construirIdTokenOidcComNonce(
      provedor: provedor,
      sub: 'sub_${provedor.valor}_$userIdRetornadoOidc',
      email: emailRetornadoOidc,
      nomeCompleto: nomeRetornadoOidc,
      rawNonce: rawNonce,
    );
    await crypto.salvarAtestadoOidcJwt(idToken);
    if (nomeRetornadoOidc.trim().isNotEmpty) {
      await crypto.generateX509Certificate(
        nomeRetornadoOidc,
        clubeAssociacao: clubeRetornadoOidc,
      );
    }

    sessaoArmazenada = SessaoUsuarioNuvem(
      userId: userIdRetornadoOidc,
      email: emailRetornadoOidc,
      provedor: provedor,
      nomeCompleto: nomeRetornadoOidc,
      clubeAssociacao: clubeRetornadoOidc,
      jwtSupabase: 'jwt_supabase_$userIdRetornadoOidc',
      atestadoOidcJwt: idToken,
      fingerprintChavePublica: rawNonce,
    );
    return sessaoArmazenada!;
  }

  @override
  Future<SessaoUsuarioNuvem> vincularChaveLocalAoProvedorOidc(
    ProvedorOidc provedor,
  ) {
    return entrarComProvedorOidc(provedor);
  }

  @override
  Future<SessaoUsuarioNuvem?> atualizarPerfilConta({
    required String nomeCompleto,
    required String clubeAssociacao,
    bool atualizarNomeNoAresta = true,
  }) async {
    final nomeLimpo = nomeCompleto.trim();
    final clubeLimpo = clubeAssociacao.trim();
    ultimoAtualizarNomeNoAresta = atualizarNomeNoAresta;
    perfisAtualizados.add((nome: nomeLimpo, clube: clubeLimpo));

    if (nomeLimpo.isNotEmpty) {
      await crypto.generateAndStoreKeysIfNeeded();
      await crypto.generateX509Certificate(
        nomeLimpo,
        clubeAssociacao: clubeLimpo,
      );
    }

    if (sessaoArmazenada == null) {
      return null;
    }
    sessaoArmazenada = sessaoArmazenada!.copiarCom(
      nomeCompleto: nomeLimpo,
      clubeAssociacao: clubeLimpo,
    );
    return sessaoArmazenada;
  }

  @override
  Future<SessaoUsuarioNuvem?> obterSessaoAtual() async => sessaoArmazenada;

  @override
  Future<String> obterTokenAppCheck() async {
    if (deveFalharAppCheck) {
      throw Exception('Falha simulada no Firebase App Check.');
    }
    return tokenAppCheckRetornado;
  }

  @override
  Future<void> encerrarSessao() async {
    sessaoArmazenada = null;
  }
}
