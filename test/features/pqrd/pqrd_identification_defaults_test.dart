import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/models/actividad_economica_pqrd.dart';
import 'package:tramiapp_flutter/core/models/asunto_interes.dart';
import 'package:tramiapp_flutter/core/models/atencion_preferencial.dart';
import 'package:tramiapp_flutter/core/models/bank_dto.dart';
import 'package:tramiapp_flutter/core/models/ciudad.dart';
import 'package:tramiapp_flutter/core/models/clasificacion_solicitud.dart';
import 'package:tramiapp_flutter/core/models/department.dart';
import 'package:tramiapp_flutter/core/models/departamento.dart';
import 'package:tramiapp_flutter/core/models/discapacidad_pqrd.dart';
import 'package:tramiapp_flutter/core/models/escolaridad_pqrd.dart';
import 'package:tramiapp_flutter/core/models/genero_pqrd.dart';
import 'package:tramiapp_flutter/core/models/grupo_etnico_pqrd.dart';
import 'package:tramiapp_flutter/core/models/grupo_interes_pqrd.dart';
import 'package:tramiapp_flutter/core/models/medio_respuesta.dart';
import 'package:tramiapp_flutter/core/models/municipality_dto.dart';
import 'package:tramiapp_flutter/core/models/nivel_estrato_pqrd.dart';
import 'package:tramiapp_flutter/core/models/nivel_sisben_pqrd.dart';
import 'package:tramiapp_flutter/core/models/pqrd_identificacion_post.dart';
import 'package:tramiapp_flutter/core/models/rango_edad_pqrd.dart';
import 'package:tramiapp_flutter/core/models/response_pqrd.dart';
import 'package:tramiapp_flutter/core/models/secretaria.dart';
import 'package:tramiapp_flutter/core/models/shield_dto.dart';
import 'package:tramiapp_flutter/core/models/theme.dart' as model_theme;
import 'package:tramiapp_flutter/core/models/tipo_documento.dart';
import 'package:tramiapp_flutter/core/models/tipo_solicitante.dart';
import 'package:tramiapp_flutter/core/models/vulnerabilidad_pqrd.dart';
import 'package:tramiapp_flutter/core/municipality/municipality_repository.dart';
import 'package:tramiapp_flutter/features/pqrd/application/pqrd_notifier.dart';
import 'package:tramiapp_flutter/features/pqrd/data/pqrd_repository.dart';
import 'package:tramiapp_flutter/features/pqrd/domain/pqrd_state.dart';
import 'package:tramiapp_flutter/features/pqrd/presentation/pqrd_identificacion_screen.dart';

/// Preselección de la PQRSDF con identificación. Los catálogos imitan los
/// reales (Girardot, 2026-10-14): primera opción de cada lista incluida.

Secretaria _secretaria(int id, String name) => Secretaria(
  idSecretaria: id,
  direccion: '',
  email: '',
  estado: true,
  horario: '',
  secretaria: name,
  telefono: '',
);

final _antioquia = Departamento(id: '1', nombreDepartamento: 'ANTIOQUIA');
final _cundinamarca = Departamento(id: '14', nombreDepartamento: 'CUNDINAMARCA');
final _bogotaDep = Departamento(id: '3', nombreDepartamento: 'BOGOTA');

final _ciudades = <String, List<Ciudad>>{
  '1': [Ciudad(id: '5001', nombreCiudad: 'MEDELLIN')],
  '14': [
    Ciudad(id: '25001', nombreCiudad: 'AGUA DE DIOS'),
    Ciudad(id: '25307', nombreCiudad: 'GIRARDOT'),
  ],
  '3': [Ciudad(id: '11001', nombreCiudad: 'BOGOTA, D.C.')],
};

