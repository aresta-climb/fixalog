import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/features/express_form/viewmodels/express_form_view_model.dart';
import 'package:cross_file/cross_file.dart';

class MockImagePicker extends Mock implements ImagePicker {}
class MockXFile extends Mock implements XFile {}

void main() {
  late MockImagePicker mockPicker;
  late ExpressFormViewModel viewModel;

  setUp(() {
    mockPicker = MockImagePicker();
    viewModel = ExpressFormViewModel(picker: mockPicker);
  });

  group('ExpressFormViewModel', () {
    test('Initial state is empty', () {
      expect(viewModel.state, isEmpty);
    });

    test('takePhoto should add an entry if photo is taken', () async {
      final mockFile = MockXFile();
      when(() => mockFile.readAsBytes()).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));
      when(() => mockPicker.pickImage(source: ImageSource.camera, imageQuality: 70))
          .thenAnswer((_) async => mockFile);

      await viewModel.takePhoto();

      expect(viewModel.state.length, 1);
      expect(viewModel.state.first.imageBytes, [1, 2, 3]);
      expect(viewModel.state.first.description, isEmpty);
    });

    test('takePhoto should do nothing if photo is null (cancelled)', () async {
      when(() => mockPicker.pickImage(source: ImageSource.camera, imageQuality: 70))
          .thenAnswer((_) async => null);

      await viewModel.takePhoto();

      expect(viewModel.state, isEmpty);
    });

    test('updateDescription should update description if index is valid', () {
      viewModel.state = [ExpressEntry(imageBytes: Uint8List.fromList([1]))];
      
      viewModel.updateDescription(0, 'Nova descrição');

      expect(viewModel.state[0].description, 'Nova descrição');
    });

    test('updateDescription should do nothing if index is invalid', () {
      viewModel.state = [ExpressEntry(imageBytes: Uint8List.fromList([1]))];
      
      viewModel.updateDescription(1, 'Nova descrição');

      expect(viewModel.state[0].description, isEmpty);
    });

    test('removeEntry should remove entry if index is valid', () {
      viewModel.state = [
        ExpressEntry(imageBytes: Uint8List.fromList([1])),
        ExpressEntry(imageBytes: Uint8List.fromList([2])),
      ];
      
      viewModel.removeEntry(0);

      expect(viewModel.state.length, 1);
      expect(viewModel.state[0].imageBytes, [2]);
    });

    test('removeEntry should do nothing if index is invalid', () {
      viewModel.state = [ExpressEntry(imageBytes: Uint8List.fromList([1]))];
      
      viewModel.removeEntry(1);

      expect(viewModel.state.length, 1);
    });
    
    test('copyWith on ExpressEntry with no parameters returns same values', () {
       final entry = ExpressEntry(imageBytes: Uint8List.fromList([1]), description: 'Test');
       final copy = entry.copyWith();
       
       expect(copy.imageBytes, [1]);
       expect(copy.description, 'Test');
    });
  });
}
