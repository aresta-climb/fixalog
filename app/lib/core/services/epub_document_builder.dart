// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:ui';

import '../l10n/resolvedor_idioma.dart';
import '../models/proto/protos/registro.pb.dart';
import 'construtor_arvore_relatorio.dart';

/// Construtor de documentos semânticos em XHTML5 e CSS para relatórios técnicos em EPUB 3.
///
/// Consome a [ArvoreRelatorio] gerada pelo [ConstrutorArvoreRelatorio] para produzir
/// marcação padronizada de acordo com a especificação W3C EPUB 3.3, organizada pelos blocos
/// do protocolo YAML, com grades de propriedades, galerias de fotos lado a lado, cartões
/// aninhados recursivamente e regras de impressão (`@media print`).
class EpubDocumentBuilder {
  final ConstrutorArvoreRelatorio _construtorArvore;

  const EpubDocumentBuilder({
    ConstrutorArvoreRelatorio construtorArvore =
        const ConstrutorArvoreRelatorio(),
  }) : _construtorArvore = construtorArvore;

  /// Extrai todas as [ReferenciaMidia] presentes em uma [Resposta],
  /// seja como mídia única (`resp.hasMidia()`) ou dentro de `resp.lista`.
  static List<ReferenciaMidia> extrairMidiasDeResposta(Resposta? resp) {
    return ConstrutorArvoreRelatorio.extrairMidiasDeResposta(resp);
  }

  /// Extrai de um [registro] o conjunto ordenado de UUIDs de materiais do catálogo referenciados
  /// em elementos `StepRefMateriais` do protocolo YAML.
  static List<String> extrairUuidsMateriaisReferenciados(Registro registro) {
    return ConstrutorArvoreRelatorio.extrairUuidsMateriaisReferenciados(
      registro,
    );
  }