PqrdDropdownOptionsState _catalogs() => PqrdDropdownOptionsState(
  secretarias: [
    _secretaria(1, 'Secretaria de Planeacion'),
    _secretaria(2, 'Secretaría de Salud'),
  ],
  asuntosInteres: [
    AsuntoInteres(id: 1, descripcion: 'Queja'),
    AsuntoInteres(id: 2, descripcion: 'Reclamo'),
  ],
  clasificacionesSolicitud: [
    ClasificacionSolicitud(id: 1, descripcion: 'De interés general'),
  ],
  tiposSolicitante: [TipoSolicitante(id: 1, descripcion: 'Persona natural')],
  atencionesPreferenciales: [
    AtencionPreferencial(id: 1, descripcion: 'NO'),
    AtencionPreferencial(id: 2, descripcion: 'Adolescente'),
  ],
  mediosRespuesta: [MedioRespuesta(id: 1, descripcion: 'Correo electrónico')],
  tiposDocumento: [
    TipoDocumento(id: 1, descripcion: 'Cédula de Ciudadanía'),
    TipoDocumento(id: 2, descripcion: 'Cédula de Extranjería'),
  ],
  gruposInteres: [
    GrupoInteresPQRD(id: 1, descripcion: 'NO'),
    GrupoInteresPQRD(id: 2, descripcion: 'Sindicato del sector público'),
  ],
  // La opción neutra no siempre es la primera: se busca por texto.
  discapacidades: [
    DiscapacidadPQRD(id: 2, descripcion: 'Discapacidad física'),
    DiscapacidadPQRD(id: 1, descripcion: 'No'),
  ],
  gruposEtnicos: [GrupoEtnicoPQRD(id: 1, descripcion: 'NO')],
  generos: [GeneroPQRD(id: 1, descripcion: 'Masculino')],
  rangosEdad: [
    RangoEdadPQRD(id: 1, descripcion: 'Primera Infancia (0-5 años)'),
  ],
  actividadesEconomicas: [
    ActividadEconomicaPQRD(id: 1, descripcion: 'Ama de casa'),
  ],
  nivelesEstrato: [NivelEstratoPQRD(id: 1, descripcion: '0')],
  nivelesSisben: [
    NivelSisbenPQRD(id: 1, descripcion: 'No Tiene'),
    NivelSisbenPQRD(id: 2, descripcion: 'Nivel 1'),
  ],
  escolaridades: [EscolaridadPQRD(id: 1, descripcion: 'Primaria')],
  vulnerabilidades: [
    VulnerabilidadPQRD(id: 1, descripcion: 'Cabeza de familia'),
  ],
  departamentos: [_antioquia, _bogotaDep, _cundinamarca],
  isLoading: false,
);

/// Catálogos ya cargados; `loadCiudades` responde con [_ciudades].
class _FakeOptions extends PqrdDropdownOptionsNotifier {
  @override
  PqrdDropdownOptionsState build() => _catalogs();

  @override
  Future<void> loadCatalogData(String codigoEntidad) async {}

  @override
  Future<void> loadCiudades(String departamentoId) async {
    state = state.copyWith(ciudades: _ciudades[departamentoId] ?? const []);
  }
}

/// Captura lo que se radicaría, sin red.
class _FakeRepo implements PqrdRepository {
  PqrdIdentificacionPost? sent;

