// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'crypto_service.dart';
import 'providers.dart';
import 'registro_logger.dart';
import 'servico_app_check.dart';

/// Provedores OIDC exclusivos suportados pelo Fixalog (sem magic link por e-mail).
enum ProvedorOidc {
  google('google'),
  apple('apple');

  final String valor;
  const ProvedorOidc(this.valor);

  static ProvedorOidc deString(String valor) {
    return ProvedorOidc.values.firstWhere(
      (p) => p.valor == valor.trim().toLowerCase(),
      orElse: () => ProvedorOidc.google,
    );
  }
}

/// Dados retornados pelo provedor OIDC + Supabase (`signInWithIdToken`) durante o login.
class CredencialOidcBruta {
  final String userId;
  final String email;
  final ProvedorOidc provedor;
  final String nomeCompleto;
  final String clubeAssociacao;
  final String jwtSupabase;
  final String idTokenOidc;

  const CredencialOidcBruta({
    required this.userId,
    required this.email,
    required this.provedor,
    required this.nomeCompleto,
    this.clubeAssociacao = '',
    required this.jwtSupabase,
    required this.idTokenOidc,
  });
}

/// Representa a sessão autenticada do usuário na nuvem vinculada à chave ECDSA local.
class SessaoUsuarioNuvem {
  final String userId;
  final String email;
  final ProvedorOidc provedor;
  final String nomeCompleto;
  final String clubeAssociacao;
  final String jwtSupabase;
  final String atestadoOidcJwt;
  final String fingerprintChavePublica;

  const SessaoUsuarioNuvem({
    required this.userId,
    required this.email,
    required this.provedor,
    required this.nomeCompleto,
    required this.clubeAssociacao,
    required this.jwtSupabase,
    required this.atestadoOidcJwt,
    required this.fingerprintChavePublica,
  });

  SessaoUsuarioNuvem copiarCom({
    String? nomeCompleto,
    String? clubeAssociacao,
  }) {
    return SessaoUsuarioNuvem(
      userId: userId,
      email: email,
      provedor: provedor,
      nomeCompleto: nomeCompleto ?? this.nomeCompleto,
      clubeAssociacao: clubeAssociacao ?? this.clubeAssociacao,
      jwtSupabase: jwtSupabase,
      atestadoOidcJwt: atestadoOidcJwt,
      fingerprintChavePublica: fingerprintChavePublica,
    );
  }

  Map<String, String> paraMapa() {
    return {
      'user_id': userId,
      'email': email,
      'provedor': provedor.valor,
      'nome_completo': nomeCompleto,
      'clube_associacao': clubeAssociacao,
      'jwt_supabase': jwtSupabase,
      'atestado_oidc_jwt': atestadoOidcJwt,
      'fingerprint_chave_publica': fingerprintChavePublica,
    };
  }

  factory SessaoUsuarioNuvem.deMapa(Map<String, dynamic> mapa) {
    return SessaoUsuarioNuvem(
      userId: (mapa['user_id'] as String?) ?? '',
      email: (mapa['email'] as String?) ?? '',
      provedor: ProvedorOidc.deString((mapa['provedor'] as String?) ?? 'google'),
      nomeCompleto: (mapa['nome_completo'] as String?) ?? '',
      clubeAssociacao: (mapa['clube_associacao'] as String?) ?? '',
      jwtSupabase: (mapa['jwt_supabase'] as String?) ?? '',
      atestadoOidcJwt: (mapa['atestado_oidc_jwt'] as String?) ?? '',
      fingerprintChavePublica:
          (mapa['fingerprint_chave_publica'] as String?) ?? '',
    );
  }
}

/// Serviço responsável pela autenticação OIDC (Sign in with Google e Sign in with Apple)
/// com vínculo criptográfico OpenPubkey (`nonce` da chave pública ECDSA local) e
/// emissão de tokens de integridade de dispositivo (Firebase App Check).
class AutenticacaoNuvemService {
  static const String _chaveSessaoJson = 'fixalog_sessao_nuvem_json';

