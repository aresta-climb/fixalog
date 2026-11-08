// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get seletorIdiomaTitulo => 'Idioma do Aplicativo';

  @override
  String get seletorIdiomaSubtitulo =>
      'Altera o idioma da interface, protocolos e novos laudos';

  @override
  String get comumSim => 'Sim';

  @override
  String get comumNao => 'Não';

  @override
  String get comumCancelar => 'CANCELAR';

  @override
  String get comumRemover => 'REMOVER';

  @override
  String get comumFechar => 'FECHAR';

  @override
  String comumErro(String detalhe) {
    return 'Erro: $detalhe';
  }

  @override
  String get termosTituloTela => 'Termos de Uso e Auditoria Técnica';

  @override
  String get termosCarregando => 'Carregando Termos de Uso...';

  @override
  String get termosErroCarregar =>
      'Não foi possível carregar os termos de uso locais. Por favor, tente novamente.';

  @override
  String get termosBotaoTentarNovamente => 'Tentar Novamente';

  @override
  String get termosBotaoLerPolitica => 'Ler Política de Privacidade';

  @override
  String get termosCheckboxDeclaro =>
      'Li e concordo com os Termos de Uso e a Política de Privacidade.';

  @override
  String get termosBotaoAceitar => 'Aceitar Termos e Continuar';

  @override
  String get termosBotaoRoleFinal => 'Role até o final para habilitar';

  @override
  String get politicaPrivacidadeTitulo => 'Política de Privacidade - Fixalog';

  @override
  String get politicaPrivacidadeErroCarregar =>
      'Não foi possível carregar a Política de Privacidade.';

  @override
  String get identidadeTituloInicial => 'IDENTIDADE TÉCNICA';

  @override
  String get identidadeTituloEdicao => 'EDITAR IDENTIDADE TÉCNICA';

  @override
  String get identidadeSubtituloInicial =>
      'Configure seus dados para assinar relatórios técnicos.';

  @override
  String get identidadeSubtituloEdicao =>
      'Atualize seus dados cadastrais. Caso possua chave criptográfica ativa, ela será preservada.';

  @override
  String get identidadeLabelNome => 'Nome Completo *';

  @override
  String get identidadeHintNome => 'Ex: João da Silva';

  @override
  String get identidadeLabelApelido => 'Apelido (Opcional)';

  @override
  String get identidadeHintApelido => 'Ex: Montanha';

  @override
  String get identidadeLabelEmail => 'E-mail *';

  @override
  String get identidadeHintEmail => 'Ex: joao@exemplo.com';

  @override
  String get identidadeLabelAssociacao => 'Associação / Clube (Opcional)';

  @override
  String get identidadeHintAssociacao => 'Ex: FEMERJ, AGUIPERJ, etc.';

  @override
  String get identidadeErroNomeVazio => 'O nome completo não pode estar vazio.';

  @override
  String get identidadeErroEmailVazio => 'O e-mail não pode estar vazio.';

  @override
  String get identidadeErroEmailInvalido => 'Formato de e-mail inválido.';

  @override
  String identidadeErroSalvar(String erro) {
    return 'Falha ao salvar a identidade: $erro';
  }

  @override
  String get identidadeBotaoGerarChaves => 'GERAR CHAVES E CONTINUAR';

  @override
  String get identidadeBotaoSalvarAlteracoes => 'SALVAR ALTERAÇÕES';

  @override
  String get homeAbaNovo => 'NOVO';

  @override
  String get homeAbaHistorico => 'HISTÓRICO';

  @override
  String get homeAbaConfig => 'CONFIG';

  @override
  String get configTituloSecaoIdentidade => 'IDENTIDADE E CHAVE CRIPTOGRÁFICA';

  @override
  String get configCertificadoAtivo => 'CERTIFICADO X.509 ATIVO';

  @override
  String get configBotaoEditarDados => 'EDITAR DADOS CADASTRAIS';

  @override
  String get configBotaoExportarChave => 'EXPORTAR CHAVE DE IDENTIDADE';

  @override
  String get configBotaoImportarChave => 'IMPORTAR CHAVE DE IDENTIDADE';

  @override
  String get configExportarTituloModal => 'EXPORTAR CHAVE DE IDENTIDADE';

  @override
  String get configExportarDescricaoModal =>
      'Defina uma senha forte (mínimo 8 caracteres) para criptografar o arquivo .fixalogkey com PBKDF2 + AES-256-GCM.';

  @override
  String get configLabelSenhaExportacao => 'Senha do arquivo';

  @override
  String get configLabelConfirmarSenha => 'Confirmar senha';

  @override
  String get configErroSenhaCurta =>
      'A senha deve ter pelo menos 8 caracteres.';

  @override
  String get configErroSenhasDiferentes => 'As senhas não coincidem.';

  @override
  String get configBotaoExportar => 'EXPORTAR';

  @override
  String get configExportarSucesso =>
      'Backup da identidade exportado com sucesso.';

  @override
  String configExportarErro(String erro) {
    return 'Falha ao exportar chave: $erro';
  }

  @override
  String get configImportarTituloModal => 'IMPORTAR CHAVE DE IDENTIDADE';

  @override
  String get configImportarDescricaoModal =>
      'Digite a senha do arquivo .fixalogkey selecionado. A chave atual será substituída.';

  @override
  String get configBotaoImportar => 'IMPORTAR';

  @override
  String get configImportarSucesso =>
      'Identidade e chave criptográfica restauradas com sucesso!';

  @override
  String get configImportarErroSenha =>
      'Senha incorreta ou arquivo de chave corrompido.';

  @override
  String get novoProtocoloSelecione => 'SELECIONE O PROTOCOLO';

  @override
  String get novoProtocoloSubtitulo =>
      'Inicie uma nova coleta de dados auditada.';

  @override
  String get novoProtocoloCardInspecaoTitulo => 'Inspeção Visual';

  @override
  String get novoProtocoloCardInspecaoSub =>
      'Vistoria rápida do estado geral e corrosão sem intervenção mecânica.';

  @override
  String get novoProtocoloCardManutencaoTitulo => 'Manutenção';

  @override
  String get novoProtocoloCardManutencaoSub =>
      'Relatório completo de substituição de ancoragens, limpeza e reequipagem.';

  @override
  String get novoProtocoloCardAberturaTitulo => 'Abertura de Via';

  @override
  String get novoProtocoloCardAberturaSub =>
      'Cadastro completo de nova linha, conquistas, croqui e proteções.';

  @override
  String get novoProtocoloCardExpressoTitulo => 'Registro Expresso';

  @override
  String get novoProtocoloCardExpressoSub =>
      'Coleta rápida de fotos, vídeos, PDFs e notas livres em campo.';

  @override
  String get novoProtocoloCardMaterialTitulo => 'Material';

  @override
  String get novoProtocoloCardMaterialSub =>
      'Cadastro e rastreabilidade de insumos, lotes, notas fiscais e testes.';

  @override
  String novoProtocoloErroCarregar(String erro) {
    return 'Erro ao carregar protocolo: $erro';
  }

  @override
  String get historicoTitulo => 'HISTÓRICO DE AUDITORIAS';

  @override
  String get historicoSubtitulo => 'Sessões salvas localmente no dispositivo.';

  @override
  String historicoAbaRelatorios(int quantidade) {
    return 'RELATÓRIOS ($quantidade)';
  }

  @override
  String historicoAbaMateriais(int quantidade) {
    return 'MATERIAIS ($quantidade)';
  }

  @override
  String get historicoVazioRelatoriosTitulo => 'Nenhum relatório encontrado';

  @override
  String get historicoVazioRelatoriosSub =>
      'Inicie um novo protocolo na aba NOVO para registrar sua primeira auditoria.';

  @override
  String get historicoVazioMateriaisTitulo => 'Nenhum material cadastrado';

  @override
  String get historicoVazioMateriaisSub =>
      'Cadastre materiais na aba NOVO para utilizá-los nos relatórios de manutenção.';

  @override
  String get historicoBotaoNovoMaterial => 'CADASTRAR MATERIAL';

  @override
  String get historicoStatusConcluido => 'CONCLUÍDO';

  @override
  String get historicoStatusEmProgresso => 'EM PROGRESSO';

  @override
  String get historicoStatusFalha => 'FALHA';

  @override
  String get historicoBotaoVerRelatorio => 'VER RELATÓRIO';

  @override
  String get historicoBotaoGerarRelatorio => 'GERAR RELATÓRIO';

  @override
  String get historicoBotaoContinuar => 'CONTINUAR';

  @override
  String get historicoBotaoEditar => 'EDITAR';

  @override
  String get historicoBotaoDuplicar => 'DUPLICAR';

  @override
  String get historicoBotaoExcluir => 'EXCLUIR';

  @override
  String get historicoConfirmarExclusaoTitulo => 'Excluir registro?';

  @override
  String historicoConfirmarExclusaoCorpo(String titulo) {
    return 'Tem certeza que deseja excluir \"$titulo\"? Esta ação removerá os arquivos locais e não pode ser desfeita.';
  }

  @override
  String get historicoMaterialEmUsoTitulo => 'Material vinculado a relatórios';

  @override
  String get historicoMaterialEmUsoCorpo =>
      'Este material está referenciado em outros relatórios. Excluí-lo não apagará os laudos já emitidos, mas removerá o item do catálogo ativo.';

  @override
  String wizardPassoNumero(int numero) {
    return 'PASSO $numero';
  }

  @override
  String get wizardBotaoVoltarPasso => 'VOLTAR A ESTE PASSO';

  @override
  String get wizardBotaoConcluir => 'CONCLUIR';

  @override
  String get wizardBotaoSeguinte => 'SEGUINTE';

  @override
  String get wizardBotaoPular => 'PULAR';

  @override
  String wizardBotaoConcluirLista(int quantidade) {
    return 'CONCLUIR LISTA ($quantidade)';
  }

  @override
  String get wizardAvisoCamposObrigatorios =>
      'Preencha todos os campos obrigatórios para prosseguir.';

  @override
  String get wizardAvisoPassoAnteriorObrigatorio =>
      'Preencha todos os campos obrigatórios do passo anterior para prosseguir.';

  @override
  String get wizardAvisoCamposItemObrigatorios =>
      'Preencha os campos obrigatórios do item.';

  @override
  String get wizardBotaoAdicionarItem => 'ADICIONAR ITEM';

  @override
  String get wizardBotaoAdicionarOutro => 'ADICIONAR OUTRO';

  @override
  String wizardMinimoItensObrigatorios(int minimo) {
    return 'Mínimo $minimo item(ns) obrigatório(s).';
  }

  @override
  String get wizardSelecioneTipo => 'SELECIONE O TIPO';

  @override
  String get wizardBotaoConfirmarItem => 'CONFIRMAR ITEM';

  @override
  String get wizardRemoverItemTitulo => 'Remover item?';

  @override
  String wizardRemoverItemCorpo(String item) {
    return 'Remover \"$item\"?';
  }

  @override
  String get wizardHintTexto => 'Digite aqui...';

  @override
  String get wizardHintTextoArea =>
      'Digite aqui... (suporta **negrito**, *itálico*, # título e listas)';

  @override
  String get wizardHintNumeros => 'Apenas números';

  @override
  String get wizardGpsDesativado => 'Serviço de localização desativado.';

  @override
  String get wizardGpsCapturado => 'COORDENADAS CAPTURADAS';

  @override
  String get wizardGpsCapturar => 'CAPTURAR POSIÇÃO GPS';

  @override
  String get wizardMidiaAdicionar => 'ADICIONAR MÍDIA';

  @override
  String get wizardMidiaSubVazio => 'Fotos, vídeos ou PDFs';

  @override
  String get wizardMidiaSubMais => 'Adicionar outra foto, vídeo ou PDF';

  @override
  String get wizardMidiaPdfAnexado => 'PDF ANEXADO';

  @override
  String get wizardMidiaVideoGravado => 'VÍDEO GRAVADO';

  @override
  String get wizardMidiaFotoCapturada => 'FOTO CAPTURADA';

  @override
  String get wizardMidiaProcessandoUm => 'PROCESSANDO MÍDIA...';

  @override
  String wizardMidiaProcessandoVarios(int quantidade) {
    return 'PROCESSANDO $quantidade MÍDIAS...';
  }

  @override
  String get wizardMidiaProcessandoSub =>
      'Salvando e calculando integridade em segundo plano...';

  @override
  String get wizardMidiaModalTitulo => 'ADICIONAR MÍDIA (FOTO, VÍDEO OU PDF)';

  @override
  String get wizardMidiaTirarFoto => 'Tirar Foto com a Câmera';

  @override
  String get wizardMidiaGravarVideo => 'Gravar com a Câmera';

  @override
  String get wizardMidiaEscolherGaleria => 'Escolher da Galeria';

  @override
  String get wizardMidiaEscolherGaleriaSub => 'Fotos e vídeos';

  @override
  String get wizardMidiaSelecionarPdf => 'Selecionar Arquivo PDF';

  @override
  String get wizardRefMatVazioCatalogo =>
      'Nenhum material cadastrado no catálogo ainda.\nToque abaixo para cadastrar um novo material.';

  @override
  String get wizardRefMatVazioBloco =>
      'Nenhum material registrado no Bloco 1.\nVolte e adicione os materiais primeiro.';

  @override
  String get wizardBotaoCadastrarNovoMaterial => 'CADASTRAR NOVO MATERIAL';

  @override
  String get wizardConclusaoTitulo => 'PROTOCOLO CONCLUÍDO';

  @override
  String get wizardConclusaoSubtitulo =>
      'Todos os dados foram coletados offline.\nO registro está pronto para ser assinado e exportado.';

  @override
  String get wizardBotaoGerarRelatorio => 'GERAR RELATÓRIO';

  @override
  String get wizardSufixoCopia => 'Cópia';

  @override
  String get geracaoEmAndamentoTitulo => 'GERANDO RELATÓRIO';

  @override
  String get geracaoConcluidaTitulo => 'RELATÓRIO PRONTO';

  @override
  String get geracaoFalhaTitulo => 'FALHA NA GERAÇÃO';

  @override
  String get geracaoBotaoAbrirRelatorio => 'ABRIR RELATÓRIO';

  @override
  String get visualizadorAbaEpub => 'LAUDO EPUB 3';

  @override
  String get visualizadorAbaPdf => 'RESUMO PDF';

  @override
  String get visualizadorBotaoCompartilhar => 'COMPARTILHAR';

  @override
  String get visualizadorBotaoAbrirExterno => 'ABRIR EXTERNO';

  @override
  String get laudoRotuloProtocolo => 'PROTOCOLO';

  @override
  String get laudoRotuloSessao => 'SESSÃO';

  @override
  String get laudoRotuloEmissao => 'EMISSÃO UTC';

  @override
  String get laudoRotuloVersao => 'VERSÃO';

  @override
  String get laudoSecaoIdentidadeTitulo => 'IDENTIDADE TÉCNICA DO EMISSOR';

  @override
  String get laudoRotuloNome => 'Nome';

  @override
  String get laudoRotuloEmail => 'E-mail';

  @override
  String get laudoRotuloAssociacao => 'Associação';

  @override
  String get laudoSecaoIntegridadeTitulo =>
      'INTEGRIDADE CRIPTOGRÁFICA E CADEIA DE CUSTÓDIA';

  @override
  String get laudoAvisoResumoImpresso =>
      'Este PDF é um resumo executivo para impressão rápida. O laudo pericial completo com mídias de alta resolução, vídeos e assinatura digital XML-DSig X.509 encontra-se no arquivo EPUB 3 correspondente.';

  @override
  String get laudoSecaoAnexoCatalogoTitulo =>
      'ANEXO — CATÁLOGO DE MATERIAIS REFERENCIADOS';

  @override
  String get laudoRotuloVideoAnexo => 'Vídeo anexado no EPUB 3';

  @override
  String laudoRotuloDocumentoPdf(int paginas) {
    return 'Documento PDF ($paginas pág.)';
  }
}
