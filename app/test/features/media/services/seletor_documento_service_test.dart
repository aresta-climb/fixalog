// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:fixalog/features/media/services/seletor_documento_service.dart';

base class FakePlatformFile extends PlatformFile {
  @override
  final String name;
  @override
  final Uri uri;
  final Uint8List _bytes;
  final bool falharLeitura;

  FakePlatformFile({
    required this.name,
    required Uint8List bytes,
    Uri? uri,
    this.falharLeitura = false,
  })  : _bytes = bytes,
        uri = uri ?? Uri.file('/tmp/$name');

  @override
  XFile get xFile => XFile.fromData(_bytes, name: name);

  @override
  int? lengthSync() => _bytes.length;

  @override
  Future<int?> length() async => _bytes.length;

  @override
  Future<Uint8List> readAsBytes() async {
    if (falharLeitura) {
      throw Exception('Falha ao ler arquivo');
    }
    return _bytes;
  }

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(_bytes);
}

class FakeFilePickerPlatform extends FilePickerPlatform
    with MockPlatformInterfaceMixin {
  PlatformFile? resultadoProximoPick;
  FileType? ultimoTipo;
  List<String>? ultimasExtensoes;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    ultimoTipo = type;
    ultimasExtensoes = allowedExtensions;
    return resultadoProximoPick;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFilePickerPlatform fakePicker;

  setUp(() {
    fakePicker = FakeFilePickerPlatform();
    FilePickerPlatform.instance = fakePicker;
  });

  group('SeletorDocumentoService Tests', () {
    test('selecionarPdf utiliza seletorCustomizado quando fornecido', () async {
      final bytesEsperados = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
      final servico = SeletorDocumentoService(
        seletorCustomizado: () async => DocumentoSelecionado(
          nome: 'nota_fiscal.pdf',
          caminho: '/tmp/nota_fiscal.pdf',
          bytes: bytesEsperados,
        ),
      );

      final doc = await servico.selecionarPdf();

      expect(doc, isNotNull);
      expect(doc!.nome, equals('nota_fiscal.pdf'));
      expect(doc.caminho, equals('/tmp/nota_fiscal.pdf'));
      expect(doc.bytes, equals(bytesEsperados));
    });

    test('selecionarPdf via FilePicker filtra por extensão pdf e retorna bytes lidos', () async {
      final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31]);
      fakePicker.resultadoProximoPick = FakePlatformFile(
        name: 'laudo_tracao.pdf',
        bytes: pdfBytes,
      );

      final servico = SeletorDocumentoService();
      final doc = await servico.selecionarPdf();

      expect(fakePicker.ultimoTipo, equals(FileType.custom));
      expect(fakePicker.ultimasExtensoes, equals(['pdf']));
      expect(doc, isNotNull);
      expect(doc!.nome, equals('laudo_tracao.pdf'));
      expect(doc.bytes, equals(pdfBytes));
    });

    test('selecionarPdf retorna null quando usuário cancela, arquivo está vazio ou leitura falha', () async {
      fakePicker.resultadoProximoPick = null;
      final servico = SeletorDocumentoService();
      expect(await servico.selecionarPdf(), isNull);

      fakePicker.resultadoProximoPick = FakePlatformFile(
        name: 'vazio.pdf',
        bytes: Uint8List(0),
      );
      expect(await servico.selecionarPdf(), isNull);

      fakePicker.resultadoProximoPick = FakePlatformFile(
        name: 'erro.pdf',
        bytes: Uint8List.fromList([1, 2]),
        falharLeitura: true,
      );
      expect(await servico.selecionarPdf(), isNull);
    });

    test('seletorDocumentoServiceProvider provê instância funcional', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final servico = container.read(seletorDocumentoServiceProvider);
      expect(servico, isA<SeletorDocumentoService>());
    });
  });
}
