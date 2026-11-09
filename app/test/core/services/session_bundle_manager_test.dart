// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String path;
  FakePathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  late SessionBundleManager manager;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fixalog_test');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    manager = SessionBundleManager();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('SessionBundleManager', () {
    test('sessionBundleManagerProvider instancia SessionBundleManager padrão', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(sessionBundleManagerProvider),
        isA<SessionBundleManager>(),
      );
    });

    test('getSessionDirectory should return correct path and create directory if not exists', () async {
      const sessionId = 'test-session-123';
      final dir = await manager.getSessionDirectory(sessionId);

      expect(dir.path, contains('sessoes'));
      expect(dir.path, contains(sessionId));
      expect(dir.existsSync(), isTrue);

      final customManager = SessionBundleManager(
        baseDirectoryGetter: () async => tempDir,
      );
      final dirCustom = await customManager.getSessionDirectory(sessionId);
      expect(dirCustom.path, equals(dir.path));
    });

    test('saveOriginalMedia e saveCompressedMedia salvam com e sem ponto na extensão', () async {
      const sessionId = 'session-456';
      const mediaUuid = 'media-789';
      final bytes = Uint8List.fromList([1, 2, 3]);

      final fileOrig = await manager.saveOriginalMedia(
        sessionId: sessionId,
        mediaUuid: mediaUuid,
        extension: 'jpg',
        bytes: bytes,
      );
      expect(fileOrig.path, endsWith('${mediaUuid}_original.jpg'));
      expect(fileOrig.readAsBytesSync(), equals(bytes));

      final fileComp = await manager.saveCompressedMedia(
        sessionId: sessionId,
        mediaUuid: mediaUuid,
        extension: 'webp',
        bytes: bytes,
      );
      expect(fileComp.path, endsWith('$mediaUuid.webp'));
      expect(fileComp.readAsBytesSync(), equals(bytes));

      final pathComPonto = await manager.getMediaFilePath(
        sessionId: sessionId,
        mediaUuid: mediaUuid,
        extension: '.jpg',
      );
      final pathSemPonto = await manager.getMediaFilePath(
        sessionId: sessionId,
        mediaUuid: mediaUuid,
        extension: 'jpg',
      );
      expect(pathComPonto, equals(pathSemPonto));
    });

    test('salvarRegistroSessao grava registro.yaml e lerRegistroSessao / readManifest leem de registro.yaml com fallback para registro.binarypb', () async {
      const idYaml = 'sessao-yaml';
      final regOriginal = Registro(
        idSessao: idYaml,
        idProtocolo: 'maintenance',
        versaoProtocolo: '3',
        yamlConteudo: 'id: maintenance\nversao: 3\n',
      )..respostas['route_name'] = Resposta(texto: 'Via Leste');

      final arquivoYaml = await manager.salvarRegistroSessao(
        sessionId: idYaml,
        registro: regOriginal,
      );
      expect(arquivoYaml.path, endsWith('registro.yaml'));
      expect(arquivoYaml.readAsStringSync(), contains('route_name'));

      final lidoDeYaml = await manager.lerRegistroSessao(sessionId: idYaml);
      expect(lidoDeYaml, equals(regOriginal));

      final bytesDeYaml = await manager.readManifest(sessionId: idYaml);
      expect(Registro.fromBuffer(bytesDeYaml), equals(regOriginal));

      // Fallback legado para registro.binarypb
      const idLegado = 'sessao-legada-pb';
      final regLegado = Registro(
        idSessao: idLegado,
        idProtocolo: 'maintenance',
        versaoProtocolo: '2',
      )..respostas['via_nome'] = Resposta(texto: 'Via Antiga');

      final arquivoPb = await manager.saveManifest(
        sessionId: idLegado,
        binarypb: Uint8List.fromList(regLegado.writeToBuffer()),
      );
      expect(arquivoPb.path, endsWith('registro.binarypb'));

      final lidoDePb = await manager.lerRegistroSessao(sessionId: idLegado);
      expect(lidoDePb, equals(regLegado));

      final bytesDePb = await manager.readManifest(sessionId: idLegado);
      expect(Registro.fromBuffer(bytesDePb), equals(regLegado));

      final arquivoJson = await manager.saveManifestJson(
        sessionId: idLegado,
        jsonStr: '{"idSessao":"$idLegado"}',
      );
      expect(arquivoJson.path, endsWith('registro.json'));
      expect(arquivoJson.readAsStringSync(), contains(idLegado));
    });

    test('deleteSessionBundle should delete directory and all contents', () async {
      const sessionId = 'session-to-delete';

      await manager.salvarRegistroSessao(
        sessionId: sessionId,
        registro: Registro(idSessao: sessionId),
      );
      final dir = await manager.getSessionDirectory(sessionId);
      expect(dir.existsSync(), isTrue);

      await manager.deleteSessionBundle(sessionId);

      expect(dir.existsSync(), isFalse);
    });

    test('getReportFilePath should return correct format fixalog_<uuid>.pdf', () async {
      const sessionId = 'b4b1a2-c3d4-4e5f-a6b7-8c9d0e1f2g3h';

      final reportPath = await manager.getReportFilePath(sessionId: sessionId);

      expect(reportPath, contains('sessoes'));
      expect(reportPath, endsWith('fixalog_b4b1a2-c3d4-4e5f-a6b7-8c9d0e1f2g3h.pdf'));
    });

    test('copiarArquivosMidiaSessao copia midias originais e pre-processadas ignorando registro.yaml, registro.binarypb, temporarios e relatorios finais', () async {
      const idOrigem = 'sessao-origem';
      const idDestino = 'sessao-destino';
      final dirOrigem = await manager.getSessionDirectory(idOrigem);

      // Mídias que devem ser copiadas
      File('${dirOrigem.path}/foto1_original.jpg').writeAsBytesSync([1, 2, 3]);
      File('${dirOrigem.path}/foto1.webp').writeAsBytesSync([4, 5, 6]);
      File('${dirOrigem.path}/foto1_thumb.jpg').writeAsBytesSync([7, 8, 9]);
      File('${dirOrigem.path}/vid1_original.mp4').writeAsBytesSync([10, 11]);
      File('${dirOrigem.path}/vid1.mp4').writeAsBytesSync([12, 13]);
      File('${dirOrigem.path}/vid1_poster.jpg').writeAsBytesSync([14, 15]);
      File('${dirOrigem.path}/doc1_original.pdf').writeAsBytesSync([16, 17]);
      File('${dirOrigem.path}/doc1_p1.webp').writeAsBytesSync([18, 19]);
      File('${dirOrigem.path}/doc1_p1_thumb.jpg').writeAsBytesSync([20, 21]);

      // Arquivos que NÃO devem ser copiados
      File('${dirOrigem.path}/registro.yaml').writeAsStringSync('idSessao: "$idOrigem"\n');
      File('${dirOrigem.path}/registro.binarypb').writeAsBytesSync([99]);
      File('${dirOrigem.path}/registro.json').writeAsStringSync('{}');
      File('${dirOrigem.path}/foto2.webp.tmp').writeAsBytesSync([88]);
      File('${dirOrigem.path}/fixalog_$idOrigem.pdf').writeAsBytesSync([77]);
      File('${dirOrigem.path}/fixalog_$idOrigem.epub').writeAsBytesSync([66]);
      File('${dirOrigem.path}/relatorio.epub').writeAsBytesSync([55]);

      await manager.copiarArquivosMidiaSessao(
        idSessaoOrigem: idOrigem,
        idSessaoDestino: idDestino,
      );

      final dirDestino = await manager.getSessionDirectory(idDestino);
      expect(File('${dirDestino.path}/foto1_original.jpg').readAsBytesSync(), equals([1, 2, 3]));
      expect(File('${dirDestino.path}/foto1.webp').readAsBytesSync(), equals([4, 5, 6]));
      expect(File('${dirDestino.path}/foto1_thumb.jpg').readAsBytesSync(), equals([7, 8, 9]));
      expect(File('${dirDestino.path}/vid1_original.mp4').readAsBytesSync(), equals([10, 11]));
      expect(File('${dirDestino.path}/vid1.mp4').readAsBytesSync(), equals([12, 13]));
      expect(File('${dirDestino.path}/vid1_poster.jpg').readAsBytesSync(), equals([14, 15]));
      expect(File('${dirDestino.path}/doc1_original.pdf').readAsBytesSync(), equals([16, 17]));
      expect(File('${dirDestino.path}/doc1_p1.webp').readAsBytesSync(), equals([18, 19]));
      expect(File('${dirDestino.path}/doc1_p1_thumb.jpg').readAsBytesSync(), equals([20, 21]));

      expect(File('${dirDestino.path}/registro.yaml').existsSync(), isFalse);
      expect(File('${dirDestino.path}/registro.binarypb').existsSync(), isFalse);
      expect(File('${dirDestino.path}/registro.json').existsSync(), isFalse);
      expect(File('${dirDestino.path}/foto2.webp.tmp').existsSync(), isFalse);
      expect(File('${dirDestino.path}/fixalog_$idOrigem.pdf').existsSync(), isFalse);
      expect(File('${dirDestino.path}/fixalog_$idOrigem.epub').existsSync(), isFalse);
      expect(File('${dirDestino.path}/relatorio.epub').existsSync(), isFalse);
    });
  });
}
