// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get seletorIdiomaTitulo => 'アプリの言語';

  @override
  String get seletorIdiomaSubtitulo => '画面表示、プロトコル、新規レポートの言語を変更します';

  @override
  String get comumSim => 'はい';

  @override
  String get comumNao => 'いいえ';

  @override
  String get comumCancelar => 'キャンセル';

  @override
  String get comumRemover => '削除';

  @override
  String get comumFechar => '閉じる';

  @override
  String comumErro(String detalhe) {
    return 'エラー: $detalhe';
  }

  @override
  String get termosTituloTela => '利用規約および技術監査条件';

  @override
  String get termosCarregando => '利用規約を読み込み中...';

  @override
  String get termosErroCarregar => 'ローカルの利用規約を読み込めませんでした。もう一度お試しください。';

  @override
  String get termosBotaoTentarNovamente => '再試行';

  @override
  String get termosBotaoLerPolitica => 'プライバシーポリシーを読む';

  @override
  String get termosCheckboxDeclaro => '利用規約およびプライバシーポリシーを読み、同意します。';

  @override
  String get termosBotaoAceitar => '規約に同意して続行';

  @override
  String get termosBotaoRoleFinal => '最後までスクロールして有効化';

  @override
  String get politicaPrivacidadeTitulo => 'プライバシーポリシー - Fixalog';

  @override
  String get politicaPrivacidadeErroCarregar => 'プライバシーポリシーを読み込めませんでした。';

  @override
  String get identidadeTituloInicial => '技術者ID設定';

  @override
  String get identidadeTituloEdicao => '技術者IDの編集';

  @override
  String get identidadeSubtituloInicial => '技術レポートに電子署名するためのプロフィールを設定します。';

  @override
  String get identidadeSubtituloEdicao => '登録情報を更新します。有効な暗号鍵はそのまま保持されます。';

  @override
  String get identidadeLabelNome => '氏名 *';

  @override
  String get identidadeHintNome => '例: 山田 太郎';

  @override
  String get identidadeLabelApelido => 'ニックネーム (任意)';

  @override
  String get identidadeHintApelido => '例: アルパイン';

  @override
  String get identidadeLabelEmail => 'メールアドレス *';

  @override
  String get identidadeHintEmail => '例: taro@example.com';

  @override
  String get identidadeLabelAssociacao => '所属団体・山岳会 (任意)';

  @override
  String get identidadeHintAssociacao => '例: JMA, JMGA, UIAAなど';

  @override
  String get identidadeErroNomeVazio => '氏名を入力してください。';

  @override
  String get identidadeErroEmailVazio => 'メールアドレスを入力してください。';

  @override
  String get identidadeErroEmailInvalido => 'メールアドレスの形式が正しくありません。';

  @override
  String identidadeErroSalvar(String erro) {
    return 'IDの保存に失敗しました: $erro';
  }

  @override
  String get identidadeBotaoGerarChaves => '鍵を生成して続行';

  @override
  String get identidadeBotaoSalvarAlteracoes => '変更を保存';

  @override
  String get homeAbaNovo => '新規';

  @override
  String get homeAbaHistorico => '履歴';

  @override
  String get homeAbaConfig => '設定';

  @override
  String get configTituloSecaoIdentidade => '技術者IDと暗号鍵';

  @override
  String get configCertificadoAtivo => 'X.509証明書 有効';

  @override
  String get configBotaoEditarDados => 'プロフィールを編集';

  @override
  String get configBotaoExportarChave => 'ID鍵をエクスポート';

  @override
  String get configBotaoImportarChave => 'ID鍵をインポート';

  @override
  String get configExportarTituloModal => 'ID鍵をエクスポート';

  @override
  String get configExportarDescricaoModal =>
      '.fixalogkeyファイルをPBKDF2 + AES-256-GCMで暗号化するため、強力なパスワード（8文字以上）を設定してください。';

  @override
  String get configLabelSenhaExportacao => 'ファイルのパスワード';

  @override
  String get configLabelConfirmarSenha => 'パスワードの確認';

  @override
  String get configErroSenhaCurta => 'パスワードは8文字以上で入力してください。';

  @override
  String get configErroSenhasDiferentes => 'パスワードが一致しません。';

  @override
  String get configBotaoExportar => 'エクスポート';

  @override
  String get configExportarSucesso => 'IDバックアップを正常にエクスポートしました。';

  @override
  String configExportarErro(String erro) {
    return '鍵のエクスポートに失敗しました: $erro';
  }

  @override
  String get configImportarTituloModal => 'ID鍵をインポート';

  @override
  String get configImportarDescricaoModal =>
      '選択した.fixalogkeyファイルのパスワードを入力してください。現在の鍵は上書きされます。';

  @override
  String get configBotaoImportar => 'インポート';

  @override
  String get configImportarSucesso => '技術者IDと暗号鍵を正常に復元しました！';

  @override
  String get configImportarErroSenha => 'パスワードが正しくないか、鍵ファイルが破損しています。';

  @override
  String get novoProtocoloSelecione => 'プロトコルを選択';

  @override
  String get novoProtocoloSubtitulo => '監査対応の新しいフィールドデータ記録を開始します。';

  @override
  String get novoProtocoloCardInspecaoTitulo => '目視点検';

  @override
  String get novoProtocoloCardInspecaoSub => '機械的介入を行わない、支点の状態・腐食の迅速な目視調査。';

  @override
  String get novoProtocoloCardManutencaoTitulo => 'メンテナンス';

  @override
  String get novoProtocoloCardManutencaoSub => 'アンカー交換、清掃、リボルティングの完全な作業報告。';

  @override
  String get novoProtocoloCardAberturaTitulo => 'ルート開拓';

  @override
  String get novoProtocoloCardAberturaSub => '新規ルート、初登情報、トポ、設置プロテクションの完全な記録。';

  @override
  String get novoProtocoloCardExpressoTitulo => 'クイック記録';

  @override
  String get novoProtocoloCardExpressoSub => '現場での写真、動画、PDF、自由メモの迅速な記録。';

  @override
  String get novoProtocoloCardMaterialTitulo => '資材登録';

  @override
  String get novoProtocoloCardMaterialSub => '機材、ロット番号、領収書、品質試験の登録とトレーサビリティ管理。';

  @override
  String novoProtocoloErroCarregar(String erro) {
    return 'プロトコルの読み込みエラー: $erro';
  }

  @override
  String get historicoTitulo => '監査履歴';

  @override
  String get historicoSubtitulo => 'この端末にローカル保存されたセッション。';

  @override
  String historicoAbaRelatorios(int quantidade) {
    return 'レポート ($quantidade)';
  }

  @override
  String historicoAbaMateriais(int quantidade) {
    return '資材 ($quantidade)';
  }

  @override
  String get historicoVazioRelatoriosTitulo => 'レポートが見つかりません';

  @override
  String get historicoVazioRelatoriosSub =>
      '「新規」タブから新しいプロトコルを開始して、最初の監査を記録してください。';

  @override
  String get historicoVazioMateriaisTitulo => '登録された資材はありません';

  @override
  String get historicoVazioMateriaisSub => '「新規」タブで資材を登録すると、メンテナンスレポートで参照できます。';

  @override
  String get historicoBotaoNovoMaterial => '資材を登録';

  @override
  String get historicoStatusConcluido => '完了';

  @override
  String get historicoStatusEmProgresso => '作成中';

  @override
  String get historicoStatusFalha => '失敗';

  @override
  String get historicoBotaoVerRelatorio => 'レポートを表示';

  @override
  String get historicoBotaoGerarRelatorio => 'レポートを生成';

  @override
  String get historicoBotaoContinuar => '再開';

  @override
  String get historicoBotaoEditar => '編集';

  @override
  String get historicoBotaoDuplicar => '複製';

  @override
  String get historicoBotaoExcluir => '削除';

  @override
  String get historicoConfirmarExclusaoTitulo => '記録を削除しますか？';

  @override
  String historicoConfirmarExclusaoCorpo(String titulo) {
    return '「$titulo」を削除してもよろしいですか？ローカルファイルが削除され、元に戻すことはできません。';
  }

  @override
  String get historicoMaterialEmUsoTitulo => 'レポートで参照されている資材';

  @override
  String get historicoMaterialEmUsoCorpo =>
      'この資材は他のレポートで参照されています。削除しても発行済みのレポートは消えませんが、有効なカタログからは削除されます。';

  @override
  String wizardPassoNumero(int numero) {
    return 'ステップ $numero';
  }

  @override
  String get wizardBotaoVoltarPasso => 'このステップに戻る';

  @override
  String get wizardBotaoConcluir => '完了';

  @override
  String get wizardBotaoSeguinte => '次へ';

  @override
  String get wizardBotaoPular => 'スキップ';

  @override
  String wizardBotaoConcluirLista(int quantidade) {
    return 'リストを完了 ($quantidade)';
  }

  @override
  String get wizardAvisoCamposObrigatorios => '続行するには、すべての必須項目を入力してください。';

  @override
  String get wizardAvisoPassoAnteriorObrigatorio =>
      '続行するには、前のステップのすべての必須項目を入力してください。';

  @override
  String get wizardAvisoCamposItemObrigatorios => 'この項目の必須フィールドを入力してください。';

  @override
  String get wizardBotaoAdicionarItem => '項目を追加';

  @override
  String get wizardBotaoAdicionarOutro => 'さらに追加';

  @override
  String wizardMinimoItensObrigatorios(int minimo) {
    return '最低 $minimo 件の項目が必要です。';
  }

  @override
  String get wizardSelecioneTipo => '種類を選択';

  @override
  String get wizardBotaoConfirmarItem => '項目を確定';

  @override
  String get wizardRemoverItemTitulo => '項目を削除しますか？';

  @override
  String wizardRemoverItemCorpo(String item) {
    return '「$item」を削除しますか？';
  }

  @override
  String get wizardHintTexto => 'ここに入力...';

  @override
  String get wizardHintTextoArea => 'ここに入力... (**太字**、*斜体*、# 見出し、リストに対応)';

  @override
  String get wizardHintNumeros => '数字のみ';

  @override
  String get wizardGpsDesativado => '位置情報サービスが無効です。';

  @override
  String get wizardGpsCapturado => 'GPS座標取得済み';

  @override
  String get wizardGpsCapturar => 'GPS位置を取得';

  @override
  String get wizardMidiaAdicionar => 'メディアを追加';

  @override
  String get wizardMidiaSubVazio => '写真、動画、またはPDF';

  @override
  String get wizardMidiaSubMais => '別の写真、動画、またはPDFを追加';

  @override
  String get wizardMidiaPdfAnexado => 'PDF添付済み';

  @override
  String get wizardMidiaVideoGravado => '動画記録済み';

  @override
  String get wizardMidiaFotoCapturada => '写真撮影済み';

  @override
  String get wizardMidiaProcessandoUm => 'メディアを処理中...';

  @override
  String wizardMidiaProcessandoVarios(int quantidade) {
    return '$quantidade 件のメディアを処理中...';
  }

  @override
  String get wizardMidiaProcessandoSub => 'バックグラウンドで保存および完全性ハッシュを計算中...';

  @override
  String get wizardMidiaModalTitulo => 'メディアを追加 (写真・動画・PDF)';

  @override
  String get wizardMidiaTirarFoto => 'カメラで写真を撮る';

  @override
  String get wizardMidiaGravarVideo => 'カメラで動画を撮る';

  @override
  String get wizardMidiaEscolherGaleria => 'ギャラリーから選択';

  @override
  String get wizardMidiaEscolherGaleriaSub => '写真と動画';

  @override
  String get wizardMidiaSelecionarPdf => 'PDFファイルを選択';

  @override
  String get wizardRefMatVazioCatalogo =>
      'カタログに資材がまだ登録されていません。\n下のボタンから新しい資材を登録してください。';

  @override
  String get wizardRefMatVazioBloco => 'ブロック1に資材が登録されていません。\n戻って先に資材を追加してください。';

  @override
  String get wizardBotaoCadastrarNovoMaterial => '新しい資材を登録';

  @override
  String get wizardConclusaoTitulo => 'プロトコル完了';

  @override
  String get wizardConclusaoSubtitulo =>
      'すべてのデータがオフラインで収集されました。\n記録の電子署名とエクスポートが可能です。';

  @override
  String get wizardBotaoGerarRelatorio => 'レポートを生成';

  @override
  String get wizardSufixoCopia => 'コピー';

  @override
  String get geracaoEmAndamentoTitulo => 'レポート生成中';

  @override
  String get geracaoConcluidaTitulo => 'レポート完了';

  @override
  String get geracaoFalhaTitulo => '生成失敗';

  @override
  String get geracaoBotaoAbrirRelatorio => 'レポートを開く';

  @override
  String get visualizadorAbaEpub => 'EPUB 3 レポート';

  @override
  String get visualizadorAbaPdf => 'PDF 概要';

  @override
  String get visualizadorBotaoCompartilhar => '共有';

  @override
  String get visualizadorBotaoAbrirExterno => '外部アプリで開く';

  @override
  String get laudoRotuloProtocolo => 'プロトコル';

  @override
  String get laudoRotuloSessao => 'セッション';

  @override
  String get laudoRotuloEmissao => '発行日時 UTC';

  @override
  String get laudoRotuloVersao => 'バージョン';

  @override
  String get laudoSecaoIdentidadeTitulo => '発行者の技術者ID';

  @override
  String get laudoRotuloNome => '氏名';

  @override
  String get laudoRotuloEmail => 'メール';

  @override
  String get laudoRotuloAssociacao => '所属団体';

  @override
  String get laudoSecaoIntegridadeTitulo => '暗号学的完全性とチェーン・オブ・カストディ';

  @override
  String get laudoAvisoResumoImpresso =>
      'このPDFは迅速な印刷用のエグゼクティブサマリーです。高解像度メディア、動画、およびX.509 XML-DSig電子署名を含む完全な鑑定レポートは、対応するEPUB 3ファイルに格納されています。';

  @override
  String get laudoSecaoAnexoCatalogoTitulo => '付録 — 参照資材カタログ';

  @override
  String get laudoRotuloVideoAnexo => 'EPUB 3に添付された動画';

  @override
  String laudoRotuloDocumentoPdf(int paginas) {
    return 'PDFドキュメント ($paginas ページ)';
  }

  @override
  String get feedbackTituloSheet => 'フィードバックの内容を選択してください';

  @override
  String get feedbackCategoriaProtocolo => 'プロトコル';

  @override
  String get feedbackCategoriaAplicativo => 'アプリ';

  @override
  String get feedbackHintDescricao => '問題点、質問、または提案を入力してください...';

  @override
  String get feedbackAvisoOffline => 'オフラインで保存され、電波回復時に自動送信されます。';

  @override
  String get feedbackBotaoEnviar => 'フィードバックを送信';

  @override
  String get feedbackSucessoEnvio => 'フィードバックを記録しました。接続時に送信されます。';

  @override
  String get configBotaoFeedback => '問題の報告・改善の提案';

  @override
  String get configSecaoGovernancaTitulo => 'ガバナンスと利用規約';

  @override
  String configTermosVersaoAceita(int versao) {
    return '同意済みバージョン: v$versao';
  }

  @override
  String configTermosDataAceite(String dataHora) {
    return '同意日時: $dataHora';
  }

  @override
  String get configTermosPendente => '未同意';

  @override
  String get configBotaoConsultarTermos => '利用規約とプライバシーポリシーを表示';

  @override
  String get configSecaoComunidadeTitulo => 'サポート・フィードバック・コミュニティ';

  @override
  String get configBotaoWhatsapp => 'WHATSAPP の ARESTA コミュニティ';

  @override
  String get configBotaoPortalWeb => 'ARESTA CLIMB 公式ポータル';

  @override
  String get configRotuloContaOidc => 'OIDC アカウント';

  @override
  String get configContaOidcNaoVinculada => '未連携 (ローカルモード)';

  @override
  String get configRotuloFingerprintChave => 'ECDSA P-256 鍵';
}