  @override
  Future<ResponsePQRD> insertPQRDIdentificacion(
    PqrdIdentificacionPost body,
  ) async {
    sent = body;
    return ResponsePQRD(estado: true, ticket: 'T-1');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _container({_FakeRepo? repo}) {
  final container = ProviderContainer(
    overrides: [
      pqrdDropdownOptionsProvider.overrideWith(_FakeOptions.new),
      if (repo != null) pqrdRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<PqrdFormState> _apply(
  ProviderContainer c, {
  String department = 'Cundinamarca',
  String city = 'Girardot',
}) async {
  await c
      .read(pqrdFormStateProvider.notifier)
      .applyIdentificationDefaults(
        c.read(pqrdDropdownOptionsProvider),
        departmentName: department,
        cityName: city,
      );
  return c.read(pqrdFormStateProvider);
}

void main() {
  test('paso 1: primera opción de todo, menos la Secretaría', () async {
    final form = await _apply(_container());

    expect(form.secretaria, isNull);
    expect(form.asuntoInteres?.descripcion, 'Queja');
    expect(form.clasificacionSolicitud?.descripcion, 'De interés general');
    expect(form.tipoSolicitante?.descripcion, 'Persona natural');
    expect(form.atencionPreferencial?.descripcion, 'NO');
    expect(form.medioRespuesta?.descripcion, 'Correo electrónico');
  });

  test('paso 2: tipo de documento y solo los opcionales neutros', () async {
    final form = await _apply(_container());

    expect(form.tipoDocumento?.descripcion, 'Cédula de Ciudadanía');
    expect(form.grupoInteres?.descripcion, 'NO');
    expect(form.discapacidad?.descripcion, 'No');
    expect(form.grupoEtnico?.descripcion, 'NO');
    expect(form.nivelSisben?.descripcion, 'No Tiene');
    // Su primera opción es un dato real del ciudadano: no se inventa.
    expect(form.genero, isNull);
    expect(form.rangoEdad, isNull);
    expect(form.actividadEconomica, isNull);
    expect(form.nivelEstrato, isNull);
    expect(form.escolaridad, isNull);
    expect(form.vulnerabilidad, isNull);
  });

  test('paso 3: departamento y ciudad del municipio, no Antioquia/Medellín',
      () async {
    final form = await _apply(_container());

    expect(form.departamento, same(_cundinamarca));
    expect(form.ciudad?.nombreCiudad, 'GIRARDOT');
  });

  test('paso 3: ignora tildes, mayúsculas y puntuación (Bogotá D.C.)',
      () async {
    final form = await _apply(
      _container(),
      department: 'Bogotá',
      city: 'Bogotá D.C.',
    );

    expect(form.departamento, same(_bogotaDep));
    expect(form.ciudad?.nombreCiudad, 'BOGOTA, D.C.');
  });

  test('paso 3: si el municipio no está en el catálogo, queda vacío', () async {
    final form = await _apply(
      _container(),
      department: 'Departamento inexistente',
      city: 'Girardot',
    );

    expect(form.departamento, isNull);
    expect(form.ciudad, isNull);
  });

  test('no pisa lo que el usuario ya eligió', () async {
    final c = _container();
    final catalogs = c.read(pqrdDropdownOptionsProvider);
    c.read(pqrdFormStateProvider.notifier).updateField(
      (s) => s.copyWith(
        asuntoInteres: catalogs.asuntosInteres[1],
        atencionPreferencial: catalogs.atencionesPreferenciales[1],
        departamento: _antioquia,
      ),
    );

    final form = await _apply(c);

    expect(form.asuntoInteres?.descripcion, 'Reclamo');
    expect(form.atencionPreferencial?.descripcion, 'Adolescente');
    expect(form.departamento, same(_antioquia));
    expect(form.ciudad, isNull, reason: 'no se toca la ubicación elegida');
  });

  test('cambiar de departamento borra la ciudad (clearCiudad)', () async {
    final c = _container();
    await _apply(c);
    expect(c.read(pqrdFormStateProvider).ciudad, isNotNull);

    c.read(pqrdFormStateProvider.notifier).updateField(
      (s) => s.copyWith(departamento: _antioquia, clearCiudad: true),
    );

    expect(c.read(pqrdFormStateProvider).ciudad, isNull);
  });

  test('"Quitar archivo" borra el adjunto (clearArchivo)', () {
    final c = _container();
    final notifier = c.read(pqrdFormStateProvider.notifier);
    notifier.updateField(
      (s) => s.copyWith(
        nombreArchivo: 'soporte.pdf',
        tipoArchivo: 'pdf',
        contenidoArchivoBase64: 'JVBERi0=',
      ),
    );

    notifier.updateField((s) => s.copyWith(clearArchivo: true));

    final form = c.read(pqrdFormStateProvider);
    expect(form.nombreArchivo, isNull);
    expect(form.tipoArchivo, isNull);
    expect(form.contenidoArchivoBase64, isNull);
  });

  group('AtencionEspecial al radicar', () {
    Future<bool?> radicarCon(String atencion) async {
      final repo = _FakeRepo();
      final c = _container(repo: repo);
      await _apply(c);
      final option = c
          .read(pqrdDropdownOptionsProvider)
          .atencionesPreferenciales
          .firstWhere((o) => o.descripcion == atencion);
      final notifier = c.read(pqrdFormStateProvider.notifier);
      notifier.updateField((s) => s.copyWith(atencionPreferencial: option));
      await notifier.submitIdentificada('8906803784');
      return repo.sent?.atencionEspecial;
    }

    test('con "NO" (la preselección) va en false', () async {
      expect(await radicarCon('NO'), isFalse);
    });

    test('con una atención real va en true', () async {
      expect(await radicarCon('Adolescente'), isTrue);
    });

    test('sin elegir va en false', () {
      expect(PqrdFormStateNotifier.requiresSpecialAttention(null), isFalse);
      expect(
        PqrdFormStateNotifier.requiresSpecialAttention(
          AtencionPreferencial(id: 9, descripcion: ' No '),
        ),
        isFalse,
      );
    });
  });

  testWidgets('la pantalla muestra los valores preseleccionados', (
    tester,
  ) async {
    final mun = MunicipalityDTO(
      id: 1,
      name: 'Girardot',
      entityCode: '8906803784',
      domain: '',
      isActive: true,
      department: Department(id: 2, name: 'Cundinamarca'),
      bank: BankDTO(nameBank: 'Banco'),
      idShield: ShieldDTO(municipalityName: 'Girardot', url: ''),
      theme: model_theme.Theme(
        primaryColor: '0xFF181E31',
        secondaryColor: '0xFF4364CD',
        secondaryColorBlack: '0xFFFFFFFF',
        onPrimaryColorLight: '0xFF000000',
        onPrimaryColorDark: '0xFFFFFFFF',
        backGroundColor: '0xFFF3F4F6',
      ),
      municipalityProcedures: const [],
      municipalitySocialMedia: const [],
      courses: const [],
      sportsFacilities: const [],
      newsByMunicipalities: const [],
      queryFields: const [],
      passwordFintech: '',
      userFintech: '',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          municipalityProvider(1).overrideWith((ref) async => mun),
          pqrdDropdownOptionsProvider.overrideWith(_FakeOptions.new),
        ],
        child: const MaterialApp(
          home: PqrdIdentificacionScreen(municipalityId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final value in [
      'Queja',
      'De interés general',
      'Persona natural',
      'NO',
      'Correo electrónico',
    ]) {
      expect(find.text(value), findsOneWidget, reason: value);
    }
    expect(find.text('Secretaria de Planeacion'), findsNothing);
  });
}
