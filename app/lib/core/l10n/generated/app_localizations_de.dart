// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get seletorIdiomaTitulo => 'App-Sprache';

  @override
  String get seletorIdiomaSubtitulo =>
      'Ändert die Sprache der Benutzeroberfläche, Protokolle und neuen Berichte';

  @override
  String get comumSim => 'Ja';

  @override
  String get comumNao => 'Nein';

  @override
  String get comumCancelar => 'ABBRECHEN';

  @override
  String get comumRemover => 'ENTFERNEN';

  @override
  String get comumFechar => 'SCHLIESSEN';

  @override
  String comumErro(String detalhe) {
    return 'Fehler: $detalhe';
  }

  @override
  String get termosTituloTela => 'Nutzungsbedingungen und Technische Prüfung';

  @override
  String get termosCarregando => 'Nutzungsbedingungen werden geladen...';

  @override
  String get termosErroCarregar =>
      'Die lokalen Nutzungsbedingungen konnten nicht geladen werden. Bitte versuchen Sie es erneut.';

  @override
  String get termosBotaoTentarNovamente => 'Erneut Versuchen';

  @override
  String get termosBotaoLerPolitica => 'Datenschutzerklärung Lesen';

  @override
  String get termosCheckboxDeclaro =>
      'Ich habe die Nutzungsbedingungen und die Datenschutzerklärung gelesen und stimme ihnen zu.';

  @override
  String get termosBotaoAceitar => 'Bedingungen Akzeptieren und Fortfahren';

  @override
  String get termosBotaoRoleFinal => 'Nach unten scrollen, um zu aktivieren';

  @override
  String get politicaPrivacidadeTitulo => 'Datenschutzerklärung - Fixalog';

  @override
  String get politicaPrivacidadeErroCarregar =>
      'Die Datenschutzerklärung konnte nicht geladen werden.';

  @override
  String get identidadeTituloInicial => 'TECHNISCHE IDENTITÄT';

  @override
  String get identidadeTituloEdicao => 'TECHNISCHE IDENTITÄT BEARBEITEN';

  @override
  String get identidadeSubtituloInicial =>
      'Richten Sie Ihre Daten ein, um technische Berichte digital zu signieren.';

  @override
  String get identidadeSubtituloEdicao =>
      'Aktualisieren Sie Ihre Profildaten. Ihr aktiver kryptografischer Schlüssel bleibt erhalten.';

  @override
  String get identidadeLabelNome => 'Vollständiger Name *';

  @override
  String get identidadeHintNome => 'Z. B. Max Mustermann';

  @override
  String get identidadeLabelApelido => 'Spitzname (Optional)';

  @override
  String get identidadeHintApelido => 'Z. B. Alpinist';

  @override
  String get identidadeLabelEmail => 'E-Mail *';

  @override
  String get identidadeHintEmail => 'Z. B. max@beispiel.de';

  @override
  String get identidadeLabelAssociacao => 'Verband / Verein (Optional)';

  @override
  String get identidadeHintAssociacao => 'Z. B. DAV, ÖAV, SAC, UIAA...';

  @override
  String get identidadeErroNomeVazio =>
      'Der vollständige Name darf nicht leer sein.';

  @override
  String get identidadeErroEmailVazio => 'Die E-Mail darf nicht leer sein.';

  @override
  String get identidadeErroEmailInvalido => 'Ungültiges E-Mail-Format.';

  @override
  String identidadeErroSalvar(String erro) {
    return 'Fehler beim Speichern der Identität: $erro';
  }

  @override
  String get identidadeBotaoGerarChaves =>
      'SCHLÜSSEL GENERIEREN UND FORTFAHREN';

  @override
  String get identidadeBotaoSalvarAlteracoes => 'ÄNDERUNGEN SPEICHERN';

  @override
  String get homeAbaNovo => 'NEU';

  @override
  String get homeAbaHistorico => 'VERLAUF';

  @override
  String get homeAbaConfig => 'OPTIONEN';

  @override
  String get configTituloSecaoIdentidade =>
      'IDENTITÄT UND KRYPTOGRAFISCHER SCHLÜSSEL';

  @override
  String get configCertificadoAtivo => 'AKTIVES X.509-ZERTIFIKAT';

  @override
  String get configBotaoEditarDados => 'PROFILDATEN BEARBEITEN';

  @override
  String get configBotaoExportarChave => 'IDENTITÄTSSCHLÜSSEL EXPORTIEREN';

  @override
  String get configBotaoImportarChave => 'IDENTITÄTSSCHLÜSSEL IMPORTIEREN';

  @override
  String get configExportarTituloModal => 'IDENTITÄTSSCHLÜSSEL EXPORTIEREN';

  @override
  String get configExportarDescricaoModal =>
      'Legen Sie ein starkes Passwort (mindestens 8 Zeichen) fest, um die .fixalogkey-Datei mit PBKDF2 + AES-256-GCM zu verschlüsseln.';

  @override
  String get configLabelSenhaExportacao => 'Dateipasswort';

  @override
  String get configLabelConfirmarSenha => 'Passwort bestätigen';

  @override
  String get configErroSenhaCurta =>
      'Das Passwort muss mindestens 8 Zeichen lang sein.';

  @override
  String get configErroSenhasDiferentes =>
      'Die Passwörter stimmen nicht überein.';

  @override
  String get configBotaoExportar => 'EXPORTIEREN';

  @override
  String get configExportarSucesso =>
      'Identitäts-Backup erfolgreich exportiert.';

  @override
  String configExportarErro(String erro) {
    return 'Fehler beim Exportieren des Schlüssels: $erro';
  }

  @override
  String get configImportarTituloModal => 'IDENTITÄTSSCHLÜSSEL IMPORTIEREN';

  @override
  String get configImportarDescricaoModal =>
      'Geben Sie das Passwort der ausgewählten .fixalogkey-Datei ein. Der aktuelle Schlüssel wird ersetzt.';

  @override
  String get configBotaoImportar => 'IMPORTIEREN';

  @override
  String get configImportarSucesso =>
      'Identität und kryptografischer Schlüssel erfolgreich wiederhergestellt!';

  @override
  String get configImportarErroSenha =>
      'Falsches Passwort oder beschädigte Schlüsseldatei.';

  @override
  String get novoProtocoloSelecione => 'PROTOKOLL AUSWÄHLEN';

  @override
  String get novoProtocoloSubtitulo =>
      'Starten Sie eine neue geprüfte Datenerfassung.';

  @override
  String get novoProtocoloCardInspecaoTitulo => 'Sichtprüfung';

  @override
  String get novoProtocoloCardInspecaoSub =>
      'Schnelle Überprüfung von Allgemeinzustand und Korrosion ohne mechanischen Eingriff.';

  @override
  String get novoProtocoloCardManutencaoTitulo => 'Wartung';

  @override
  String get novoProtocoloCardManutencaoSub =>
      'Vollständiger Bericht über Hakenwechsel, Reinigung und Sanierung.';

  @override
  String get novoProtocoloCardAberturaTitulo => 'Neutour / Erstbegehung';

  @override
  String get novoProtocoloCardAberturaSub =>
      'Vollständige Dokumentation einer neuen Linie, Topo und installierter Sicherungen.';

  @override
  String get novoProtocoloCardExpressoTitulo => 'Express-Protokoll';

  @override
  String get novoProtocoloCardExpressoSub =>
      'Schnelle Erfassung von Fotos, Videos, PDFs und freien Feldnotizen.';

  @override
  String get novoProtocoloCardMaterialTitulo => 'Material';

  @override
  String get novoProtocoloCardMaterialSub =>
      'Erfassung und Rückverfolgbarkeit von Material, Chargen, Belegen und Prüfungen.';

  @override
  String novoProtocoloErroCarregar(String erro) {
    return 'Fehler beim Laden des Protokolls: $erro';
  }

  @override
  String get historicoTitulo => 'PRÜFUNGSVERLAUF';

  @override
  String get historicoSubtitulo =>
      'Lokal auf dem Gerät gespeicherte Sitzungen.';

  @override
  String historicoAbaRelatorios(int quantidade) {
    return 'BERICHTE ($quantidade)';
  }

  @override
  String historicoAbaMateriais(int quantidade) {
    return 'MATERIALIEN ($quantidade)';
  }

  @override
  String get historicoVazioRelatoriosTitulo => 'Keine Berichte gefunden';

  @override
  String get historicoVazioRelatoriosSub =>
      'Starten Sie ein neues Protokoll im Reiter NEU, um Ihre erste Prüfung aufzuzeichnen.';

  @override
  String get historicoVazioMateriaisTitulo => 'Keine Materialien registriert';

  @override
  String get historicoVazioMateriaisSub =>
      'Registrieren Sie Materialien im Reiter NEU, um sie in Wartungsberichten zu verwenden.';

  @override
  String get historicoBotaoNovoMaterial => 'MATERIAL REGISTRIEREN';

  @override
  String get historicoStatusConcluido => 'ABGESCHLOSSEN';

  @override
  String get historicoStatusEmProgresso => 'IN BEARBEITUNG';

  @override
  String get historicoStatusFalha => 'FEHLGESCHLAGEN';

  @override
  String get historicoBotaoVerRelatorio => 'BERICHT ANSEHEN';

  @override
  String get historicoBotaoGerarRelatorio => 'BERICHT ERSTELLEN';

  @override
  String get historicoBotaoContinuar => 'FORTSETZEN';

  @override
  String get historicoBotaoEditar => 'BEARBEITEN';

  @override
  String get historicoBotaoDuplicar => 'DUPLIZIEREN';

  @override
  String get historicoBotaoExcluir => 'LÖSCHEN';

  @override
  String get historicoConfirmarExclusaoTitulo => 'Eintrag löschen?';

  @override
  String historicoConfirmarExclusaoCorpo(String titulo) {
    return 'Möchten Sie \"$titulo\" wirklich löschen? Diese Aktion entfernt lokale Dateien und kann nicht rückgängig gemacht werden.';
  }

  @override
  String get historicoMaterialEmUsoTitulo => 'Material mit Berichten verknüpft';

  @override
  String get historicoMaterialEmUsoCorpo =>
      'Dieses Material wird in anderen Berichten referenziert. Durch das Löschen werden bereits ausgestellte Berichte nicht gelöscht, das Element wird jedoch aus dem aktiven Katalog entfernt.';

  @override
  String wizardPassoNumero(int numero) {
    return 'SCHRITT $numero';
  }

  @override
  String get wizardBotaoVoltarPasso => 'ZU DIESEM SCHRITT ZURÜCKKEHREN';

  @override
  String get wizardBotaoConcluir => 'ABSCHLIESSEN';

  @override
  String get wizardBotaoSeguinte => 'WEITER';

  @override
  String get wizardBotaoPular => 'ÜBERSPRINGEN';

  @override
  String wizardBotaoConcluirLista(int quantidade) {
    return 'LISTE ABSCHLIESSEN ($quantidade)';
  }

  @override
  String get wizardAvisoCamposObrigatorios =>
      'Bitte füllen Sie alle Pflichtfelder aus, um fortzufahren.';

  @override
  String get wizardAvisoPassoAnteriorObrigatorio =>
      'Bitte füllen Sie alle Pflichtfelder des vorherigen Schritts aus, um fortzufahren.';

  @override
  String get wizardAvisoCamposItemObrigatorios =>
      'Bitte füllen Sie die Pflichtfelder des Elements aus.';

  @override
  String get wizardBotaoAdicionarItem => 'ELEMENT HINZUFÜGEN';

  @override
  String get wizardBotaoAdicionarOutro => 'WEITERES HINZUFÜGEN';

  @override
  String wizardMinimoItensObrigatorios(int minimo) {
    return 'Mindestens $minimo Pflichtelement(e).';
  }

  @override
  String get wizardSelecioneTipo => 'TYP AUSWÄHLEN';

  @override
  String get wizardBotaoConfirmarItem => 'ELEMENT BESTÄTIGEN';

  @override
  String get wizardRemoverItemTitulo => 'Element entfernen?';

  @override
  String wizardRemoverItemCorpo(String item) {
    return '\"$item\" entfernen?';
  }

  @override
  String get wizardHintTexto => 'Hier eingeben...';

  @override
  String get wizardHintTextoArea =>
      'Hier eingeben... (unterstützt **fett**, *kursiv*, # Überschrift und Listen)';

  @override
  String get wizardHintNumeros => 'Nur Zahlen';

  @override
  String get wizardGpsDesativado => 'Standortdienst deaktiviert.';

  @override
  String get wizardGpsCapturado => 'KOORDINATEN ERFASST';

  @override
  String get wizardGpsCapturar => 'GPS-POSITION ERFASSEN';

  @override
  String get wizardMidiaAdicionar => 'MEDIEN HINZUFÜGEN';

  @override
  String get wizardMidiaSubVazio => 'Fotos, Videos oder PDFs';

  @override
  String get wizardMidiaSubMais => 'Weiteres Foto, Video oder PDF hinzufügen';

  @override
  String get wizardMidiaPdfAnexado => 'PDF ANGEHÄNGT';

  @override
  String get wizardMidiaVideoGravado => 'VIDEO AUFGENOMMEN';

  @override
  String get wizardMidiaFotoCapturada => 'FOTO AUFGENOMMEN';

  @override
  String get wizardMidiaProcessandoUm => 'MEDIEN WERDEN VERARBEITET...';

  @override
  String wizardMidiaProcessandoVarios(int quantidade) {
    return '$quantidade MEDIEN WERDEN VERARBEITET...';
  }

  @override
  String get wizardMidiaProcessandoSub =>
      'Speichern und Integritätsberechnung im Hintergrund...';

  @override
  String get wizardMidiaModalTitulo =>
      'MEDIEN HINZUFÜGEN (FOTO, VIDEO ODER PDF)';

  @override
  String get wizardMidiaTirarFoto => 'Foto mit Kamera aufnehmen';

  @override
  String get wizardMidiaGravarVideo => 'Video mit Kamera aufnehmen';

  @override
  String get wizardMidiaEscolherGaleria => 'Aus Galerie auswählen';

  @override
  String get wizardMidiaEscolherGaleriaSub => 'Fotos und Videos';

  @override
  String get wizardMidiaSelecionarPdf => 'PDF-Datei auswählen';

  @override
  String get wizardRefMatVazioCatalogo =>
      'Noch keine Materialien im Katalog registriert.\nTippen Sie unten, um ein neues Material zu registrieren.';

  @override
  String get wizardRefMatVazioBloco =>
      'Keine Materialien in Block 1 registriert.\nGehen Sie zurück und fügen Sie zuerst Materialien hinzu.';

  @override
  String get wizardBotaoCadastrarNovoMaterial => 'NEUES MATERIAL REGISTRIEREN';

  @override
  String get wizardConclusaoTitulo => 'PROTOKOLL ABGESCHLOSSEN';

  @override
  String get wizardConclusaoSubtitulo =>
      'Alle Daten wurden offline erfasst.\nDer Eintrag ist bereit zum Signieren und Exportieren.';

  @override
  String get wizardBotaoGerarRelatorio => 'BERICHT ERSTELLEN';

  @override
  String get wizardSufixoCopia => 'Kopie';

  @override
  String get geracaoEmAndamentoTitulo => 'BERICHT WIRD ERSTELLT';

  @override
  String get geracaoConcluidaTitulo => 'BERICHT BEREIT';

  @override
  String get geracaoFalhaTitulo => 'ERSTELLUNG FEHLGESCHLAGEN';

  @override
  String get geracaoBotaoAbrirRelatorio => 'BERICHT ÖFFNEN';

  @override
  String get visualizadorAbaEpub => 'EPUB 3 BERICHT';

  @override
  String get visualizadorAbaPdf => 'PDF-ZUSAMMENFASSUNG';

  @override
  String get visualizadorBotaoCompartilhar => 'TEILEN';

  @override
  String get visualizadorBotaoAbrirExterno => 'EXTERN ÖFFNEN';

  @override
  String get laudoRotuloProtocolo => 'PROTOKOLL';

  @override
  String get laudoRotuloSessao => 'SITZUNG';

  @override
  String get laudoRotuloEmissao => 'AUSGESTELLT UTC';

  @override
  String get laudoRotuloVersao => 'VERSION';

  @override
  String get laudoSecaoIdentidadeTitulo =>
      'TECHNISCHE IDENTITÄT DES AUSSTELLERS';

  @override
  String get laudoRotuloNome => 'Name';

  @override
  String get laudoRotuloEmail => 'E-Mail';

  @override
  String get laudoRotuloAssociacao => 'Verband';

  @override
  String get laudoSecaoIntegridadeTitulo =>
      'KRYPTOGRAFISCHE INTEGRITÄT UND NACHWEISKETTE';

  @override
  String get laudoAvisoResumoImpresso =>
      'Dieses PDF ist eine Kurzzusammenfassung für den schnellen Ausdruck. Der vollständige Sachverständigenbericht mit hochauflösenden Medien, Videos und digitaler X.509 XML-DSig-Signatur befindet sich in der entsprechenden EPUB 3-Datei.';

  @override
  String get laudoSecaoAnexoCatalogoTitulo =>
      'ANHANG — KATALOG DER REFERENZIERTEN MATERIALIEN';

  @override
  String get laudoRotuloVideoAnexo => 'Video im EPUB 3 angehängt';

  @override
  String laudoRotuloDocumentoPdf(int paginas) {
    return 'PDF-Dokument ($paginas S.)';
  }

  @override
  String get feedbackTituloSheet => 'Worum geht es in Ihrer Rückmeldung?';

  @override
  String get feedbackCategoriaProtocolo => 'Protokoll';

  @override
  String get feedbackCategoriaAplicativo => 'App';

  @override
  String get feedbackHintDescricao =>
      'Beschreiben Sie das Problem, die Frage oder den Vorschlag...';

  @override
  String get feedbackAvisoOffline =>
      'Offline gespeichert und automatisch gesendet, sobald Empfang besteht.';

  @override
  String get feedbackBotaoEnviar => 'RÜCKMELDUNG SENDEN';

  @override
  String get feedbackSucessoEnvio =>
      'Rückmeldung gespeichert! Wird bei Verbindung automatisch gesendet.';

  @override
  String get configBotaoFeedback => 'PROBLEM ODER VORSCHLAG MELDEN';

  @override
  String get configSecaoGovernancaTitulo =>
      'GOVERNANCE UND RECHTLICHE BEDINGUNGEN';

  @override
  String configTermosVersaoAceita(int versao) {
    return 'Akzeptierte Version: v$versao';
  }

  @override
  String configTermosDataAceite(String dataHora) {
    return 'Zustimmung am: $dataHora';
  }

  @override
  String get configTermosPendente => 'Zustimmung ausstehend';

  @override
  String get configBotaoConsultarTermos =>
      'NUTZUNGSBEDINGUNGEN & DATENSCHUTZ ANSEHEN';

  @override
  String get configSecaoComunidadeTitulo => 'SUPPORT, FEEDBACK & COMMUNITY';

  @override
  String get configBotaoWhatsapp => 'ARESTA-COMMUNITY AUF WHATSAPP';

  @override
  String get configBotaoPortalWeb => 'OFFIZIELLES ARESTA CLIMB PORTAL';

  @override
  String get configRotuloContaOidc => 'OIDC-Konto';

  @override
  String get configContaOidcNaoVinculada => 'Nicht verknüpft (lokaler Modus)';

  @override
  String get configRotuloFingerprintChave => 'ECDSA P-256 Schlüssel';
}
