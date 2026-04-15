import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../core/models/local/identity_record.dart';
import '../../../core/services/crypto_service.dart';

// Este provider inicializaria a database no app reale. Para o MVP, assumimos acesso ao Isar.
final isarProvider = Provider<Isar?>((ref) => throw UnimplementedError());

class IdentityFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  IdentityFormState({this.isLoading = false, this.errorMessage, this.isSuccess = false});

  IdentityFormState copyWith({bool? isLoading, String? errorMessage, bool? isSuccess}) {
    return IdentityFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class IdentityFormController extends StateNotifier<IdentityFormState> {
  final Isar? _isar;
  final CryptoService _cryptoService;

  IdentityFormController(this._isar, this._cryptoService) : super(IdentityFormState());

  Future<void> submitIdentity(String nome, String clube) async {
    if (nome.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Atenção. O nome não pode estar vazio.');
      return;
    }
    
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      // 1. Gera e guarda assimetricamente usando flutter_secure_storage
      await _cryptoService.generateAndStoreKeysIfNeeded();

      // 2. Persiste o Identidade no Isar
      if (_isar != null) {
        final identity = IdentityRecord()
          ..nome = nome
          ..clubeAssociacao = clube.isEmpty ? 'N/A' : clube
          ..dataRegistro = DateTime.now();

        await _isar!.writeTxn(() async {
          await _isar!.identityRecords.put(identity);
        });
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Falha durante registro: \$e');
    }
  }
}

final identityFormProvider = StateNotifierProvider<IdentityFormController, IdentityFormState>((ref) {
  final isar = ref.watch(isarProvider);
  final cryptoService = CryptoService();
  return IdentityFormController(isar, cryptoService);
});

final hasIdentityProvider = FutureProvider<bool>((ref) async {
  final isar = ref.watch(isarProvider);
  if (isar == null) return false;
  final count = await isar.identityRecords.count();
  return count > 0;
});

final currentIdentityProvider = FutureProvider<IdentityRecord?>((ref) async {
  final isar = ref.watch(isarProvider);
  if (isar == null) return null;
  return await isar.identityRecords.where().findFirst();
});
