// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get seletorIdiomaTitulo => 'App Language';

  @override
  String get seletorIdiomaSubtitulo =>
      'Changes the language of the interface, protocols, and new reports';

  @override
  String get comumSim => 'Yes';

  @override
  String get comumNao => 'No';

  @override
  String get comumCancelar => 'CANCEL';

  @override
  String get comumRemover => 'REMOVE';

  @override
  String get comumFechar => 'CLOSE';

  @override
  String comumErro(String detalhe) {
    return 'Error: $detalhe';
  }

  @override
  String get termosTituloTela => 'Terms of Use and Technical Audit';

  @override
  String get termosCarregando => 'Loading Terms of Use...';

  @override
  String get termosErroCarregar =>
      'Could not load the local terms of use. Please try again.';

  @override
  String get termosBotaoTentarNovamente => 'Try Again';

  @override
  String get termosBotaoLerPolitica => 'Read Privacy Policy';

  @override
  String get termosCheckboxDeclaro =>
      'I have read and agree to the Terms of Use and Privacy Policy.';

  @override
  String get termosBotaoAceitar => 'Accept Terms and Continue';

  @override
  String get termosBotaoRoleFinal => 'Scroll to the bottom to enable';

  @override
  String get politicaPrivacidadeTitulo => 'Privacy Policy - Fixalog';

  @override
  String get politicaPrivacidadeErroCarregar =>
      'Could not load the Privacy Policy.';

  @override
  String get identidadeTituloInicial => 'TECHNICAL IDENTITY';

  @override
  String get identidadeTituloEdicao => 'EDIT TECHNICAL IDENTITY';

  @override
  String get identidadeSubtituloInicial =>
      'Set up your profile to digitally sign technical reports.';

  @override
  String get identidadeSubtituloEdicao =>
      'Update your profile details. Your active cryptographic key will be preserved.';

  @override
  String get identidadeLabelNome => 'Full Name *';

  @override
  String get identidadeHintNome => 'E.g., John Doe';

  @override
  String get identidadeLabelApelido => 'Nickname (Optional)';

  @override
  String get identidadeHintApelido => 'E.g., Rocky';

  @override
  String get identidadeLabelEmail => 'Email *';

  @override
  String get identidadeHintEmail => 'E.g., john@example.com';

  @override
  String get identidadeLabelAssociacao => 'Association / Club (Optional)';

  @override
  String get identidadeHintAssociacao => 'E.g., UIAA, AAC, FEMERJ...';

  @override
  String get identidadeErroNomeVazio => 'Full name cannot be empty.';

  @override
  String get identidadeErroEmailVazio => 'Email cannot be empty.';

  @override
  String get identidadeErroEmailInvalido => 'Invalid email format.';

  @override
  String identidadeErroSalvar(String erro) {
    return 'Failed to save identity: $erro';
  }

  @override
  String get identidadeBotaoGerarChaves => 'GENERATE KEYS AND CONTINUE';

  @override
  String get identidadeBotaoSalvarAlteracoes => 'SAVE CHANGES';

  @override
  String get homeAbaNovo => 'NEW';

  @override
  String get homeAbaHistorico => 'HISTORY';

  @override
  String get homeAbaConfig => 'SETTINGS';

  @override
  String get configTituloSecaoIdentidade => 'IDENTITY AND CRYPTOGRAPHIC KEY';

  @override
  String get configCertificadoAtivo => 'ACTIVE X.509 CERTIFICATE';

  @override
  String get configBotaoEditarDados => 'EDIT PROFILE DATA';

  @override
  String get configBotaoExportarChave => 'EXPORT IDENTITY KEY';

  @override
  String get configBotaoImportarChave => 'IMPORT IDENTITY KEY';

  @override
  String get configExportarTituloModal => 'EXPORT IDENTITY KEY';

  @override
  String get configExportarDescricaoModal =>
      'Set a strong password (minimum 8 characters) to encrypt the .fixalogkey file with PBKDF2 + AES-256-GCM.';

  @override
  String get configLabelSenhaExportacao => 'File password';

  @override
  String get configLabelConfirmarSenha => 'Confirm password';

  @override
  String get configErroSenhaCurta => 'Password must be at least 8 characters.';

  @override
  String get configErroSenhasDiferentes => 'Passwords do not match.';

  @override
  String get configBotaoExportar => 'EXPORT';

  @override
  String get configExportarSucesso => 'Identity backup exported successfully.';

  @override
  String configExportarErro(String erro) {
    return 'Failed to export key: $erro';
  }

  @override
  String get configImportarTituloModal => 'IMPORT IDENTITY KEY';

  @override
  String get configImportarDescricaoModal =>
      'Enter the password for the selected .fixalogkey file. The current key will be replaced.';

  @override
  String get configBotaoImportar => 'IMPORT';

  @override
  String get configImportarSucesso =>
      'Identity and cryptographic key restored successfully!';

  @override
  String get configImportarErroSenha =>
      'Incorrect password or corrupted key file.';

  @override
  String get novoProtocoloSelecione => 'SELECT PROTOCOL';

  @override
  String get novoProtocoloSubtitulo =>
      'Start a new audited field data collection.';

  @override
  String get novoProtocoloCardInspecaoTitulo => 'Visual Inspection';

  @override
  String get novoProtocoloCardInspecaoSub =>
      'Quick survey of general condition and corrosion without mechanical intervention.';

  @override
  String get novoProtocoloCardManutencaoTitulo => 'Hardware Maintenance';

  @override
  String get novoProtocoloCardManutencaoSub =>
      'Complete report of anchor replacement, cleaning, and rebolting.';

  @override
  String get novoProtocoloCardAberturaTitulo => 'Route Opening';

  @override
  String get novoProtocoloCardAberturaSub =>
      'Full record of a new climbing line, first ascent, topo, and fixed gear.';

  @override
  String get novoProtocoloCardExpressoTitulo => 'Express Log';

  @override
  String get novoProtocoloCardExpressoSub =>
      'Quick capture of photos, videos, PDFs, and free-form field notes.';

  @override
  String get novoProtocoloCardMaterialTitulo => 'Material';

  @override
  String get novoProtocoloCardMaterialSub =>
      'Registration and traceability of hardware, batches, invoices, and tests.';

  @override
  String novoProtocoloErroCarregar(String erro) {
    return 'Error loading protocol: $erro';
  }

  @override
  String get historicoTitulo => 'AUDIT HISTORY';

  @override
  String get historicoSubtitulo => 'Sessions saved locally on this device.';

  @override
  String historicoAbaRelatorios(int quantidade) {
    return 'REPORTS ($quantidade)';
  }

  @override
  String historicoAbaMateriais(int quantidade) {
    return 'MATERIALS ($quantidade)';
  }

  @override
  String get historicoVazioRelatoriosTitulo => 'No reports found';

  @override
  String get historicoVazioRelatoriosSub =>
      'Start a new protocol in the NEW tab to record your first audit.';

  @override
  String get historicoVazioMateriaisTitulo => 'No materials registered';

  @override
  String get historicoVazioMateriaisSub =>
      'Register materials in the NEW tab to use them in maintenance reports.';

  @override
  String get historicoBotaoNovoMaterial => 'REGISTER MATERIAL';

  @override
  String get historicoStatusConcluido => 'COMPLETED';

  @override
  String get historicoStatusEmProgresso => 'IN PROGRESS';

  @override
  String get historicoStatusFalha => 'FAILED';

  @override
  String get historicoBotaoVerRelatorio => 'VIEW REPORT';

  @override
  String get historicoBotaoGerarRelatorio => 'GENERATE REPORT';

  @override
  String get historicoBotaoContinuar => 'CONTINUE';

  @override
  String get historicoBotaoEditar => 'EDIT';

  @override
  String get historicoBotaoDuplicar => 'DUPLICATE';

  @override
  String get historicoBotaoExcluir => 'DELETE';

  @override
  String get historicoConfirmarExclusaoTitulo => 'Delete record?';

  @override
  String historicoConfirmarExclusaoCorpo(String titulo) {
    return 'Are you sure you want to delete \"$titulo\"? This action will remove local files and cannot be undone.';
  }

  @override
  String get historicoMaterialEmUsoTitulo => 'Material linked to reports';

  @override
  String get historicoMaterialEmUsoCorpo =>
      'This material is referenced in other reports. Deleting it will not erase already issued reports, but will remove the item from the active catalog.';

  @override
  String wizardPassoNumero(int numero) {
    return 'STEP $numero';
  }

  @override
  String get wizardBotaoVoltarPasso => 'RETURN TO THIS STEP';

  @override
  String get wizardBotaoConcluir => 'FINISH';

  @override
  String get wizardBotaoSeguinte => 'NEXT';

  @override
  String get wizardBotaoPular => 'SKIP';

  @override
  String wizardBotaoConcluirLista(int quantidade) {
    return 'FINISH LIST ($quantidade)';
  }

  @override
  String get wizardAvisoCamposObrigatorios =>
      'Fill in all required fields to proceed.';

  @override
  String get wizardAvisoPassoAnteriorObrigatorio =>
      'Fill in all required fields of the previous step to proceed.';

  @override
  String get wizardAvisoCamposItemObrigatorios =>
      'Fill in the required fields for this item.';

  @override
  String get wizardBotaoAdicionarItem => 'ADD ITEM';

  @override
  String get wizardBotaoAdicionarOutro => 'ADD ANOTHER';

  @override
  String wizardMinimoItensObrigatorios(int minimo) {
    return 'Minimum $minimo required item(s).';
  }

  @override
  String get wizardSelecioneTipo => 'SELECT TYPE';

  @override
  String get wizardBotaoConfirmarItem => 'CONFIRM ITEM';

  @override
  String get wizardRemoverItemTitulo => 'Remove item?';

  @override
  String wizardRemoverItemCorpo(String item) {
    return 'Remove \"$item\"?';
  }

  @override
  String get wizardHintTexto => 'Type here...';

  @override
  String get wizardHintTextoArea =>
      'Type here... (supports **bold**, *italic*, # heading and lists)';

  @override
  String get wizardHintNumeros => 'Numbers only';

  @override
  String get wizardGpsDesativado => 'Location service disabled.';

  @override
  String get wizardGpsCapturado => 'COORDINATES CAPTURED';

  @override
  String get wizardGpsCapturar => 'CAPTURE GPS POSITION';

  @override
  String get wizardMidiaAdicionar => 'ADD MEDIA';

  @override
  String get wizardMidiaSubVazio => 'Photos, videos or PDFs';

  @override
  String get wizardMidiaSubMais => 'Add another photo, video or PDF';

  @override
  String get wizardMidiaPdfAnexado => 'ATTACHED PDF';

  @override
  String get wizardMidiaVideoGravado => 'RECORDED VIDEO';

  @override
  String get wizardMidiaFotoCapturada => 'CAPTURED PHOTO';

  @override
  String get wizardMidiaProcessandoUm => 'PROCESSING MEDIA...';

  @override
  String wizardMidiaProcessandoVarios(int quantidade) {
    return 'PROCESSING $quantidade MEDIA FILES...';
  }

  @override
  String get wizardMidiaProcessandoSub =>
      'Saving and calculating integrity in background...';

  @override
  String get wizardMidiaModalTitulo => 'ADD MEDIA (PHOTO, VIDEO OR PDF)';

  @override
  String get wizardMidiaTirarFoto => 'Take Photo with Camera';

  @override
  String get wizardMidiaGravarVideo => 'Record Video with Camera';

  @override
  String get wizardMidiaEscolherGaleria => 'Choose from Gallery';

  @override
  String get wizardMidiaEscolherGaleriaSub => 'Photos and videos';

  @override
  String get wizardMidiaSelecionarPdf => 'Select PDF File';

  @override
  String get wizardRefMatVazioCatalogo =>
      'No materials registered in the catalog yet.\nTap below to register a new material.';

  @override
  String get wizardRefMatVazioBloco =>
      'No materials registered in Block 1.\nGo back and add materials first.';

  @override
  String get wizardBotaoCadastrarNovoMaterial => 'REGISTER NEW MATERIAL';

  @override
  String get wizardConclusaoTitulo => 'PROTOCOL COMPLETED';

  @override
  String get wizardConclusaoSubtitulo =>
      'All data has been collected offline.\nThe record is ready to be signed and exported.';

  @override
  String get wizardBotaoGerarRelatorio => 'GENERATE REPORT';

  @override
  String get wizardSufixoCopia => 'Copy';

  @override
  String get geracaoEmAndamentoTitulo => 'GENERATING REPORT';

  @override
  String get geracaoConcluidaTitulo => 'REPORT READY';

  @override
  String get geracaoFalhaTitulo => 'GENERATION FAILED';

  @override
  String get geracaoBotaoAbrirRelatorio => 'OPEN REPORT';

  @override
  String get visualizadorAbaEpub => 'EPUB 3 REPORT';

  @override
  String get visualizadorAbaPdf => 'PDF SUMMARY';

  @override
  String get visualizadorBotaoCompartilhar => 'SHARE';

  @override
  String get visualizadorBotaoAbrirExterno => 'OPEN EXTERNALLY';

  @override
  String get laudoRotuloProtocolo => 'PROTOCOL';

  @override
  String get laudoRotuloSessao => 'SESSION';

  @override
  String get laudoRotuloEmissao => 'ISSUED UTC';

  @override
  String get laudoRotuloVersao => 'VERSION';

  @override
  String get laudoSecaoIdentidadeTitulo => 'ISSUER TECHNICAL IDENTITY';

  @override
  String get laudoRotuloNome => 'Name';

  @override
  String get laudoRotuloEmail => 'Email';

  @override
  String get laudoRotuloAssociacao => 'Association';

  @override
  String get laudoSecaoIntegridadeTitulo =>
      'CRYPTOGRAPHIC INTEGRITY AND CHAIN OF CUSTODY';

  @override
  String get laudoAvisoResumoImpresso =>
      'This PDF is an executive summary for quick printing. The full forensic report with high-resolution media, videos, and X.509 XML-DSig digital signature is contained in the corresponding EPUB 3 file.';

  @override
  String get laudoSecaoAnexoCatalogoTitulo =>
      'APPENDIX — REFERENCED MATERIALS CATALOG';

  @override
  String get laudoRotuloVideoAnexo => 'Video attached in EPUB 3';

  @override
  String laudoRotuloDocumentoPdf(int paginas) {
    return 'PDF Document ($paginas pp.)';
  }
}
