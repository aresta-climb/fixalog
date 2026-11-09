// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'registro_logger_fake.dart';

void main() {
  group('RegistroLoggerFake — Contrato Determinístico em Memória', () {
    test(
      'registra infos, avisos, erros operacionais, crashes e rebaixa desconexão em logFalhaSyncOuDownload',
      () {
        final fake = RegistroLoggerFake();

        fake.logInfo('Sessão iniciada');
        fake.logAviso('Bateria abaixo de 15%');
        fake.logError(
          'Falha de leitura local',
          error: const FileSystemException('Arquivo ausente'),
          stackTrace: StackTrace.current,
        );
        fake.logCrash(
          'Corrupção de pacote EPUB',
          error: StateError('Hash inválido'),
          stackTrace: StackTrace.current,
          contextosExtras: {
            'receita_robo_caotico': {'passos': 3},
          },
        );
        fake.logFalhaSyncOuDownload(
          'Sem sinal na parede',
          error: const SocketException('Network is unreachable'),
          stackTrace: StackTrace.current,
        );

        expect(fake.infosRegistrados, equals(['Sessão iniciada']));
        expect(fake.avisosRegistrados, hasLength(2));
        expect(fake.avisosRegistrados.first, equals('Bateria abaixo de 15%'));
        expect(fake.avisosRegistrados.last, contains('Sem sinal na parede'));
        expect(fake.breadcrumbsSentry, hasLength(3));
        expect(fake.breadcrumbsSentry.first.level, equals(SentryLevel.info));
        expect(fake.breadcrumbsSentry.last.level, equals(SentryLevel.warning));

        expect(fake.errosRegistrados, hasLength(2));
        expect(fake.crashesRegistrados, hasLength(1));
        expect(
          fake.crashesRegistrados.single.mensagemContexto,
          equals('Corrupção de pacote EPUB'),
        );
        expect(
          fake.crashesRegistrados.single.contextosExtras?['receita_robo_caotico'],
          equals({'passos': 3}),
        );

        fake.limpar();
        expect(fake.infosRegistrados, isEmpty);
        expect(fake.avisosRegistrados, isEmpty);
        expect(fake.errosRegistrados, isEmpty);
        expect(fake.breadcrumbsSentry, isEmpty);
      },
    );
  });
}
