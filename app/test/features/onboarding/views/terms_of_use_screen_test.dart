import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/onboarding/views/terms_of_use_screen.dart';
import 'package:app/features/identity/viewmodels/identity_form_view_model.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:app/core/models/local/app_config_record.dart';

class FakeAppConfigCollection extends Fake
    implements IsarCollection<AppConfigRecord> {
  bool returnNullOnGet = true;
  int putCalls = 0;

  @override
  Future<AppConfigRecord?> get(int id) async {
    return returnNullOnGet
        ? null
        : (AppConfigRecord()..acceptedTermsVersion = 0);
  }

  @override
  Future<int> put(AppConfigRecord object) async {
    putCalls++;
    return 1;
  }
}

class FakeIsar extends Fake implements Isar {
  final FakeAppConfigCollection fakeCollection = FakeAppConfigCollection();

  @override
  IsarCollection<T> collection<T>() {
    if (T == AppConfigRecord) {
      return fakeCollection as IsarCollection<T>;
    }
    throw UnimplementedError();
  }

  @override
  Future<T> writeTxn<T>(Future<T> Function() callback, {bool silent = false}) {
    return callback();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'requestPermissions') {
              return {1: 1, 3: 1}; // Camera and Location granted
            }
            return null;
          },
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          null,
        );
  });

  testWidgets('Should display terms and handle accept flow (identity exists)', (
    WidgetTester tester,
  ) async {
    final fakeIsar = FakeIsar();
    fakeIsar.fakeCollection.returnNullOnGet = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hasIdentityProvider.overrideWith((ref) => Future.value(true)),
          isarProvider.overrideWithValue(fakeIsar),
        ],
        child: const MaterialApp(home: TermsOfUseScreen()),
      ),
    );

    expect(find.text('Termos de Uso'), findsOneWidget);
    expect(find.text('Entendi, Aceitar e Continuar'), findsOneWidget);

    await tester.tap(find.text('Entendi, Aceitar e Continuar'));
    await tester.pump(); // Start loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle(); // Finish nav

    // Since hasIdentity is true, it should navigate to HomeScreen
    expect(find.text('Novo Protocolo'), findsWidgets); // HomeScreen bottom bar
    expect(fakeIsar.fakeCollection.putCalls, 1);
  });

  testWidgets('Should handle accept flow (no identity)', (
    WidgetTester tester,
  ) async {
    final fakeIsar = FakeIsar();
    fakeIsar.fakeCollection.returnNullOnGet = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hasIdentityProvider.overrideWith((ref) => Future.value(false)),
          isarProvider.overrideWithValue(fakeIsar),
        ],
        child: const MaterialApp(home: TermsOfUseScreen()),
      ),
    );

    await tester.tap(find.text('Entendi, Aceitar e Continuar'));
    await tester.pumpAndSettle();

    // Since hasIdentity is false, it should navigate to IdentitySetupScreen
    expect(
      find.byIcon(Icons.credit_card_outlined),
      findsOneWidget,
    ); // Identity setup screen icon
    expect(fakeIsar.fakeCollection.putCalls, 1);
  });
}
