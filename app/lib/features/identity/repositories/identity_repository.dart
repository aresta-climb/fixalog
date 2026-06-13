import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../core/models/local/identity_record.dart';
import '../viewmodels/identity_form_view_model.dart' show isarProvider;

// Import local do isarProvider que atualmente mora no main ou controller
// Vamos defini-lo aqui temporariamente até termos um core/providers,
// ou simplesmente importar do controller antigo por enquanto.
// Como o isarProvider está no identity_form_controller.dart atualmente,
// precisamos repensar onde ele mora. 
// O ideal é definir isarProvider em um arquivo no core.
// Por hora, declararemos a interface e implementação.

abstract class IdentityRepository {
  Future<bool> hasIdentity();
  Future<IdentityRecord?> getCurrentIdentity();
  Future<void> saveIdentity(IdentityRecord identity);
}

class IsarIdentityRepository implements IdentityRepository {
  final Isar? _isar;

  IsarIdentityRepository(this._isar);

  @override
  Future<bool> hasIdentity() async {
    if (_isar == null) return false;
    final count = await _isar!.identityRecords.count();
    return count > 0;
  }

  @override
  Future<IdentityRecord?> getCurrentIdentity() async {
    if (_isar == null) return null;
    return await _isar!.identityRecords.where().findFirst();
  }

  @override
  Future<void> saveIdentity(IdentityRecord identity) async {
    if (_isar == null) throw Exception('Isar instance is null');
    await _isar!.writeTxn(() async {
      await _isar!.identityRecords.put(identity);
    });
  }
}

// TODO: isarProvider currently lives in the identity controller/viewmodel.
// Import it dynamically or move it to a core file later.

final identityRepositoryProvider = Provider<IdentityRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return IsarIdentityRepository(isar);
});
