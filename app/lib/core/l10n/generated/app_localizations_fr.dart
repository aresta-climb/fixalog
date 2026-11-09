// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get seletorIdiomaTitulo => 'Langue de l\'Application';

  @override
  String get seletorIdiomaSubtitulo =>
      'Modifie la langue de l\'interface, des protocoles et des nouveaux rapports';

  @override
  String get comumSim => 'Oui';

  @override
  String get comumNao => 'Non';

  @override
  String get comumCancelar => 'ANNULER';

  @override
  String get comumRemover => 'SUPPRIMER';

  @override
  String get comumFechar => 'FERMER';

  @override
  String comumErro(String detalhe) {
    return 'Erreur : $detalhe';
  }

  @override
  String get termosTituloTela => 'Conditions d\'Utilisation et Audit Technique';

  @override
  String get termosCarregando => 'Chargement des Conditions d\'Utilisation...';

  @override
  String get termosErroCarregar =>
      'Impossible de charger les conditions d\'utilisation locales. Veuillez réessayer.';

  @override
  String get termosBotaoTentarNovamente => 'Réessayer';

  @override
  String get termosBotaoLerPolitica => 'Lire la Politique de Confidentialité';

  @override
  String get termosCheckboxDeclaro =>
      'J\'ai lu et j\'accepte les Conditions d\'Utilisation et la Politique de Confidentialité.';

  @override
  String get termosBotaoAceitar => 'Accepter les Conditions et Continuer';

  @override
  String get termosBotaoRoleFinal =>
      'Faites défiler jusqu\'en bas pour activer';

  @override
  String get politicaPrivacidadeTitulo =>
      'Politique de Confidentialité - Fixalog';

  @override
  String get politicaPrivacidadeErroCarregar =>
      'Impossible de charger la Politique de Confidentialité.';

  @override
  String get identidadeTituloInicial => 'IDENTITÉ TECHNIQUE';

  @override
  String get identidadeTituloEdicao => 'MODIFIER L\'IDENTITÉ TECHNIQUE';

  @override
  String get identidadeSubtituloInicial =>
      'Configurez vos informations pour signer des rapports techniques.';

  @override
  String get identidadeSubtituloEdicao =>
      'Mettez à jour vos informations. Votre clé cryptographique active sera conservée.';

  @override
  String get identidadeLabelNome => 'Nom Complet *';

  @override
  String get identidadeHintNome => 'Ex : Jean Dupont';

  @override
  String get identidadeLabelApelido => 'Pseudonyme (Optionnel)';

  @override
  String get identidadeHintApelido => 'Ex : Alpin';

  @override
  String get identidadeLabelEmail => 'E-mail *';

  @override
  String get identidadeHintEmail => 'Ex : jean@exemple.com';

  @override
  String get identidadeLabelAssociacao => 'Association / Club (Optionnel)';

  @override
  String get identidadeHintAssociacao => 'Ex : FFME, FFCAM, UIAA...';

  @override
  String get identidadeErroNomeVazio => 'Le nom complet ne peut pas être vide.';

  @override
  String get identidadeErroEmailVazio => 'L\'e-mail ne peut pas être vide.';

  @override
  String get identidadeErroEmailInvalido => 'Format d\'e-mail invalide.';

  @override
  String identidadeErroSalvar(String erro) {
    return 'Échec de l\'enregistrement de l\'identité : $erro';
  }

  @override
  String get identidadeBotaoGerarChaves => 'GÉNÉRER LES CLÉS ET CONTINUER';

  @override
  String get identidadeBotaoSalvarAlteracoes => 'ENREGISTRER LES MODIFICATIONS';

  @override
  String get homeAbaNovo => 'NOUVEAU';

  @override
  String get homeAbaHistorico => 'HISTORIQUE';

  @override
  String get homeAbaConfig => 'CONFIG';

  @override
  String get configTituloSecaoIdentidade => 'IDENTITÉ ET CLÉ CRYPTOGRAPHIQUE';

  @override
  String get configCertificadoAtivo => 'CERTIFICAT X.509 ACTIF';

  @override
  String get configBotaoEditarDados => 'MODIFIER LE PROFIL';

  @override
  String get configBotaoExportarChave => 'EXPORTER LA CLÉ D\'IDENTITÉ';

  @override
  String get configBotaoImportarChave => 'IMPORTER LA CLÉ D\'IDENTITÉ';

  @override
  String get configExportarTituloModal => 'EXPORTER LA CLÉ D\'IDENTITÉ';

  @override
  String get configExportarDescricaoModal =>
      'Définissez un mot de passe fort (minimum 8 caractères) pour chiffrer le fichier .fixalogkey avec PBKDF2 + AES-256-GCM.';

  @override
  String get configLabelSenhaExportacao => 'Mot de passe du fichier';

  @override
  String get configLabelConfirmarSenha => 'Confirmer le mot de passe';

  @override
  String get configErroSenhaCurta =>
      'Le mot de passe doit comporter au moins 8 caractères.';

  @override
  String get configErroSenhasDiferentes =>
      'Les mots de passe ne correspondent pas.';

  @override
  String get configBotaoExportar => 'EXPORTER';

  @override
  String get configExportarSucesso =>
      'Sauvegarde de l\'identité exportée avec succès.';

  @override
  String configExportarErro(String erro) {
    return 'Échec de l\'exportation de la clé : $erro';
  }

  @override
  String get configImportarTituloModal => 'IMPORTER LA CLÉ D\'IDENTITÉ';

  @override
  String get configImportarDescricaoModal =>
      'Saisissez le mot de passe du fichier .fixalogkey sélectionné. La clé actuelle sera remplacée.';

  @override
  String get configBotaoImportar => 'IMPORTER';

  @override
  String get configImportarSucesso =>
      'Identité et clé cryptographique restaurées avec succès !';

  @override
  String get configImportarErroSenha =>
      'Mot de passe incorrect ou fichier de clé corrompu.';

  @override
  String get novoProtocoloSelecione => 'SÉLECTIONNEZ LE PROTOCOLE';

  @override
  String get novoProtocoloSubtitulo =>
      'Démarrez une nouvelle collecte de données auditée.';

  @override
  String get novoProtocoloCardInspecaoTitulo => 'Inspection Visuelle';

  @override
  String get novoProtocoloCardInspecaoSub =>
      'Contrôle rapide de l\'état général et de la corrosion sans intervention mécanique.';

  @override
  String get novoProtocoloCardManutencaoTitulo => 'Maintenance';

  @override
  String get novoProtocoloCardManutencaoSub =>
      'Rapport complet de remplacement d\'ancrages, nettoyage et rééquipement.';

  @override
  String get novoProtocoloCardAberturaTitulo => 'Ouverture de Voie';

  @override
  String get novoProtocoloCardAberturaSub =>
      'Enregistrement complet d\'une nouvelle ligne, équipement, topo et points.';

  @override
  String get novoProtocoloCardExpressoTitulo => 'Journal Express';

  @override
  String get novoProtocoloCardExpressoSub =>
      'Collecte rapide de photos, vidéos, PDF et notes libres sur le terrain.';

  @override
  String get novoProtocoloCardMaterialTitulo => 'Matériel';

  @override
  String get novoProtocoloCardMaterialSub =>
      'Enregistrement et traçabilité du matériel, des lots, factures et tests.';

  @override
  String novoProtocoloErroCarregar(String erro) {
    return 'Erreur lors du chargement du protocole : $erro';
  }

  @override
  String get historicoTitulo => 'HISTORIQUE DES AUDITS';

  @override
  String get historicoSubtitulo =>
      'Sessions enregistrées localement sur l\'appareil.';

  @override
  String historicoAbaRelatorios(int quantidade) {
    return 'RAPPORTS ($quantidade)';
  }

  @override
  String historicoAbaMateriais(int quantidade) {
    return 'MATÉRIELS ($quantidade)';
  }

  @override
  String get historicoVazioRelatoriosTitulo => 'Aucun rapport trouvé';

  @override
  String get historicoVazioRelatoriosSub =>
      'Démarrez un nouveau protocole dans l\'onglet NOUVEAU pour enregistrer votre premier audit.';

  @override
  String get historicoVazioMateriaisTitulo => 'Aucun matériel enregistré';

  @override
  String get historicoVazioMateriaisSub =>
      'Enregistrez du matériel dans l\'onglet NOUVEAU pour l\'utiliser dans vos rapports de maintenance.';

  @override
  String get historicoBotaoNovoMaterial => 'ENREGISTRER DU MATÉRIEL';

  @override
  String get historicoStatusConcluido => 'TERMINÉ';

  @override
  String get historicoStatusEmProgresso => 'EN COURS';

  @override
  String get historicoStatusFalha => 'ÉCHEC';

  @override
  String get historicoBotaoVerRelatorio => 'VOIR LE RAPPORT';

  @override
  String get historicoBotaoGerarRelatorio => 'GÉNÉRER LE RAPPORT';

  @override
  String get historicoBotaoContinuar => 'CONTINUER';

  @override
  String get historicoBotaoEditar => 'MODIFIER';

  @override
  String get historicoBotaoDuplicar => 'DUPLIQUER';

  @override
  String get historicoBotaoExcluir => 'SUPPRIMER';

  @override
  String get historicoConfirmarExclusaoTitulo =>
      'Supprimer l\'enregistrement ?';

  @override
  String historicoConfirmarExclusaoCorpo(String titulo) {
    return 'Voulez-vous vraiment supprimer \"$titulo\" ? Cette action supprimera les fichiers locaux et est irréversible.';
  }

  @override
  String get historicoMaterialEmUsoTitulo => 'Matériel lié à des rapports';

  @override
  String get historicoMaterialEmUsoCorpo =>
      'Ce matériel est référencé dans d\'autres rapports. Le supprimer n\'effacera pas les rapports déjà émis, mais le retirera du catalogue actif.';

  @override
  String wizardPassoNumero(int numero) {
    return 'ÉTAPE $numero';
  }

  @override
  String get wizardBotaoVoltarPasso => 'REVENIR À CETTE ÉTAPE';

  @override
  String get wizardBotaoConcluir => 'TERMINER';

  @override
  String get wizardBotaoSeguinte => 'SUIVANT';

  @override
  String get wizardBotaoPular => 'PASSER';

  @override
  String wizardBotaoConcluirLista(int quantidade) {
    return 'TERMINER LA LISTE ($quantidade)';
  }

  @override
  String get wizardAvisoCamposObrigatorios =>
      'Veuillez remplir tous les champs obligatoires pour continuer.';

  @override
  String get wizardAvisoPassoAnteriorObrigatorio =>
      'Veuillez remplir tous les champs obligatoires de l\'étape précédente pour continuer.';

  @override
  String get wizardAvisoCamposItemObrigatorios =>
      'Veuillez remplir les champs obligatoires de l\'élément.';

  @override
  String get wizardBotaoAdicionarItem => 'AJOUTER UN ÉLÉMENT';

  @override
  String get wizardBotaoAdicionarOutro => 'AJOUTER UN AUTRE';

  @override
  String wizardMinimoItensObrigatorios(int minimo) {
    return 'Minimum $minimo élément(s) obligatoire(s).';
  }

  @override
  String get wizardSelecioneTipo => 'SÉLECTIONNEZ LE TYPE';

  @override
  String get wizardBotaoConfirmarItem => 'CONFIRMER L\'ÉLÉMENT';

  @override
  String get wizardRemoverItemTitulo => 'Supprimer l\'élément ?';

  @override
  String wizardRemoverItemCorpo(String item) {
    return 'Supprimer \"$item\" ?';
  }

  @override
  String get wizardHintTexto => 'Saisissez ici...';

  @override
  String get wizardHintTextoArea =>
      'Saisissez ici... (prend en charge **gras**, *italique*, # titre et listes)';

  @override
  String get wizardHintNumeros => 'Chiffres uniquement';

  @override
  String get wizardGpsDesativado => 'Service de localisation désactivé.';

  @override
  String get wizardGpsCapturado => 'COORDONNÉES CAPTURÉES';

  @override
  String get wizardGpsCapturar => 'CAPTURER LA POSITION GPS';

  @override
  String get wizardMidiaAdicionar => 'AJOUTER UN MÉDIA';

  @override
  String get wizardMidiaSubVazio => 'Photos, vidéos ou PDF';

  @override
  String get wizardMidiaSubMais => 'Ajouter une autre photo, vidéo ou PDF';

  @override
  String get wizardMidiaPdfAnexado => 'PDF JOINT';

  @override
  String get wizardMidiaVideoGravado => 'VIDÉO ENREGISTRÉE';

  @override
  String get wizardMidiaFotoCapturada => 'PHOTO CAPTURÉE';

  @override
  String get wizardMidiaProcessandoUm => 'TRAITEMENT DU MÉDIA...';

  @override
  String wizardMidiaProcessandoVarios(int quantidade) {
    return 'TRAITEMENT DE $quantidade MÉDIAS...';
  }

  @override
  String get wizardMidiaProcessandoSub =>
      'Enregistrement et calcul d\'intégrité en arrière-plan...';

  @override
  String get wizardMidiaModalTitulo => 'AJOUTER UN MÉDIA (PHOTO, VIDÉO OU PDF)';

  @override
  String get wizardMidiaTirarFoto => 'Prendre une Photo';

  @override
  String get wizardMidiaGravarVideo => 'Enregistrer une Vidéo';

  @override
  String get wizardMidiaEscolherGaleria => 'Choisir dans la Galerie';

  @override
  String get wizardMidiaEscolherGaleriaSub => 'Photos et vidéos';

  @override
  String get wizardMidiaSelecionarPdf => 'Sélectionner un Fichier PDF';

  @override
  String get wizardRefMatVazioCatalogo =>
      'Aucun matériel enregistré dans le catalogue.\nAppuyez ci-dessous pour enregistrer un nouveau matériel.';

  @override
  String get wizardRefMatVazioBloco =>
      'Aucun matériel enregistré dans le Bloc 1.\nRevenez en arrière et ajoutez d\'abord le matériel.';

  @override
  String get wizardBotaoCadastrarNovoMaterial =>
      'ENREGISTRER UN NOUVEAU MATÉRIEL';

  @override
  String get wizardConclusaoTitulo => 'PROTOCOLE TERMINÉ';

  @override
  String get wizardConclusaoSubtitulo =>
      'Toutes les données ont été collectées hors ligne.\nL\'enregistrement est prêt à être signé et exporté.';

  @override
  String get wizardBotaoGerarRelatorio => 'GÉNÉRER LE RAPPORT';

  @override
  String get wizardSufixoCopia => 'Copie';

  @override
  String get geracaoEmAndamentoTitulo => 'GÉNÉRATION DU RAPPORT';

  @override
  String get geracaoConcluidaTitulo => 'RAPPORT PRÊT';

  @override
  String get geracaoFalhaTitulo => 'ÉCHEC DE LA GÉNÉRATION';

  @override
  String get geracaoBotaoAbrirRelatorio => 'OUVRIR LE RAPPORT';

  @override
  String get visualizadorAbaEpub => 'RAPPORT EPUB 3';

  @override
  String get visualizadorAbaPdf => 'RÉSUMÉ PDF';

  @override
  String get visualizadorBotaoCompartilhar => 'PARTAGER';

  @override
  String get visualizadorBotaoAbrirExterno => 'OUVRIR EN EXTERNE';

  @override
  String get laudoRotuloProtocolo => 'PROTOCOLE';

  @override
  String get laudoRotuloSessao => 'SESSION';

  @override
  String get laudoRotuloEmissao => 'ÉMISSION UTC';

  @override
  String get laudoRotuloVersao => 'VERSION';

  @override
  String get laudoSecaoIdentidadeTitulo => 'IDENTITÉ TECHNIQUE DE L\'ÉMETTEUR';

  @override
  String get laudoRotuloNome => 'Nom';

  @override
  String get laudoRotuloEmail => 'E-mail';

  @override
  String get laudoRotuloAssociacao => 'Association';

  @override
  String get laudoSecaoIntegridadeTitulo =>
      'INTÉGRITÉ CRYPTOGRAPHIQUE ET CHAÎNE DE TRAÇABILITÉ';

  @override
  String get laudoAvisoResumoImpresso =>
      'Ce PDF est un résumé exécutif pour impression rapide. Le rapport d\'expertise complet avec médias haute résolution, vidéos et signature numérique XML-DSig X.509 se trouve dans le fichier EPUB 3 correspondant.';

  @override
  String get laudoSecaoAnexoCatalogoTitulo =>
      'ANNEXE — CATALOGUE DES MATÉRIELS RÉFÉRENCÉS';

  @override
  String get laudoRotuloVideoAnexo => 'Vidéo jointe dans l\'EPUB 3';

  @override
  String laudoRotuloDocumentoPdf(int paginas) {
    return 'Document PDF ($paginas p.)';
  }

  @override
  String get feedbackTituloSheet => 'Sur quoi porte votre signalement ?';

  @override
  String get feedbackCategoriaProtocolo => 'Protocole';

  @override
  String get feedbackCategoriaAplicativo => 'Application';

  @override
  String get feedbackHintDescricao =>
      'Décrivez le problème, la question ou la suggestion...';

  @override
  String get feedbackAvisoOffline =>
      'Enregistré hors ligne et envoyé automatiquement dès le retour du réseau.';

  @override
  String get feedbackBotaoEnviar => 'ENVOYER LE SIGNALEMENT';

  @override
  String get feedbackSucessoEnvio =>
      'Signalement enregistré ! Il sera envoyé dès la reconnexion.';

  @override
  String get configBotaoFeedback => 'SIGNALER UN PROBLÈME OU UNE SUGGESTION';

  @override
  String get configSecaoGovernancaTitulo => 'GOUVERNANCE ET CONDITIONS LÉGALES';

  @override
  String configTermosVersaoAceita(int versao) {
    return 'Version acceptée : v$versao';
  }

  @override
  String configTermosDataAceite(String dataHora) {
    return 'Consentement le : $dataHora';
  }

  @override
  String get configTermosPendente => 'Acceptation en attente';

  @override
  String get configBotaoConsultarTermos =>
      'CONSULTER CONDITIONS ET CONFIDENTIALITÉ';

  @override
  String get configSecaoComunidadeTitulo => 'SUPPORT, RETOURS ET COMMUNAUTÉ';

  @override
  String get configBotaoWhatsapp => 'COMMUNAUTÉ ARESTA SUR WHATSAPP';

  @override
  String get configBotaoPortalWeb => 'PORTAIL OFFICIEL ARESTA CLIMB';

  @override
  String get configRotuloContaOidc => 'Compte OIDC';

  @override
  String get configContaOidcNaoVinculada => 'Non lié (mode local)';

  @override
  String get configRotuloFingerprintChave => 'Clé ECDSA P-256';
}
