import 'dart:convert';

import '../../municipality/domain/municipality_model.dart';
import '../../tramites/domain/procedure_identity.dart';

/// Dónde se ofrece un video.
enum VideoPlace {
  /// Bienvenida: todavía no hay alcaldía elegida.
  welcome('welcome'),

  /// Ayuda y Soporte de una alcaldía.
  help('ayuda');

  const VideoPlace(this.value);

  /// Valor en Remote Config y en la analítica (`origen`).
  final String value;

  static VideoPlace? tryParse(Object? value) {
    for (final place in values) {
      if (place.value == value) return place;
    }
    return null;
  }
}

/// Un video tutorial de YouTube que se ve dentro de la app.
class TutorialVideo {
  const TutorialVideo({
    required this.id,
    required this.title,
    required this.youtubeId,
    required this.places,
    this.requires = const {},
  });

  /// Clave estable para la analítica (`video`), p. ej. `pagos`.
  final String id;
  final String title;

  /// Id del video en YouTube (lo que va después de `watch?v=`).
  final String youtubeId;
  final Set<VideoPlace> places;

  /// Si no está vacío, el video solo sale en alcaldías que tengan activo
  /// algún trámite de estos tipos. En Welcome no hay alcaldía, así que un
  /// video con requisitos nunca sale ahí.
  final Set<ProcedureKind> requires;

  bool isAvailable(VideoPlace place, {MunicipalityModel? municipality}) {
    if (!places.contains(place)) return false;
    if (requires.isEmpty) return true;
    if (municipality == null) return false;
    return [
      ...municipality.tramitesPrincipales,
      ...municipality.otrosTramites,
    ].any((t) => t.isActive && requires.contains(t.kind));
  }

  /// Lee una entrada de Remote Config; `null` si le falta algo.
  static TutorialVideo? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = _text(json['id']);
    final title = _text(json['title']);
    final youtubeId = _text(json['youtubeId']);
    final places = {
      for (final p in _list(json['places'])) ?VideoPlace.tryParse(p),
    };
    if (id == null || title == null || youtubeId == null || places.isEmpty) {
      return null;
    }
    return TutorialVideo(
      id: id,
      title: title,
      youtubeId: youtubeId,
      places: places,
      requires: {
        for (final k in _list(json['requires']))
          ?ProcedureKind.tryParse(k is String ? k : null),
      },
    );
  }

  static String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  static List<Object?> _list(Object? value) => value is List ? value : const [];
}

/// Videos tutoriales (Remote Config `tutorial_videos`): un interruptor y la
/// lista. Si la key no existe se usan [defaults]; si viene la lista, la
/// reemplaza completa (así se pueden quitar o agregar videos sin versión).
///
/// ```json
/// {
///   "enabled": true,
///   "videos": [
///     { "id": "pagos", "title": "…", "youtubeId": "8K_o2pC19qY",
///       "places": ["welcome", "ayuda"] },
///     { "id": "tramites", "title": "…", "youtubeId": "YQQfugIjP6U",
///       "places": ["ayuda"], "requires": ["COURSES", "VENUES"] }
///   ]
/// }
/// ```
///
/// `requires` usa los tipos de trámite del API (`ProcedureKind.apiValue`).
class TutorialVideosConfig {
  const TutorialVideosConfig({this.enabled = true, this.videos = defaults});

  /// Sin Remote Config (pruebas, o Firebase sin inicializar): apagado.
  static const unavailable = TutorialVideosConfig(enabled: false, videos: []);

  /// Videos del canal de 1cero1 (lista «Tutoriales TramiApp», 2026-01-13).
  /// Están grabados con la app Kotlin; los pasos coinciden con esta. El de
  /// pagos es la versión narrada (2026-10-22); el original sin voz era
  /// `S8lCwQrrcZo`.
  static const defaults = [
    TutorialVideo(
      id: 'pagos',
      title: 'Cómo pagar tus impuestos',
      youtubeId: '8K_o2pC19qY',
      places: {VideoPlace.welcome, VideoPlace.help},
    ),
    // Cursos y reserva de espacios. Al final muestra la PQRSDF anónima, pero
    // no la identificada: no se ofrece solo por tener PQRSDF.
    TutorialVideo(
      id: 'tramites',
      title: 'Cursos y reserva de espacios',
      youtubeId: 'YQQfugIjP6U',
      places: {VideoPlace.help},
      requires: {ProcedureKind.courses, ProcedureKind.venues},
    ),
  ];

  final bool enabled;
  final List<TutorialVideo> videos;

  /// Un JSON roto no los apaga: se queda con los de la app.
  factory TutorialVideosConfig.fromJsonString(String raw) {
    if (raw.trim().isEmpty) return const TutorialVideosConfig();
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return const TutorialVideosConfig();
      final list = json['videos'];
      return TutorialVideosConfig(
        enabled: json['enabled'] is bool ? json['enabled'] as bool : true,
        videos: list is List
            ? [for (final v in list) ?TutorialVideo.fromJson(v)]
            : defaults,
      );
    } catch (_) {
      return const TutorialVideosConfig();
    }
  }

  /// Videos para [place], en el orden de la configuración.
  List<TutorialVideo> videosFor(
    VideoPlace place, {
    MunicipalityModel? municipality,
  }) {
    if (!enabled) return const [];
    return [
      for (final v in videos)
        if (v.isAvailable(place, municipality: municipality)) v,
    ];
  }
}
