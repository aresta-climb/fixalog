// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import '../models/proto/protos/registro.pb.dart';

/// Construtor de documentos semânticos em XHTML5 e CSS para relatórios técnicos em EPUB 3.
///
/// Produz a marcação padronizada de acordo com a especificação W3C EPUB 3.3,
/// contendo regras para exibição interativa em tela e regras de impressão (@media print)
/// para exportação de PDFs resumidos de protocolo.
class EpubDocumentBuilder {
  /// Gera a folha de estilos CSS completa com regras para visualização em tela e impressão.
  String gerarCss() {
    return '''
/* Estilos Gerais do Relatório FixLog */
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
  header {
    border-bottom: 2px solid #000000;
  }
  h1, h2, .campo-chave {
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

  /// Gera a marcação XHTML5 semântica para o relatório a partir dos dados do [registro].
  String gerarXhtml({
    required Registro registro,
    required String idSessao,
    required String urlCanonica,
    Map<String, String> mapeamentoMidias = const {},
    Map<String, String> posterFrames = const {},
    Map<String, String> qrCodesVideos = const {},
    String? qrCodeCanonica,
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

    // Cabeçalho exclusivo para versão impressa (PDF Resumido)
    buffer.writeln('  <div class="cabecalho-versao-impressa">');
    buffer.writeln('    <p><strong>FixLog — Relatório Técnico de Manutenção (Versão Resumida)</strong></p>');
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

        if (resposta.hasTexto()) {
          buffer.write('<span>${resposta.texto}</span>');
        } else if (resposta.hasNumero()) {
          buffer.write('<span>${resposta.numero}</span>');
        } else if (resposta.hasInteiro()) {
          buffer.write('<span>${resposta.inteiro}</span>');
        } else if (resposta.hasBooleano()) {
          buffer.write('<span>${resposta.booleano ? "Sim" : "Não"}</span>');
        } else if (resposta.hasMidia()) {
          final midia = resposta.midia;
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

          if (respItem.hasTexto()) {
            buffer.write('<span>${respItem.texto}</span>');
          } else if (respItem.hasNumero()) {
            buffer.write('<span>${respItem.numero}</span>');
          } else if (respItem.hasInteiro()) {
            buffer.write('<span>${respItem.inteiro}</span>');
          } else if (respItem.hasBooleano()) {
            buffer.write('<span>${respItem.booleano ? "Sim" : "Não"}</span>');
          } else if (respItem.hasMidia()) {
            final midia = respItem.midia;
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
            }
          }
          buffer.writeln('</div>');
        }
        buffer.writeln('      </div>');
      }
      buffer.writeln('    </section>');
    }

    buffer.writeln('  </main>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }
}
