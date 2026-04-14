import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CryptoService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Mock: gera as chaves assimétricas persistindo em Secure Storage via AES
  Future<void> generateAndStoreKeysIfNeeded() async {
    final existingKey = await _secureStorage.read(key: 'private_key');
    if (existingKey == null) {
      // Stub: Aqui uma ECDSA/RSA KeyPair geraria via pointycastle
      await _secureStorage.write(key: 'private_key', value: 'generated_key_mock_base64');
      await _secureStorage.write(key: 'public_key', value: 'public_key_mock_base64');
    }
  }

  /// Pega o hash do conteudo (PDF + YAML) gerado
  String computeDocumentHash(List<int> documentBytes) {
    var digest = sha256.convert(documentBytes);
    return digest.toString();
  }

  /// Assina o hash usando a chave do device imitando JWS signature
  Future<String> signDocumentHash(String hash) async {
    final privateKey = await _secureStorage.read(key: 'private_key');
    // Stub: PointyCastle Signer (e.g. RSASigner(SHA256Digest(), ...))
    if (privateKey == null) {
      throw Exception("Chaves não existem no dispositivo");
    }
    
    // Simula a assinatura agregando o privado no hash para o MVP
    var signatureMock = base64Encode(utf8.encode("\$privateKey:\$hash"));
    return signatureMock;
  }
}
