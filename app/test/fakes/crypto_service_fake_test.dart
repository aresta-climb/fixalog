// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'crypto_service_fake.dart';

void main() {
  group('CryptoServiceFake', () {
    test('Gera par ECDSA em memória, emite X.509 com CN e OU e preserva a mesma chave ao atualizar certificado', () async {
      final fake = CryptoServiceFake();
      final rawNonce1 = await fake.calcularRawNonceChavePublica();
      expect(rawNonce1.length, 64);

      final cert1 = await fake.generateX509Certificate(
        'Renato Ferreira',
        clubeAssociacao: 'FEMERJ',
      );
      expect(cert1, contains('BEGIN CERTIFICATE'));
      expect(await fake.obterCertificadoX509Pem(), equals(cert1));

      final x509 = X509Utils.x509CertificateFromPem(cert1);
      expect(x509.subject['2.5.4.3'], equals('Renato Ferreira'));
      expect(x509.subject['2.5.4.11'], equals('FEMERJ'));

      final cert2 = await fake.generateX509Certificate(
        'Renato Atualizado',
        clubeAssociacao: 'CEC',
      );
      expect(cert2, isNot(equals(cert1)));
      expect(await fake.calcularFingerprintChavePublica(), equals(rawNonce1));
    });

    test('Persiste atestado OIDC JWT, assina documentos e simula falhas configuráveis', () async {
      final fake = CryptoServiceFake();
      await fake.generateAndStoreKeysIfNeeded();
      await fake.salvarAtestadoOidcJwt('eyJhbGciOiJSUzI1NiJ9.payload.sig');
      expect(
        await fake.obterAtestadoOidcJwt(),
        equals('eyJhbGciOiJSUzI1NiJ9.payload.sig'),
      );

      final assinatura = await fake.signDocument([1, 2, 3, 4]);
      expect(assinatura.length, greaterThan(20));

      expect(await fake.getPdfSigner(), isNotNull);
      fake.biometriaAutorizada = false;
      await expectLater(fake.getPdfSigner(), throwsException);

      final fakeFalha = CryptoServiceFake(deveFalharGeracaoChaves: true);
      await expectLater(fakeFalha.generateAndStoreKeysIfNeeded(), throwsException);
      await expectLater(fakeFalha.getPublicKeyPem(), throwsException);
      await expectLater(fakeFalha.getPrivateKeyPem(), throwsException);
      await expectLater(
        fakeFalha.generateX509Certificate('Renato'),
        throwsException,
      );
      await expectLater(fakeFalha.signDocument([1]), throwsException);
    });
  });
}
