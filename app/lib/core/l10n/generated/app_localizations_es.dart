// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get seletorIdiomaTitulo => 'Idioma de la Aplicación';

  @override
  String get seletorIdiomaSubtitulo =>
      'Cambia el idioma de la interfaz, protocolos y nuevos informes';

  @override
  String get comumSim => 'Sí';

  @override
  String get comumNao => 'No';

  @override
  String get comumCancelar => 'CANCELAR';

  @override
  String get comumRemover => 'ELIMINAR';

  @override
  String get comumFechar => 'CERRAR';

  @override
  String comumErro(String detalhe) {
    return 'Error: $detalhe';
  }

  @override
  String get termosTituloTela => 'Términos de Uso y Auditoría Técnica';

  @override
  String get termosCarregando => 'Cargando Términos de Uso...';

  @override
  String get termosErroCarregar =>
      'No se pudieron cargar los términos de uso locales. Por favor, inténtelo de nuevo.';

  @override
  String get termosBotaoTentarNovamente => 'Intentar de Nuevo';

  @override
  String get termosBotaoLerPolitica => 'Leer Política de Privacidad';

  @override
  String get termosCheckboxDeclaro =>
      'He leído y acepto los Términos de Uso y la Política de Privacidad.';

  @override
  String get termosBotaoAceitar => 'Aceptar Términos y Continuar';

  @override
  String get termosBotaoRoleFinal => 'Desplácese hasta el final para habilitar';

  @override
  String get politicaPrivacidadeTitulo => 'Política de Privacidad - Fixalog';

  @override
  String get politicaPrivacidadeErroCarregar =>
      'No se pudo cargar la Política de Privacidad.';

  @override
  String get identidadeTituloInicial => 'IDENTIDAD TÉCNICA';

  @override
  String get identidadeTituloEdicao => 'EDITAR IDENTIDAD TÉCNICA';

  @override
  String get identidadeSubtituloInicial =>
      'Configure sus datos para firmar informes técnicos.';

  @override
  String get identidadeSubtituloEdicao =>
      'Actualice sus datos de perfil. Su clave criptográfica activa se conservará.';

  @override
  String get identidadeLabelNome => 'Nombre Completo *';

  @override
  String get identidadeHintNome => 'Ej: Juan Pérez';

  @override
  String get identidadeLabelApelido => 'Apodo (Opcional)';

  @override
  String get identidadeHintApelido => 'Ej: Montaña';

  @override
  String get identidadeLabelEmail => 'Correo electrónico *';

  @override
  String get identidadeHintEmail => 'Ej: juan@ejemplo.com';

  @override
  String get identidadeLabelAssociacao => 'Asociación / Club (Opcional)';

  @override
  String get identidadeHintAssociacao => 'Ej: FEDME, UIAA, etc.';

  @override
  String get identidadeErroNomeVazio =>
      'El nombre completo no puede estar vacío.';

  @override
  String get identidadeErroEmailVazio =>
      'El correo electrónico no puede estar vacío.';

  @override
  String get identidadeErroEmailInvalido =>
      'Formato de correo electrónico inválido.';

  @override
  String identidadeErroSalvar(String erro) {
    return 'Error al guardar la identidad: $erro';
  }

  @override
  String get identidadeBotaoGerarChaves => 'GENERAR CLAVES Y CONTINUAR';

  @override
  String get identidadeBotaoSalvarAlteracoes => 'GUARDAR CAMBIOS';

  @override
  String get homeAbaNovo => 'NUEVO';

  @override
  String get homeAbaHistorico => 'HISTORIAL';

  @override
  String get homeAbaConfig => 'AJUSTES';

  @override
  String get configTituloSecaoIdentidade => 'IDENTIDAD Y CLAVE CRIPTOGRÁFICA';

  @override
  String get configCertificadoAtivo => 'CERTIFICADO X.509 ACTIVO';

  @override
  String get configBotaoEditarDados => 'EDITAR DATOS DE PERFIL';

  @override
  String get configBotaoExportarChave => 'EXPORTAR CLAVE DE IDENTIDAD';

  @override
  String get configBotaoImportarChave => 'IMPORTAR CLAVE DE IDENTIDAD';

  @override
  String get configExportarTituloModal => 'EXPORTAR CLAVE DE IDENTIDAD';

  @override
  String get configExportarDescricaoModal =>
      'Defina una contraseña segura (mínimo 8 caracteres) para cifrar el archivo .fixalogkey con PBKDF2 + AES-256-GCM.';

  @override
  String get configLabelSenhaExportacao => 'Contraseña del archivo';

  @override
  String get configLabelConfirmarSenha => 'Confirmar contraseña';

  @override
  String get configErroSenhaCurta =>
      'La contraseña debe tener al menos 8 caracteres.';

  @override
  String get configErroSenhasDiferentes => 'Las contraseñas no coinciden.';

  @override
  String get configBotaoExportar => 'EXPORTAR';

  @override
  String get configExportarSucesso =>
      'Copia de seguridad de identidad exportada con éxito.';

  @override
  String configExportarErro(String erro) {
    return 'Error al exportar clave: $erro';
  }

  @override
  String get configImportarTituloModal => 'IMPORTAR CLAVE DE IDENTIDAD';

  @override
  String get configImportarDescricaoModal =>
      'Ingrese la contraseña del archivo .fixalogkey seleccionado. La clave actual será reemplazada.';

  @override
  String get configBotaoImportar => 'IMPORTAR';

  @override
  String get configImportarSucesso =>
      '¡Identidad y clave criptográfica restauradas con éxito!';

  @override
  String get configImportarErroSenha =>
      'Contraseña incorrecta o archivo de clave dañado.';

  @override
  String get novoProtocoloSelecione => 'SELECCIONE EL PROTOCOLO';

  @override
  String get novoProtocoloSubtitulo =>
      'Inicie una nueva recopilación de datos auditada.';

  @override
  String get novoProtocoloCardInspecaoTitulo => 'Inspección Visual';

  @override
  String get novoProtocoloCardInspecaoSub =>
      'Inspección rápida del estado general y corrosión sin intervención mecánica.';

  @override
  String get novoProtocoloCardManutencaoTitulo => 'Mantenimiento';

  @override
  String get novoProtocoloCardManutencaoSub =>
      'Informe completo de sustitución de anclajes, limpieza y reequipamiento.';

  @override
  String get novoProtocoloCardAberturaTitulo => 'Apertura de Vía';

  @override
  String get novoProtocoloCardAberturaSub =>
      'Registro completo de nueva línea, apertura, croquis y protecciones.';

  @override
  String get novoProtocoloCardExpressoTitulo => 'Registro Exprés';

  @override
  String get novoProtocoloCardExpressoSub =>
      'Captura rápida de fotos, videos, PDFs y notas libres en campo.';

  @override
  String get novoProtocoloCardMaterialTitulo => 'Material';

  @override
  String get novoProtocoloCardMaterialSub =>
      'Registro y trazabilidad de materiales, lotes, facturas y pruebas.';

  @override
  String novoProtocoloErroCarregar(String erro) {
    return 'Error al cargar el protocolo: $erro';
  }

  @override
  String get historicoTitulo => 'HISTORIAL DE AUDITORÍAS';

  @override
  String get historicoSubtitulo =>
      'Sesiones guardadas localmente en el dispositivo.';

  @override
  String historicoAbaRelatorios(int quantidade) {
    return 'INFORMES ($quantidade)';
  }

  @override
  String historicoAbaMateriais(int quantidade) {
    return 'MATERIALES ($quantidade)';
  }

  @override
  String get historicoVazioRelatoriosTitulo => 'No se encontraron informes';

  @override
  String get historicoVazioRelatoriosSub =>
      'Inicie un nuevo protocolo en la pestaña NUEVO para registrar su primera auditoría.';

  @override
  String get historicoVazioMateriaisTitulo => 'Ningún material registrado';

  @override
  String get historicoVazioMateriaisSub =>
      'Registre materiales en la pestaña NUEVO para usarlos en los informes de mantenimiento.';

  @override
  String get historicoBotaoNovoMaterial => 'REGISTRAR MATERIAL';

  @override
  String get historicoStatusConcluido => 'COMPLETADO';

  @override
  String get historicoStatusEmProgresso => 'EN PROGRESO';

  @override
  String get historicoStatusFalha => 'FALLIDO';

  @override
  String get historicoBotaoVerRelatorio => 'VER INFORME';

  @override
  String get historicoBotaoGerarRelatorio => 'GENERAR INFORME';

  @override
  String get historicoBotaoContinuar => 'CONTINUAR';

  @override
  String get historicoBotaoEditar => 'EDITAR';

  @override
  String get historicoBotaoDuplicar => 'DUPLICAR';

  @override
  String get historicoBotaoExcluir => 'ELIMINAR';

  @override
  String get historicoConfirmarExclusaoTitulo => '¿Eliminar registro?';

  @override
  String historicoConfirmarExclusaoCorpo(String titulo) {
    return '¿Está seguro de que desea eliminar \"$titulo\"? Esta acción eliminará los archivos locales y no se puede deshacer.';
  }

  @override
  String get historicoMaterialEmUsoTitulo => 'Material vinculado a informes';

  @override
  String get historicoMaterialEmUsoCorpo =>
      'Este material está referenciado en otros informes. Eliminarlo no borrará los informes ya emitidos, pero quitará el elemento del catálogo activo.';

  @override
  String wizardPassoNumero(int numero) {
    return 'PASO $numero';
  }

  @override
  String get wizardBotaoVoltarPasso => 'VOLVER A ESTE PASO';

  @override
  String get wizardBotaoConcluir => 'FINALIZAR';

  @override
  String get wizardBotaoSeguinte => 'SIGUIENTE';

  @override
  String get wizardBotaoPular => 'OMITIR';

  @override
  String wizardBotaoConcluirLista(int quantidade) {
    return 'FINALIZAR LISTA ($quantidade)';
  }

  @override
  String get wizardAvisoCamposObrigatorios =>
      'Complete todos los campos obligatorios para continuar.';

  @override
  String get wizardAvisoPassoAnteriorObrigatorio =>
      'Complete todos los campos obligatorios del paso anterior para continuar.';

  @override
  String get wizardAvisoCamposItemObrigatorios =>
      'Complete los campos obligatorios del elemento.';

  @override
  String get wizardBotaoAdicionarItem => 'AÑADIR ELEMENTO';

  @override
  String get wizardBotaoAdicionarOutro => 'AÑADIR OTRO';

  @override
  String wizardMinimoItensObrigatorios(int minimo) {
    return 'Mínimo $minimo elemento(s) obligatorio(s).';
  }

  @override
  String get wizardSelecioneTipo => 'SELECCIONE EL TIPO';

  @override
  String get wizardBotaoConfirmarItem => 'CONFIRMAR ELEMENTO';

  @override
  String get wizardRemoverItemTitulo => '¿Eliminar elemento?';

  @override
  String wizardRemoverItemCorpo(String item) {
    return '¿Eliminar \"$item\"?';
  }

  @override
  String get wizardHintTexto => 'Escriba aquí...';

  @override
  String get wizardHintTextoArea =>
      'Escriba aquí... (admite **negrita**, *cursiva*, # título y listas)';

  @override
  String get wizardHintNumeros => 'Solo números';

  @override
  String get wizardGpsDesativado => 'Servicio de ubicación desactivado.';

  @override
  String get wizardGpsCapturado => 'COORDENADAS CAPTURADAS';

  @override
  String get wizardGpsCapturar => 'CAPTURAR POSICIÓN GPS';

  @override
  String get wizardMidiaAdicionar => 'AÑADIR MULTIMEDIA';

  @override
  String get wizardMidiaSubVazio => 'Fotos, videos o PDFs';

  @override
  String get wizardMidiaSubMais => 'Añadir otra foto, video o PDF';

  @override
  String get wizardMidiaPdfAnexado => 'PDF ADJUNTO';

  @override
  String get wizardMidiaVideoGravado => 'VIDEO GRABADO';

  @override
  String get wizardMidiaFotoCapturada => 'FOTO CAPTURADA';

  @override
  String get wizardMidiaProcessandoUm => 'PROCESANDO MULTIMEDIA...';

  @override
  String wizardMidiaProcessandoVarios(int quantidade) {
    return 'PROCESANDO $quantidade ARCHIVOS...';
  }

  @override
  String get wizardMidiaProcessandoSub =>
      'Guardando y calculando integridad en segundo plano...';

  @override
  String get wizardMidiaModalTitulo => 'AÑADIR MULTIMEDIA (FOTO, VIDEO O PDF)';

  @override
  String get wizardMidiaTirarFoto => 'Tomar Foto con la Cámara';

  @override
  String get wizardMidiaGravarVideo => 'Grabar con la Cámara';

  @override
  String get wizardMidiaEscolherGaleria => 'Elegir de la Galería';

  @override
  String get wizardMidiaEscolherGaleriaSub => 'Fotos y videos';

  @override
  String get wizardMidiaSelecionarPdf => 'Seleccionar Archivo PDF';

  @override
  String get wizardRefMatVazioCatalogo =>
      'Aún no hay materiales registrados en el catálogo.\nToque abajo para registrar un nuevo material.';

  @override
  String get wizardRefMatVazioBloco =>
      'Ningún material registrado en el Bloque 1.\nVuelva y añada los materiales primero.';

  @override
  String get wizardBotaoCadastrarNovoMaterial => 'REGISTRAR NUEVO MATERIAL';

  @override
  String get wizardConclusaoTitulo => 'PROTOCOLO COMPLETADO';

  @override
  String get wizardConclusaoSubtitulo =>
      'Todos los datos fueron recopilados sin conexión.\nEl registro está listo para ser firmado y exportado.';

  @override
  String get wizardBotaoGerarRelatorio => 'GENERAR INFORME';

  @override
  String get wizardSufixoCopia => 'Copia';

  @override
  String get geracaoEmAndamentoTitulo => 'GENERANDO INFORME';

  @override
  String get geracaoConcluidaTitulo => 'INFORME LISTO';

  @override
  String get geracaoFalhaTitulo => 'FALLO EN LA GENERACIÓN';

  @override
  String get geracaoBotaoAbrirRelatorio => 'ABRIR INFORME';

  @override
  String get visualizadorAbaEpub => 'INFORME EPUB 3';

  @override
  String get visualizadorAbaPdf => 'RESUMEN PDF';

  @override
  String get visualizadorBotaoCompartilhar => 'COMPARTIR';

  @override
  String get visualizadorBotaoAbrirExterno => 'ABRIR EXTERNO';

  @override
  String get laudoRotuloProtocolo => 'PROTOCOLO';

  @override
  String get laudoRotuloSessao => 'SESIÓN';

  @override
  String get laudoRotuloEmissao => 'EMISIÓN UTC';

  @override
  String get laudoRotuloVersao => 'VERSIÓN';

  @override
  String get laudoSecaoIdentidadeTitulo => 'IDENTIDAD TÉCNICA DEL EMISOR';

  @override
  String get laudoRotuloNome => 'Nombre';

  @override
  String get laudoRotuloEmail => 'Correo electrónico';

  @override
  String get laudoRotuloAssociacao => 'Asociación';

  @override
  String get laudoSecaoIntegridadeTitulo =>
      'INTEGRIDAD CRIPTOGRÁFICA Y CADENA DE CUSTODIA';

  @override
  String get laudoAvisoResumoImpresso =>
      'Este PDF es un resumen ejecutivo para impresión rápida. El informe pericial completo con medios en alta resolución, videos y firma digital XML-DSig X.509 se encuentra en el archivo EPUB 3 correspondiente.';

  @override
  String get laudoSecaoAnexoCatalogoTitulo =>
      'ANEXO — CATÁLOGO DE MATERIALES REFERENCIADOS';

  @override
  String get laudoRotuloVideoAnexo => 'Video adjunto en el EPUB 3';

  @override
  String laudoRotuloDocumentoPdf(int paginas) {
    return 'Documento PDF ($paginas pág.)';
  }
}
