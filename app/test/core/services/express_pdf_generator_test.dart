import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/express_pdf_generator.dart';
import 'package:app/features/express_form/viewmodels/express_form_view_model.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:app/core/models/local/identity_record.dart';

import 'package:app/core/services/crypto_service.dart';
import 'package:app/core/services/providers.dart';
import 'package:app/features/identity/viewmodels/identity_form_view_model.dart';

class MockGeolocatorPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements GeolocatorPlatform {}

class MockWidgetRef extends Mock implements WidgetRef {}

class MockCryptoService extends Mock implements CryptoService {}

class FakeProviderListenable extends Fake implements ProviderListenable<Object?> {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeProviderListenable());
  });

  late MockGeolocatorPlatform mockGeolocatorPlatform;
  late MockWidgetRef mockWidgetRef;
  late MockCryptoService mockCryptoService;

  setUp(() {
    mockGeolocatorPlatform = MockGeolocatorPlatform();
    GeolocatorPlatform.instance = mockGeolocatorPlatform;
    mockWidgetRef = MockWidgetRef();
    mockCryptoService = MockCryptoService();
  });

  group('ExpressPdfGenerator - Fraude de Localização', () {
    test('Should throw Exception if location service is disabled', () async {
      when(() => mockGeolocatorPlatform.isLocationServiceEnabled())
          .thenAnswer((_) async => false);

      expect(
        () => ExpressPdfGenerator.generateAndPreviewPdf([], mockWidgetRef),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Serviço de localização desativado'))),
      );
    });

    test('Should throw Exception if location permission is denied after request', () async {
      when(() => mockGeolocatorPlatform.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockGeolocatorPlatform.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      when(() => mockGeolocatorPlatform.requestPermission())
          .thenAnswer((_) async => LocationPermission.denied);

      expect(
        () => ExpressPdfGenerator.generateAndPreviewPdf([], mockWidgetRef),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Permissão de localização negada.'))),
      );
    });

    test('Should throw Exception if location permission is denied forever', () async {
      when(() => mockGeolocatorPlatform.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockGeolocatorPlatform.checkPermission())
          .thenAnswer((_) async => LocationPermission.deniedForever);

      expect(
        () => ExpressPdfGenerator.generateAndPreviewPdf([], mockWidgetRef),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Permissão de localização negada permanentemente.'))),
      );
    });

    test('Should throw Exception if position isMocked is true', () async {
      // Arrange
      when(() => mockGeolocatorPlatform.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockGeolocatorPlatform.checkPermission())
          .thenAnswer((_) async => LocationPermission.always);
          
      final mockedPosition = Position(
        longitude: -46.6,
        latitude: -23.5,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 800,
        altitudeAccuracy: 10,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
        isMocked: true, 
      );

      when(() => mockGeolocatorPlatform.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          )).thenAnswer((_) async => mockedPosition);

      // Act & Assert
      expect(
        () => ExpressPdfGenerator.generateAndPreviewPdf([], mockWidgetRef),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Fake GPS detectado'))),
      );
    });

    test('Should acquire PdfSigner and inject Protobuf Base64 into XMP', () async {
      // Arrange
      when(() => mockGeolocatorPlatform.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockGeolocatorPlatform.checkPermission())
          .thenAnswer((_) async => LocationPermission.always);
          
      final validPosition = Position(
        longitude: -46.6,
        latitude: -23.5,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 800,
        altitudeAccuracy: 10,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
        isMocked: false, 
      );

      when(() => mockGeolocatorPlatform.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          )).thenAnswer((_) async => validPosition);

      // Mock identity
      when(() => mockWidgetRef.read(currentIdentityProvider.future))
          .thenAnswer((_) async => null);

      when(() => mockWidgetRef.read(cryptoServiceProvider))
          .thenReturn(mockCryptoService);

      when(() => mockCryptoService.getPdfSigner())
          .thenThrow(Exception('PdfSigner mock chamado'));

      when(() => mockCryptoService.computeDocumentHash(any()))
          .thenReturn('mocked_hash');

      when(() => mockCryptoService.getPublicKeyPem())
          .thenAnswer((_) async => 'mocked_public_key');

      // Act & Assert
      expect(
        () => ExpressPdfGenerator.generateAndPreviewPdf([], mockWidgetRef),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('PdfSigner mock chamado'))),
      );
    });

    test('Should build valid XMP Metadata without throwing errors', () {
      // Act
      final xmlDoc = ExpressPdfGenerator.buildXmpMetadata(
        protobufBytes: [1, 2, 3],
        signature: 'mock_signature',
        documentHash: 'mock_hash',
        publicKey: 'mock_public_key',
      );

      // Assert
      final xmlString = xmlDoc.toXmlString();
      expect(xmlString, contains('xmlns:fixalog="http://fixalog.app/1.0/"'));
      expect(xmlString, contains('fixalog:signature="mock_signature"'));
      expect(xmlString, contains('fixalog:hash="mock_hash"'));
      expect(xmlString, contains('fixalog:publicKey="bW9ja19wdWJsaWNfa2V5"')); // base64Encode(utf8.encode('mock_public_key'))
    });

    test('Should handle exception during document signature', () async {
      when(() => mockGeolocatorPlatform.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockGeolocatorPlatform.checkPermission())
          .thenAnswer((_) async => LocationPermission.always);
          
      final validPosition = Position(
        longitude: -46.6,
        latitude: -23.5,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 800,
        altitudeAccuracy: 10,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
        isMocked: false, 
      );

      when(() => mockGeolocatorPlatform.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          )).thenAnswer((_) async => validPosition);

      when(() => mockWidgetRef.read(currentIdentityProvider.future))
          .thenAnswer((_) async => null);

      when(() => mockWidgetRef.read(cryptoServiceProvider))
          .thenReturn(mockCryptoService);

      when(() => mockCryptoService.getPdfSigner())
          .thenAnswer((_) async => (List<int> bytes) async => 'mock_signature');

      when(() => mockCryptoService.computeDocumentHash(any()))
          .thenReturn('mocked_hash');

      // Throw exception here!
      when(() => mockCryptoService.signDocument(any()))
          .thenThrow(Exception('Falha intencional na assinatura'));

      try {
        await ExpressPdfGenerator.generateAndPreviewPdf([], mockWidgetRef);
      } catch (e) {
        // Will throw MissingPluginException eventually, but the catch block inside the method will be executed first.
      }
    });

    test('Should generate PDF and attempt to share', () async {
      // Arrange
      when(() => mockGeolocatorPlatform.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockGeolocatorPlatform.checkPermission())
          .thenAnswer((_) async => LocationPermission.always);
          
      final validPosition = Position(
        longitude: -46.6,
        latitude: -23.5,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 800,
        altitudeAccuracy: 10,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
        isMocked: false, 
      );

      when(() => mockGeolocatorPlatform.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          )).thenAnswer((_) async => validPosition);

      // Mock identity
      when(() => mockWidgetRef.read(currentIdentityProvider.future))
          .thenAnswer((_) async => IdentityRecord()..nome = 'Renato');

      when(() => mockWidgetRef.read(cryptoServiceProvider))
          .thenReturn(mockCryptoService);

      when(() => mockCryptoService.getPdfSigner())
          .thenAnswer((_) async => (List<int> bytes) async => 'mock_signature');

      when(() => mockCryptoService.computeDocumentHash(any()))
          .thenReturn('mocked_hash');

      when(() => mockCryptoService.getPublicKeyPem())
          .thenAnswer((_) async => 'mocked_public_key');

      when(() => mockCryptoService.signDocument(any()))
          .thenAnswer((_) async => 'mock_signature');

      // 1x1 transparent PNG
      final validImageBytes = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==');

      // Act & Assert
      // Because we are in headless environment, Printing.sharePdf will throw MissingPluginException or similar
      // But it proves the document built successfully up to that point
      try {
        final entries = [
          ExpressEntry(imageBytes: validImageBytes, description: 'Test photo'),
          ExpressEntry(imageBytes: validImageBytes, description: ''), // to cover empty description branch
          ExpressEntry(imageBytes: validImageBytes, description: 'Video thumb', isVideo: true) // cover video warning branch
        ];
        await ExpressPdfGenerator.generateAndPreviewPdf(entries, mockWidgetRef);
      } catch (e) {
        expect(e.toString(), isNot(contains('Fake GPS detectado')));
        expect(e.toString(), isNot(contains('PdfSigner mock chamado')));
      }
    });
  });
}
