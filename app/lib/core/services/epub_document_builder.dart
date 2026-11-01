// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import '../models/proto/protos/registro.pb.dart';

/// Construtor de documentos semânticos em XHTML5 e CSS para relatórios técnicos em EPUB 3.
///
/// Produz a marcação padronizada de acordo com a especificação W3C EPUB 3.3,
/// contendo regras para exibição interativa em tela e regras de impressão (@media print)
/// para exportação de PDFs resumidos de protocolo.
class EpubDocumentBuilder {
  /// Extrai todas as [ReferenciaMidia] presentes em uma [Resposta],
  /// seja como mídia única (`resp.hasMidia()`) ou dentro de `resp.lista`.
  static List<ReferenciaMidia> extrairMidiasDeResposta(Resposta? resp) {
    if (resp == null) return const [];
    if (resp.hasMidia()) return [resp.midia];
    if (resp.hasLista()) {
      return resp.lista.valores
          .where((v) => v.hasMidia())
          .map((v) => v.midia)
          .toList();
    }
    return const [];
  }

  /// Extrai de um [registro] o conjunto ordenado de UUIDs de materiais do catálogo referenciados.
  static List<String> extrairUuidsMateriaisReferenciados(Registro registro) {
    final Set<String> uuids = {};

    void processarChaveValor(String chave, Resposta resposta) {
      if (chave != 'lista_materiais_c' && !chave.startsWith('ref_mat')) return;
      if (resposta.hasTexto()) {
        for (final parte in resposta.texto.split(',')) {
          final limpo = parte.trim();
          if (limpo.isNotEmpty) {
            uuids.add(limpo);
          }
        }
      } else if (resposta.hasLista()) {
        for (final item in resposta.lista.valores) {
          if (item.hasTexto() && item.texto.trim().isNotEmpty) {
            uuids.add(item.texto.trim());
          }
        }
      }
    }

    for (final entrada in registro.respostas.entries) {
      processarChaveValor(entrada.key, entrada.value);
    }
    for (final grupo in registro.listas) {
      for (final entrada in grupo.respostasItem.entries) {
        processarChaveValor(entrada.key, entrada.value);
      }
    }

    return uuids.toList();
  }

