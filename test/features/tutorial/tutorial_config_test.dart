import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/features/tramites/domain/info_tramite.dart';
import 'package:tramiapp_flutter/features/tramites/domain/procedure_identity.dart';
import 'package:tramiapp_flutter/features/tutorial/domain/tutorial_config.dart';
import 'package:tramiapp_flutter/features/tutorial/domain/tutorial_content.dart';
import 'package:tramiapp_flutter/features/tutorial/presentation/tutorial_palette.dart';

TutorialContent _content({List<InfoTramite> tramites = const []}) =>
    TutorialContent(
      alcaldia: 'Alcaldía de Rionegro',
      shieldUrl: '',
      primary: const Color(0xFF005B8C),
      cards: TutorialCard.values,
      tramites: tramites,
    );

const _pqrsdf = InfoTramite(
  nombre: 'PQRSDF',
  icono: 'assets/images/icopqrsdf.svg',
  color: Colors.white,
  accion: ShowPqrds(),
  idtramite: 4,
  isActive: true,
  category: TramiteCategory.other,
  key: 'PQRSDF',
  kind: ProcedureKind.pqrsdf,
);

void main() {
  group('TutorialConfig', () {
    test('sin JSON: encendido y con los textos de la app', () {
      final config = TutorialConfig.fromJsonString('');
      expect(config.enabled, isTrue);
      expect(
        config.copyFor(TutorialCard.welcome, _content()).title,
        'Bienvenido a la app de la Alcaldía de Rionegro',
      );
    });

    test('el interruptor apaga el tutorial', () {
      expect(
        TutorialConfig.fromJsonString('{"enabled":false}').enabled,
        isFalse,
      );
    });

    test('un JSON roto no lo apaga', () {
      final config = TutorialConfig.fromJsonString('{no es json');
      expect(config.enabled, isTrue);
      expect(config.copy, isEmpty);
    });

    test('los textos remotos se fusionan campo a campo', () {
      final config = TutorialConfig.fromJsonString('''
        {"cards": {
          "2A": {"title": "Paga sin filas"},
          "1": {"title": "Hola, {alcaldia}", "body": "  "},
          "99": {"title": "no existe"}
        }}''');
      final c = _content();
      expect(
        config.copyFor(TutorialCard.taxesInApp, c).title,
        'Paga sin filas',
      );
      expect(
        config.copyFor(TutorialCard.taxesInApp, c).body,
        TutorialConfig.defaultCopy['2A']!.body,
      );
      // Vacío = el de la app.
      expect(
        config.copyFor(TutorialCard.welcome, c).title,
        'Hola, Alcaldía de Rionegro',
      );
      expect(
        config.copyFor(TutorialCard.welcome, c).body,
        TutorialConfig.defaultCopy['1']!.body,
      );
      expect(config.copy.containsKey('99'), isFalse);
    });

    test('la tarjeta 4 nombra las PQRSDF solo si la alcaldía las tiene', () {
      const config = TutorialConfig();
      expect(
        config.copyFor(TutorialCard.tramites, _content()).body,
        isNot(contains('PQRSDF')),
      );
      expect(
        config
            .copyFor(TutorialCard.tramites, _content(tramites: [_pqrsdf]))
            .body,
        contains('PQRSDF'),
      );
    });

    test('hay texto por defecto para cada tarjeta', () {
      for (final card in TutorialCard.values) {
        expect(TutorialConfig.defaultCopy[card.id], isNotNull, reason: card.id);
      }
    });
  });

  group('TutorialPalette', () {
    test('un primario que pasa AA se usa tal cual', () {
      const blue = Color(0xFF005B8C);
      expect(TutorialPalette.accessiblePrimary(blue), blue);
      expect(TutorialPalette.contrastOnWhite(blue), greaterThan(7));
      expect(
        TutorialPalette.contrastOnWhite(const Color(0xFF2E7D32)),
        greaterThan(5),
      );
    });

    test('un primario claro se oscurece hasta pasar AA', () {
      const yellow = Color(0xFFFFD600);
      expect(TutorialPalette.contrastOnWhite(yellow), lessThan(4.5));
      final fixed = TutorialPalette.accessiblePrimary(yellow);
      expect(TutorialPalette.contrastOnWhite(fixed), greaterThanOrEqualTo(4.5));
      // Conserva el tono.
      expect(
        HSLColor.fromColor(fixed).hue,
        closeTo(HSLColor.fromColor(yellow).hue, 1),
      );
    });

    test('los tintes salen de mezclar el primario con blanco', () {
      final p = TutorialPalette.from(const Color(0xFF005B8C));
      expect(p.tint10, Color.lerp(Colors.white, p.primary, .1));
      expect(p.tint20, Color.lerp(Colors.white, p.primary, .2));
    });
  });
}
