import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/core/services/crypto_service.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:local_auth/local_auth.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  late CryptoService cryptoService;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockLocalAuthentication mockLocalAuth;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    mockLocalAuth = MockLocalAuthentication();
    // Assuming we refactor CryptoService to take dependencies via constructor
    cryptoService = CryptoService(
      secureStorage: mockSecureStorage,
      localAuth: mockLocalAuth,
    );
  });

  group('ECDSA Key Generation & Storage', () {
    test('Should generate and store ECDSA keys when none exist', () async {
      // Arrange
      when(() => mockSecureStorage.read(key: 'private_key'))
          .thenAnswer((_) async => null);
      when(() => mockSecureStorage.write(key: 'private_key', value: any(named: 'value')))
          .thenAnswer((_) async {});
      when(() => mockSecureStorage.write(key: 'public_key', value: any(named: 'value')))
          .thenAnswer((_) async {});

      // Act
      await cryptoService.generateAndStoreKeysIfNeeded();

      // Assert
      verify(() => mockSecureStorage.read(key: 'private_key')).called(1);
      
      // Verify that write was called with PEM formatted keys
      final capturedPrivate = verify(() => mockSecureStorage.write(
        key: 'private_key', 
        value: captureAny(named: 'value')
      )).captured;
      final capturedPublic = verify(() => mockSecureStorage.write(
        key: 'public_key', 
        value: captureAny(named: 'value')
      )).captured;

      expect(capturedPrivate.first as String, contains('BEGIN EC PRIVATE KEY')); // basic_utils PEM format
      expect(capturedPublic.first as String, contains('BEGIN PUBLIC KEY'));
    });

    test('Should not generate new keys if private_key already exists', () async {
      // Arrange
      when(() => mockSecureStorage.read(key: 'private_key'))
          .thenAnswer((_) async => 'some_existing_pem');

      // Act
      await cryptoService.generateAndStoreKeysIfNeeded();

      // Assert
      verify(() => mockSecureStorage.read(key: 'private_key')).called(1);
      verifyNever(() => mockSecureStorage.write(key: 'private_key', value: any(named: 'value')));
      verifyNever(() => mockSecureStorage.write(key: 'public_key', value: any(named: 'value')));
    });
  });

  group('X.509 Certificate Generation', () {
    test('Should generate a valid Self-Signed X.509 Certificate', () async {
      // Arrange
      // Mock the storage to return valid PEMs so the service can read them to generate the cert
      final keyPair = CryptoUtils.generateEcKeyPair();
      final privateKeyPem = CryptoUtils.encodeEcPrivateKeyToPem(keyPair.privateKey as ECPrivateKey);
      final publicKeyPem = CryptoUtils.encodeEcPublicKeyToPem(keyPair.publicKey as ECPublicKey);

      when(() => mockSecureStorage.read(key: 'private_key'))
          .thenAnswer((_) async => privateKeyPem);
      when(() => mockSecureStorage.read(key: 'public_key'))
          .thenAnswer((_) async => publicKeyPem);

      // Act
      final certPem = await cryptoService.generateX509Certificate('Renato');

      // Assert
      expect(certPem, isNotNull);
      expect(certPem, contains('BEGIN CERTIFICATE'));
      
      // Parse the cert to verify its subject
      final x509 = X509Utils.x509CertificateFromPem(certPem);
      expect(x509.subject, containsPair('2.5.4.3', 'Renato')); // CN
      expect(x509.subject, containsPair('2.5.4.10', 'FixaLog')); // O
      when(() => mockSecureStorage.read(key: 'public_key'))
          .thenAnswer((_) async => null);

      expect(() => cryptoService.generateX509Certificate('Renato'), throwsException);
    });
  });

  group('PdfSigner & Biometrics', () {
    test('Should return PdfSigner when biometric authentication succeeds', () async {
      // Arrange
      final keyPair = CryptoUtils.generateEcKeyPair();
      final privateKeyPem = CryptoUtils.encodeEcPrivateKeyToPem(keyPair.privateKey as ECPrivateKey);

      when(() => mockSecureStorage.read(key: 'private_key'))
          .thenAnswer((_) async => privateKeyPem);
          
      when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
          )).thenAnswer((_) async => true);

      // Act
      final signer = await cryptoService.getPdfSigner();

      // Assert
      expect(signer, isNotNull);
      verify(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
          )).called(1);
    });

    test('Should throw Exception when biometric authentication fails', () async {
      // Arrange
      when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
          )).thenAnswer((_) async => false);

      // Act & Assert
      expect(() => cryptoService.getPdfSigner(), throwsException);
    });

    test('Should throw Exception in getPdfSigner if private key is missing', () async {
      when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
          )).thenAnswer((_) async => true);
      when(() => mockSecureStorage.read(key: 'private_key')).thenAnswer((_) async => null);

      expect(() => cryptoService.getPdfSigner(), throwsException);
    });
  });

  group('Sign Document and PublicKey', () {
    test('Should sign document using real ECDSA', () async {
      final keyPair = CryptoUtils.generateEcKeyPair();
      final privateKeyPem = CryptoUtils.encodeEcPrivateKeyToPem(keyPair.privateKey as ECPrivateKey);

      when(() => mockSecureStorage.read(key: 'private_key'))
          .thenAnswer((_) async => privateKeyPem);

      final signatureBase64 = await cryptoService.signDocument([1, 2, 3]);

      expect(signatureBase64, isNotNull);
      expect(signatureBase64.length, greaterThan(20)); // Base64 encoded ASN.1 DER is around 96 bytes
    });

    test('Should throw Exception in signDocument if private key is missing', () async {
      when(() => mockSecureStorage.read(key: 'private_key')).thenAnswer((_) async => null);
      expect(() => cryptoService.signDocument([1, 2, 3]), throwsException);
    });

    test('Should get PublicKeyPem successfully', () async {
      when(() => mockSecureStorage.read(key: 'public_key'))
          .thenAnswer((_) async => 'mocked_public_key');

      final pub = await cryptoService.getPublicKeyPem();

      expect(pub, 'mocked_public_key');
    });

    test('Should throw Exception in getPublicKeyPem if public key is missing', () async {
      when(() => mockSecureStorage.read(key: 'public_key')).thenAnswer((_) async => null);
      expect(() => cryptoService.getPublicKeyPem(), throwsException);
    });

    test('Should compute document hash correctly', () {
      final docBytes = [1, 2, 3, 4, 5];
      final hash = cryptoService.computeDocumentHash(docBytes);
      // SHA-256 of [1, 2, 3, 4, 5]
      expect(hash, '74f81fe167d99b4cb41d6d0ccda82278caee9f3e2f25d5e5a3936ff3dcec60d0');
    });
  });

  test('Should initialize with default instances when parameters are null', () {
    final service = CryptoService();
    expect(service, isNotNull);
  });
}
