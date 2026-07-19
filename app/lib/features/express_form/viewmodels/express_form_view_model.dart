import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'package:app/core/models/proto/registro.pb.dart';
import 'package:app/core/models/local/submission_record.dart';
import 'package:app/core/services/session_bundle_manager.dart';
import 'package:app/features/identity/viewmodels/identity_form_view_model.dart'
    show isarProvider;
import 'package:isar_community/isar.dart';

/// Representa uma entrada (foto ou vídeo) e sua descrição dentro de um formulário de registro.
class ExpressEntry {
  final String mediaPath;
  final String description;
  final bool isVideo;
  final String uuid;

  ExpressEntry({
    required this.mediaPath,
    this.description = '',
    this.isVideo = false,
    String? uuid,
  }) : uuid = uuid ?? const Uuid().v4();

  ExpressEntry copyWith({
    String? mediaPath,
    String? description,
    bool? isVideo,
    String? uuid,
  }) {
    return ExpressEntry(
      mediaPath: mediaPath ?? this.mediaPath,
      description: description ?? this.description,
      isVideo: isVideo ?? this.isVideo,
      uuid: uuid ?? this.uuid,
    );
  }
}

/// Gerencia o estado (lista de fotos/vídeos e descrições) durante a edição de um Registro.
///
/// Esta classe orquestra a captura de mídias, criação/atualização do manifesto Protobuf,
/// conversão de mídias para hash (segurança/auditoria), persistência no `SessionBundleManager`
/// e gravação inicial do histórico no Isar. Também é capaz de recarregar uma sessão inteira.
class ExpressFormViewModel extends StateNotifier<List<ExpressEntry>> {
  final ImagePicker _picker;
  final SessionBundleManager? _sessionManager;
  final Isar? _isar;
  String? currentSessionId;

  ExpressFormViewModel({
    ImagePicker? picker,
    SessionBundleManager? sessionManager,
    Isar? isar,
  }) : _picker = picker ?? ImagePicker(),
       _sessionManager = sessionManager,
       _isar = isar,
       super([]);

