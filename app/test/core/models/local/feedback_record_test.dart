// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/core/models/local/feedback_record.dart';

void main() {
  group('FeedbackRecord — Serialização SQLite (toMap / fromMap)', () {
    test(
      'serializa e desserializa todos os campos preservando tipos, defaults e flag booleana enviado',
      () {
        final data = DateTime.utc(2026, 11, 9, 12, 30, 0);
        final novoRegistro = FeedbackRecord(
          idFeedback: 'fb-uuid-001',
          mensagem: 'Dúvida sobre chapeleta Pingo no Bloco 2',
          categoria: 'protocolo',
          caminhoImagem: '/tmp/feedback_queue/fb-uuid-001.webp',
          metadadosJson: '{"idioma":"pt","protocolo":"abertura_via"}',
          dataCriacao: data,
          enviado: false,
        );

        final mapaSemId = novoRegistro.toMap();
        expect(mapaSemId.containsKey('id'), isFalse);
        expect(mapaSemId['id_feedback'], equals('fb-uuid-001'));
        expect(
          mapaSemId['mensagem'],
          equals('Dúvida sobre chapeleta Pingo no Bloco 2'),
        );
        expect(mapaSemId['categoria'], equals('protocolo'));
        expect(
          mapaSemId['caminho_imagem'],
          equals('/tmp/feedback_queue/fb-uuid-001.webp'),
        );
        expect(
          mapaSemId['metadados_json'],
          equals('{"idioma":"pt","protocolo":"abertura_via"}'),
        );
        expect(mapaSemId['data_criacao'], equals(data.toIso8601String()));
        expect(mapaSemId['enviado'], equals(0));

        // Com ID atribuído e enviado = true
        final registroSalvo = novoRegistro.copiarCom(id: 42, enviado: true);
        final mapaComId = registroSalvo.toMap();
        expect(mapaComId['id'], equals(42));
        expect(mapaComId['enviado'], equals(1));

        final reconstruido = FeedbackRecord.fromMap(mapaComId);
        expect(reconstruido.id, equals(42));
        expect(reconstruido.idFeedback, equals('fb-uuid-001'));
        expect(
          reconstruido.mensagem,
          equals('Dúvida sobre chapeleta Pingo no Bloco 2'),
        );
        expect(reconstruido.categoria, equals('protocolo'));
        expect(
          reconstruido.caminhoImagem,
          equals('/tmp/feedback_queue/fb-uuid-001.webp'),
        );
        expect(
          reconstruido.metadadosJson,
          equals('{"idioma":"pt","protocolo":"abertura_via"}'),
        );
        expect(reconstruido.dataCriacao, equals(data));
        expect(reconstruido.enviado, isTrue);
      },
    );

    test(
      'fromMap aplica valores padrão seguros quando colunas opcionais vêm nulas ou vazias',
      () {
        final reconstruido = FeedbackRecord.fromMap(const <String, Object?>{});
        expect(reconstruido.id, equals(0));
        expect(reconstruido.idFeedback, isEmpty);
        expect(reconstruido.mensagem, isEmpty);
        expect(reconstruido.categoria, equals('aplicativo'));
        expect(reconstruido.caminhoImagem, isEmpty);
        expect(reconstruido.metadadosJson, equals('{}'));
        expect(reconstruido.enviado, isFalse);

        final copia = reconstruido.copiarCom(
          idFeedback: 'fb-2',
          mensagem: 'Mensagem atualizada',
          categoria: 'outro',
          caminhoImagem: '/tmp/img.png',
          metadadosJson: '{"k":"v"}',
          dataCriacao: DateTime.utc(2026, 1, 1),
        );
        expect(copia.idFeedback, equals('fb-2'));
        expect(copia.mensagem, equals('Mensagem atualizada'));
        expect(copia.categoria, equals('outro'));
        expect(copia.caminhoImagem, equals('/tmp/img.png'));
        expect(copia.metadadosJson, equals('{"k":"v"}'));
        expect(copia.dataCriacao, equals(DateTime.utc(2026, 1, 1)));
      },
    );
  });
}
