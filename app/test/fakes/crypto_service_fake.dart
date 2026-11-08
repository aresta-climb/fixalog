// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:typed_data';
import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:fixalog/core/services/crypto_service.dart';

/// Implementação Fake determinística em memória de [CryptoService] para
/// testes sem acoplamento a Keystore/Keychain do sistema operacional.
class CryptoServiceFake extends CryptoService {
  bool deveFalharGeracaoChaves;
  bool biometriaAutorizada;
  String? chavePrivadaPem;
  String? chavePublicaPem;
  String? certificadoX509Pem;
  String? atestadoOidcJwt;

  CryptoServiceFake({
    this.deveFalharGeracaoChaves = false,
    this.biometriaAutorizada = true,
    this.chavePrivadaPem,
    this.chavePublicaPem,
    this.certificadoX509Pem,
    this.atestadoOidcJwt,
  });

  @override
  Future<void> generateAndStoreKeysIfNeeded() async {
    if (deveFalharGeracaoChaves) {
      throw Exception('Falha simulada no armazenamento seguro de chaves.');
    }
    if (chavePrivadaPem == null || chavePublicaPem == null) {
      final par = CryptoUtils.generateEcKeyPair();
      chavePrivadaPem = CryptoUtils.encodeEcPrivateKeyToPem(
        par.privateKey as ECPrivateKey,
      );
      chavePublicaPem = CryptoUtils.encodeEcPublicKeyToPem(
        par.publicKey as ECPublicKey,
      );
    }
  }

  @override
  Future<String> generateX509Certificate(
    String mantenedorName, {
    String? clubeAssociacao,
  }) async {
    if (chavePrivadaPem == null || chavePublicaPem == null) {
      throw Exception(
        'Chaves não encontradas no dispositivo. Gere as chaves primeiro.',
      );
    }
    final privateKey = CryptoUtils.ecPrivateKeyFromPem(chavePrivadaPem!);
    final publicKey = CryptoUtils.ecPublicKeyFromPem(chavePublicaPem!);
    final subject = <String, String>{
      'CN': mantenedorName.trim(),
      'O': 'Fixalog',
    };
    final clubeLimpo = clubeAssociacao?.trim();
    if (clubeLimpo != null && clubeLimpo.isNotEmpty && clubeLimpo != 'N/A') {
      subject['OU'] = clubeLimpo;
    }
    final csr = X509Utils.generateEccCsrPem(subject, privateKey, publicKey);
    certificadoX509Pem = X509Utils.generateSelfSignedCertificate(
      privateKey,
      csr,
      365 * 5,
    );
    return certificadoX509Pem!;
  }

  @override
  Future<String?> obterCertificadoX509Pem() async => certificadoX509Pem;

  @override
  Future<String> calcularRawNonceChavePublica() async {
    await generateAndStoreKeysIfNeeded();
    return calcularFingerprintChavePublica();
  }

  @override
  Future<String> calcularFingerprintChavePublica() async {
    final pub = await getPublicKeyPem();
    return sha256.convert(utf8.encode(pub.trim())).toString();
  }

  @override
  Future<void> salvarAtestadoOidcJwt(String jwt) async {
    atestadoOidcJwt = jwt.trim();
  }

  @override
  Future<String?> obterAtestadoOidcJwt() async => atestadoOidcJwt;

  @override
  Future<dynamic> getPdfSigner() async {
    if (!biometriaAutorizada) {
      throw Exception('Autenticação biométrica falhou.');
    }
    if (chavePrivadaPem == null) {
      throw Exception('Chaves não encontradas.');
    }
    return chavePrivadaPem;
  }

  @override
  Future<String> getPublicKeyPem() async {
    final pub = chavePublicaPem;
    if (pub == null) {
      throw Exception('Chave pública não encontrada.');
    }
    return pub;
  }

  @override
  Future<String> getPrivateKeyPem() async {
    final priv = chavePrivadaPem;
    if (priv == null) {
      throw Exception('Chave privada não encontrada.');
    }
    return priv;
  }

  @override
  Future<String> signDocument(List<int> documentBytes) async {
    final priv = chavePrivadaPem;
    if (priv == null) {
      throw Exception('Chaves não existem no dispositivo');
    }
    final privateKey = CryptoUtils.ecPrivateKeyFromPem(priv);
    final sig = CryptoUtils.ecSign(
      privateKey,
      Uint8List.fromList(documentBytes),
      algorithmName: 'SHA-256/ECDSA',
    );
    return CryptoUtils.ecSignatureToBase64(sig);
  }
}
