import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/models/local/app_config_record.dart';
import '../../identity/views/identity_setup_screen.dart';
import '../../identity/viewmodels/identity_form_view_model.dart';
import '../../home/views/home_screen.dart';

// Version of the terms of use. Increment this if the terms change significantly.
const int kCurrentTermsVersion = 1;

class TermsOfUseScreen extends ConsumerStatefulWidget {
  const TermsOfUseScreen({super.key});

  @override
  ConsumerState<TermsOfUseScreen> createState() => _TermsOfUseScreenState();
}

class _TermsOfUseScreenState extends ConsumerState<TermsOfUseScreen> {
  bool _isLoading = false;

  Future<void> _acceptAndContinue() async {
    setState(() => _isLoading = true);

    // Request permissions
    await [
      Permission.camera,
      Permission.locationWhenInUse,
    ].request();

    // Save accepted version
    final isar = ref.read(isarProvider);
    if (isar != null) {
      await isar.writeTxn(() async {
        var config = await isar.appConfigRecords.get(1);
        config ??= AppConfigRecord();
        config.acceptedTermsVersion = kCurrentTermsVersion;
        await isar.appConfigRecords.put(config);
      });
    }

    if (!mounted) return;

    // Check if identity exists
    final hasIdentity = await ref.read(hasIdentityProvider.future);
    
    if (!mounted) return;

    if (hasIdentity) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const IdentitySetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Termos de Uso')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.privacy_tip_outlined, size: 64, color: Color(0xFFFF6B00)),
            const SizedBox(height: 24),
            Text(
              'Por que precisamos da sua Câmera e do GPS?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontFamily: 'SpaceGrotesk'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'O FixaLog é uma ferramenta de auditoria de manutenções em vias de escalada. '
              'Para gerar relatórios confiáveis e úteis para a comunidade, este aplicativo coleta evidências '
              'fotográficas de cada ancoragem modificada, além de registrar a exata localização (GPS) onde a foto foi tirada.\n\n'
              'Sua câmera e localização são usadas exclusivamente para a montagem deste relatório (exportado em PDF).',
              style: TextStyle(fontSize: 16, height: 1.5, fontFamily: 'Inter'),
            ),
            const Spacer(),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _acceptAndContinue,
                child: const Text('Entendi, Aceitar e Continuar'),
              ),
          ],
        ),
      ),
    );
  }
}