  /// Gera a folha de estilos CSS completa com regras para visualização em tela e impressão,
  /// declarando seletivamente os `@font-face` da família Google Noto Sans para [codigoIdioma].
  String gerarCss({String codigoIdioma = 'pt'}) {
    final codigoNorm = codigoIdioma.split(RegExp(r'[-_]')).first.toLowerCase();
    final fontFacesAdicionais = StringBuffer();
    if (codigoNorm == 'ar') {
      fontFacesAdicionais.write('''
@font-face {
  font-family: 'Noto Sans Arabic';
  font-style: normal;
  font-weight: 400;
  src: url('fonts/NotoSansArabic-Regular.ttf') format('truetype');
}
@font-face {
  font-family: 'Noto Sans Arabic';
  font-style: normal;
  font-weight: 700;
  src: url('fonts/NotoSansArabic-Bold.ttf') format('truetype');
}
''');
    } else if (codigoNorm == 'ja') {
      fontFacesAdicionais.write('''
@font-face {
  font-family: 'Noto Sans JP';
  font-style: normal;
  font-weight: 400;
  src: url('fonts/NotoSansJP-Regular.ttf') format('truetype');
}
@font-face {
  font-family: 'Noto Sans JP';
  font-style: normal;
  font-weight: 700;
  src: url('fonts/NotoSansJP-Bold.ttf') format('truetype');
}
''');
    }

    return '''
/* Estilos Gerais do Relatório Fixalog */
@font-face {
  font-family: 'Noto Sans';
  font-style: normal;
  font-weight: 400;
  src: url('fonts/NotoSans-Regular.ttf') format('truetype');
}
@font-face {
  font-family: 'Noto Sans';
  font-style: normal;
  font-weight: 700;
  src: url('fonts/NotoSans-Bold.ttf') format('truetype');
}
${fontFacesAdicionais.toString()}:root {
  --cor-fundo: #121416;
  --cor-superficie: #1a1c1e;
  --cor-superficie-elevada: #222528;
  --cor-destaque: #ff6b00;
  --cor-destaque-suave: rgba(255, 107, 0, 0.12);
  --cor-texto: #e1e2e5;
  --cor-texto-suave: #9ea3a8;
  --cor-borda: #333537;
}

body {
  font-family: 'Noto Sans', 'Noto Sans Arabic', 'Noto Sans JP', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  line-height: 1.6;
  color: var(--cor-texto);
  background-color: var(--cor-fundo);
  margin: 0;
  padding: 20px;
}

.barra-navegacao-retorno {
  margin-bottom: 16px;
}

.botao-voltar {
  display: inline-block;
  color: var(--cor-destaque);
  text-decoration: none;
  font-weight: bold;
  font-size: 0.9rem;
  padding: 6px 12px;
  border: 1px solid var(--cor-destaque);
  border-radius: 6px;
}

.cabecalho-protocolo {
  background-color: var(--cor-superficie);
  border: 1px solid var(--cor-borda);
  border-left: 4px solid var(--cor-destaque);
  border-radius: 10px;
  padding: 18px 20px;
  margin-bottom: 24px;
}

.topo-cabecalho {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 6px;
}

.badge-versao {
  display: inline-block;
  background-color: var(--cor-destaque-suave);
  color: var(--cor-destaque);
  border: 1px solid var(--cor-destaque);
  font-size: 0.75rem;
  font-weight: bold;
  padding: 2px 8px;
  border-radius: 999px;
}

h1 {
  font-size: 1.5rem;
  color: var(--cor-destaque);
  margin: 0 0 6px 0;
  line-height: 1.3;
}

.subtitulo-protocolo {
  color: var(--cor-texto-suave);
  font-size: 0.92rem;
  margin: 0 0 12px 0;
}

.metadados-sessao {
  border-top: 1px solid var(--cor-borda);
  padding-top: 10px;
  font-size: 0.85rem;
  color: var(--cor-texto-suave);
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 6px 16px;
}

.bloco-protocolo {
  background-color: var(--cor-superficie);
  border: 1px solid var(--cor-borda);
  border-radius: 10px;
  padding: 18px 20px;
  margin-bottom: 20px;
}

.cabecalho-bloco {
  border-bottom: 1px solid var(--cor-borda);
  padding-bottom: 10px;
  margin-bottom: 16px;
}

h2 {
  font-size: 1.25rem;
  color: var(--cor-texto);
  margin: 0;
}

.subtitulo-bloco {
  color: var(--cor-texto-suave);
  font-size: 0.88rem;
  margin: 4px 0 0 0;
}

/* Grade de Propriedades Curtas (2 colunas responsivas) */
.grade-propriedades {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 12px;
  margin-bottom: 16px;
}

.item-propriedade {
  background-color: var(--cor-superficie-elevada);
  border: 1px solid var(--cor-borda);
  border-radius: 8px;
  padding: 10px 14px;
}

.campo-chave {
  font-weight: bold;
  font-size: 0.82rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--cor-destaque);
}

.campo-subrotulo {
  font-size: 0.78rem;
  color: var(--cor-texto-suave);
  margin-top: 2px;
}

.campo-valor {
  font-size: 1rem;
  color: var(--cor-texto);
  margin-top: 4px;
  font-weight: 500;
}

/* Destaque de Escolha (LARGE_TILES e SelecaoRamo) */
.destaque-escolha {
  background-color: var(--cor-destaque-suave);
  border-left: 4px solid var(--cor-destaque);
  border-radius: 6px;
  padding: 12px 16px;
  margin-bottom: 16px;
}

.pergunta-escolha {
  font-size: 0.82rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--cor-texto-suave);
  font-weight: bold;
}

.opcao-escolhida {
  font-size: 1.08rem;
  font-weight: bold;
  color: var(--cor-destaque);
  margin-top: 2px;
}

.subrotulo-escolha {
  font-size: 0.86rem;
  color: var(--cor-texto);
  margin-top: 2px;
}

/* Bloco de Texto Longo (TEXT_AREA / Markdown) */
.bloco-texto-longo {
  background-color: var(--cor-superficie-elevada);
  border: 1px solid var(--cor-borda);
  border-radius: 8px;
  padding: 12px 16px;
  margin-bottom: 16px;
}

/* Referências de Materiais */
.bloco-ref-materiais {
  margin-bottom: 16px;
}

.lista-chips-materiais {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 8px;
}

.link-material {
  display: inline-block;
  background-color: var(--cor-destaque-suave);
  color: var(--cor-destaque);
  border: 1px solid var(--cor-destaque);
  border-radius: 6px;
  padding: 6px 12px;
  font-weight: bold;
  font-size: 0.9rem;
  text-decoration: none;
}

/* Galeria de Mídias e Fotos Lado a Lado */
.galeria-midias {
  margin-bottom: 16px;
}

.grade-fotos {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 16px;
  margin: 12px 0;
}

.midia-foto {
  margin: 0;
  background-color: var(--cor-superficie-elevada);
  border: 1px solid var(--cor-borda);
  border-radius: 8px;
  padding: 10px;
  text-align: center;
}

.legenda-midia {
  font-weight: bold;
  font-size: 0.85rem;
  color: var(--cor-destaque);
  margin-bottom: 8px;
  text-align: left;
}

.midia-foto img {
  max-width: 100%;
  max-height: 360px;
  width: auto;
  height: auto;
  border-radius: 6px;
}

.container-video {
  background-color: var(--cor-superficie-elevada);
  border: 1px solid var(--cor-borda);
  border-radius: 8px;
  padding: 12px;
  margin: 12px 0;
}

.documento-pdf-container {
  background-color: var(--cor-superficie-elevada);
  border: 1px solid var(--cor-borda);
  border-radius: 8px;
  padding: 12px;
  margin: 12px 0;
}

.acao-pdf-original {
  margin: 8px 0 12px 0;
}

.link-pdf-original {
  display: inline-block;
  color: var(--cor-destaque);
  text-decoration: none;
  font-weight: bold;
  font-size: 0.9rem;
  padding: 6px 12px;
  border: 1px solid var(--cor-destaque);
  border-radius: 6px;
}

.legenda-pagina-pdf {
  font-size: 0.85rem;
  color: var(--cor-texto-suave);
  margin: 4px 0;
}

/* Seções de Lista e Cartões Numerados Aninháveis */
.secao-lista {
  margin-top: 16px;
  margin-bottom: 16px;
}

.cabecalho-secao-lista {
  margin-bottom: 12px;
}

.titulo-secao-lista {
  font-size: 1.1rem;
  color: var(--cor-destaque);
  margin: 0;
}

.subtitulo-secao-lista {
  font-size: 0.84rem;
  color: var(--cor-texto-suave);
  margin: 2px 0 0 0;
}

.card-item-lista {
  background-color: var(--cor-superficie-elevada);
  border: 1px solid var(--cor-borda);
  border-radius: 10px;
  margin-bottom: 16px;
  overflow: hidden;
}

.corpo-card-item .card-item-lista {
  background-color: var(--cor-superficie);
  border-left: 3px solid var(--cor-destaque);
}

.cabecalho-card-item {
  display: flex;
  align-items: center;
  gap: 12px;
  background-color: rgba(255, 255, 255, 0.03);
  border-bottom: 1px solid var(--cor-borda);
  padding: 10px 16px;
}

.badge-indice-item {
  background-color: var(--cor-destaque);
  color: #ffffff;
  font-weight: bold;
  font-size: 0.82rem;
  padding: 2px 8px;
  border-radius: 6px;
}

.titulos-card-item {
  display: flex;
  flex-direction: column;
}

.titulo-card-item {
  font-size: 1.02rem;
  color: var(--cor-texto);
}

.subtitulo-card-item {
  font-size: 0.8rem;
  color: var(--cor-texto-suave);
}

.corpo-card-item {
  padding: 16px;
}

.secao-materiais-anexos {
  background-color: var(--cor-superficie);
  border: 1px solid var(--cor-borda);
  border-radius: 10px;
  padding: 18px 20px;
  margin-top: 24px;
}

.conteudo-markdown {
  margin-top: 6px;
}

.conteudo-markdown p {
  margin: 0 0 8px 0;
}

.conteudo-markdown h4, .conteudo-markdown h5 {
  margin: 8px 0 4px 0;
  color: var(--cor-destaque);
}

.conteudo-markdown ul, .conteudo-markdown ol {
  margin: 4px 0 8px 20px;
  padding: 0;
}

.conteudo-markdown code {
  font-family: monospace;
  background-color: rgba(255, 255, 255, 0.08);
  padding: 1px 4px;
  border-radius: 4px;
}

/* Regras de Tela (@media screen) */
@media screen {
  .cabecalho-versao-impressa {
    display: none;
  }
  .player-video {
    display: block;
    width: 100%;
    max-width: 720px;
    border-radius: 8px;
    background-color: #000;
  }
  .poster-impressao {
    display: none;
  }
}

/* Regras de Impressão (@media print) */
@media print {
  body {
    background-color: #ffffff !important;
    color: #000000 !important;
    padding: 0;
  }
  .barra-navegacao-retorno, .acao-pdf-original {
    display: none !important;
  }
  .cabecalho-protocolo, .bloco-protocolo, .item-propriedade, .bloco-texto-longo, .card-item-lista, .midia-foto, .container-video, .documento-pdf-container, .secao-materiais-anexos {
    background-color: #ffffff !important;
    border-color: #cccccc !important;
    color: #000000 !important;
    page-break-inside: avoid;
  }
  h1, h2, .titulo-secao-lista, .campo-chave, .opcao-escolhida, .link-material, .legenda-midia {
    color: #000000 !important;
  }
  .badge-indice-item {
    background-color: #222222 !important;
    color: #ffffff !important;
  }
  .cabecalho-versao-impressa {
    display: block !important;
    border: 1.5px solid #444444;
    background-color: #f9f9f9;
    padding: 12px 16px;
    margin-bottom: 24px;
    border-radius: 6px;
    page-break-inside: avoid;
  }
  .cabecalho-versao-impressa a {
    color: #0044cc;
    word-break: break-all;
  }
  .player-video {
    display: none !important;
  }
  .poster-impressao {
    display: flex !important;
    align-items: center;
    gap: 16px;
    border: 1px dashed #666666;
    padding: 10px;
    border-radius: 6px;
    page-break-inside: avoid;
    margin: 12px 0;
  }
  .poster-impressao .foto-poster {
    max-width: 200px;
    height: auto;
    border-radius: 4px;
  }
  .poster-impressao .qr-box {
    font-size: 0.85rem;
  }
  .poster-impressao .qr-code {
    width: 90px;
    height: 90px;
  }
}
''';
  }

