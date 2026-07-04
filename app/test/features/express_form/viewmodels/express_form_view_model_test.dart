import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/features/express_form/viewmodels/express_form_view_model.dart';

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

    test('takePhoto should add an entry with mediaPath if photo is taken', () async {
      final mockFile = MockXFile();
      when(() => mockFile.path).thenReturn('/tmp/foto.jpg');
      
      when(
        () =>
            mockPicker.pickImage(source: ImageSource.camera, imageQuality: 70),
      ).thenAnswer((_) async => mockFile);

      await viewModel.takePhoto();

      expect(viewModel.state.length, 1);
      expect(viewModel.state.first.mediaPath, '/tmp/foto.jpg');
      expect(viewModel.state.first.description, isEmpty);
      expect(viewModel.state.first.isVideo, isFalse);
    });

    test('takePhoto should do nothing if photo is null (cancelled)', () async {
      when(
        () =>
            mockPicker.pickImage(source: ImageSource.camera, imageQuality: 70),
      ).thenAnswer((_) async => null);

      await viewModel.takePhoto();

      expect(viewModel.state, isEmpty);
    });

    test('updateDescription should update description if index is valid', () {
      viewModel.state = [
        ExpressEntry(mediaPath: '/tmp/foto1.jpg'),
      ];

      viewModel.updateDescription(0, 'Nova descrição');

      expect(viewModel.state[0].description, 'Nova descrição');
    });

    test('updateDescription should do nothing if index is invalid', () {
      viewModel.state = [
        ExpressEntry(mediaPath: '/tmp/foto1.jpg'),
      ];

      viewModel.updateDescription(1, 'Nova descrição');

      expect(viewModel.state[0].description, isEmpty);
    });

    test('removeEntry should remove entry if index is valid', () {
      viewModel.state = [
        ExpressEntry(mediaPath: '/tmp/foto1.jpg'),
        ExpressEntry(mediaPath: '/tmp/foto2.jpg'),
      ];

      viewModel.removeEntry(0);

      expect(viewModel.state.length, 1);
      expect(viewModel.state[0].mediaPath, '/tmp/foto2.jpg');
    });

    test('removeEntry should do nothing if index is invalid', () {
      viewModel.state = [
        ExpressEntry(mediaPath: '/tmp/foto1.jpg'),
      ];

      viewModel.removeEntry(1);

      expect(viewModel.state.length, 1);
    });

    test('copyWith on ExpressEntry with no parameters returns same values', () {
      final entry = ExpressEntry(
        mediaPath: '/tmp/foto1.jpg',
        description: 'Test',
        isVideo: true,
      );
      final copy = entry.copyWith();

      expect(copy.mediaPath, '/tmp/foto1.jpg');
      expect(copy.description, 'Test');
      expect(copy.isVideo, true);
    });
  });
}
