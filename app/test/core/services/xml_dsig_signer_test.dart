// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:fixlog/core/services/xml_dsig_signer.dart';

void main() {
  group('XmlDsigSigner - Testes Unitários', () {
    late XmlDsigSigner assinador;
    late ECPrivateKey privateKey;
    late ECPublicKey publicKey;
    late String privateKeyPem;
    late String publicKeyPem;

    setUp(() {
      assinador = XmlDsigSigner();

      // Gera um par de chaves ECDSA secp256r1 em memória para os testes
      final keyPair = CryptoUtils.generateEcKeyPair();
      privateKey = keyPair.privateKey as ECPrivateKey;
      publicKey = keyPair.publicKey as ECPublicKey;

      privateKeyPem = CryptoUtils.encodeEcPrivateKeyToPem(privateKey);
      publicKeyPem = CryptoUtils.encodeEcPublicKeyToPem(publicKey);
    });

    test('gerarAssinaturaXml deve construir estrutura W3C XML-DSig completa com referências corretas', () async {
      final arquivos = {
        'OEBPS/content.opf': utf8.encode('<package>manifesto</package>'),
        'OEBPS/relatorio.xhtml': utf8.encode('<html>corpo</html>'),
        'OEBPS/midias/foto.webp': [1, 2, 3, 4],
      };

      final xmlAssinatura = await assinador.gerarAssinaturaXml(
        arquivos: arquivos,
        privateKeyPem: privateKeyPem,
        certificadoX509Pem: '-----BEGIN CERTIFICATE-----\nMOCK_CERT\n-----END CERTIFICATE-----',
      );

      expect(xmlAssinatura, contains('xmlns="http://www.w3.org/2000/09/xmldsig#"'));
      expect(xmlAssinatura, contains('<SignedInfo'));
      expect(xmlAssinatura, contains('Algorithm="http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha256"'));
      expect(xmlAssinatura, contains('<SignatureValue>'));
      expect(xmlAssinatura, contains('<X509Certificate>MOCK_CERT</X509Certificate>'));

      // Verifica cada referência e seu hash SHA-256
      for (final entrada in arquivos.entries) {
        final hashEsperado = base64.encode(sha256.convert(entrada.value).bytes);
        expect(xmlAssinatura, contains('URI="${entrada.key}"'));
        expect(xmlAssinatura, contains('<DigestValue>$hashEsperado</DigestValue>'));
      }
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

    test('verificarAssinatura deve retornar false se qualquer arquivo for alterado', () async {
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

      final valida = assinador.verificarAssinatura(
        signaturesXml: xmlAssinatura,
        arquivos: arquivosAdulterados,
        publicKeyPem: publicKeyPem,
      );

      expect(valida, isFalse);
    });

    test('verificarAssinatura deve retornar false se chave pública for diferente', () async {
      final arquivos = {
        'OEBPS/relatorio.xhtml': utf8.encode('<html>dados originais</html>'),
      };

      final xmlAssinatura = await assinador.gerarAssinaturaXml(
        arquivos: arquivos,
        privateKeyPem: privateKeyPem,
      );

      // Gera outra chave pública
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
