// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:typed_data';
import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Serviço de criptografia assimétrica ECDSA (secp256r1 / P-256), geração de
/// certificados X.509 autoassinados e armazenamento seguro com suporte a
/// backup E2EE nativo do sistema operacional (iCloud Keychain / Google Backup).
class CryptoService {
  static const FlutterSecureStorage _armazenamentoPadrao = FlutterSecureStorage(
    iOptions: IOSOptions(
      synchronizable: true,
      accessibility: KeychainAccessibility.first_unlock,
    ),
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;
  final Future<bool> Function(String motivo)? _autenticadorBiometrico;

  CryptoService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
    Future<bool> Function(String motivo)? autenticadorBiometrico,
  })  : _secureStorage = secureStorage ?? _armazenamentoPadrao,
        _localAuth = localAuth ?? LocalAuthentication(),
        _autenticadorBiometrico = autenticadorBiometrico;

  /// Gera o par de chaves ECDSA secp256r1 persistindo em Secure Storage
  /// caso ainda não exista no dispositivo ou no cofre sincronizado do SO.
  Future<void> generateAndStoreKeysIfNeeded() async {
    final existingKey = await _secureStorage.read(key: 'private_key');
    if (existingKey == null) {
      final keyPair = CryptoUtils.generateEcKeyPair();

      final privateKeyPem = CryptoUtils.encodeEcPrivateKeyToPem(
        keyPair.privateKey as ECPrivateKey,
      );
      final publicKeyPem = CryptoUtils.encodeEcPublicKeyToPem(
        keyPair.publicKey as ECPublicKey,
      );

      await _secureStorage.write(key: 'private_key', value: privateKeyPem);
      await _secureStorage.write(key: 'public_key', value: publicKeyPem);
    }
  }

  /// Gera um Certificado X.509 Autoassinado com CN=Nome, O=Fixalog (e OU=Clube
  /// quando informado) preservando o par de chaves ECDSA existente.
  Future<String> generateX509Certificate(
    String mantenedorName, {
    String? clubeAssociacao,
  }) async {
    final privateKeyPem = await _secureStorage.read(key: 'private_key');
    final publicKeyPem = await _secureStorage.read(key: 'public_key');

    if (privateKeyPem == null || publicKeyPem == null) {
      throw Exception(
        'Chaves não encontradas no dispositivo. Gere as chaves primeiro.',
      );
    }

    final privateKey = CryptoUtils.ecPrivateKeyFromPem(privateKeyPem);
    final publicKey = CryptoUtils.ecPublicKeyFromPem(publicKeyPem);

    final subject = <String, String>{
      'CN': mantenedorName.trim(),
      'O': 'Fixalog',
    };
    final clubeLimpo = clubeAssociacao?.trim();
    if (clubeLimpo != null && clubeLimpo.isNotEmpty && clubeLimpo != 'N/A') {
      subject['OU'] = clubeLimpo;
    }

    final csr = X509Utils.generateEccCsrPem(subject, privateKey, publicKey);

    final x509Pem = X509Utils.generateSelfSignedCertificate(
      privateKey,
      csr,
      365 * 5,
    );

    await _secureStorage.write(key: 'x509_certificate', value: x509Pem);
    return x509Pem;
  }

  /// Retorna o último certificado X.509 PEM emitido e persistido localmente.
  Future<String?> obterCertificadoX509Pem() async {
    return _secureStorage.read(key: 'x509_certificate');
  }

  /// Calcula o `rawNonce` OpenPubkey (`sha256(public_key_pem.trim())` em hex)
  /// garantindo que o par de chaves ECDSA exista antes do cálculo.
  Future<String> calcularRawNonceChavePublica() async {
    await generateAndStoreKeysIfNeeded();
    return calcularFingerprintChavePublica();
  }

  /// Calcula o fingerprint SHA-256 hexadecimal da chave pública PEM armazenada.
  Future<String> calcularFingerprintChavePublica() async {
    final publicKeyPem = await getPublicKeyPem();
    return sha256.convert(utf8.encode(publicKeyPem.trim())).toString();
  }

  /// Persiste o `id_token` OIDC (Google ou Apple) contendo o `nonce` vinculado
  /// à chave pública ECDSA local.
  Future<void> salvarAtestadoOidcJwt(String jwt) async {
    await _secureStorage.write(key: 'atestado_oidc_jwt', value: jwt.trim());
  }

  /// Recupera o `id_token` OIDC persistido para inclusão em `META-INF/signatures.xml`.
  Future<String?> obterAtestadoOidcJwt() async {
    return _secureStorage.read(key: 'atestado_oidc_jwt');
  }

  /// Autentica o usuário via biometria e retorna a chave privada PEM.
  Future<dynamic> getPdfSigner() async {
    const motivo = 'Autorize a assinatura do documento com sua biometria';
    final authenticated = _autenticadorBiometrico != null
        ? await _autenticadorBiometrico(motivo)
        : await _localAuth.authenticate(localizedReason: motivo);

    if (!authenticated) {
      throw Exception('Autenticação biométrica falhou.');
    }

    final privateKeyPem = await _secureStorage.read(key: 'private_key');
    if (privateKeyPem == null) {
      throw Exception('Chaves não encontradas.');
    }

    return privateKeyPem;
  }

  /// Calcula o hash SHA-256 hexadecimal do conteúdo de um documento.
  String computeDocumentHash(List<int> documentBytes) {
    final digest = sha256.convert(documentBytes);
    return digest.toString();
  }

  /// Retorna a chave pública PEM armazenada para ser embutida no relatório.
  Future<String> getPublicKeyPem() async {
    final publicKeyPem = await _secureStorage.read(key: 'public_key');
    if (publicKeyPem == null) {
      throw Exception('Chave pública não encontrada.');
    }
    return publicKeyPem;
  }

  /// Retorna a chave privada PEM armazenada no secure storage.
  Future<String> getPrivateKeyPem() async {
    final privateKeyPem = await _secureStorage.read(key: 'private_key');
    if (privateKeyPem == null) {
      throw Exception('Chave privada não encontrada.');
    }
    return privateKeyPem;
  }

  /// Assina os bytes do documento usando a chave privada ECDSA secp256r1 local.
  Future<String> signDocument(List<int> documentBytes) async {
    final privateKeyPem = await _secureStorage.read(key: 'private_key');
    if (privateKeyPem == null) {
      throw Exception('Chaves não existem no dispositivo');
    }

    final privateKey = CryptoUtils.ecPrivateKeyFromPem(privateKeyPem);
    final sig = CryptoUtils.ecSign(
      privateKey,
      Uint8List.fromList(documentBytes),
      algorithmName: 'SHA-256/ECDSA',
    );
    return CryptoUtils.ecSignatureToBase64(sig);
  }
}
