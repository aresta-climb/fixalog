// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:xml/xml.dart';

/// Serviço responsável por gerar e validar assinaturas digitais W3C XML-DSig para containers EPUB 3.
///
/// Adere à especificação W3C XML Signature (RFC 3275) e EPUB Open Container Format (OCF),
/// calculando digests SHA-256 de todos os recursos (XHTML, CSS, imagens WebP, vídeos MP4, Protobuf)
/// e envelopando a assinatura criptográfica com chaves ECDSA secp256r1.
class XmlDsigSigner {
  /// Gera o documento XML para `META-INF/signatures.xml` assinando a lista de [arquivos] fornecida.
  Future<String> gerarAssinaturaXml({
    required Map<String, List<int>> arquivos,
    required String privateKeyPem,
    String? certificadoX509Pem,
  }) async {
    final bufferSignedInfo = StringBuffer();
    bufferSignedInfo.writeln('<SignedInfo xmlns="http://www.w3.org/2000/09/xmldsig#">');
    bufferSignedInfo.writeln('  <CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>');
    bufferSignedInfo.writeln('  <SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha256"/>');

    // Ordena as chaves para canonicidade determinística
    final caminhosOrdenados = arquivos.keys.toList()..sort();
    for (final caminho in caminhosOrdenados) {
      final bytesArquivo = arquivos[caminho]!;
      final digestBytes = sha256.convert(bytesArquivo).bytes;
      final digestBase64 = base64.encode(digestBytes);

      bufferSignedInfo.writeln('  <Reference URI="$caminho">');
      bufferSignedInfo.writeln('    <DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>');
      bufferSignedInfo.writeln('    <DigestValue>$digestBase64</DigestValue>');
      bufferSignedInfo.writeln('  </Reference>');
    }
    bufferSignedInfo.write('</SignedInfo>');

    final signedInfoXml = bufferSignedInfo.toString();

    // Assina os bytes de SignedInfo com a chave privada ECDSA
    final privateKey = CryptoUtils.ecPrivateKeyFromPem(privateKeyPem);
    final ecSignature = CryptoUtils.ecSign(
      privateKey,
      Uint8List.fromList(utf8.encode(signedInfoXml)),
      algorithmName: 'SHA-256/ECDSA',
    );
    final signatureValueBase64 = CryptoUtils.ecSignatureToBase64(ecSignature);

    // Monta o XML final de signatures.xml
    final bufferFinal = StringBuffer();
    bufferFinal.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    bufferFinal.writeln('<signatures xmlns="urn:oasis:names:tc:opendocument:xmlns:container">');
    bufferFinal.writeln('  <Signature xmlns="http://www.w3.org/2000/09/xmldsig#" id="FixalogSignature">');
    bufferFinal.writeln('    $signedInfoXml');
    bufferFinal.writeln('    <SignatureValue>$signatureValueBase64</SignatureValue>');

    if (certificadoX509Pem != null && certificadoX509Pem.isNotEmpty) {
      final certLimpo = certificadoX509Pem
          .replaceAll('-----BEGIN CERTIFICATE-----', '')
          .replaceAll('-----END CERTIFICATE-----', '')
          .replaceAll('\r', '')
          .replaceAll('\n', '')
          .trim();
      bufferFinal.writeln('    <KeyInfo>');
      bufferFinal.writeln('      <X509Data>');
      bufferFinal.writeln('        <X509Certificate>$certLimpo</X509Certificate>');
      bufferFinal.writeln('      </X509Data>');
      bufferFinal.writeln('    </KeyInfo>');
    }

    bufferFinal.writeln('  </Signature>');
    bufferFinal.writeln('</signatures>');

    return bufferFinal.toString();
  }

  /// Verifica a integridade dos [arquivos] e a validade da assinatura digital contida em [signaturesXml].
  bool verificarAssinatura({
    required String signaturesXml,
    required Map<String, List<int>> arquivos,
    required String publicKeyPem,
  }) {
    try {
      final doc = XmlDocument.parse(signaturesXml);
      final signatureElement = doc.findAllElements('Signature').firstOrNull;
      if (signatureElement == null) return false;

      final signedInfoElement = signatureElement.findElements('SignedInfo').firstOrNull;
      if (signedInfoElement == null) return false;

      final signatureValueElement = signatureElement.findElements('SignatureValue').firstOrNull;
      if (signatureValueElement == null) return false;

      // 1. Verifica os digests de cada <Reference>
      final references = signedInfoElement.findElements('Reference');
      for (final ref in references) {
        final uri = ref.getAttribute('URI');
        if (uri == null || !arquivos.containsKey(uri)) {
          return false;
        }

        final digestValueElement = ref.findElements('DigestValue').firstOrNull;
        if (digestValueElement == null) return false;

        final digestEsperado = digestValueElement.innerText.trim();
        final bytesArquivo = arquivos[uri]!;
        final digestCalculado = base64.encode(sha256.convert(bytesArquivo).bytes);

        if (digestEsperado != digestCalculado) {
          return false;
        }
      }

      // 2. Verifica a assinatura criptográfica ECDSA de <SignedInfo>
      final signedInfoText = signedInfoElement.toXmlString();
      final sigValueBase64 = signatureValueElement.innerText.trim();
      final ecSig = CryptoUtils.ecSignatureFromBase64(sigValueBase64);
      final publicKey = CryptoUtils.ecPublicKeyFromPem(publicKeyPem);

      return CryptoUtils.ecVerify(
        publicKey,
        Uint8List.fromList(utf8.encode(signedInfoText)),
        ecSig,
        algorithm: 'SHA-256/ECDSA',
      );
    } catch (_) {
      return false;
    }
  }
}
