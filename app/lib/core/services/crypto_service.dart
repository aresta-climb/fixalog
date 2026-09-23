// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:local_auth/local_auth.dart';

class CryptoService {
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;

  CryptoService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication();

  /// Gera as chaves ECDSA secp256r1 persistindo em Secure Storage
  Future<void> generateAndStoreKeysIfNeeded() async {
    final existingKey = await _secureStorage.read(key: 'private_key');
    if (existingKey == null) {
      // Gera ECDSA KeyPair (secp256r1 é o padrão prime256v1 em pointycastle)
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

  /// Gera um Certificado X.509 Autoassinado com CN=Nome, O=FixLog
  Future<String> generateX509Certificate(String mantenedorName) async {
    final privateKeyPem = await _secureStorage.read(key: 'private_key');
    final publicKeyPem = await _secureStorage.read(key: 'public_key');

    if (privateKeyPem == null || publicKeyPem == null) {
      throw Exception(
        "Chaves não encontradas no dispositivo. Gere as chaves primeiro.",
      );
    }

    final privateKey = CryptoUtils.ecPrivateKeyFromPem(privateKeyPem);
    final publicKey = CryptoUtils.ecPublicKeyFromPem(publicKeyPem);

    final subject = {'CN': mantenedorName, 'O': 'FixLog'};

    final csr = X509Utils.generateEccCsrPem(subject, privateKey, publicKey);

    final x509Pem = X509Utils.generateSelfSignedCertificate(
      privateKey,
      csr,
      365 * 5,
    );

    return x509Pem;
  }

  /// Autentica o usuário e retorna o signer
  Future<dynamic> getPdfSigner() async {
    final authenticated = await _localAuth.authenticate(
      localizedReason: 'Autorize a assinatura do documento com sua biometria',
    );

    if (!authenticated) {
      throw Exception("Autenticação biométrica falhou.");
    }

    final privateKeyPem = await _secureStorage.read(key: 'private_key');
    if (privateKeyPem == null) {
      throw Exception("Chaves não encontradas.");
    }

    // Retorna a chave PEM temporariamente para o gerador usar (será refatorado com PdfSignatureBase)
    return privateKeyPem;
  }

  /// Pega o hash do conteudo (PDF + YAML) gerado
  String computeDocumentHash(List<int> documentBytes) {
    var digest = sha256.convert(documentBytes);
    return digest.toString();
  }

  /// Retorna a chave pública armazenada para ser embutida no relatório
  Future<String> getPublicKeyPem() async {
    final publicKeyPem = await _secureStorage.read(key: 'public_key');
    if (publicKeyPem == null) {
      throw Exception("Chave pública não encontrada.");
    }
    return publicKeyPem;
  }

  /// Retorna a chave privada armazenada no secure storage
  Future<String> getPrivateKeyPem() async {
    final privateKeyPem = await _secureStorage.read(key: 'private_key');
    if (privateKeyPem == null) {
      throw Exception("Chave privada não encontrada.");
    }
    return privateKeyPem;
  }

  /// Assina o binário usando a chave do device (ECDSA secp256r1)
  Future<String> signDocument(List<int> documentBytes) async {
    final privateKeyPem = await _secureStorage.read(key: 'private_key');
    if (privateKeyPem == null) {
      throw Exception("Chaves não existem no dispositivo");
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
