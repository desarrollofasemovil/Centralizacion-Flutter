import 'package:tramiapp_flutter/core/analytics/analytics_service.dart';

/// Captura los eventos en vez de mandarlos a Firebase.
class RecordingAnalytics extends AnalyticsService {
  RecordingAnalytics() : super(() => throw StateError('sin Firebase'));

  final events = <(String, Map<String, Object>?)>[];

  /// Nombres de los eventos en el orden en que se registraron.
  List<String> get names => [for (final (name, _) in events) name];

  /// Parámetros del único evento con ese nombre.
  Map<String, Object>? single(String name) =>
      events.where((e) => e.$1 == name).single.$2;

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add((name, parameters));
  }
}
