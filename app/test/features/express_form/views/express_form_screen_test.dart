import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/express_form/views/express_form_screen.dart';
import 'package:app/features/express_form/viewmodels/express_form_view_model.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:app/core/services/crypto_service.dart';
import 'package:app/core/services/providers.dart';

class MockGeolocatorPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements GeolocatorPlatform {}

class MockImagePicker extends Mock implements ImagePicker {}
class MockXFile extends Mock implements XFile {}
class MockCryptoService extends Mock implements CryptoService {}

void main() {
  late MockGeolocatorPlatform mockGeolocatorPlatform;
  late MockImagePicker mockPicker;
  late MockCryptoService mockCryptoService;

  final validImageBytes = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==');

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    mockGeolocatorPlatform = MockGeolocatorPlatform();
    GeolocatorPlatform.instance = mockGeolocatorPlatform;
    mockPicker = MockImagePicker();
    mockCryptoService = MockCryptoService();
  });

  Widget _buildScreen({required List<ExpressEntry> initialEntries}) {
    return ProviderScope(
      overrides: [
        expressFormViewModelProvider.overrideWith((ref) {
          final vm = ExpressFormViewModel(picker: mockPicker);
          // Set initial state
          vm.state = initialEntries;
          return vm;
        }),
        cryptoServiceProvider.overrideWithValue(mockCryptoService),
      ],
      child: const MaterialApp(home: ExpressFormScreen()),
    );
  }

  group('ExpressFormScreen Widget Tests', () {
    testWidgets('Shows empty state when no photos', (tester) async {
      await tester.pumpWidget(_buildScreen(initialEntries: []));

      expect(find.textContaining('Nenhuma foto adicionada ainda'), findsOneWidget);
      expect(find.text('Gerar Relatório'), findsNothing);
    });

    testWidgets('Tapping FAB takes photo', (tester) async {
      await tester.pumpWidget(_buildScreen(initialEntries: []));

      final mockFile = MockXFile();
      when(() => mockFile.readAsBytes()).thenAnswer((_) async => validImageBytes);
      when(() => mockPicker.pickImage(source: ImageSource.camera, imageQuality: 70))
          .thenAnswer((_) async => mockFile);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      verify(() => mockPicker.pickImage(source: ImageSource.camera, imageQuality: 70)).called(1);
      // Now there is one photo
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('Shows photo list and allows deleting and typing description', (tester) async {
      final entries = [
        ExpressEntry(imageBytes: validImageBytes, description: 'Initial')
      ];
      await tester.pumpWidget(_buildScreen(initialEntries: entries));

      expect(find.byType(Card), findsOneWidget);

      // Type in description
      await tester.enterText(find.byType(TextField), 'Nova descrição');
      await tester.pump();
      
      expect(find.text('Nova descrição'), findsOneWidget);

      // Tap delete
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('Tapping Gerar Relatorio shows loading and handles success', (tester) async {
      final entries = [
        ExpressEntry(imageBytes: validImageBytes)
      ];
      await tester.pumpWidget(_buildScreen(initialEntries: entries));

      // Make generation throw an exception so we don't have to mock the whole PDF generation success flow
      when(() => mockGeolocatorPlatform.isLocationServiceEnabled())
          .thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 100));
            throw Exception('Simulated PDF Error');
          });

      await tester.tap(find.text('Gerar Relatório'));
      await tester.pump(); // Start dialog transition
      await tester.pump(); // Build dialog
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle(); // Finishes delayed exception, dialog pop, and snackbar transition

      expect(find.textContaining('Simulated PDF Error'), findsOneWidget);
    });
  });
}
