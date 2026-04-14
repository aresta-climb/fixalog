import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/wizard/views/wizard_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: FixaLogApp(),
    ),
  );
}

class FixaLogApp extends StatelessWidget {
  const FixaLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixaLog',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121416), // Surface Noise Background
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B00), // Rescue Orange
          primaryContainer: Color(0xFFFF6B00),
          onPrimaryContainer: Colors.black, // High contrast text on orange
          secondary: Color(0xFF4F6D44), // Moss Green
          surface: Color(0xFF1A1C1E), // Surface-container-low
          surfaceContainerHighest: Color(0xFF333537),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontFamily: 'SpaceGrotesk', letterSpacing: -0.02),
          bodyMedium: TextStyle(fontFamily: 'Inter'),
          labelMedium: TextStyle(fontFamily: 'SpaceGrotesk', textBaseline: TextBaseline.alphabetic),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B00),
            foregroundColor: Colors.black, // on_primary_container
            minimumSize: const Size(double.infinity, 56), // Hit area for gloved hands
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // xl radius
            elevation: 0, 
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF333537), // surface_container_highest
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFF6B00), width: 2),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
      ),
      home: const DummyHomeScreen(),
    );
  }
}

class DummyHomeScreen extends StatelessWidget {
  const DummyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Protocolos FixaLog'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WizardScreen()));
              },
              child: const Text('NOVA MANUTENÇÃO'),
            ),
          ],
        ),
      ),
    );
  }
}
