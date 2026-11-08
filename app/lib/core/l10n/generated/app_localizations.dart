// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('pt'),
  ];

  /// No description provided for @seletorIdiomaTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Idioma do Aplicativo'**
  String get seletorIdiomaTitulo;

  /// No description provided for @seletorIdiomaSubtitulo.
  ///
  /// In pt, this message translates to:
  /// **'Altera o idioma da interface, protocolos e novos laudos'**
  String get seletorIdiomaSubtitulo;

  /// No description provided for @comumSim.
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get comumSim;

  /// No description provided for @comumNao.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get comumNao;

  /// No description provided for @comumCancelar.
  ///
  /// In pt, this message translates to:
  /// **'CANCELAR'**
  String get comumCancelar;

  /// No description provided for @comumRemover.
  ///
  /// In pt, this message translates to:
  /// **'REMOVER'**
  String get comumRemover;

  /// No description provided for @comumFechar.
  ///
  /// In pt, this message translates to:
  /// **'FECHAR'**
  String get comumFechar;

  /// No description provided for @comumErro.
  ///
  /// In pt, this message translates to:
  /// **'Erro: {detalhe}'**
  String comumErro(String detalhe);

  /// No description provided for @termosTituloTela.
  ///
  /// In pt, this message translates to:
  /// **'Termos de Uso e Auditoria Técnica'**
  String get termosTituloTela;

  /// No description provided for @termosCarregando.
  ///
  /// In pt, this message translates to:
  /// **'Carregando Termos de Uso...'**
  String get termosCarregando;

  /// No description provided for @termosErroCarregar.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os termos de uso locais. Por favor, tente novamente.'**
  String get termosErroCarregar;

  /// No description provided for @termosBotaoTentarNovamente.
  ///
  /// In pt, this message translates to:
  /// **'Tentar Novamente'**
  String get termosBotaoTentarNovamente;

  /// No description provided for @termosBotaoLerPolitica.
  ///
  /// In pt, this message translates to:
  /// **'Ler Política de Privacidade'**
  String get termosBotaoLerPolitica;

  /// No description provided for @termosCheckboxDeclaro.
  ///
  /// In pt, this message translates to:
  /// **'Li e concordo com os Termos de Uso e a Política de Privacidade.'**
  String get termosCheckboxDeclaro;

  /// No description provided for @termosBotaoAceitar.
  ///
  /// In pt, this message translates to:
  /// **'Aceitar Termos e Continuar'**
  String get termosBotaoAceitar;

  /// No description provided for @termosBotaoRoleFinal.
  ///
  /// In pt, this message translates to:
  /// **'Role até o final para habilitar'**
  String get termosBotaoRoleFinal;

  /// No description provided for @politicaPrivacidadeTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Política de Privacidade - Fixalog'**
  String get politicaPrivacidadeTitulo;

  /// No description provided for @politicaPrivacidadeErroCarregar.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar a Política de Privacidade.'**
  String get politicaPrivacidadeErroCarregar;

  /// No description provided for @identidadeTituloInicial.
  ///
  /// In pt, this message translates to:
  /// **'IDENTIDADE TÉCNICA'**
  String get identidadeTituloInicial;

  /// No description provided for @identidadeTituloEdicao.
  ///
  /// In pt, this message translates to:
  /// **'EDITAR IDENTIDADE TÉCNICA'**
  String get identidadeTituloEdicao;

  /// No description provided for @identidadeSubtituloInicial.
  ///
  /// In pt, this message translates to:
  /// **'Configure seus dados para assinar relatórios técnicos.'**
  String get identidadeSubtituloInicial;

  /// No description provided for @identidadeSubtituloEdicao.
  ///
  /// In pt, this message translates to:
  /// **'Atualize seus dados cadastrais. Caso possua chave criptográfica ativa, ela será preservada.'**
  String get identidadeSubtituloEdicao;

  /// No description provided for @identidadeLabelNome.
  ///
  /// In pt, this message translates to:
  /// **'Nome Completo *'**
  String get identidadeLabelNome;

  /// No description provided for @identidadeHintNome.
  ///
  /// In pt, this message translates to:
  /// **'Ex: João da Silva'**
  String get identidadeHintNome;

  /// No description provided for @identidadeLabelApelido.
  ///
  /// In pt, this message translates to:
  /// **'Apelido (Opcional)'**
  String get identidadeLabelApelido;

  /// No description provided for @identidadeHintApelido.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Montanha'**
  String get identidadeHintApelido;

  /// No description provided for @identidadeLabelEmail.
  ///
  /// In pt, this message translates to:
  /// **'E-mail *'**
  String get identidadeLabelEmail;

  /// No description provided for @identidadeHintEmail.
  ///
  /// In pt, this message translates to:
  /// **'Ex: joao@exemplo.com'**
  String get identidadeHintEmail;

  /// No description provided for @identidadeLabelAssociacao.
  ///
  /// In pt, this message translates to:
  /// **'Associação / Clube (Opcional)'**
  String get identidadeLabelAssociacao;

  /// No description provided for @identidadeHintAssociacao.
  ///
  /// In pt, this message translates to:
  /// **'Ex: FEMERJ, AGUIPERJ, etc.'**
  String get identidadeHintAssociacao;

  /// No description provided for @identidadeErroNomeVazio.
  ///
  /// In pt, this message translates to:
  /// **'O nome completo não pode estar vazio.'**
  String get identidadeErroNomeVazio;

  /// No description provided for @identidadeErroEmailVazio.
  ///
  /// In pt, this message translates to:
  /// **'O e-mail não pode estar vazio.'**
  String get identidadeErroEmailVazio;

  /// No description provided for @identidadeErroEmailInvalido.
  ///
  /// In pt, this message translates to:
  /// **'Formato de e-mail inválido.'**
  String get identidadeErroEmailInvalido;

  /// No description provided for @identidadeErroSalvar.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao salvar a identidade: {erro}'**
  String identidadeErroSalvar(String erro);

  /// No description provided for @identidadeBotaoGerarChaves.
  ///
  /// In pt, this message translates to:
  /// **'GERAR CHAVES E CONTINUAR'**
  String get identidadeBotaoGerarChaves;

  /// No description provided for @identidadeBotaoSalvarAlteracoes.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR ALTERAÇÕES'**
  String get identidadeBotaoSalvarAlteracoes;

  /// No description provided for @homeAbaNovo.
  ///
  /// In pt, this message translates to:
  /// **'NOVO'**
  String get homeAbaNovo;

  /// No description provided for @homeAbaHistorico.
  ///
  /// In pt, this message translates to:
  /// **'HISTÓRICO'**
  String get homeAbaHistorico;

  /// No description provided for @homeAbaConfig.
  ///
  /// In pt, this message translates to:
  /// **'CONFIG'**
  String get homeAbaConfig;

  /// No description provided for @configTituloSecaoIdentidade.
  ///
  /// In pt, this message translates to:
  /// **'IDENTIDADE E CHAVE CRIPTOGRÁFICA'**
  String get configTituloSecaoIdentidade;

  /// No description provided for @configCertificadoAtivo.
  ///
  /// In pt, this message translates to:
  /// **'CERTIFICADO X.509 ATIVO'**
  String get configCertificadoAtivo;

  /// No description provided for @configBotaoEditarDados.
  ///
  /// In pt, this message translates to:
  /// **'EDITAR DADOS CADASTRAIS'**
  String get configBotaoEditarDados;

  /// No description provided for @configBotaoExportarChave.
  ///
  /// In pt, this message translates to:
  /// **'EXPORTAR CHAVE DE IDENTIDADE'**
  String get configBotaoExportarChave;

  /// No description provided for @configBotaoImportarChave.
  ///
  /// In pt, this message translates to:
  /// **'IMPORTAR CHAVE DE IDENTIDADE'**
  String get configBotaoImportarChave;

  /// No description provided for @configExportarTituloModal.
  ///
  /// In pt, this message translates to:
  /// **'EXPORTAR CHAVE DE IDENTIDADE'**
  String get configExportarTituloModal;

  /// No description provided for @configExportarDescricaoModal.
  ///
  /// In pt, this message translates to:
  /// **'Defina uma senha forte (mínimo 8 caracteres) para criptografar o arquivo .fixalogkey com PBKDF2 + AES-256-GCM.'**
  String get configExportarDescricaoModal;

  /// No description provided for @configLabelSenhaExportacao.
  ///
  /// In pt, this message translates to:
  /// **'Senha do arquivo'**
  String get configLabelSenhaExportacao;

  /// No description provided for @configLabelConfirmarSenha.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar senha'**
  String get configLabelConfirmarSenha;

  /// No description provided for @configErroSenhaCurta.
  ///
  /// In pt, this message translates to:
  /// **'A senha deve ter pelo menos 8 caracteres.'**
  String get configErroSenhaCurta;

  /// No description provided for @configErroSenhasDiferentes.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem.'**
  String get configErroSenhasDiferentes;

  /// No description provided for @configBotaoExportar.
  ///
  /// In pt, this message translates to:
  /// **'EXPORTAR'**
  String get configBotaoExportar;

  /// No description provided for @configExportarSucesso.
  ///
  /// In pt, this message translates to:
  /// **'Backup da identidade exportado com sucesso.'**
  String get configExportarSucesso;

  /// No description provided for @configExportarErro.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao exportar chave: {erro}'**
  String configExportarErro(String erro);

  /// No description provided for @configImportarTituloModal.
  ///
  /// In pt, this message translates to:
  /// **'IMPORTAR CHAVE DE IDENTIDADE'**
  String get configImportarTituloModal;

  /// No description provided for @configImportarDescricaoModal.
  ///
  /// In pt, this message translates to:
  /// **'Digite a senha do arquivo .fixalogkey selecionado. A chave atual será substituída.'**
  String get configImportarDescricaoModal;

  /// No description provided for @configBotaoImportar.
  ///
  /// In pt, this message translates to:
  /// **'IMPORTAR'**
  String get configBotaoImportar;

  /// No description provided for @configImportarSucesso.
  ///
  /// In pt, this message translates to:
  /// **'Identidade e chave criptográfica restauradas com sucesso!'**
  String get configImportarSucesso;

  /// No description provided for @configImportarErroSenha.
  ///
  /// In pt, this message translates to:
  /// **'Senha incorreta ou arquivo de chave corrompido.'**
  String get configImportarErroSenha;

  /// No description provided for @novoProtocoloSelecione.
  ///
  /// In pt, this message translates to:
  /// **'SELECIONE O PROTOCOLO'**
  String get novoProtocoloSelecione;

  /// No description provided for @novoProtocoloSubtitulo.
  ///
  /// In pt, this message translates to:
  /// **'Inicie uma nova coleta de dados auditada.'**
  String get novoProtocoloSubtitulo;

  /// No description provided for @novoProtocoloCardInspecaoTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Inspeção Visual'**
  String get novoProtocoloCardInspecaoTitulo;

  /// No description provided for @novoProtocoloCardInspecaoSub.
  ///
  /// In pt, this message translates to:
  /// **'Vistoria rápida do estado geral e corrosão sem intervenção mecânica.'**
  String get novoProtocoloCardInspecaoSub;

  /// No description provided for @novoProtocoloCardManutencaoTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção'**
  String get novoProtocoloCardManutencaoTitulo;

  /// No description provided for @novoProtocoloCardManutencaoSub.
  ///
  /// In pt, this message translates to:
  /// **'Relatório completo de substituição de ancoragens, limpeza e reequipagem.'**
  String get novoProtocoloCardManutencaoSub;

  /// No description provided for @novoProtocoloCardAberturaTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Abertura de Via'**
  String get novoProtocoloCardAberturaTitulo;

  /// No description provided for @novoProtocoloCardAberturaSub.
  ///
  /// In pt, this message translates to:
  /// **'Cadastro completo de nova linha, conquistas, croqui e proteções.'**
  String get novoProtocoloCardAberturaSub;

  /// No description provided for @novoProtocoloCardExpressoTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Registro Expresso'**
  String get novoProtocoloCardExpressoTitulo;

  /// No description provided for @novoProtocoloCardExpressoSub.
  ///
  /// In pt, this message translates to:
  /// **'Coleta rápida de fotos, vídeos, PDFs e notas livres em campo.'**
  String get novoProtocoloCardExpressoSub;

  /// No description provided for @novoProtocoloCardMaterialTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Material'**
  String get novoProtocoloCardMaterialTitulo;

  /// No description provided for @novoProtocoloCardMaterialSub.
  ///
  /// In pt, this message translates to:
  /// **'Cadastro e rastreabilidade de insumos, lotes, notas fiscais e testes.'**
  String get novoProtocoloCardMaterialSub;

  /// No description provided for @novoProtocoloErroCarregar.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar protocolo: {erro}'**
  String novoProtocoloErroCarregar(String erro);

  /// No description provided for @historicoTitulo.
  ///
  /// In pt, this message translates to:
  /// **'HISTÓRICO DE AUDITORIAS'**
  String get historicoTitulo;

  /// No description provided for @historicoSubtitulo.
  ///
  /// In pt, this message translates to:
  /// **'Sessões salvas localmente no dispositivo.'**
  String get historicoSubtitulo;

  /// No description provided for @historicoAbaRelatorios.
  ///
  /// In pt, this message translates to:
  /// **'RELATÓRIOS ({quantidade})'**
  String historicoAbaRelatorios(int quantidade);

  /// No description provided for @historicoAbaMateriais.
  ///
  /// In pt, this message translates to:
  /// **'MATERIAIS ({quantidade})'**
  String historicoAbaMateriais(int quantidade);

  /// No description provided for @historicoVazioRelatoriosTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum relatório encontrado'**
  String get historicoVazioRelatoriosTitulo;

  /// No description provided for @historicoVazioRelatoriosSub.
  ///
  /// In pt, this message translates to:
  /// **'Inicie um novo protocolo na aba NOVO para registrar sua primeira auditoria.'**
  String get historicoVazioRelatoriosSub;

  /// No description provided for @historicoVazioMateriaisTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum material cadastrado'**
  String get historicoVazioMateriaisTitulo;

  /// No description provided for @historicoVazioMateriaisSub.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre materiais na aba NOVO para utilizá-los nos relatórios de manutenção.'**
  String get historicoVazioMateriaisSub;

  /// No description provided for @historicoBotaoNovoMaterial.
  ///
  /// In pt, this message translates to:
  /// **'CADASTRAR MATERIAL'**
  String get historicoBotaoNovoMaterial;

  /// No description provided for @historicoStatusConcluido.
  ///
  /// In pt, this message translates to:
  /// **'CONCLUÍDO'**
  String get historicoStatusConcluido;

  /// No description provided for @historicoStatusEmProgresso.
  ///
  /// In pt, this message translates to:
  /// **'EM PROGRESSO'**
  String get historicoStatusEmProgresso;

  /// No description provided for @historicoStatusFalha.
  ///
  /// In pt, this message translates to:
  /// **'FALHA'**
  String get historicoStatusFalha;

  /// No description provided for @historicoBotaoVerRelatorio.
  ///
  /// In pt, this message translates to:
  /// **'VER RELATÓRIO'**
  String get historicoBotaoVerRelatorio;

  /// No description provided for @historicoBotaoGerarRelatorio.
  ///
  /// In pt, this message translates to:
  /// **'GERAR RELATÓRIO'**
  String get historicoBotaoGerarRelatorio;

  /// No description provided for @historicoBotaoContinuar.
  ///
  /// In pt, this message translates to:
  /// **'CONTINUAR'**
  String get historicoBotaoContinuar;

  /// No description provided for @historicoBotaoEditar.
  ///
  /// In pt, this message translates to:
  /// **'EDITAR'**
  String get historicoBotaoEditar;

  /// No description provided for @historicoBotaoDuplicar.
  ///
  /// In pt, this message translates to:
  /// **'DUPLICAR'**
  String get historicoBotaoDuplicar;

  /// No description provided for @historicoBotaoExcluir.
  ///
  /// In pt, this message translates to:
  /// **'EXCLUIR'**
  String get historicoBotaoExcluir;

  /// No description provided for @historicoConfirmarExclusaoTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Excluir registro?'**
  String get historicoConfirmarExclusaoTitulo;

  /// No description provided for @historicoConfirmarExclusaoCorpo.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja excluir \"{titulo}\"? Esta ação removerá os arquivos locais e não pode ser desfeita.'**
  String historicoConfirmarExclusaoCorpo(String titulo);

  /// No description provided for @historicoMaterialEmUsoTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Material vinculado a relatórios'**
  String get historicoMaterialEmUsoTitulo;

  /// No description provided for @historicoMaterialEmUsoCorpo.
  ///
  /// In pt, this message translates to:
  /// **'Este material está referenciado em outros relatórios. Excluí-lo não apagará os laudos já emitidos, mas removerá o item do catálogo ativo.'**
  String get historicoMaterialEmUsoCorpo;

  /// No description provided for @wizardPassoNumero.
  ///
  /// In pt, this message translates to:
  /// **'PASSO {numero}'**
  String wizardPassoNumero(int numero);

  /// No description provided for @wizardBotaoVoltarPasso.
  ///
  /// In pt, this message translates to:
  /// **'VOLTAR A ESTE PASSO'**
  String get wizardBotaoVoltarPasso;

  /// No description provided for @wizardBotaoConcluir.
  ///
  /// In pt, this message translates to:
  /// **'CONCLUIR'**
  String get wizardBotaoConcluir;

  /// No description provided for @wizardBotaoSeguinte.
  ///
  /// In pt, this message translates to:
  /// **'SEGUINTE'**
  String get wizardBotaoSeguinte;

  /// No description provided for @wizardBotaoPular.
  ///
  /// In pt, this message translates to:
  /// **'PULAR'**
  String get wizardBotaoPular;

  /// No description provided for @wizardBotaoConcluirLista.
  ///
  /// In pt, this message translates to:
  /// **'CONCLUIR LISTA ({quantidade})'**
  String wizardBotaoConcluirLista(int quantidade);

  /// No description provided for @wizardAvisoCamposObrigatorios.
  ///
  /// In pt, this message translates to:
  /// **'Preencha todos os campos obrigatórios para prosseguir.'**
  String get wizardAvisoCamposObrigatorios;

  /// No description provided for @wizardAvisoPassoAnteriorObrigatorio.
  ///
  /// In pt, this message translates to:
  /// **'Preencha todos os campos obrigatórios do passo anterior para prosseguir.'**
  String get wizardAvisoPassoAnteriorObrigatorio;

  /// No description provided for @wizardAvisoCamposItemObrigatorios.
  ///
  /// In pt, this message translates to:
  /// **'Preencha os campos obrigatórios do item.'**
  String get wizardAvisoCamposItemObrigatorios;

  /// No description provided for @wizardBotaoAdicionarItem.
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR ITEM'**
  String get wizardBotaoAdicionarItem;

  /// No description provided for @wizardBotaoAdicionarOutro.
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR OUTRO'**
  String get wizardBotaoAdicionarOutro;

  /// No description provided for @wizardMinimoItensObrigatorios.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo {minimo} item(ns) obrigatório(s).'**
  String wizardMinimoItensObrigatorios(int minimo);

  /// No description provided for @wizardSelecioneTipo.
  ///
  /// In pt, this message translates to:
  /// **'SELECIONE O TIPO'**
  String get wizardSelecioneTipo;

  /// No description provided for @wizardBotaoConfirmarItem.
  ///
  /// In pt, this message translates to:
  /// **'CONFIRMAR ITEM'**
  String get wizardBotaoConfirmarItem;

  /// No description provided for @wizardRemoverItemTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Remover item?'**
  String get wizardRemoverItemTitulo;

  /// No description provided for @wizardRemoverItemCorpo.
  ///
  /// In pt, this message translates to:
  /// **'Remover \"{item}\"?'**
  String wizardRemoverItemCorpo(String item);

  /// No description provided for @wizardHintTexto.
  ///
  /// In pt, this message translates to:
  /// **'Digite aqui...'**
  String get wizardHintTexto;

  /// No description provided for @wizardHintTextoArea.
  ///
  /// In pt, this message translates to:
  /// **'Digite aqui... (suporta **negrito**, *itálico*, # título e listas)'**
  String get wizardHintTextoArea;

  /// No description provided for @wizardHintNumeros.
  ///
  /// In pt, this message translates to:
  /// **'Apenas números'**
  String get wizardHintNumeros;

  /// No description provided for @wizardGpsDesativado.
  ///
  /// In pt, this message translates to:
  /// **'Serviço de localização desativado.'**
  String get wizardGpsDesativado;

  /// No description provided for @wizardGpsCapturado.
  ///
  /// In pt, this message translates to:
  /// **'COORDENADAS CAPTURADAS'**
  String get wizardGpsCapturado;

  /// No description provided for @wizardGpsCapturar.
  ///
  /// In pt, this message translates to:
  /// **'CAPTURAR POSIÇÃO GPS'**
  String get wizardGpsCapturar;

  /// No description provided for @wizardMidiaAdicionar.
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR MÍDIA'**
  String get wizardMidiaAdicionar;

  /// No description provided for @wizardMidiaSubVazio.
  ///
  /// In pt, this message translates to:
  /// **'Fotos, vídeos ou PDFs'**
  String get wizardMidiaSubVazio;

  /// No description provided for @wizardMidiaSubMais.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar outra foto, vídeo ou PDF'**
  String get wizardMidiaSubMais;

  /// No description provided for @wizardMidiaPdfAnexado.
  ///
  /// In pt, this message translates to:
  /// **'PDF ANEXADO'**
  String get wizardMidiaPdfAnexado;

  /// No description provided for @wizardMidiaVideoGravado.
  ///
  /// In pt, this message translates to:
  /// **'VÍDEO GRAVADO'**
  String get wizardMidiaVideoGravado;

  /// No description provided for @wizardMidiaFotoCapturada.
  ///
  /// In pt, this message translates to:
  /// **'FOTO CAPTURADA'**
  String get wizardMidiaFotoCapturada;

  /// No description provided for @wizardMidiaProcessandoUm.
  ///
  /// In pt, this message translates to:
  /// **'PROCESSANDO MÍDIA...'**
  String get wizardMidiaProcessandoUm;

  /// No description provided for @wizardMidiaProcessandoVarios.
  ///
  /// In pt, this message translates to:
  /// **'PROCESSANDO {quantidade} MÍDIAS...'**
  String wizardMidiaProcessandoVarios(int quantidade);

  /// No description provided for @wizardMidiaProcessandoSub.
  ///
  /// In pt, this message translates to:
  /// **'Salvando e calculando integridade em segundo plano...'**
  String get wizardMidiaProcessandoSub;

  /// No description provided for @wizardMidiaModalTitulo.
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR MÍDIA (FOTO, VÍDEO OU PDF)'**
  String get wizardMidiaModalTitulo;

  /// No description provided for @wizardMidiaTirarFoto.
  ///
  /// In pt, this message translates to:
  /// **'Tirar Foto com a Câmera'**
  String get wizardMidiaTirarFoto;

  /// No description provided for @wizardMidiaGravarVideo.
  ///
  /// In pt, this message translates to:
  /// **'Gravar com a Câmera'**
  String get wizardMidiaGravarVideo;

  /// No description provided for @wizardMidiaEscolherGaleria.
  ///
  /// In pt, this message translates to:
  /// **'Escolher da Galeria'**
  String get wizardMidiaEscolherGaleria;

  /// No description provided for @wizardMidiaEscolherGaleriaSub.
  ///
  /// In pt, this message translates to:
  /// **'Fotos e vídeos'**
  String get wizardMidiaEscolherGaleriaSub;

  /// No description provided for @wizardMidiaSelecionarPdf.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Arquivo PDF'**
  String get wizardMidiaSelecionarPdf;

  /// No description provided for @wizardRefMatVazioCatalogo.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum material cadastrado no catálogo ainda.\nToque abaixo para cadastrar um novo material.'**
  String get wizardRefMatVazioCatalogo;

  /// No description provided for @wizardRefMatVazioBloco.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum material registrado no Bloco 1.\nVolte e adicione os materiais primeiro.'**
  String get wizardRefMatVazioBloco;

  /// No description provided for @wizardBotaoCadastrarNovoMaterial.
  ///
  /// In pt, this message translates to:
  /// **'CADASTRAR NOVO MATERIAL'**
  String get wizardBotaoCadastrarNovoMaterial;

  /// No description provided for @wizardConclusaoTitulo.
  ///
  /// In pt, this message translates to:
  /// **'PROTOCOLO CONCLUÍDO'**
  String get wizardConclusaoTitulo;

  /// No description provided for @wizardConclusaoSubtitulo.
  ///
  /// In pt, this message translates to:
  /// **'Todos os dados foram coletados offline.\nO registro está pronto para ser assinado e exportado.'**
  String get wizardConclusaoSubtitulo;

  /// No description provided for @wizardBotaoGerarRelatorio.
  ///
  /// In pt, this message translates to:
  /// **'GERAR RELATÓRIO'**
  String get wizardBotaoGerarRelatorio;

  /// No description provided for @wizardSufixoCopia.
  ///
  /// In pt, this message translates to:
  /// **'Cópia'**
  String get wizardSufixoCopia;

  /// No description provided for @geracaoEmAndamentoTitulo.
  ///
  /// In pt, this message translates to:
  /// **'GERANDO RELATÓRIO'**
  String get geracaoEmAndamentoTitulo;

  /// No description provided for @geracaoConcluidaTitulo.
  ///
  /// In pt, this message translates to:
  /// **'RELATÓRIO PRONTO'**
  String get geracaoConcluidaTitulo;

  /// No description provided for @geracaoFalhaTitulo.
  ///
  /// In pt, this message translates to:
  /// **'FALHA NA GERAÇÃO'**
  String get geracaoFalhaTitulo;

  /// No description provided for @geracaoBotaoAbrirRelatorio.
  ///
  /// In pt, this message translates to:
  /// **'ABRIR RELATÓRIO'**
  String get geracaoBotaoAbrirRelatorio;

  /// No description provided for @visualizadorAbaEpub.
  ///
  /// In pt, this message translates to:
  /// **'LAUDO EPUB 3'**
  String get visualizadorAbaEpub;

  /// No description provided for @visualizadorAbaPdf.
  ///
  /// In pt, this message translates to:
  /// **'RESUMO PDF'**
  String get visualizadorAbaPdf;

  /// No description provided for @visualizadorBotaoCompartilhar.
  ///
  /// In pt, this message translates to:
  /// **'COMPARTILHAR'**
  String get visualizadorBotaoCompartilhar;

  /// No description provided for @visualizadorBotaoAbrirExterno.
  ///
  /// In pt, this message translates to:
  /// **'ABRIR EXTERNO'**
  String get visualizadorBotaoAbrirExterno;

  /// No description provided for @laudoRotuloProtocolo.
  ///
  /// In pt, this message translates to:
  /// **'PROTOCOLO'**
  String get laudoRotuloProtocolo;

  /// No description provided for @laudoRotuloSessao.
  ///
  /// In pt, this message translates to:
  /// **'SESSÃO'**
  String get laudoRotuloSessao;

  /// No description provided for @laudoRotuloEmissao.
  ///
  /// In pt, this message translates to:
  /// **'EMISSÃO UTC'**
  String get laudoRotuloEmissao;

  /// No description provided for @laudoRotuloVersao.
  ///
  /// In pt, this message translates to:
  /// **'VERSÃO'**
  String get laudoRotuloVersao;

  /// No description provided for @laudoSecaoIdentidadeTitulo.
  ///
  /// In pt, this message translates to:
  /// **'IDENTIDADE TÉCNICA DO EMISSOR'**
  String get laudoSecaoIdentidadeTitulo;

  /// No description provided for @laudoRotuloNome.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get laudoRotuloNome;

  /// No description provided for @laudoRotuloEmail.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get laudoRotuloEmail;

  /// No description provided for @laudoRotuloAssociacao.
  ///
  /// In pt, this message translates to:
  /// **'Associação'**
  String get laudoRotuloAssociacao;

  /// No description provided for @laudoSecaoIntegridadeTitulo.
  ///
  /// In pt, this message translates to:
  /// **'INTEGRIDADE CRIPTOGRÁFICA E CADEIA DE CUSTÓDIA'**
  String get laudoSecaoIntegridadeTitulo;

  /// No description provided for @laudoAvisoResumoImpresso.
  ///
  /// In pt, this message translates to:
  /// **'Este PDF é um resumo executivo para impressão rápida. O laudo pericial completo com mídias de alta resolução, vídeos e assinatura digital XML-DSig X.509 encontra-se no arquivo EPUB 3 correspondente.'**
  String get laudoAvisoResumoImpresso;

  /// No description provided for @laudoSecaoAnexoCatalogoTitulo.
  ///
  /// In pt, this message translates to:
  /// **'ANEXO — CATÁLOGO DE MATERIAIS REFERENCIADOS'**
  String get laudoSecaoAnexoCatalogoTitulo;

  /// No description provided for @laudoRotuloVideoAnexo.
  ///
  /// In pt, this message translates to:
  /// **'Vídeo anexado no EPUB 3'**
  String get laudoRotuloVideoAnexo;

  /// No description provided for @laudoRotuloDocumentoPdf.
  ///
  /// In pt, this message translates to:
  /// **'Documento PDF ({paginas} pág.)'**
  String laudoRotuloDocumentoPdf(int paginas);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