  /// Gera a folha de estilos CSS completa com regras para visualização em tela e impressão.
  String gerarCss() {
    return '''
/* Estilos Gerais do Relatório Fixalog */
:root {
  --cor-fundo: #121416;
  --cor-superficie: #1a1c1e;
  --cor-destaque: #ff6b00;
  --cor-texto: #e1e2e5;
  --cor-texto-suave: #9e9e9e;
  --cor-borda: #333537;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  line-height: 1.6;
  color: var(--cor-texto);
  background-color: var(--cor-fundo);
  margin: 0;
  padding: 24px;
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

.link-material {
  color: var(--cor-destaque);
  font-weight: bold;
  text-decoration: underline;
}

header {
  border-bottom: 2px solid var(--cor-destaque);
  padding-bottom: 16px;
  margin-bottom: 24px;
}

h1 {
  font-size: 1.8rem;
  color: var(--cor-destaque);
  margin: 0 0 8px 0;
}

h2 {
  font-size: 1.3rem;
  margin-top: 24px;
  border-bottom: 1px solid var(--cor-borda);
  padding-bottom: 6px;
}

.metadados-sessao {
  background-color: var(--cor-superficie);
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 0.9rem;
  margin-bottom: 24px;
}

.campo-registro {
  margin-bottom: 12px;
  padding: 8px 0;
}

.campo-chave {
  font-weight: bold;
  color: var(--cor-destaque);
}

.midia-foto {
  margin: 16px 0;
  text-align: center;
}

.midia-foto img {
  max-width: 100%;
  height: auto;
  border-radius: 8px;
  border: 1px solid var(--cor-borda);
}

.container-video {
  margin: 16px 0;
}

.documento-pdf-container {
  margin: 16px 0;
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
  header {
    border-bottom: 2px solid #000000;
  }
  h1, h2, .campo-chave, .link-material {
    color: #000000 !important;
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

  String _renderizarTextoOuReferenciaMaterial(
    String chave,
    String valorTexto,
    Map<String, String> titulosMateriais,
  ) {
    final ehCampoRefMaterial =
        chave == 'lista_materiais_c' || chave.startsWith('ref_mat');
    final tokens = valorTexto
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final contemMaterialConhecido =
        tokens.any((t) => titulosMateriais.containsKey(t));

    if (!ehCampoRefMaterial && !contemMaterialConhecido) {
      return _renderizarTextoOuMarkdown(valorTexto);
    }

    final links = tokens.map((token) {
      if (ehCampoRefMaterial || titulosMateriais.containsKey(token)) {
        final rotulo = titulosMateriais[token] ?? token;
        return '<a href="materiais/$token/OEBPS/relatorio.xhtml" class="link-material">$rotulo</a>';
      }
      return '<span>$token</span>';
    }).join(', ');

    return '<span>$links</span>';
  }

  String _renderizarTextoOuMarkdown(String valorTexto) {
    final normalizado = valorTexto.replaceAll('\r\n', '\n');
    final possuiMultiplasLinhas = normalizado.contains('\n');
    final possuiBlocoMarkdown = RegExp(
      r'^(#{1,6}\s+|[-*]\s+|\d+\.\s+)',
      multiLine: true,
    ).hasMatch(normalizado);
    final possuiInlineMarkdown = RegExp(
      r'(\*\*[^*]+\*\*|~~[^~]+~~|`[^`]+`|\*[^*\n]+\*)',
    ).hasMatch(normalizado);

    if (!possuiMultiplasLinhas && !possuiBlocoMarkdown) {
      if (!possuiInlineMarkdown) {
        return '<span>$valorTexto</span>';
      }
      return '<span>${_renderizarInlineMarkdown(normalizado)}</span>';
    }

    final linhas = normalizado.split('\n');
    final buffer = StringBuffer('<div class="conteudo-markdown">');
    final paragrafoAtual = <String>[];
    String? tipoListaAberta; // 'ul' ou 'ol'

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
    var escapado = texto
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');

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

  String _renderizarMidiaDocumento(
    ArquivoDocumento doc,
    Map<String, String> mapeamentoMidias,
  ) {
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

    final buf = StringBuffer();
    buf.write('<div class="documento-pdf-container">');
    if (caminhoPdf.isNotEmpty) {
      buf.write(
        '<div class="acao-pdf-original">'
        '<a href="$caminhoPdf" download="$nome" class="link-pdf-original">'
        '📄 Baixar / Abrir PDF Original ($nome)'
        '</a>'
        '</div>',
      );
    }
    for (final pag in paginasMapeadas) {
      buf.write(
        '<div class="midia-foto pagina-pdf">'
        '<p class="legenda-pagina-pdf">$nome — Página ${pag.numero} de $totalPaginas</p>'
        '<img src="${pag.caminho}" alt="Página ${pag.numero} de $nome"/>'
        '</div>',
      );
    }
    buf.write('</div>');
    return buf.toString();
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
  }) {
    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln(
      '<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="pt-BR">',
    );
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="utf-8"/>');
    buffer.writeln('  <title>Relatório de Manutenção - ${registro.idProtocolo}</title>');
    buffer.writeln('  <link rel="stylesheet" type="text/css" href="estilo.css"/>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    // Barra de navegação de retorno (útil ao navegar da manutenção para a ficha do material)
    buffer.writeln('  <nav class="barra-navegacao-retorno">');
    buffer.writeln(
      '    <a href="javascript:history.back()" class="botao-voltar">← Voltar para a página anterior</a>',
    );
    buffer.writeln('  </nav>');

    // Cabeçalho exclusivo para versão impressa (PDF Resumido)
    buffer.writeln('  <div class="cabecalho-versao-impressa">');
    buffer.writeln('    <p><strong>Fixalog — Relatório Técnico de Manutenção (Versão Resumida)</strong></p>');
    buffer.writeln(
      '    <p>Este documento é uma representação impressa. O relatório canônico oficial — contendo os vídeos originais de inspeção em alta definição e dados brutos — está disponível em:</p>',
    );
    buffer.writeln('    <p><a href="$urlCanonica">$urlCanonica</a></p>');
    if (qrCodeCanonica != null && qrCodeCanonica.isNotEmpty) {
      buffer.writeln('    <img src="$qrCodeCanonica" class="qr-code" alt="QR Code do Relatório Oficial"/>');
    }
    buffer.writeln('  </div>');

    // Cabeçalho Principal
    buffer.writeln('  <header>');
    buffer.writeln('    <h1>Relatório de Vistoria: ${registro.idProtocolo}</h1>');
    buffer.writeln('    <div class="metadados-sessao">');
    buffer.writeln('      <div><strong>Sessão ID:</strong> $idSessao</div>');
    buffer.writeln('      <div><strong>URL Canônica:</strong> $urlCanonica</div>');
    buffer.writeln('    </div>');
    buffer.writeln('  </header>');

    buffer.writeln('  <main>');

    // Respostas Simples
    if (registro.respostas.isNotEmpty) {
      buffer.writeln('    <section class="secao-respostas">');
      buffer.writeln('      <h2>Dados Coletados</h2>');

      for (final entrada in registro.respostas.entries) {
        final chave = entrada.key;
        final resposta = entrada.value;

        buffer.write('      <div class="campo-registro">');
        buffer.write('<span class="campo-chave">$chave:</span> ');

        final midiasResposta = extrairMidiasDeResposta(resposta);
        if (resposta.hasTexto()) {
          buffer.write(
            _renderizarTextoOuReferenciaMaterial(
              chave,
              resposta.texto,
              titulosMateriais,
            ),
          );
        } else if (resposta.hasNumero()) {
          buffer.write('<span>${resposta.numero}</span>');
        } else if (resposta.hasInteiro()) {
          buffer.write('<span>${resposta.inteiro}</span>');
        } else if (resposta.hasBooleano()) {
          buffer.write('<span>${resposta.booleano ? "Sim" : "Não"}</span>');
        } else if (midiasResposta.isNotEmpty) {
          for (final midia in midiasResposta) {
            if (midia.hasImagem()) {
              final uuid = midia.imagem.uuid;
              final caminho = mapeamentoMidias[uuid] ?? '';
              if (caminho.isNotEmpty) {
                buffer.write(
                  '<div class="midia-foto"><img src="$caminho" alt="Foto da proteção $chave"/></div>',
                );
              }
            } else if (midia.hasVideo()) {
              final uuid = midia.video.uuid;
              final caminhoVideo = mapeamentoMidias[uuid] ?? '';
              final caminhoPoster = posterFrames[uuid] ?? '';
              final caminhoQr = qrCodesVideos[uuid] ?? '';

              buffer.write('<div class="container-video">');
              // Player de tela
              buffer.write(
                '<video controls="controls" poster="$caminhoPoster" class="player-video">'
                '<source src="$caminhoVideo" type="video/mp4" />'
                'Seu visualizador não suporta reprodução de vídeo.'
                '</video>',
              );
              // Fallback de impressão (PDF)
              buffer.write(
                '<div class="poster-impressao">'
                '<img src="$caminhoPoster" class="foto-poster" alt="Frame da inspeção"/>'
                '<div class="qr-box">'
                '<img src="$caminhoQr" class="qr-code" alt="QR Code do Vídeo"/>'
                '<p>Escaneie para assistir ao vídeo desta proteção online</p>'
                '</div>'
                '</div>',
              );
              buffer.write('</div>');
            } else if (midia.hasDocumento()) {
              buffer.write(
                _renderizarMidiaDocumento(midia.documento, mapeamentoMidias),
              );
            }
          }
        } else if (resposta.hasLista()) {
          final textos = resposta.lista.valores
              .where((v) => v.hasTexto() && v.texto.isNotEmpty)
              .map((v) => v.texto)
              .join(', ');
          if (textos.isNotEmpty) {
            buffer.write(
              _renderizarTextoOuReferenciaMaterial(
                chave,
                textos,
                titulosMateriais,
              ),
            );
          }
        }
        buffer.writeln('</div>');
      }
      buffer.writeln('    </section>');
    }

    // Listas / Grupos Repetidos
    if (registro.listas.isNotEmpty) {
      buffer.writeln('    <section class="secao-listas">');
      buffer.writeln('      <h2>Itens Catalogados</h2>');

      for (final grupo in registro.listas) {
        buffer.writeln('      <div class="grupo-lista">');
        buffer.writeln('        <h3>${grupo.idLista} (${grupo.idTipo})</h3>');

        for (final item in grupo.respostasItem.entries) {
          final chaveItem = item.key;
          final respItem = item.value;

          buffer.write('        <div class="campo-registro">');
          buffer.write('<span class="campo-chave">$chaveItem:</span> ');

          final midiasItem = extrairMidiasDeResposta(respItem);
          if (respItem.hasTexto()) {
            buffer.write(
              _renderizarTextoOuReferenciaMaterial(
                chaveItem,
                respItem.texto,
                titulosMateriais,
              ),
            );
          } else if (respItem.hasNumero()) {
            buffer.write('<span>${respItem.numero}</span>');
          } else if (respItem.hasInteiro()) {
            buffer.write('<span>${respItem.inteiro}</span>');
          } else if (respItem.hasBooleano()) {
            buffer.write('<span>${respItem.booleano ? "Sim" : "Não"}</span>');
          } else if (midiasItem.isNotEmpty) {
            for (final midia in midiasItem) {
              if (midia.hasImagem()) {
                final uuid = midia.imagem.uuid;
                final caminho = mapeamentoMidias[uuid] ?? '';
                if (caminho.isNotEmpty) {
                  buffer.write(
                    '<div class="midia-foto"><img src="$caminho" alt="Foto do item $chaveItem"/></div>',
                  );
                }
              } else if (midia.hasVideo()) {
                final uuid = midia.video.uuid;
                final caminhoVideo = mapeamentoMidias[uuid] ?? '';
                final caminhoPoster = posterFrames[uuid] ?? '';
                final caminhoQr = qrCodesVideos[uuid] ?? '';

                buffer.write('<div class="container-video">');
                buffer.write(
                  '<video controls="controls" poster="$caminhoPoster" class="player-video">'
                  '<source src="$caminhoVideo" type="video/mp4" />'
                  '</video>',
                );
                buffer.write(
                  '<div class="poster-impressao">'
                  '<img src="$caminhoPoster" class="foto-poster" alt="Frame da inspeção"/>'
                  '<div class="qr-box">'
                  '<img src="$caminhoQr" class="qr-code" alt="QR Code do Vídeo"/>'
                  '<p>Escaneie para assistir ao vídeo desta proteção online</p>'
                  '</div>'
                  '</div>',
                );
                buffer.write('</div>');
              } else if (midia.hasDocumento()) {
                buffer.write(
                  _renderizarMidiaDocumento(midia.documento, mapeamentoMidias),
                );
              }
            }
          } else if (respItem.hasLista()) {
            final textos = respItem.lista.valores
                .where((v) => v.hasTexto() && v.texto.isNotEmpty)
                .map((v) => v.texto)
                .join(', ');
            if (textos.isNotEmpty) {
              buffer.write(
                _renderizarTextoOuReferenciaMaterial(
                  chaveItem,
                  textos,
                  titulosMateriais,
                ),
              );
            }
          }
          buffer.writeln('</div>');
        }
        buffer.writeln('      </div>');
      }
      buffer.writeln('    </section>');
    }

    if (titulosMateriais.isNotEmpty) {
      buffer.writeln('    <section class="secao-materiais-anexos">');
      buffer.writeln('      <h2>Materiais Utilizados (Fichas Técnicas Anexas)</h2>');
      buffer.writeln('      <ul>');
      for (final entradaMat in titulosMateriais.entries) {
        final uuidMat = entradaMat.key;
        final tituloMat = entradaMat.value;
        buffer.writeln(
          '        <li><a href="materiais/$uuidMat/OEBPS/relatorio.xhtml" class="link-material">$tituloMat</a></li>',
        );
      }
      buffer.writeln('      </ul>');
      buffer.writeln('    </section>');
    }

    buffer.writeln('  </main>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }
}
