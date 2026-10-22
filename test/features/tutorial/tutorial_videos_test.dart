import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/theme/design.dart';
import 'package:tramiapp_flutter/features/municipality/domain/municipality_model.dart';
import 'package:tramiapp_flutter/features/tramites/domain/info_tramite.dart';
import 'package:tramiapp_flutter/features/tramites/domain/integration_type_model.dart';
import 'package:tramiapp_flutter/features/tramites/domain/procedure_identity.dart';
import 'package:tramiapp_flutter/features/tutorial/domain/tutorial_videos.dart';

InfoTramite _tramite(ProcedureKind kind, {bool active = true}) => InfoTramite(
  nombre: kind.apiValue,
  icono: 'assets/images/icopredial.svg',
  color: Colors.white,
  accion: const ShowPqrds(),
  idtramite: kind.index,
  isActive: active,
  category: TramiteCategory.other,
  key: kind.apiValue,
  kind: kind,
);

MunicipalityModel _municipality(List<InfoTramite> tramites) =>
    MunicipalityModel(
      idMunicipio: 81,
      codigoEntidad: 'E',
      nombreMunicipio: 'Alcaldía de Rionegro',
      departamento: 'Antioquia',
      design: Design.fromThemeHex(alcaldiaName: 'Rionegro', shieldUrl: ''),
      tipoIntegracion: const TramitesporAPP(
        codigoEntidad: 'E',
        campoConsulta: [],
      ),
      domain: '',
      bank: '',
      privacyPolicyUrl: '',
      dataPolicyUrl: '',
      newsUrl: '',
      otrosTramites: tramites,
    );

List<String> _ids(List<TutorialVideo> videos) => [
  for (final v in videos) v.id,
];

void main() {
  const config = TutorialVideosConfig();

  test('en Bienvenida solo sale el de pagos', () {
    expect(_ids(config.videosFor(VideoPlace.welcome)), ['pagos']);
  });

  test('el de trámites sale en Ayuda solo con cursos o reservas', () {
    final onlyPqrsdf = _municipality([_tramite(ProcedureKind.pqrsdf)]);
    final withCourses = _municipality([_tramite(ProcedureKind.courses)]);
    final withVenues = _municipality([_tramite(ProcedureKind.venues)]);
    final inactiveCourses = _municipality([
      _tramite(ProcedureKind.courses, active: false),
    ]);

    expect(
      _ids(config.videosFor(VideoPlace.help, municipality: onlyPqrsdf)),
      ['pagos'],
    );
    expect(
      _ids(config.videosFor(VideoPlace.help, municipality: withCourses)),
      ['pagos', 'tramites'],
    );
    expect(
      _ids(config.videosFor(VideoPlace.help, municipality: withVenues)),
      ['pagos', 'tramites'],
    );
    expect(
      _ids(config.videosFor(VideoPlace.help, municipality: inactiveCourses)),
      ['pagos'],
    );
    // Mientras carga la alcaldía, los que dependen de ella no salen.
    expect(_ids(config.videosFor(VideoPlace.help)), ['pagos']);
  });

  test('los ids de YouTube por defecto son los de la lista del canal', () {
    expect(
      {for (final v in TutorialVideosConfig.defaults) v.id: v.youtubeId},
      {'pagos': 'S8lCwQrrcZo', 'tramites': 'YQQfugIjP6U'},
    );
  });

  group('Remote Config', () {
    test('sin lista usa los de la app', () {
      final c = TutorialVideosConfig.fromJsonString('{"enabled":true}');
      expect(_ids(c.videos), ['pagos', 'tramites']);
    });

    test('el interruptor los apaga', () {
      final c = TutorialVideosConfig.fromJsonString('{"enabled":false}');
      expect(c.videosFor(VideoPlace.welcome), isEmpty);
    });

    test('un JSON roto no los apaga', () {
      final c = TutorialVideosConfig.fromJsonString('{roto');
      expect(_ids(c.videosFor(VideoPlace.welcome)), ['pagos']);
    });

    test('la lista remota reemplaza la de la app y salta lo incompleto', () {
      final c = TutorialVideosConfig.fromJsonString('''
        {"videos": [
          {"id": "pqrsdf", "title": "Envía una PQRSDF", "youtubeId": "abc",
           "places": ["ayuda"], "requires": ["PQRSDF", "NO_EXISTE"]},
          {"id": "sin_lugar", "title": "x", "youtubeId": "y", "places": []},
          {"id": "sin_video", "title": "x", "places": ["welcome"]}
        ]}''');
      expect(_ids(c.videos), ['pqrsdf']);
      expect(c.videos.single.requires, {ProcedureKind.pqrsdf});
      expect(
        _ids(
          c.videosFor(
            VideoPlace.help,
            municipality: _municipality([_tramite(ProcedureKind.pqrsdf)]),
          ),
        ),
        ['pqrsdf'],
      );
      expect(c.videosFor(VideoPlace.welcome), isEmpty);
    });
  });
}