  /// URL padrão do projeto Supabase compartilhado (`aresta`).
  static const String urlSupabasePadrao = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://yzkhiaoqtxvvcyyuwmqg.supabase.co',
  );

  /// Publishable key pública padrão do projeto Supabase (`aresta`) exigida no cabeçalho `apikey` do gateway.
  static const String chaveAnonSupabasePadrao = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_-pmZpZIRey5ukpGubgzVwg_fT_qKRJN',
  );

  /// Web Client ID do Google Cloud Console para emissão de `id_token` via Credential Manager.
  static const String idClienteWebGooglePadrao = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '1025411452942-l2dbk6vrt52di1ql7lm4u65i0ndvodes.apps.googleusercontent.com',
  );

  /// iOS Client ID do Google Cloud Console para fluxo OAuth nativo no iOS.
  static const String idClienteIosGooglePadrao = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue:
        '1025411452942-eimt7ppo50n2ctur5r8ag4trk1mlo999.apps.googleusercontent.com',
  );

  /// URL ativa do Supabase GoTrue (permite apontar para servidor local em testes de integração).
  static String urlSupabaseAtiva = urlSupabasePadrao;

  /// Canal nativo (iOS `ASAuthorizationAppleIDProvider` / Android `CredentialManager`) para login OIDC.
  static const MethodChannel canalAutenticacaoNativa = MethodChannel(
    'com.arestaclimb.fixalog/autenticacao_nativa',
  );

  static const FlutterSecureStorage _armazenamentoPadrao = FlutterSecureStorage(
    iOptions: IOSOptions(
      synchronizable: true,
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  final CryptoService _cryptoService;
  final FlutterSecureStorage _secureStorage;
  final Future<CredencialOidcBruta> Function(
    ProvedorOidc provedor,
    String rawNonce,
  ) _autenticadorOidc;
  final Future<String> Function() _provedorTokenAppCheck;
  final Future<void> Function(
    String nomeCompleto,
    String clubeAssociacao,
  )? _sincronizadorPerfilRemoto;

  AutenticacaoNuvemService({
    CryptoService? cryptoService,
    FlutterSecureStorage? secureStorage,
    Future<CredencialOidcBruta> Function(
      ProvedorOidc provedor,
      String rawNonce,
    )? autenticadorOidc,
    Future<String> Function()? provedorTokenAppCheck,
    Future<void> Function(
      String nomeCompleto,
      String clubeAssociacao,
    )? sincronizadorPerfilRemoto,
  })  : _cryptoService = cryptoService ?? CryptoService(),
        _secureStorage = secureStorage ?? _armazenamentoPadrao,
        _autenticadorOidc = autenticadorOidc ?? _autenticadorOidcPadrao,
        _provedorTokenAppCheck =
            provedorTokenAppCheck ?? _provedorAppCheckPadrao,
        _sincronizadorPerfilRemoto = sincronizadorPerfilRemoto;

  /// Constrói um JWT OIDC assinado localmente em ambiente sem SDK nativo configurado,
  /// preservando o contrato OpenPubkey (`nonce = sha256(rawNonce)`).
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

  /// Realiza a troca de um `id_token` OIDC (Google ou Apple) por uma sessão JWT do Supabase GoTrue
  /// (`POST /auth/v1/token?grant_type=id_token`) enviando o `rawNonce` para verificação criptográfica.
  static Future<CredencialOidcBruta> trocarIdTokenNoSupabase({
    required ProvedorOidc provedor,
    required String idToken,
    required String rawNonce,
    String nomeInicial = '',
    String emailInicial = '',
    String? urlSupabase,
    String chaveAnonSupabase = chaveAnonSupabasePadrao,
  }) async {
    final client = HttpClient();
    try {
      final base = urlSupabase ?? urlSupabaseAtiva;
      final uri = Uri.parse('$base/auth/v1/token?grant_type=id_token');
      final req = await client.postUrl(uri);
      req.headers.set('Content-Type', 'application/json');
      req.headers.set('apikey', chaveAnonSupabase);
      req.add(
        utf8.encode(
          jsonEncode({
            'provider': provedor.valor,
            'id_token': idToken,
            'nonce': rawNonce,
          }),
        ),
      );
      final res = await req.close();
      final corpo = await utf8.decoder.bind(res).join();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw HttpException(
          'Falha ao autenticar no Supabase (${res.statusCode}): $corpo',
          uri: uri,
        );
      }
      final dados = jsonDecode(corpo) as Map<String, dynamic>;
      final accessToken = (dados['access_token'] as String?) ?? '';
      final usuario =
          (dados['user'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
      final metadados =
          (usuario['user_metadata'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};
      final userId = (usuario['id'] as String?) ?? '';
      final email = (usuario['email'] as String?) ?? emailInicial;
      final nomeFixalogMeta =
          (metadados['nome_completo_fixalog'] as String?)?.trim() ?? '';
      final clubeFixalogMeta =
          (metadados['clube_associacao_fixalog'] as String?)?.trim() ?? '';
      final nomePublicoMeta =
          (metadados['autor_nome_publico'] as String?)?.trim() ?? '';
      final nomeMeta = (metadados['full_name'] as String?) ??
          (metadados['name'] as String?) ??
          '';

      var nomePerfilAresta = '';
      if (userId.isNotEmpty && accessToken.isNotEmpty) {
        final uriPerfil = Uri.parse(
          '$base/rest/v1/perfis?user_id=eq.${Uri.encodeQueryComponent(userId)}&select=autor_nome_publico',
        );
        final reqPerfil = await client.getUrl(uriPerfil);
        reqPerfil.headers.set('apikey', chaveAnonSupabase);
        reqPerfil.headers.set('Authorization', 'Bearer $accessToken');
        final resPerfil = await reqPerfil.close();
        final corpoPerfil = await utf8.decoder.bind(resPerfil).join();
        if (resPerfil.statusCode >= 200 && resPerfil.statusCode < 300) {
          final listaPerfis = jsonDecode(corpoPerfil);
          if (listaPerfis is List && listaPerfis.isNotEmpty) {
            final primeiro = listaPerfis.first as Map<String, dynamic>;
            nomePerfilAresta =
                (primeiro['autor_nome_publico'] as String?)?.trim() ?? '';
          }
        }
      }

      var nomeEfetivo = '';
      for (final candidato in <String>[
        nomeFixalogMeta,
        nomePerfilAresta,
        nomePublicoMeta,
        nomeInicial.trim(),
        nomeMeta.trim(),
      ]) {
        if (candidato.isNotEmpty) {
          nomeEfetivo = candidato;
          break;
        }
      }

      return CredencialOidcBruta(
        userId: userId,
        email: email,
        provedor: provedor,
        nomeCompleto: nomeEfetivo,
        clubeAssociacao: clubeFixalogMeta,
        jwtSupabase: accessToken,
        idTokenOidc: idToken,
      );
    } finally {
      client.close(force: true);
    }
  }

  static Future<CredencialOidcBruta> _autenticadorOidcPadrao(
    ProvedorOidc provedor,
    String rawNonce,
  ) async {
    try {
      final metodo = provedor == ProvedorOidc.apple
          ? 'solicitarIdTokenApple'
          : 'solicitarIdTokenGoogle';
      final respostaNativa = await canalAutenticacaoNativa
          .invokeMapMethod<String, dynamic>(metodo, <String, dynamic>{
            'rawNonce': rawNonce,
            'webClientId': idClienteWebGooglePadrao,
            'iosClientId': idClienteIosGooglePadrao,
          });
      if (respostaNativa != null) {
        final idTokenNativo = (respostaNativa['idToken'] as String?) ?? '';
        final nomeNativo = (respostaNativa['nomeCompleto'] as String?) ?? '';
        final emailNativo = (respostaNativa['email'] as String?) ?? '';
        return await trocarIdTokenNoSupabase(
          provedor: provedor,
          idToken: idTokenNativo,
          rawNonce: rawNonce,
          nomeInicial: nomeNativo,
          emailInicial: emailNativo,
        );
      }
    } on MissingPluginException {
      // Em ambientes de teste ou desktop sem handler nativo registrado, utiliza o fallback local.
    }

    final email = provedor == ProvedorOidc.apple
        ? 'escalador@privaterelay.appleid.com'
        : 'escalador@gmail.com';
    const nome = 'Escalador Aresta';
    final idToken = construirIdTokenOidcComNonce(
      provedor: provedor,
      sub: 'oidc_${provedor.valor}_sub',
      email: email,
      nomeCompleto: nome,
      rawNonce: rawNonce,
    );
    return CredencialOidcBruta(
      userId: 'usr_${provedor.valor}_padrao',
      email: email,
      provedor: provedor,
      nomeCompleto: nome,
      clubeAssociacao: '',
      jwtSupabase: 'jwt_supabase_${provedor.valor}',
      idTokenOidc: idToken,
    );
  }

  static Future<String> _provedorAppCheckPadrao() async {
    final token = await ServicoAppCheck.instancia.obterToken();
    return token ?? 'app_check_token_fixalog_padrao';
  }

  /// Valida que o `id_token` OIDC recebido contém o claim `nonce` correspondente
  /// ao `rawNonce` (`sha256(public_key_pem)`) ou `sha256(rawNonce)`.
  static bool validarNonceNoIdToken({
    required String idTokenOidc,
    required String rawNonceEsperado,
  }) {
    final partes = idTokenOidc.trim().split('.');
    if (partes.length != 3) {
      return false;
    }
    try {
      final payloadJson = utf8.decode(
        base64Url.decode(base64Url.normalize(partes[1])),
      );
      final mapa = jsonDecode(payloadJson);
      if (mapa is! Map<String, dynamic>) {
        return false;
      }
      final nonceClaim = mapa['nonce'] as String?;
      if (nonceClaim == null || nonceClaim.isEmpty) {
        return false;
      }
      final hashDoRawNonce =
          sha256.convert(utf8.encode(rawNonceEsperado)).toString();
      return nonceClaim == rawNonceEsperado || nonceClaim == hashDoRawNonce;
    } catch (_) {
      return false;
    }
  }

  /// Realiza o login OIDC (Google ou Apple) injetando o `rawNonce` da chave pública
  /// ECDSA local (gerada ou restaurada do cofre E2EE do SO) e persiste o atestado OIDC.
  Future<SessaoUsuarioNuvem> entrarComProvedorOidc(
    ProvedorOidc provedor,
  ) async {
    final rawNonce = await _cryptoService.calcularRawNonceChavePublica();
    final credencial = await _autenticadorOidc(provedor, rawNonce);

    if (!validarNonceNoIdToken(
      idTokenOidc: credencial.idTokenOidc,
      rawNonceEsperado: rawNonce,
    )) {
      throw const FormatException(
        'O id_token OIDC retornado não contém o nonce criptográfico esperado da chave pública.',
      );
    }

    await _cryptoService.salvarAtestadoOidcJwt(credencial.idTokenOidc);

    final nomeEfetivo = credencial.nomeCompleto.trim();
    final clubeEfetivo = credencial.clubeAssociacao.trim();
    if (nomeEfetivo.isNotEmpty) {
      await _cryptoService.generateX509Certificate(
        nomeEfetivo,
        clubeAssociacao: clubeEfetivo,
      );
    }

    final sessao = SessaoUsuarioNuvem(
      userId: credencial.userId,
      email: credencial.email,
      provedor: credencial.provedor,
      nomeCompleto: nomeEfetivo,
      clubeAssociacao: clubeEfetivo,
      jwtSupabase: credencial.jwtSupabase,
      atestadoOidcJwt: credencial.idTokenOidc,
      fingerprintChavePublica: rawNonce,
    );

    await _secureStorage.write(
      key: _chaveSessaoJson,
      value: jsonEncode(sessao.paraMapa()),
    );

    return sessao;
  }

  /// Re-vincula uma chave privada ECDSA local pré-existente (ou recém-restaurada)
  /// a um novo `id_token` OIDC com o `nonce` correspondente.
  Future<SessaoUsuarioNuvem> vincularChaveLocalAoProvedorOidc(
    ProvedorOidc provedor,
  ) {
    return entrarComProvedorOidc(provedor);
  }

  /// Sincroniza o Nome Completo e Clube/Associação nos metadados do Supabase Auth (`PUT /auth/v1/user`)
  /// e, quando [atualizarNomeNoAresta] for verdadeiro, atualiza também `public.perfis.autor_nome_publico`.
  static Future<void> sincronizarPerfilNoSupabase({
    required SessaoUsuarioNuvem sessao,
    required String nomeCompleto,
    required String clubeAssociacao,
    required bool atualizarNomeNoAresta,
    String? urlSupabase,
    String chaveAnonSupabase = chaveAnonSupabasePadrao,
  }) async {
    final client = HttpClient();
    try {
      final base = urlSupabase ?? urlSupabaseAtiva;
      final uriUser = Uri.parse('$base/auth/v1/user');
      final reqUser = await client.putUrl(uriUser);
      reqUser.headers.set('Content-Type', 'application/json');
      reqUser.headers.set('apikey', chaveAnonSupabase);
      reqUser.headers.set('Authorization', 'Bearer ${sessao.jwtSupabase}');
      reqUser.add(
        utf8.encode(
          jsonEncode({
            'data': {
              'nome_completo_fixalog': nomeCompleto,
              'clube_associacao_fixalog': clubeAssociacao,
              if (atualizarNomeNoAresta) 'autor_nome_publico': nomeCompleto,
            },
          }),
        ),
      );
      final resUser = await reqUser.close();
      await resUser.drain<void>();

      if (atualizarNomeNoAresta) {
        final uriPerfil = Uri.parse(
          '$base/rest/v1/perfis?user_id=eq.${Uri.encodeQueryComponent(sessao.userId)}',
        );
        final reqPerfil = await client.patchUrl(uriPerfil);
        reqPerfil.headers.set('Content-Type', 'application/json');
        reqPerfil.headers.set('apikey', chaveAnonSupabase);
        reqPerfil.headers.set('Authorization', 'Bearer ${sessao.jwtSupabase}');
        reqPerfil.add(
          utf8.encode(
            jsonEncode({
              'autor_nome_publico': nomeCompleto,
            }),
          ),
        );
        final resPerfil = await reqPerfil.close();
        await resPerfil.drain<void>();
      }
    } catch (_) {
      // Sincronização em nuvem é best-effort para não bloquear operação offline-first.
    } finally {
      client.close(force: true);
    }
  }

  /// Atualiza o Nome Completo e Clube/Associação da conta autenticada e
  /// re-emite o certificado X.509 local mantendo o mesmo par de chaves ECDSA.
  Future<SessaoUsuarioNuvem?> atualizarPerfilConta({
    required String nomeCompleto,
    required String clubeAssociacao,
    bool atualizarNomeNoAresta = true,
  }) async {
    final nomeLimpo = nomeCompleto.trim();
    final clubeLimpo = clubeAssociacao.trim();

    if (nomeLimpo.isNotEmpty) {
      await _cryptoService.generateAndStoreKeysIfNeeded();
      await _cryptoService.generateX509Certificate(
        nomeLimpo,
        clubeAssociacao: clubeLimpo,
      );
    }

    if (_sincronizadorPerfilRemoto != null) {
      await _sincronizadorPerfilRemoto(nomeLimpo, clubeLimpo);
    }

    final sessaoAtual = await obterSessaoAtual();
    if (sessaoAtual == null) {
      return null;
    }

    if (_sincronizadorPerfilRemoto == null) {
      await sincronizarPerfilNoSupabase(
        sessao: sessaoAtual,
        nomeCompleto: nomeLimpo,
        clubeAssociacao: clubeLimpo,
        atualizarNomeNoAresta: atualizarNomeNoAresta,
      );
    }

    final atualizada = sessaoAtual.copiarCom(
      nomeCompleto: nomeLimpo,
      clubeAssociacao: clubeLimpo,
    );
    await _secureStorage.write(
      key: _chaveSessaoJson,
      value: jsonEncode(atualizada.paraMapa()),
    );
    return atualizada;
  }

  /// Retorna a sessão autenticada persistida localmente ou `null` caso não autenticado.
  Future<SessaoUsuarioNuvem?> obterSessaoAtual() async {
    final bruto = await _secureStorage.read(key: _chaveSessaoJson);
    if (bruto == null || bruto.trim().isEmpty) {
      return null;
    }
    try {
      final mapa = jsonDecode(bruto) as Map<String, dynamic>;
      return SessaoUsuarioNuvem.deMapa(mapa);
    } catch (e) {
      RegistroLogger.instancia.logAviso(
        'Falha ao decodificar sessão OIDC persistida localmente: $e',
      );
      return null;
    }
  }

  /// Obtém o token de atestação de integridade do aplicativo (Firebase App Check).
  Future<String> obterTokenAppCheck() {
    return _provedorTokenAppCheck();
  }

  /// Encerra a sessão de nuvem mantendo as chaves ECDSA locais intactas.
  Future<void> encerrarSessao() async {
    await _secureStorage.delete(key: _chaveSessaoJson);
  }
}

final autenticacaoNuvemServiceProvider = Provider<AutenticacaoNuvemService>((
  ref,
) {
  final cryptoService = ref.watch(cryptoServiceProvider);
  return AutenticacaoNuvemService(cryptoService: cryptoService);
});
