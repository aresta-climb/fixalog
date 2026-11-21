// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../tool/release_tools/auditar_binario_loja.dart';

void main() {
  group('AuditorBinarioLoja', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('auditor_binario_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    File criarZip(String nome, Map<String, List<int>> entradas) {
      final archive = Archive();
      entradas.forEach((caminho, bytes) {
        archive.addFile(ArchiveFile(caminho, bytes.length, bytes));
      });
      final zipBytes = ZipEncoder().encode(archive);
      final file = File('${tempDir.path}/$nome');
      file.writeAsBytesSync(zipBytes);
      return file;
    }

    test('deve aprovar pacote .aab limpo contendo bibliotecas nativas obrigatórias e zero marcadores de smoke', () {
      final aab = criarZip('app-release.aab', <String, List<int>>{
        'base/dex/classes.dex': ascii.encode('dex035-codigo-producao-puro'),
        'base/lib/arm64-v8a/libapp.so': ascii.encode('ELF-dart-aot-main'),
        'base/lib/arm64-v8a/libflutter.so': ascii.encode('ELF-flutter-engine'),
        'base/lib/arm64-v8a/libffmpegkit.so': ascii.encode('ELF-ffmpegkit'),
      });

      final resultado = AuditorBinarioLoja.auditarAab(aab);
      expect(resultado.aprovado, isTrue, reason: resultado.erros.join('\n'));
      expect(resultado.erros, isEmpty);
    });

    test('deve reprovar pacote .aab quando marcador de smoke test estiver presente em dex ou libapp.so', () {
      final aabContaminado = criarZip('contaminado.aab', <String, List<int>>{
        'base/dex/classes.dex': ascii.encode('dex com com.arestaclimb.fixalog/smoke_ci vazado'),
        'base/lib/arm64-v8a/libapp.so': ascii.encode('ELF-dart-aot-com-/__smoke__/oidc-token'),
        'base/lib/arm64-v8a/libflutter.so': ascii.encode('ELF-flutter'),
        'base/lib/arm64-v8a/libffmpegkit.so': ascii.encode('ELF-ffmpeg'),
      });

      final resultado = AuditorBinarioLoja.auditarAab(aabContaminado);
      expect(resultado.aprovado, isFalse);
      expect(resultado.erros.join('\n'), contains('smoke_ci'));
      expect(resultado.erros.join('\n'), contains('/__smoke__/'));
    });

    test('deve reprovar pacote .aab quando biblioteca nativa obrigatória estiver ausente', () {
      final aabIncompleto = criarZip('incompleto.aab', <String, List<int>>{
        'base/dex/classes.dex': ascii.encode('dex035'),
        'base/lib/arm64-v8a/libapp.so': ascii.encode('ELF'),
      });

      final resultado = AuditorBinarioLoja.auditarAab(aabIncompleto);
      expect(resultado.aprovado, isFalse);
      expect(resultado.erros, isNotEmpty);
    });

    test('deve aprovar pacote .ipa limpo com Frameworks e Info.plist em conformidade', () {
      final ipa = criarZip('Runner.ipa', <String, List<int>>{
        'Payload/Runner.app/Runner': ascii.encode('MachO-Runner-arm64'),
        'Payload/Runner.app/Frameworks/App.framework/App': ascii.encode('MachO-App-aot'),
        'Payload/Runner.app/Frameworks/Flutter.framework/Flutter': ascii.encode('MachO-Flutter'),
        'Payload/Runner.app/Frameworks/ffmpegkit.framework/ffmpegkit': ascii.encode('MachO-ffmpeg'),
        'Payload/Runner.app/Info.plist': ascii.encode(
          '<plist><dict><key>ITSAppUsesNonExemptEncryption</key><false/></dict></plist>',
        ),
      });

      final resultado = AuditorBinarioLoja.auditarIpa(ipa);
      expect(resultado.aprovado, isTrue, reason: resultado.erros.join('\n'));
    });

    test('deve reprovar pacote .ipa quando contiver ARESTA_SMOKE_SERVER ou faltar framework essencial', () {
      final ipaContaminado = criarZip('Runner_ruim.ipa', <String, List<int>>{
        'Payload/Runner.app/Runner': ascii.encode('MachO ARESTA_SMOKE_SERVER vazado'),
        'Payload/Runner.app/Frameworks/App.framework/App': ascii.encode('MachO-App'),
        'Payload/Runner.app/Info.plist': ascii.encode('plist sem chave de criptografia'),
      });

      final resultado = AuditorBinarioLoja.auditarIpa(ipaContaminado);
      expect(resultado.aprovado, isFalse);
      expect(resultado.erros.join('\n'), contains('ARESTA_SMOKE_SERVER'));
      expect(resultado.erros.join('\n'), contains('ITSAppUsesNonExemptEncryption'));
    });
  });
}
