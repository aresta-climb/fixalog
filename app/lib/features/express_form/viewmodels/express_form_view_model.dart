import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class ExpressEntry {
  final Uint8List imageBytes;
  final String description;
  final bool isVideo;

  ExpressEntry({
    required this.imageBytes,
    this.description = '',
    this.isVideo = false,
  });

  ExpressEntry copyWith({
    Uint8List? imageBytes,
    String? description,
    bool? isVideo,
  }) {
    return ExpressEntry(
      imageBytes: imageBytes ?? this.imageBytes,
      description: description ?? this.description,
      isVideo: isVideo ?? this.isVideo,
    );
  }
}

class ExpressFormViewModel extends StateNotifier<List<ExpressEntry>> {
  final ImagePicker _picker;

  ExpressFormViewModel({ImagePicker? picker}) : _picker = picker ?? ImagePicker(), super([]);

  Future<void> takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      state = [...state, ExpressEntry(imageBytes: bytes)];
    }
  }

  void updateDescription(int index, String newDescription) {
    if (index >= 0 && index < state.length) {
      final updatedList = List<ExpressEntry>.from(state);
      updatedList[index] = updatedList[index].copyWith(description: newDescription);
      state = updatedList;
    }
  }

  void removeEntry(int index) {
    if (index >= 0 && index < state.length) {
      final updatedList = List<ExpressEntry>.from(state);
      updatedList.removeAt(index);
      state = updatedList;
    }
  }
}

final expressFormViewModelProvider = StateNotifierProvider<ExpressFormViewModel, List<ExpressEntry>>((ref) {
  return ExpressFormViewModel();
});
