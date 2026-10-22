import 'dart:convert';

import 'tutorial_content.dart';

/// Título y texto de una tarjeta.
class TutorialCopy {
  const TutorialCopy(this.title, this.body);

  final String title;
  final String body;
}

/// Configuración del tutorial en Remote Config (key `tutorial_config`): un
/// interruptor y los textos. Lo que no venga, o venga vacío, usa los textos de
/// la app ([TutorialConfig.defaultCopy]).
///
/// ```json
/// {
///   "enabled": true,
///   "cards": {
///     "1": { "title": "Bienvenido a la app de la {alcaldia}", "body": "…" },
///     "4_sin_pqrsdf": { "body": "…" }
///   }
/// }
/// ```
///
/// Claves de `cards`: los ids de [TutorialCard] (`1`, `2A`, … `7`) más
/// `4_sin_pqrsdf`, el texto de la 4 cuando la alcaldía no tiene PQRSDF.
/// `{alcaldia}` se reemplaza por «Alcaldía de {nombre}».
class TutorialConfig {
  const TutorialConfig({this.enabled = true, this.copy = const {}});

  /// Sin Remote Config (pruebas, o Firebase sin inicializar): apagado, para no
  /// tapar la Home con algo que nadie configuró.
  static const unavailable = TutorialConfig(enabled: false);

  /// `false` = no sale al entrar a la Home ni en Ayuda y Soporte.
  final bool enabled;

  /// Textos remotos por clave; ya fusionados campo a campo con los de la app.
  final Map<String, TutorialCopy> copy;

  static const alcaldiaPlaceholder = '{alcaldia}';
  static const tramitesNoPqrsdfKey = '4_sin_pqrsdf';

  /// Textos propuestos en el diseño (Claude Design, 2026-10-22).
  static const defaultCopy = <String, TutorialCopy>{
    '1': TutorialCopy(
      'Bienvenido a la app de la $alcaldiaPlaceholder',
      'Consulta, paga y haz tus trámites con tu alcaldía desde el celular, '
          'sin filas.',
    ),
    '2A': TutorialCopy(
      'Paga tus impuestos en minutos',
      'Consulta tu factura con tu documento, descárgala o compártela y paga '
          'por PSE de forma segura.',
    ),
    '2B': TutorialCopy(
      'Paga en el portal oficial de tu alcaldía',
      'Toca el impuesto y te llevamos al sitio de pagos de la alcaldía para '
          'que pagues de forma segura.',
    ),
    '3A': TutorialCopy(
      'Que no se te pase ningún pago',
      'Toca «Recordarme» en tu factura y te avisamos antes de que venza. '
          'Todos tus avisos están en Mis recordatorios, en el menú.',
    ),
    '3B': TutorialCopy(
      'Que no se te pase ningún pago',
      'En Mis recordatorios, en el menú, crea avisos para tus fechas de pago '
          'y te avisamos a tiempo.',
    ),
    '4': TutorialCopy(
      'Tus trámites, en un solo lugar',
      'Pide certificados, envía tus PQRSDF y más, según lo que ofrezca tu '
          'alcaldía.',
    ),
    tramitesNoPqrsdfKey: TutorialCopy(
      'Tus trámites, en un solo lugar',
      'Pide certificados y haz otros trámites, según lo que ofrezca tu '
          'alcaldía.',
    ),
    // La 5 no tiene texto: la guía de letras es el contenido.
    '5': TutorialCopy('¿Una petición, queja o reclamo?', ''),
    '6A': TutorialCopy(
      'Sigue tus pagos',
      'En Historial ves el estado de cada pago. Cuando uno quede aprobado, '
          'toca «Recordarme el próximo pago».',
    ),
    '6B': TutorialCopy(
      'Sigue tus pagos',
      'En Historial ves el estado de los pagos que haces en la app.',
    ),
    '7': TutorialCopy(
      'Crea tu cuenta',
      'Guarda tus recordatorios y tu historial de pagos. Entra con Google o '
          'con tu correo.',
    ),
  };

  /// Lee el JSON de Remote Config. Un JSON roto no apaga el tutorial: se
  /// queda con lo de la app.
  factory TutorialConfig.fromJsonString(String raw) {
    if (raw.trim().isEmpty) return const TutorialConfig();
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return const TutorialConfig();
      final cards = json['cards'];
      final copy = <String, TutorialCopy>{};
      if (cards is Map<String, dynamic>) {
        for (final MapEntry(:key, :value) in cards.entries) {
          final base = defaultCopy[key];
          if (base == null || value is! Map<String, dynamic>) continue;
          copy[key] = TutorialCopy(
            _text(value['title']) ?? base.title,
            _text(value['body']) ?? base.body,
          );
        }
      }
      return TutorialConfig(
        enabled: json['enabled'] is bool ? json['enabled'] as bool : true,
        copy: copy,
      );
    } catch (_) {
      return const TutorialConfig();
    }
  }

  static String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  /// Textos de [card] para esta alcaldía.
  TutorialCopy copyFor(TutorialCard card, TutorialContent content) {
    final key = card == TutorialCard.tramites && !content.tramitesIncludePqrsdf
        ? tramitesNoPqrsdfKey
        : card.id;
    final c = copy[key] ?? defaultCopy[key]!;
    return TutorialCopy(
      c.title.replaceAll(alcaldiaPlaceholder, content.alcaldia),
      c.body.replaceAll(alcaldiaPlaceholder, content.alcaldia),
    );
  }
}