  Future<void> takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (photo != null) {
      state = [...state, ExpressEntry(mediaPath: photo.path)];
    }
  }

  void updateDescription(int index, String newDescription) {
    if (index >= 0 && index < state.length) {
      final updatedList = List<ExpressEntry>.from(state);
      updatedList[index] = updatedList[index].copyWith(
        description: newDescription,
      );
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

  /// Constrói o objeto Protobuf `RegistroManutencao` com base no estado atual da lista.
  ///
  /// Mapeia o UUID, descrições e o tipo de arquivo de forma segura. Hash originais
  /// são injetados posteriormente durante a fase de `saveSession`.
  RegistroManutencao generateManifest(String sessionId) {
    final manifest = RegistroManutencao(idSessao: sessionId);

    for (final entry in state) {
      final acao = AcaoManutencao(
        idInstancia: entry.uuid,
        outro: DetalheAcaoCustomizada(descricao: entry.description),
      );

      if (entry.isVideo) {
        acao.outro.video = ReferenciaMidia(
          video: ArquivoVideo(
            uuid: entry.uuid,
            tipoOriginal: 'video/mp4', // Mocado por enquanto
          ),
        );
      } else {
        acao.outro.foto = ReferenciaMidia(
          imagem: ArquivoImagem(uuid: entry.uuid, tipoOriginal: 'image/jpeg'),
        );
      }

      manifest.acoes.add(acao);
    }

    return manifest;
  }

  /// Carrega uma sessão inteira a partir do armazenamento (Bundle local) para edição.
  ///
  /// O manifesto `.binarypb` é convertido para o objeto Protobuf nativo. A partir dele,
  /// as UUIDs são lidas e a `SessionBundleManager` busca os caminhos absolutos das mídias
  /// para montar os cartões novamente na tela e permitir alterações em relatórios salvos.
  Future<void> loadSession(String sessionId) async {
    currentSessionId = sessionId;
    if (_sessionManager == null) return;

    final bytes = await _sessionManager.readManifest(sessionId: sessionId);
    final manifest = RegistroManutencao.fromBuffer(bytes);

    final entries = <ExpressEntry>[];
    for (final acao in manifest.acoes) {
      if (acao.hasOutro()) {
        final outro = acao.outro;
        final hasVideo = outro.hasVideo();
        final hasFoto = outro.hasFoto();

        String? mediaUuid;
        String ext = '.jpg';
        if (hasVideo) {
          mediaUuid = outro.video.video.uuid;
          ext = '.mp4';
        } else if (hasFoto) {
          mediaUuid = outro.foto.imagem.uuid;
        }

        if (mediaUuid != null) {
          final path = await _sessionManager.getMediaFilePath(
            sessionId: sessionId,
            mediaUuid: '${mediaUuid}_original',
            extension: ext,
          );

          entries.add(
            ExpressEntry(
              mediaPath: path,
              description: outro.descricao,
              isVideo: hasVideo,
              uuid: mediaUuid,
            ),
          );
        }
      }
    }

    state = entries;
  }

  /// Salva todas as mídias da sessão e o manifesto binário no File System.
  ///
  /// O ID da sessão atual (`currentSessionId`) será reutilizado caso este seja
  /// um fluxo de edição do Histórico; se for uma nova sessão, um UUID v4 novo é gerado.
  /// Durante o processo, os Hashes SHA-256 das mídias originais são embutidos no manifesto
  /// (Garantia de Integridade Criptográfica de Arquivos para o modelo Rust/PDF).
  Future<String> saveSession() async {
    final sessionId = currentSessionId ?? const Uuid().v4();
    currentSessionId = sessionId;
    final manifest = generateManifest(sessionId);

    if (_sessionManager != null) {
      // Create session directory and save original files
      for (int i = 0; i < state.length; i++) {
        final entry = state[i];
        final bytes = await File(entry.mediaPath).readAsBytes();

        final hashStr = sha256.convert(bytes).toString();

        if (entry.isVideo) {
          manifest.acoes[i].outro.video.video.hashOriginal = hashStr;
        } else {
          manifest.acoes[i].outro.foto.imagem.hashOriginal = hashStr;
        }

        await _sessionManager.saveOriginalMedia(
          sessionId: sessionId,
          mediaUuid: entry.uuid,
          extension: entry.isVideo ? '.mp4' : '.jpg',
          bytes: bytes,
        );
      }

      await _sessionManager.saveManifest(
        sessionId: sessionId,
        binarypb: manifest.writeToBuffer(),
      );

      await _sessionManager.saveManifestJson(
        sessionId: sessionId,
        jsonStr: manifest.writeToJson(),
      );
    }

    if (_isar != null) {
      final existingRecord = await _isar.submissionRecords.filter().idSessaoEqualTo(sessionId).findFirst();
      final record = existingRecord ?? SubmissionRecord();

      record
        ..idSessao = sessionId
        ..idProtocolo = 'express'
        ..nomeProtocolo = 'Registro Expresso'
        ..dataInclusao = DateTime.now()
        ..hashAssinatura = ''
        ..pdfPath = '' // Invalidar PDF anterior caso exista (edição)
        ..protobufPath =
            await _sessionManager?.getMediaFilePath(
              sessionId: sessionId,
              mediaUuid: 'registro',
              extension: '.binarypb',
            ) ??
            ''
        ..enviadoNuvem = false;

      await _isar.writeTxn(() async {
        await _isar.submissionRecords.put(record);
      });
    }

    return sessionId;
  }

  /// Limpa toda a sessão atual (memória e metadados).
  ///
  /// Chamado invariavelmente ao iniciar um "Novo Protocolo" pela UI, para garantir
  /// que nenhum dado de uma edição ou criação abortada vaze na próxima iteração.
  void clearSession() {
    currentSessionId = null;
    state = [];
  }
}

final expressFormViewModelProvider =
    StateNotifierProvider<ExpressFormViewModel, List<ExpressEntry>>((ref) {
      final sessionManager = ref.watch(sessionBundleManagerProvider);
      final isar = ref.watch(isarProvider);

      return ExpressFormViewModel(sessionManager: sessionManager, isar: isar);
    });
