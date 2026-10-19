import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/analytics/analytics_service.dart';
import 'package:tramiapp_flutter/features/tramites/domain/info_tramite.dart';

/// Captura los eventos en vez de mandarlos a Firebase.
class _RecordingAnalytics extends AnalyticsService {
  _RecordingAnalytics() : super(() => throw StateError('sin Firebase'));

  final events = <(String, Map<String, Object>?)>[];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add((name, parameters));
  }
}

InfoTramite _tramite(TramiteAccion accion, {bool isActive = true}) =>
    InfoTramite(
      nombre: 'Impuesto predial',
      icono: '',
      color: Colors.blue,
      accion: accion,
      idtramite: 42,
      isActive: isActive,
      category: TramiteCategory.main,
      key: 'PREDIAL',
    );

void main() {
  group('municipalitySlug (misma regla que formatTopicName de Kotlin)', () {
    test('quita acentos y cambia espacios por guion bajo', () {
      expect(municipalitySlug('Medellín'), 'Medellin');
      expect(municipalitySlug('El Carmen de Viboral'), 'El_Carmen_de_Viboral');
      expect(municipalitySlug('Nariño'), 'Narino');
      expect(municipalitySlug('  Santa Fé de Antioquia '), 'Santa_Fe_de_Antioquia');
    });

    test('elimina caracteres no permitidos en tópicos FCM', () {
      expect(municipalitySlug('San José (Caldas)'), 'San_Jose_Caldas');
    });
  });

  group('logTramiteClick', () {
    late _RecordingAnalytics analytics;
    setUp(() => analytics = _RecordingAnalytics());

    test('URL: conserva el nombre clic_url_directa y manda solo el dominio',
        () async {
      await analytics.logTramiteClick(
        _tramite(
          const AbrirUrl('https://portal.medellin.gov.co/pagos?cedula=123'),
        ),
        municipalityId: 7,
      );

      final (name, params) = analytics.events.single;
      expect(name, 'clic_url_directa');
      expect(params, {
        'municipio_id': 7,
        'tramite_codigo': 'PREDIAL',
        'tramite_id': 42,
        'tramite_nombre': 'Impuesto predial',
        'url_dominio': 'portal.medellin.gov.co',
        'requiere_datos': 'si',
      });
    });

    test('URL sin esquema también resuelve el dominio', () async {
      await analytics.logTramiteClick(
        _tramite(const AbrirUrlDirecto('www.ejemplo.gov.co/ruta')),
        municipalityId: 1,
      );
      expect(analytics.events.single.$2!['url_dominio'], 'www.ejemplo.gov.co');
      expect(analytics.events.single.$2!['requiere_datos'], 'no');
    });

    test('trámite inactivo se cuenta aparte', () async {
      await analytics.logTramiteClick(
        _tramite(const ShowPqrds(), isActive: false),
        municipalityId: 1,
      );
      expect(analytics.events.single.$1, 'clic_tramite_inactivo');
    });

    test('nombre largo se corta a 100 caracteres (límite de GA4)', () async {
      await analytics.logTramiteClick(
        _tramite(const ShowPqrds()).copyWith(nombre: 'x' * 150),
        municipalityId: 1,
      );
      final nombre = analytics.events.single.$2!['tramite_nombre'] as String;
      expect(nombre.length, 100);
    });
  });

  test('sin Firebase inicializado no lanza', () async {
    final service = AnalyticsService(() => FirebaseAnalytics.instance);
    await service.logEvent('prueba');
    await service.setMunicipality(id: 1, name: 'Medellín');
  });
}