  String _escaparXml(String texto) {
    return texto
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  String _renderizarTextoOuMarkdown(String valorTexto) {
    final normalizado = valorTexto.replaceAll('\r\n', '\n');
    final possuiMultiplasLinhas = normalizado.contains('\n');
    final possuiBlocoMarkdown = RegExp(
      r'^(#{1,6}\s+|[-*]\s+|\d+\.\s+)',
      multiLine: true,
    ).hasMatch(normalizado);
    if (!possuiMultiplasLinhas && !possuiBlocoMarkdown) {
      return '<div class="campo-valor">${_renderizarInlineMarkdown(normalizado)}</div>';
    }

    final linhas = normalizado.split('\n');
    final buffer = StringBuffer('<div class="conteudo-markdown">');
    final paragrafoAtual = <String>[];
    String? tipoListaAberta;

    void fecharParagrafo() {
      if (paragrafoAtual.isNotEmpty) {
        buffer.write('<p>${paragrafoAtual.join('<br/>')}</p>');
        paragrafoAtual.clear();
      }
    }

    void fecharLista() {
      if (tipoListaAberta != null) {
        buffer.write('</$tipoListaAberta>');
        tipoListaAberta = null;
      }
    }

    for (final linhaBruta in linhas) {
      final linha = linhaBruta.trimRight();
      final limpa = linha.trim();

      if (limpa.isEmpty) {
        fecharParagrafo();
        fecharLista();
        continue;
      }

      final matchHeading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(limpa);
      if (matchHeading != null) {
        fecharParagrafo();
        fecharLista();
        final nivel = matchHeading.group(1)!.length;
        final tag = nivel <= 2 ? 'h4' : 'h5';
        final conteudo = _renderizarInlineMarkdown(matchHeading.group(2)!);
        buffer.write('<$tag>$conteudo</$tag>');
        continue;
      }

      final matchUl = RegExp(r'^[-*]\s+(.*)$').firstMatch(limpa);
      if (matchUl != null) {
        fecharParagrafo();
        if (tipoListaAberta != 'ul') {
          fecharLista();
          buffer.write('<ul>');
          tipoListaAberta = 'ul';
        }
        buffer.write('<li>${_renderizarInlineMarkdown(matchUl.group(1)!)}</li>');
        continue;
      }

      final matchOl = RegExp(r'^\d+\.\s+(.*)$').firstMatch(limpa);
      if (matchOl != null) {
        fecharParagrafo();
        if (tipoListaAberta != 'ol') {
          fecharLista();
          buffer.write('<ol>');
          tipoListaAberta = 'ol';
        }
        buffer.write('<li>${_renderizarInlineMarkdown(matchOl.group(1)!)}</li>');
        continue;
      }

      fecharLista();
      paragrafoAtual.add(_renderizarInlineMarkdown(limpa));
    }

    fecharParagrafo();
    fecharLista();
    buffer.write('</div>');
    return buffer.toString();
  }

  String _renderizarInlineMarkdown(String texto) {
    var escapado = _escaparXml(texto);

    escapado = escapado.replaceAllMapped(
      RegExp(r'`([^`]+)`'),
      (m) => '<code>${m.group(1)}</code>',
    );
    escapado = escapado.replaceAllMapped(
      RegExp(r'\*\*([^*]+)\*\*'),
      (m) => '<strong>${m.group(1)}</strong>',
    );
    escapado = escapado.replaceAllMapped(
      RegExp(r'~~([^~]+)~~'),
      (m) => '<del>${m.group(1)}</del>',
    );
    escapado = escapado.replaceAllMapped(
      RegExp(r'\*([^*\n]+)\*'),
      (m) => '<em>${m.group(1)}</em>',
    );
    return escapado;
  }

  String _renderizarMidiaDocumento({
    required String rotuloCampo,
    required ArquivoDocumento doc,
    required Map<String, String> mapeamentoMidias,
  }) {
    final uuid = doc.uuid;
    final nome = doc.nomeOriginal.isNotEmpty ? doc.nomeOriginal : '$uuid.pdf';
    final caminhoPdf = mapeamentoMidias[uuid] ?? '';

    final paginasMapeadas = <({int numero, String caminho})>[];
    final limiteBusca = doc.quantidadePaginas > 0 ? doc.quantidadePaginas : 999;
    for (var i = 1; i <= limiteBusca; i++) {
      final caminhoPagina = mapeamentoMidias['${uuid}_p$i'] ?? '';
      if (caminhoPagina.isNotEmpty) {
        paginasMapeadas.add((numero: i, caminho: caminhoPagina));
      } else if (doc.quantidadePaginas == 0) {
        break;
      }
    }

    if (caminhoPdf.isEmpty && paginasMapeadas.isEmpty) {
      return '';
    }

    final totalPaginas = doc.quantidadePaginas > 0
        ? doc.quantidadePaginas
        : paginasMapeadas.length;
    final nomeEscapado = _escaparXml(nome);

    final buf = StringBuffer();
    buf.write('<div class="documento-pdf-container">');
    buf.write('<div class="legenda-midia">${_escaparXml(rotuloCampo)}</div>');
    if (caminhoPdf.isNotEmpty) {
      buf.write(
        '<div class="acao-pdf-original">'
        '<a href="$caminhoPdf" download="$nomeEscapado" class="link-pdf-original">'
        '📄 Baixar / Abrir PDF Original ($nomeEscapado)'
        '</a>'
        '</div>',
      );
    }
    if (paginasMapeadas.isNotEmpty) {
      buf.write('<div class="grade-fotos">');
      for (final pag in paginasMapeadas) {
        buf.write(
          '<div class="midia-foto pagina-pdf">'
          '<p class="legenda-pagina-pdf">$nomeEscapado — Página ${pag.numero} de $totalPaginas</p>'
          '<img src="${pag.caminho}" alt="Página ${pag.numero} de $nomeEscapado"/>'
          '</div>',
        );
      }
      buf.write('</div>');
    }
    buf.write('</div>');
    return buf.toString();
  }

  String _renderizarNodo({
    required NodoRelatorio nodo,
    required Map<String, String> mapeamentoMidias,
    required Map<String, String> posterFrames,
    required Map<String, String> qrCodesVideos,
    required Map<String, String> titulosMateriais,
  }) {
    switch (nodo) {
      case GradePropriedadesRelatorio():
        final buf = StringBuffer('<div class="grade-propriedades">');
        for (final prop in nodo.propriedades) {
          buf.write('<div class="item-propriedade">');
          buf.write('<div class="campo-chave">${_escaparXml(prop.rotulo)}</div>');
          if (prop.subrotulo.isNotEmpty) {
            buf.write(
              '<div class="campo-subrotulo">${_escaparXml(prop.subrotulo)}</div>',
            );
          }
          buf.write(
            '<div class="campo-valor">${_escaparXml(prop.valor)}</div>',
          );
          buf.write('</div>');
        }
        buf.write('</div>');
        return buf.toString();

      case DestaqueEscolhaRelatorio():
        final buf = StringBuffer('<div class="destaque-escolha">');
        buf.write(
          '<div class="pergunta-escolha">${_escaparXml(nodo.rotuloPergunta)}</div>',
        );
        buf.write(
          '<div class="opcao-escolhida">${_escaparXml(nodo.rotuloOpcao)}</div>',
        );
        if (nodo.subrotuloOpcao.isNotEmpty) {
          buf.write(
            '<div class="subrotulo-escolha">${_escaparXml(nodo.subrotuloOpcao)}</div>',
          );
        }
        buf.write('</div>');
        return buf.toString();

      case TextoLongoRelatorio():
        final buf = StringBuffer('<div class="bloco-texto-longo">');
        buf.write('<div class="campo-chave">${_escaparXml(nodo.rotulo)}</div>');
        if (nodo.subrotulo.isNotEmpty) {
          buf.write(
            '<div class="campo-subrotulo">${_escaparXml(nodo.subrotulo)}</div>',
          );
        }
        buf.write(_renderizarTextoOuMarkdown(nodo.textoMarkdown));
        buf.write('</div>');
        return buf.toString();

      case ReferenciasMateriaisRelatorio():
        final buf = StringBuffer('<div class="bloco-ref-materiais">');
        buf.write('<div class="campo-chave">${_escaparXml(nodo.rotulo)}</div>');
        if (nodo.subrotulo.isNotEmpty) {
          buf.write(
            '<div class="campo-subrotulo">${_escaparXml(nodo.subrotulo)}</div>',
          );
        }
        buf.write('<div class="lista-chips-materiais">');
        for (final uuid in nodo.uuidsMateriais) {
          final rotuloMat = titulosMateriais[uuid] ?? uuid;
          buf.write(
            '<a href="materiais/$uuid/OEBPS/relatorio.xhtml" class="link-material">${_escaparXml(rotuloMat)}</a>',
          );
        }
        buf.write('</div></div>');
        return buf.toString();

      case GaleriaMidiasRelatorio():
        final fotosBuffer = StringBuffer();
        final outrosBuffer = StringBuffer();

        for (final item in nodo.itens) {
          final midia = item.midia;
          final rotuloEscapado = _escaparXml(item.rotuloCampo);
          if (midia.hasImagem()) {
            final uuid = midia.imagem.uuid;
            final caminho = mapeamentoMidias[uuid] ?? '';
            if (caminho.isNotEmpty) {
              fotosBuffer.write(
                '<figure class="midia-foto">'
                '<figcaption class="legenda-midia">$rotuloEscapado</figcaption>'
                '<img src="$caminho" alt="$rotuloEscapado"/>'
                '</figure>',
              );
            }
          } else if (midia.hasVideo()) {
            final uuid = midia.video.uuid;
            final caminhoVideo = mapeamentoMidias[uuid] ?? '';
            final caminhoPoster = posterFrames[uuid] ?? '';
            final caminhoQr = qrCodesVideos[uuid] ?? '';

            outrosBuffer.write('<div class="container-video">');
            outrosBuffer.write('<div class="legenda-midia">$rotuloEscapado</div>');
            outrosBuffer.write(
              '<video controls="controls" poster="$caminhoPoster" class="player-video">'
              '<source src="$caminhoVideo" type="video/mp4" />'
              'Seu visualizador não suporta reprodução de vídeo.'
              '</video>',
            );
            outrosBuffer.write(
              '<div class="poster-impressao">'
              '<img src="$caminhoPoster" class="foto-poster" alt="Frame da inspeção"/>'
              '<div class="qr-box">'
              '<img src="$caminhoQr" class="qr-code" alt="QR Code do Vídeo"/>'
              '<p>Escaneie para assistir ao vídeo desta proteção online</p>'
              '</div>'
              '</div>',
            );
            outrosBuffer.write('</div>');
          } else if (midia.hasDocumento()) {
            outrosBuffer.write(
              _renderizarMidiaDocumento(
                rotuloCampo: item.rotuloCampo,
                doc: midia.documento,
                mapeamentoMidias: mapeamentoMidias,
              ),
            );
          }
        }

        if (fotosBuffer.isEmpty && outrosBuffer.isEmpty) {
          return '';
        }

        final buf = StringBuffer('<div class="galeria-midias">');
        if (fotosBuffer.isNotEmpty) {
          buf.write('<div class="grade-fotos">${fotosBuffer.toString()}</div>');
        }
        buf.write(outrosBuffer.toString());
        buf.write('</div>');
        return buf.toString();

      case SecaoListaRelatorio():
        final buf = StringBuffer('<div class="secao-lista">');
        buf.write('<div class="cabecalho-secao-lista">');
        buf.write(
          '<h3 class="titulo-secao-lista">${_escaparXml(nodo.rotulo)}</h3>',
        );
        if (nodo.subrotulo.isNotEmpty) {
          buf.write(
            '<p class="subtitulo-secao-lista">${_escaparXml(nodo.subrotulo)}</p>',
          );
        }
        buf.write('</div>');

        for (final item in nodo.itens) {
          buf.write('<article class="card-item-lista">');
          buf.write('<div class="cabecalho-card-item">');
          buf.write(
            '<span class="badge-indice-item">${_escaparXml(item.indiceFormatado)}</span>',
          );
          buf.write('<div class="titulos-card-item">');
          buf.write(
            '<strong class="titulo-card-item">${_escaparXml(item.rotuloTipo)}</strong>',
          );
          if (item.subrotuloTipo.isNotEmpty) {
            buf.write(
              '<span class="subtitulo-card-item">${_escaparXml(item.subrotuloTipo)}</span>',
            );
          }
          buf.write('</div></div>');
          buf.write('<div class="corpo-card-item">');
          for (final subNodo in item.nodos) {
            buf.write(
              _renderizarNodo(
                nodo: subNodo,
                mapeamentoMidias: mapeamentoMidias,
                posterFrames: posterFrames,
                qrCodesVideos: qrCodesVideos,
                titulosMateriais: titulosMateriais,
              ),
            );
          }
          buf.write('</div></article>');
        }
        buf.write('</div>');
        return buf.toString();
    }
  }

  /// Gera a marcação XHTML5 semântica para o relatório a partir dos dados do [registro].
  String gerarXhtml({
    required Registro registro,
    required String idSessao,
    required String urlCanonica,
    Map<String, String> mapeamentoMidias = const {},
    Map<String, String> posterFrames = const {},
    Map<String, String> qrCodesVideos = const {},
    String? qrCodeCanonica,
    Map<String, String> titulosMateriais = const {},
    String? codigoIdioma,
    Map<String, dynamic>? traducoesProtocolo,
  }) {
    final langAttr = codigoIdioma ?? 'pt-BR';
    final codigoNorm = langAttr.split(RegExp(r'[-_]')).first.toLowerCase();
    final atributoDir = codigoNorm == 'ar' ? ' dir="rtl"' : '';
    final l10n = ResolvedorIdioma.obterTraducoes(Locale(codigoNorm));
    final arvore = _construtorArvore.construir(
      registro,
      codigoIdioma: codigoIdioma != null ? codigoNorm : null,
      traducoes: traducoesProtocolo,
    );
    final buffer = StringBuffer();

    final tituloPrincipal = arvore.tituloExibicao != arvore.nomeProtocolo
        ? '${arvore.nomeProtocolo} — ${arvore.tituloExibicao}'
        : arvore.nomeProtocolo;

    buffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln(
      '<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="$langAttr"$atributoDir>',
    );
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="utf-8"/>');
    buffer.writeln('  <title>${_escaparXml(tituloPrincipal)}</title>');
    buffer.writeln('  <link rel="stylesheet" type="text/css" href="estilo.css"/>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    buffer.writeln('  <nav class="barra-navegacao-retorno">');
    buffer.writeln(
      '    <a href="javascript:history.back()" class="botao-voltar">← Voltar para a página anterior</a>',
    );
    buffer.writeln('  </nav>');

    final sufixoResumo = codigoNorm == 'pt' ? ' (Versão Resumida)' : '';
    final avisoImpresso = codigoNorm == 'pt'
        ? 'Este documento é uma representação impressa. ${l10n.laudoAvisoResumoImpresso}'
        : l10n.laudoAvisoResumoImpresso;
    buffer.writeln('  <div class="cabecalho-versao-impressa">');
    buffer.writeln(
      '    <p><strong>Fixalog — ${_escaparXml(arvore.nomeProtocolo)}$sufixoResumo</strong></p>',
    );
    buffer.writeln(
      '    <p>${_escaparXml(avisoImpresso)}</p>',
    );
    buffer.writeln('    <p><a href="$urlCanonica">$urlCanonica</a></p>');
    if (qrCodeCanonica != null && qrCodeCanonica.isNotEmpty) {
      buffer.writeln(
        '    <img src="$qrCodeCanonica" class="qr-code" alt="QR Code do Relatório Oficial"/>',
      );
    }
    buffer.writeln('  </div>');

    buffer.writeln('  <header class="cabecalho-protocolo">');
    if (arvore.versaoProtocolo.isNotEmpty) {
      buffer.writeln('    <div class="topo-cabecalho">');
      buffer.writeln(
        '      <span class="badge-versao">v${_escaparXml(arvore.versaoProtocolo)}</span>',
      );
      buffer.writeln('    </div>');
    }
    buffer.writeln('    <h1>${_escaparXml(tituloPrincipal)}</h1>');
    if (arvore.descricaoProtocolo.isNotEmpty) {
      buffer.writeln(
        '    <p class="subtitulo-protocolo">${_escaparXml(arvore.descricaoProtocolo)}</p>',
      );
    }
    buffer.writeln('    <div class="metadados-sessao">');
    buffer.writeln('      <div><strong>${_escaparXml(l10n.laudoRotuloSessao)}:</strong> $idSessao</div>');
    buffer.writeln(
      '      <div><strong>URL Canônica:</strong> $urlCanonica</div>',
    );
    buffer.writeln('    </div>');
    buffer.writeln('  </header>');

    buffer.writeln('  <main>');

    for (final bloco in arvore.blocos) {
      buffer.writeln(
        '    <section class="bloco-protocolo" id="bloco-${_escaparXml(bloco.id)}">',
      );
      buffer.writeln('      <div class="cabecalho-bloco">');
      buffer.writeln('        <h2>${_escaparXml(bloco.titulo)}</h2>');
      if (bloco.subtitulo.isNotEmpty) {
        buffer.writeln(
          '        <p class="subtitulo-bloco">${_escaparXml(bloco.subtitulo)}</p>',
        );
      }
      buffer.writeln('      </div>');

      for (final nodo in bloco.nodos) {
        final htmlNodo = _renderizarNodo(
          nodo: nodo,
          mapeamentoMidias: mapeamentoMidias,
          posterFrames: posterFrames,
          qrCodesVideos: qrCodesVideos,
          titulosMateriais: titulosMateriais,
        );
        if (htmlNodo.isNotEmpty) {
          buffer.writeln('      $htmlNodo');
        }
      }

      buffer.writeln('    </section>');
    }

    if (titulosMateriais.isNotEmpty) {
      buffer.writeln('    <section class="secao-materiais-anexos">');
      buffer.writeln(
        '      <h2>${_escaparXml(l10n.laudoSecaoAnexoCatalogoTitulo)}</h2>',
      );
      buffer.writeln('      <div class="lista-chips-materiais">');
      for (final entradaMat in titulosMateriais.entries) {
        final uuidMat = entradaMat.key;
        final tituloMat = entradaMat.value;
        buffer.writeln(
          '        <a href="materiais/$uuidMat/OEBPS/relatorio.xhtml" class="link-material">${_escaparXml(tituloMat)}</a>',
        );
      }
      buffer.writeln('      </div>');
      buffer.writeln('    </section>');
    }

    buffer.writeln('  </main>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }
}
