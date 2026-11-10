// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:fixalog/core/services/xml_dsig_signer.dart';

void main() {
  group('XmlDsigSigner - Testes Unitários', () {
    late XmlDsigSigner assinador;
    late ECPrivateKey privateKey;
    late ECPublicKey publicKey;
    late String privateKeyPem;
    late String publicKeyPem;

    setUp(() {
      assinador = XmlDsigSigner();

      final keyPair = CryptoUtils.generateEcKeyPair();
      privateKey = keyPair.privateKey as ECPrivateKey;
      publicKey = keyPair.publicKey as ECPublicKey;

      privateKeyPem = CryptoUtils.encodeEcPrivateKeyToPem(privateKey);
      publicKeyPem = CryptoUtils.encodeEcPublicKeyToPem(publicKey);
    });

    test('gerarAssinaturaXml deve construir estrutura W3C XML-DSig completa com referências e atestado OIDC', () async {
      final arquivos = {
        'OEBPS/content.opf': utf8.encode('<package>manifesto</package>'),
        'OEBPS/relatorio.xhtml': utf8.encode('<html>corpo</html>'),
        'OEBPS/midias/foto.webp': [1, 2, 3, 4],
      };

      final xmlAssinatura = await assinador.gerarAssinaturaXml(
        arquivos: arquivos,
        privateKeyPem: privateKeyPem,
        publicKeyPem: publicKeyPem,
        certificadoX509Pem: '-----BEGIN CERTIFICATE-----\nMOCK_CERT\n-----END CERTIFICATE-----',
        atestadoOidcJwt: 'eyJhbGciOiJSUzI1NiJ9.payload.sig',
      );

      expect(xmlAssinatura, contains('xmlns="http://www.w3.org/2000/09/xmldsig#"'));
      expect(xmlAssinatura, contains('<SignedInfo'));
      expect(xmlAssinatura, contains('Algorithm="http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha256"'));
      expect(xmlAssinatura, contains('<SignatureValue>'));
      expect(xmlAssinatura, contains('<X509Certificate>MOCK_CERT</X509Certificate>'));
      expect(xmlAssinatura, contains('<PublicKeyPem>${publicKeyPem.trim()}</PublicKeyPem>'));
      expect(xmlAssinatura, contains('<OidcIdToken>eyJhbGciOiJSUzI1NiJ9.payload.sig</OidcIdToken>'));
      expect(
        assinador.extrairAtestadoOidcJwt(xmlAssinatura),
        equals('eyJhbGciOiJSUzI1NiJ9.payload.sig'),
      );

      for (final entrada in arquivos.entries) {
        final hashEsperado = base64.encode(sha256.convert(entrada.value).bytes);
        expect(xmlAssinatura, contains('URI="${entrada.key}"'));
        expect(xmlAssinatura, contains('<DigestValue>$hashEsperado</DigestValue>'));
      }
    });

    test('extrairAtestadoOidcJwt retorna null quando XML nao possui OidcIdToken ou eh malformado', () async {
      final xmlSemOidc = await assinador.gerarAssinaturaXml(
        arquivos: {'OEBPS/relatorio.xhtml': utf8.encode('<html/>')},
        privateKeyPem: privateKeyPem,
      );
      expect(assinador.extrairAtestadoOidcJwt(xmlSemOidc), isNull);
      expect(assinador.extrairAtestadoOidcJwt('<xml-invalido'), isNull);
    });

    test('verificarAssinatura deve retornar true para arquivos íntegros', () async {
      final arquivos = {
        'OEBPS/relatorio.xhtml': utf8.encode('<html>dados originais</html>'),
        'OEBPS/dados/registro.binarypb': [10, 20, 30],
      };

      final xmlAssinatura = await assinador.gerarAssinaturaXml(
        arquivos: arquivos,
        privateKeyPem: privateKeyPem,
      );

      final valida = assinador.verificarAssinatura(
        signaturesXml: xmlAssinatura,
        arquivos: arquivos,
        publicKeyPem: publicKeyPem,
      );

      expect(valida, isTrue);
    });

    test('verificarAssinatura deve retornar false se qualquer arquivo for alterado ou ausente', () async {
      final arquivos = {
        'OEBPS/relatorio.xhtml': utf8.encode('<html>dados originais</html>'),
      };

      final xmlAssinatura = await assinador.gerarAssinaturaXml(
        arquivos: arquivos,
        privateKeyPem: privateKeyPem,
      );

      final arquivosAdulterados = {
        'OEBPS/relatorio.xhtml': utf8.encode('<html>dados ADULTERADOS!</html>'),
      };

      expect(
        assinador.verificarAssinatura(
          signaturesXml: xmlAssinatura,
          arquivos: arquivosAdulterados,
          publicKeyPem: publicKeyPem,
        ),
        isFalse,
      );

      expect(
        assinador.verificarAssinatura(
          signaturesXml: xmlAssinatura,
          arquivos: const {},
          publicKeyPem: publicKeyPem,
        ),
        isFalse,
      );
      expect(
        assinador.verificarAssinatura(
          signaturesXml: '<invalido/>',
          arquivos: arquivos,
          publicKeyPem: publicKeyPem,
        ),
        isFalse,
      );
    });

    test('verificarAssinatura deve retornar false se chave pública for diferente', () async {
      final arquivos = {
        'OEBPS/relatorio.xhtml': utf8.encode('<html>dados originais</html>'),
      };

      final xmlAssinatura = await assinador.gerarAssinaturaXml(
        arquivos: arquivos,
        privateKeyPem: privateKeyPem,
      );

      final outroKeyPair = CryptoUtils.generateEcKeyPair();
      final outraPublicKeyPem = CryptoUtils.encodeEcPublicKeyToPem(outroKeyPair.publicKey as ECPublicKey);

      final valida = assinador.verificarAssinatura(
        signaturesXml: xmlAssinatura,
        arquivos: arquivos,
        publicKeyPem: outraPublicKeyPem,
      );

      expect(valida, isFalse);
    });
  });
}
