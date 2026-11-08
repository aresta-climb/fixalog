// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get seletorIdiomaTitulo => 'لغة التطبيق';

  @override
  String get seletorIdiomaSubtitulo =>
      'يُغيّر لغة الواجهة والبروتوكولات والتقارير الجديدة';

  @override
  String get comumSim => 'نعم';

  @override
  String get comumNao => 'لا';

  @override
  String get comumCancelar => 'إلغاء';

  @override
  String get comumRemover => 'إزالة';

  @override
  String get comumFechar => 'إغلاق';

  @override
  String comumErro(String detalhe) {
    return 'خطأ: $detalhe';
  }

  @override
  String get termosTituloTela => 'شروط الاستخدام والتدقيق التقني';

  @override
  String get termosCarregando => 'جاري تحميل شروط الاستخدام...';

  @override
  String get termosErroCarregar =>
      'تعذّر تحميل شروط الاستخدام المحلية. يرجى المحاولة مرة أخرى.';

  @override
  String get termosBotaoTentarNovamente => 'إعادة المحاولة';

  @override
  String get termosBotaoLerPolitica => 'قراءة سياسة الخصوصية';

  @override
  String get termosCheckboxDeclaro =>
      'لقد قرأت وأوافق على شروط الاستخدام وسياسة الخصوصية.';

  @override
  String get termosBotaoAceitar => 'قبول الشروط والمتابعة';

  @override
  String get termosBotaoRoleFinal => 'مرّر إلى الأسفل للتفعيل';

  @override
  String get politicaPrivacidadeTitulo => 'سياسة الخصوصية - Fixalog';

  @override
  String get politicaPrivacidadeErroCarregar => 'تعذّر تحميل سياسة الخصوصية.';

  @override
  String get identidadeTituloInicial => 'الهوية التقنية';

  @override
  String get identidadeTituloEdicao => 'تعديل الهوية التقنية';

  @override
  String get identidadeSubtituloInicial =>
      'قم بإعداد بياناتك لتوقيع التقارير التقنية رقمياً.';

  @override
  String get identidadeSubtituloEdicao =>
      'قم بتحديث بيانات ملفك الشخصي. سيتم الحفاظ على مفتاح التشفير النشط الخاص بك.';

  @override
  String get identidadeLabelNome => 'الاسم الكامل *';

  @override
  String get identidadeHintNome => 'مثال: أحمد محمد';

  @override
  String get identidadeLabelApelido => 'اللقب (اختياري)';

  @override
  String get identidadeHintApelido => 'مثال: المتسلق';

  @override
  String get identidadeLabelEmail => 'البريد الإلكتروني *';

  @override
  String get identidadeHintEmail => 'مثال: ahmed@example.com';

  @override
  String get identidadeLabelAssociacao => 'الجمعية / النادي (اختياري)';

  @override
  String get identidadeHintAssociacao => 'مثال: UIAA...';

  @override
  String get identidadeErroNomeVazio => 'لا يمكن أن يكون الاسم الكامل فارغاً.';

  @override
  String get identidadeErroEmailVazio =>
      'لا يمكن أن يكون البريد الإلكتروني فارغاً.';

  @override
  String get identidadeErroEmailInvalido => 'تنسيق البريد الإلكتروني غير صالح.';

  @override
  String identidadeErroSalvar(String erro) {
    return 'فشل حفظ الهوية: $erro';
  }

  @override
  String get identidadeBotaoGerarChaves => 'إنشاء المفاتيح والمتابعة';

  @override
  String get identidadeBotaoSalvarAlteracoes => 'حفظ التغييرات';

  @override
  String get homeAbaNovo => 'جديد';

  @override
  String get homeAbaHistorico => 'السجل';

  @override
  String get homeAbaConfig => 'الإعدادات';

  @override
  String get configTituloSecaoIdentidade => 'الهوية ومفتاح التشفير';

  @override
  String get configCertificadoAtivo => 'شهادة X.509 نشطة';

  @override
  String get configBotaoEditarDados => 'تعديل البيانات الشخصية';

  @override
  String get configBotaoExportarChave => 'تصدير مفتاح الهوية';

  @override
  String get configBotaoImportarChave => 'استيراد مفتاح الهوية';

  @override
  String get configExportarTituloModal => 'تصدير مفتاح الهوية';

  @override
  String get configExportarDescricaoModal =>
      'عيّن كلمة مرور قوية (8 أحرف على الأقل) لتشفير ملف .fixalogkey باستخدام PBKDF2 + AES-256-GCM.';

  @override
  String get configLabelSenhaExportacao => 'كلمة مرور الملف';

  @override
  String get configLabelConfirmarSenha => 'تأكيد كلمة المرور';

  @override
  String get configErroSenhaCurta =>
      'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل.';

  @override
  String get configErroSenhasDiferentes => 'كلمتا المرور غير متطابقتين.';

  @override
  String get configBotaoExportar => 'تصدير';

  @override
  String get configExportarSucesso =>
      'تم تصدير النسخة الاحتياطية للهوية بنجاح.';

  @override
  String configExportarErro(String erro) {
    return 'فشل تصدير المفتاح: $erro';
  }

  @override
  String get configImportarTituloModal => 'استيراد مفتاح الهوية';

  @override
  String get configImportarDescricaoModal =>
      'أدخل كلمة مرور ملف .fixalogkey المحدد. سيتم استبدال المفتاح الحالي.';

  @override
  String get configBotaoImportar => 'استيراد';

  @override
  String get configImportarSucesso =>
      'تمت استعادة الهوية ومفتاح التشفير بنجاح!';

  @override
  String get configImportarErroSenha =>
      'كلمة المرور غير صحيحة أو ملف المفتاح تالف.';

  @override
  String get novoProtocoloSelecione => 'اختر البروتوكول';

  @override
  String get novoProtocoloSubtitulo =>
      'ابدأ عملية جمع بيانات ميدانية موثقة جديدة.';

  @override
  String get novoProtocoloCardInspecaoTitulo => 'الفحص البصري';

  @override
  String get novoProtocoloCardInspecaoSub =>
      'معاينة سريعة للحالة العامة والتآكل دون تدخل ميكانيكي.';

  @override
  String get novoProtocoloCardManutencaoTitulo => 'الصيانة';

  @override
  String get novoProtocoloCardManutencaoSub =>
      'تقرير شامل لاستبدال نقاط التثبيت والتنظيف وإعادة التجهيز.';

  @override
  String get novoProtocoloCardAberturaTitulo => 'فتح مسار جديد';

  @override
  String get novoProtocoloCardAberturaSub =>
      'توثيق كامل لمسار تسلق جديد والمخطط والحمايات المثبتة.';

  @override
  String get novoProtocoloCardExpressoTitulo => 'سجل سريع';

  @override
  String get novoProtocoloCardExpressoSub =>
      'التقاط سريع للصور ومقاطع الفيديو وملفات PDF والملاحظات الميدانية.';

  @override
  String get novoProtocoloCardMaterialTitulo => 'المواد';

  @override
  String get novoProtocoloCardMaterialSub =>
      'تسجيل وتتبع المعدات والدفعات والفواتير واختبارات الجودة.';

  @override
  String novoProtocoloErroCarregar(String erro) {
    return 'خطأ في تحميل البروتوكول: $erro';
  }

  @override
  String get historicoTitulo => 'سجل المعاينات';

  @override
  String get historicoSubtitulo => 'الجلسات المحفوظة محلياً على هذا الجهاز.';

  @override
  String historicoAbaRelatorios(int quantidade) {
    return 'التقارير ($quantidade)';
  }

  @override
  String historicoAbaMateriais(int quantidade) {
    return 'المواد ($quantidade)';
  }

  @override
  String get historicoVazioRelatoriosTitulo => 'لم يتم العثور على تقارير';

  @override
  String get historicoVazioRelatoriosSub =>
      'ابدأ بروتوكولاً جديداً في علامة التبويب جديد لتسجيل أول معاينة لك.';

  @override
  String get historicoVazioMateriaisTitulo => 'لا توجد مواد مسجلة';

  @override
  String get historicoVazioMateriaisSub =>
      'سجّل المواد في علامة التبويب جديد لاستخدامها في تقارير الصيانة.';

  @override
  String get historicoBotaoNovoMaterial => 'تسجيل مادة';

  @override
  String get historicoStatusConcluido => 'مكتمل';

  @override
  String get historicoStatusEmProgresso => 'قيد التنفيذ';

  @override
  String get historicoStatusFalha => 'فشل';

  @override
  String get historicoBotaoVerRelatorio => 'عرض التقرير';

  @override
  String get historicoBotaoGerarRelatorio => 'إنشاء التقرير';

  @override
  String get historicoBotaoContinuar => 'متابعة';

  @override
  String get historicoBotaoEditar => 'تعديل';

  @override
  String get historicoBotaoDuplicar => 'تكرار';

  @override
  String get historicoBotaoExcluir => 'حذف';

  @override
  String get historicoConfirmarExclusaoTitulo => 'حذف السجل؟';

  @override
  String historicoConfirmarExclusaoCorpo(String titulo) {
    return 'هل أنت متأكد من حذف \"$titulo\"؟ سيؤدي هذا الإجراء إلى إزالة الملفات المحلية ولا يمكن التراجع عنه.';
  }

  @override
  String get historicoMaterialEmUsoTitulo => 'المادة مرتبطة بتقارير';

  @override
  String get historicoMaterialEmUsoCorpo =>
      'هذه المادة مشار إليها في تقارير أخرى. حذفها لن يمحو التقارير الصادرة مسبقاً، لكنه سيزيل العنصر من الكتالوج النشط.';

  @override
  String wizardPassoNumero(int numero) {
    return 'الخطوة $numero';
  }

  @override
  String get wizardBotaoVoltarPasso => 'العودة إلى هذه الخطوة';

  @override
  String get wizardBotaoConcluir => 'إنهاء';

  @override
  String get wizardBotaoSeguinte => 'التالي';

  @override
  String get wizardBotaoPular => 'تخطي';

  @override
  String wizardBotaoConcluirLista(int quantidade) {
    return 'إنهاء القائمة ($quantidade)';
  }

  @override
  String get wizardAvisoCamposObrigatorios =>
      'يرجى ملء جميع الحقول المطلوبة للمتابعة.';

  @override
  String get wizardAvisoPassoAnteriorObrigatorio =>
      'يرجى ملء جميع الحقول المطلوبة في الخطوة السابقة للمتابعة.';

  @override
  String get wizardAvisoCamposItemObrigatorios =>
      'يرجى ملء الحقول المطلوبة لهذا العنصر.';

  @override
  String get wizardBotaoAdicionarItem => 'إضافة عنصر';

  @override
  String get wizardBotaoAdicionarOutro => 'إضافة عنصر آخر';

  @override
  String wizardMinimoItensObrigatorios(int minimo) {
    return 'الحد الأدنى $minimo عنصر مطلوب.';
  }

  @override
  String get wizardSelecioneTipo => 'اختر النوع';

  @override
  String get wizardBotaoConfirmarItem => 'تأكيد العنصر';

  @override
  String get wizardRemoverItemTitulo => 'إزالة العنصر؟';

  @override
  String wizardRemoverItemCorpo(String item) {
    return 'إزالة \"$item\"؟';
  }

  @override
  String get wizardHintTexto => 'اكتب هنا...';

  @override
  String get wizardHintTextoArea =>
      'اكتب هنا... (يدعم **عريض**، *مائل*، # عنوان والقوائم)';

  @override
  String get wizardHintNumeros => 'أرقام فقط';

  @override
  String get wizardGpsDesativado => 'خدمة الموقع غير مفعلة.';

  @override
  String get wizardGpsCapturado => 'تم التقاط الإحداثيات';

  @override
  String get wizardGpsCapturar => 'التقاط موقع GPS';

  @override
  String get wizardMidiaAdicionar => 'إضافة وسائط';

  @override
  String get wizardMidiaSubVazio => 'صور أو فيديوهات أو ملفات PDF';

  @override
  String get wizardMidiaSubMais => 'إضافة صورة أو فيديو أو ملف PDF آخر';

  @override
  String get wizardMidiaPdfAnexado => 'ملف PDF مرفق';

  @override
  String get wizardMidiaVideoGravado => 'فيديو مسجل';

  @override
  String get wizardMidiaFotoCapturada => 'صورة ملتقطة';

  @override
  String get wizardMidiaProcessandoUm => 'جاري معالجة الوسائط...';

  @override
  String wizardMidiaProcessandoVarios(int quantidade) {
    return 'جاري معالجة $quantidade ملفات وسائط...';
  }

  @override
  String get wizardMidiaProcessandoSub =>
      'جاري الحفظ وحساب السلامة الرقمية في الخلفية...';

  @override
  String get wizardMidiaModalTitulo => 'إضافة وسائط (صورة أو فيديو أو PDF)';

  @override
  String get wizardMidiaTirarFoto => 'التقاط صورة بالكاميرا';

  @override
  String get wizardMidiaGravarVideo => 'تسجيل فيديو بالكاميرا';

  @override
  String get wizardMidiaEscolherGaleria => 'الاختيار من المعرض';

  @override
  String get wizardMidiaEscolherGaleriaSub => 'صور وفيديوهات';

  @override
  String get wizardMidiaSelecionarPdf => 'اختيار ملف PDF';

  @override
  String get wizardRefMatVazioCatalogo =>
      'لا توجد مواد مسجلة في الكتالوج بعد.\nاضغط أدناه لتسجيل مادة جديدة.';

  @override
  String get wizardRefMatVazioBloco =>
      'لا توجد مواد مسجلة في القسم 1.\nعد وأضف المواد أولاً.';

  @override
  String get wizardBotaoCadastrarNovoMaterial => 'تسجيل مادة جديدة';

  @override
  String get wizardConclusaoTitulo => 'اكتمل البروتوكول';

  @override
  String get wizardConclusaoSubtitulo =>
      'تم جمع جميع البيانات دون اتصال بالإنترنت.\nالسجل جاهز للتوقيع والتصدير.';

  @override
  String get wizardBotaoGerarRelatorio => 'إنشاء التقرير';

  @override
  String get wizardSufixoCopia => 'نسخة';

  @override
  String get geracaoEmAndamentoTitulo => 'جاري إنشاء التقرير';

  @override
  String get geracaoConcluidaTitulo => 'التقرير جاهز';

  @override
  String get geracaoFalhaTitulo => 'فشل الإنشاء';

  @override
  String get geracaoBotaoAbrirRelatorio => 'فتح التقرير';

  @override
  String get visualizadorAbaEpub => 'تقرير EPUB 3';

  @override
  String get visualizadorAbaPdf => 'ملخص PDF';

  @override
  String get visualizadorBotaoCompartilhar => 'مشاركة';

  @override
  String get visualizadorBotaoAbrirExterno => 'فتح خارجياً';

  @override
  String get laudoRotuloProtocolo => 'البروتوكول';

  @override
  String get laudoRotuloSessao => 'الجلسة';

  @override
  String get laudoRotuloEmissao => 'تاريخ الإصدار UTC';

  @override
  String get laudoRotuloVersao => 'الإصدار';

  @override
  String get laudoSecaoIdentidadeTitulo => 'الهوية التقنية للمُصدِر';

  @override
  String get laudoRotuloNome => 'الاسم';

  @override
  String get laudoRotuloEmail => 'البريد الإلكتروني';

  @override
  String get laudoRotuloAssociacao => 'الجمعية';

  @override
  String get laudoSecaoIntegridadeTitulo => 'السلامة التشفيرية وسلسلة الحفظ';

  @override
  String get laudoAvisoResumoImpresso =>
      'ملف PDF هذا هو ملخص تنفيذي للطباعة السريعة. التقرير الفني الكامل مع الوسائط عالية الدقة ومقاطع الفيديو والتوقيع الرقمي XML-DSig X.509 موجود في ملف EPUB 3 المقابل.';

  @override
  String get laudoSecaoAnexoCatalogoTitulo =>
      'ملحق — كتالوج المواد المشار إليها';

  @override
  String get laudoRotuloVideoAnexo => 'فيديو مرفق في EPUB 3';

  @override
  String laudoRotuloDocumentoPdf(int paginas) {
    return 'مستند PDF ($paginas ص)';
  }
}
