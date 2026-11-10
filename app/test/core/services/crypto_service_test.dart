// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:basic_utils/basic_utils.dart';
import 'package:fixalog/core/services/crypto_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CryptoService cryptoService;
  late bool biometriaPermitida;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    biometriaPermitida = true;
    cryptoService = CryptoService(
      autenticadorBiometrico: (_) async => biometriaPermitida,
    );
  });

  group('Geração e Armazenamento de Chaves ECDSA', () {
    test('Gera e persiste par de chaves ECDSA quando nenhuma chave existe no cofre', () async {
      await cryptoService.generateAndStoreKeysIfNeeded();

      final privateKeyPem = await cryptoService.getPrivateKeyPem();
      final publicKeyPem = await cryptoService.getPublicKeyPem();

      expect(privateKeyPem, contains('BEGIN EC PRIVATE KEY'));
      expect(publicKeyPem, contains('BEGIN PUBLIC KEY'));
    });

    test('Preserva par de chaves existente sem sobrescrever em chamadas subsequentes', () async {
      await cryptoService.generateAndStoreKeysIfNeeded();
      final primeiraPrivada = await cryptoService.getPrivateKeyPem();
      final primeiraPublica = await cryptoService.getPublicKeyPem();

      await cryptoService.generateAndStoreKeysIfNeeded();
      expect(await cryptoService.getPrivateKeyPem(), equals(primeiraPrivada));
      expect(await cryptoService.getPublicKeyPem(), equals(primeiraPublica));
    });
  });

  group('Certificado X.509, Nonce OpenPubkey e Atestado OIDC', () {
    test('Gera certificado X.509 autoassinado com CN, O e OU sem regenerar chave ECDSA', () async {
      await cryptoService.generateAndStoreKeysIfNeeded();
      final fingerprintInicial = await cryptoService.calcularFingerprintChavePublica();

      final certPem = await cryptoService.generateX509Certificate(
        'Renato',
        clubeAssociacao: 'FEMERJ',
      );

      expect(certPem, contains('BEGIN CERTIFICATE'));
      expect(await cryptoService.obterCertificadoX509Pem(), equals(certPem));

      final x509 = X509Utils.x509CertificateFromPem(certPem);
      final subject = x509.tbsCertificate!.subject;
      expect(subject, containsPair('2.5.4.3', 'Renato'));
      expect(subject, containsPair('2.5.4.10', 'Fixalog'));
      expect(subject, containsPair('2.5.4.11', 'FEMERJ'));

      final certAtualizado = await cryptoService.generateX509Certificate(
        'Renato Ferreira',
        clubeAssociacao: 'N/A',
      );
      final x509Atualizado = X509Utils.x509CertificateFromPem(certAtualizado);
      final subjectAtualizado = x509Atualizado.tbsCertificate!.subject;
      expect(subjectAtualizado, containsPair('2.5.4.3', 'Renato Ferreira'));
      expect(subjectAtualizado.containsKey('2.5.4.11'), isFalse);
      expect(
        await cryptoService.calcularFingerprintChavePublica(),
        equals(fingerprintInicial),
      );
    });

    test('Lança exceção ao tentar gerar X.509 sem chaves previamente geradas', () async {
      await expectLater(
        cryptoService.generateX509Certificate('Renato'),
        throwsException,
      );
    });

    test('Calcula rawNonce SHA-256 da chave pública e persiste atestado OIDC JWT', () async {
      final rawNonce = await cryptoService.calcularRawNonceChavePublica();
      expect(rawNonce.length, equals(64));
      expect(
        await cryptoService.calcularFingerprintChavePublica(),
        equals(rawNonce),
      );

      expect(await cryptoService.obterAtestadoOidcJwt(), isNull);
      await cryptoService.salvarAtestadoOidcJwt('  jwt.oidc.google  ');
      expect(await cryptoService.obterAtestadoOidcJwt(), equals('jwt.oidc.google'));
    });
  });

  group('Biometria, Assinatura e Hash de Documento', () {
    test('Retorna chave privada em getPdfSigner quando biometria é aprovada', () async {
      await cryptoService.generateAndStoreKeysIfNeeded();
      final signer = await cryptoService.getPdfSigner();
      expect(signer, contains('BEGIN EC PRIVATE KEY'));
    });

    test('Lança exceção em getPdfSigner quando biometria falha ou chave inexiste', () async {
      await expectLater(cryptoService.getPdfSigner(), throwsException);

      await cryptoService.generateAndStoreKeysIfNeeded();
      biometriaPermitida = false;
      await expectLater(cryptoService.getPdfSigner(), throwsException);
    });

    test('Assina documento com ECDSA real e valida exceções quando chaves não existem', () async {
      await expectLater(cryptoService.getPublicKeyPem(), throwsException);
      await expectLater(cryptoService.getPrivateKeyPem(), throwsException);
      await expectLater(cryptoService.signDocument([1, 2, 3]), throwsException);

      await cryptoService.generateAndStoreKeysIfNeeded();
      final signatureBase64 = await cryptoService.signDocument([1, 2, 3]);
      expect(signatureBase64.length, greaterThan(20));

      final hash = cryptoService.computeDocumentHash([1, 2, 3, 4, 5]);
      expect(
        hash,
        '74f81fe167d99b4cb41d6d0ccda82278caee9f3e2f25d5e5a3936ff3dcec60d0',
      );
    });

    test('Inicializa com instâncias padrão quando nenhum parâmetro é fornecido', () {
      final padrao = CryptoService();
      expect(padrao, isNotNull);
    });
  });
}
