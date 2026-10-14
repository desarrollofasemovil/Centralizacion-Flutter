import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/services/api_providers.dart';
import '../../../core/models/user_dto.dart';
import '../../../core/models/pqrd_anonima_post.dart';
import '../../../core/models/pqrd_identificacion_post.dart';
import '../../../core/models/response_pqrd.dart';
import '../../../core/models/ciudadano.dart';
import '../../../core/models/documentos.dart';
import '../../../core/models/tipo_documento.dart';
import '../../../core/models/secretaria.dart';
import '../../../core/models/asunto_interes.dart';
import '../../../core/models/clasificacion_solicitud.dart';
import '../../../core/models/tipo_solicitante.dart';
import '../../../core/models/atencion_preferencial.dart';
import '../../../core/models/medio_respuesta.dart';
import '../../../core/models/grupo_interes_pqrd.dart';
import '../../../core/models/discapacidad_pqrd.dart';
import '../../../core/models/grupo_etnico_pqrd.dart';
import '../../../core/models/genero_pqrd.dart';
import '../../../core/models/rango_edad_pqrd.dart';
import '../../../core/models/actividad_economica_pqrd.dart';
import '../../../core/models/nivel_estrato_pqrd.dart';
import '../../../core/models/nivel_sisben_pqrd.dart';
import '../../../core/models/escolaridad_pqrd.dart';
import '../../../core/models/vulnerabilidad_pqrd.dart';
import '../../../core/models/departamento.dart';
import '../../auth/application/auth_providers.dart';
import '../data/pqrd_repository.dart';
import '../domain/pqrd_state.dart';

final pqrdRepositoryProvider = Provider<PqrdRepository>((ref) {
  return PqrdRepository(
    ref.watch(pqrdApiServiceProvider),
    ref.watch(generalesApiServiceProvider),
  );
});

class PqrdDropdownOptionsNotifier extends Notifier<PqrdDropdownOptionsState> {
  @override
  PqrdDropdownOptionsState build() {
    return const PqrdDropdownOptionsState();
  }

  PqrdRepository get _repository => ref.read(pqrdRepositoryProvider);

  /// Dedup: evita relanzar el lote completo cuando el flujo entra dos veces
  /// (la pantalla de elección y el wizard llamaban ambos a `loadCatalogData`,
  /// disparando el lote de 18 GET por duplicado — visto en logs de red).
  bool _catalogInFlight = false;
  String? _loadedEntityCode;

  /// Ejecuta [future] y, si falla (error de red o de parseo del DTO), devuelve
  /// una lista vacía en vez de propagar. Replica el try/catch por-endpoint del
  /// `PqrdRepositoryImpl` de Kotlin: así un único catálogo defectuoso no vacía
  /// TODOS los selects. Antes un `Future.wait` sin protección tumbaba el lote
  /// entero cuando un solo endpoint (p. ej. Departamentos, que envía `Id`
  /// numérico) lanzaba al deserializar.
  Future<List<T>> _safe<T>(String tag, Future<List<T>> future) async {
    try {
      return await future;
    } catch (e) {
      debugPrint('PQRD_CATALOG: "$tag" falló -> $e');
      return <T>[];
    }
  }

  Future<void> loadCatalogData(String codigoEntidad) async {
    if (_catalogInFlight) return;
    if (_loadedEntityCode == codigoEntidad && !state.isLoading) return;
    _catalogInFlight = true;
    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        _safe('secretarias', _repository.listSecretariaEntidad(codigoEntidad)),
        _safe('asuntosInteres', _repository.listAsuntoInteres(codigoEntidad)),
        _safe(
          'clasificaciones',
          _repository.listClasificacionSolicitud(codigoEntidad),
        ),
        _safe(
          'tiposSolicitante',
          _repository.listTipoSolicitante(codigoEntidad),
        ),
        _safe(
          'atencionesPreferenciales',
          _repository.listAtencionPreferencial(codigoEntidad),
        ),
        _safe('mediosRespuesta', _repository.listMedioRespuesta(codigoEntidad)),
        _safe('tiposDocumento', _repository.listTipoDocumento(codigoEntidad)),
        _safe(
          'gruposInteres',
          _repository.getListGrupoInteresPQRD(codigoEntidad),
        ),
        _safe(
          'discapacidades',
          _repository.listDiscapacidadPQRD(codigoEntidad),
        ),
        _safe(
          'gruposEtnicos',
          _repository.getListGrupoEtnicoPQRD(codigoEntidad),
        ),
        _safe('generos', _repository.listGeneroPQRD(codigoEntidad)),
        _safe('rangosEdad', _repository.listRangoEdadPQRD(codigoEntidad)),
        _safe(
          'actividadesEconomicas',
          _repository.listActividadEconomicaPQRD(codigoEntidad),
        ),
        _safe(
          'nivelesEstrato',
          _repository.listNivelEstratoPQRD(codigoEntidad),
        ),
        _safe('nivelesSisben', _repository.listNivelSisbenPQRD(codigoEntidad)),
        _safe('escolaridades', _repository.listEscolaridadPQRD(codigoEntidad)),
        _safe(
          'vulnerabilidades',
          _repository.listVulnerabilidadPQRD(codigoEntidad),
        ),
        _safe('departamentos', _repository.getDepartamentos()),
      ]);

      state = PqrdDropdownOptionsState(
        secretarias: (results[0] as List).cast<Secretaria>(),
        asuntosInteres: (results[1] as List).cast<AsuntoInteres>(),
        clasificacionesSolicitud: (results[2] as List)
            .cast<ClasificacionSolicitud>(),
        tiposSolicitante: (results[3] as List).cast<TipoSolicitante>(),
        atencionesPreferenciales: (results[4] as List)
            .cast<AtencionPreferencial>(),
        mediosRespuesta: (results[5] as List).cast<MedioRespuesta>(),
        tiposDocumento: (results[6] as List).cast<TipoDocumento>(),
        gruposInteres: (results[7] as List).cast<GrupoInteresPQRD>(),
        discapacidades: (results[8] as List).cast<DiscapacidadPQRD>(),
        gruposEtnicos: (results[9] as List).cast<GrupoEtnicoPQRD>(),
        generos: (results[10] as List).cast<GeneroPQRD>(),
        rangosEdad: (results[11] as List).cast<RangoEdadPQRD>(),
        actividadesEconomicas: (results[12] as List)
            .cast<ActividadEconomicaPQRD>(),
        nivelesEstrato: (results[13] as List).cast<NivelEstratoPQRD>(),
        nivelesSisben: (results[14] as List).cast<NivelSisbenPQRD>(),
        escolaridades: (results[15] as List).cast<EscolaridadPQRD>(),
        vulnerabilidades: (results[16] as List).cast<VulnerabilidadPQRD>(),
        departamentos: (results[17] as List).cast<Departamento>(),
        isLoading: false,
      );

      _loadedEntityCode = codigoEntidad;

      final user = ref.read(sessionProvider);
      if (user != null) {
        ref.read(pqrdFormStateProvider.notifier).autofill(user, state);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    } finally {
      _catalogInFlight = false;
    }
  }

  /// [departamentoId] es el `Departamento.id` (String, p. ej. "5"); el backend
  /// espera `?id_Departamento=`.
  Future<void> loadCiudades(String departamentoId) async {
    state = state.copyWith(isLoadingCiudades: true);
    try {
      final list = await _repository.getCiudadesPorDepartamento(departamentoId);
      state = state.copyWith(ciudades: list, isLoadingCiudades: false);
    } catch (e) {
      state = state.copyWith(isLoadingCiudades: false);
    }
  }
}

final pqrdDropdownOptionsProvider =
    NotifierProvider<PqrdDropdownOptionsNotifier, PqrdDropdownOptionsState>(
      PqrdDropdownOptionsNotifier.new,
    );

class PqrdFormStateNotifier extends Notifier<PqrdFormState> {
  @override
  PqrdFormState build() {
    return const PqrdFormState();
  }

  PqrdRepository get _repository => ref.read(pqrdRepositoryProvider);

  void updateField(PqrdFormState Function(PqrdFormState) updater) {
    state = updater(state);
  }

  void autofill(UserDTO user, PqrdDropdownOptionsState dropdowns) {
    final typeDocs = dropdowns.tiposDocumento;
    TipoDocumento? typeDoc;
    for (final d in typeDocs) {
      if (d.descripcion.toLowerCase() == user.documentType.name.toLowerCase()) {
        typeDoc = d;
        break;
      }
    }
    if (typeDoc == null && typeDocs.isNotEmpty) {
      typeDoc = typeDocs.first;
    }

    state = state.copyWith(
      identificacion: user.nationalId,
      primerNombre: user.firstName,
      segundoNombre: user.middleName ?? '',
      primerApellido: user.lastName,
      segundoApellido: user.secondLastName ?? '',
      correoElectronico: user.email,
      direccion: user.address,
      telefonoCelular: user.phoneNumber,
      tipoDocumento: typeDoc,
    );
  }

  /// Preselección de la PQRSDF con identificación, para no tener que abrir uno
  /// por uno los ~20 selects. Pedido de producto (2026-10-14); el Kotlin no lo
  /// hace. Solo llena campos vacíos: no pisa lo que el usuario ya eligió ni el
  /// autollenado de la sesión ([autofill]).
  ///
  /// - Paso 1: la primera opción de cada lista, **menos la Secretaría**: decide
  ///   a qué dependencia llega la PQRD, así que el usuario la elige a propósito.
  /// - Paso 2: tipo de documento (primera opción) y, de los opcionales, solo los
  ///   que tienen una opción neutra ("NO", "No tiene"…). Género, rango de edad,
  ///   actividad, estrato, escolaridad y vulnerabilidad quedan vacíos: su primera
  ///   opción es un dato real ("Masculino", "Primera Infancia (0-5 años)"…) que
  ///   se radicaría como cierto si el usuario no lo cambia.
  /// - Paso 3: el departamento y la ciudad del municipio de la app
  ///   ([departmentName], [cityName]), buscados por nombre en el catálogo (la
  ///   primera opción sería Antioquia / Medellín para todos).
  Future<void> applyIdentificationDefaults(
    PqrdDropdownOptionsState options, {
    required String departmentName,
    required String cityName,
  }) async {
    T? first<T>(List<T> items) => items.isEmpty ? null : items.first;

    final s = state;
    state = s.copyWith(
      asuntoInteres: s.asuntoInteres ?? first(options.asuntosInteres),
      clasificacionSolicitud:
          s.clasificacionSolicitud ?? first(options.clasificacionesSolicitud),
      tipoSolicitante: s.tipoSolicitante ?? first(options.tiposSolicitante),
      atencionPreferencial:
          s.atencionPreferencial ?? first(options.atencionesPreferenciales),
      medioRespuesta: s.medioRespuesta ?? first(options.mediosRespuesta),
      tipoDocumento: s.tipoDocumento ?? first(options.tiposDocumento),
      grupoInteres:
          s.grupoInteres ??
          _neutralOption(options.gruposInteres, (o) => o.descripcion),
      discapacidad:
          s.discapacidad ??
          _neutralOption(options.discapacidades, (o) => o.descripcion),
      grupoEtnico:
          s.grupoEtnico ??
          _neutralOption(options.gruposEtnicos, (o) => o.descripcion),
      nivelSisben:
          s.nivelSisben ??
          _neutralOption(options.nivelesSisben, (o) => o.descripcion),
    );

    if (state.departamento != null) return;
    final departamento = _matchByName(
      options.departamentos,
      (d) => d.nombreDepartamento,
      departmentName,
    );
    if (departamento == null) return;
    state = state.copyWith(departamento: departamento, clearCiudad: true);

    await ref
        .read(pqrdDropdownOptionsProvider.notifier)
        .loadCiudades(departamento.id);
    // El usuario pudo cambiar de departamento o elegir ciudad mientras cargaba.
    if (!identical(state.departamento, departamento) || state.ciudad != null) {
      return;
    }
    final ciudad = _matchByName(
      ref.read(pqrdDropdownOptionsProvider).ciudades,
      (c) => c.nombreCiudad,
      cityName,
    );
    if (ciudad != null) state = state.copyWith(ciudad: ciudad);
  }

  /// `true` si se eligió una atención preferencial real; `false` sin elegir o
  /// con la opción "NO".
  @visibleForTesting
  static bool requiresSpecialAttention(AtencionPreferencial? option) =>
      option != null && _normalize(option.descripcion) != 'NO';

  static const _neutralLabels = {
    'NO',
    'NINGUNO',
    'NINGUNA',
    'NO TIENE',
    'NO APLICA',
  };

  /// La opción "NO" / "No tiene" de la lista, esté donde esté; `null` si no hay.
  static T? _neutralOption<T>(List<T> items, String Function(T) label) {
    for (final item in items) {
      if (_neutralLabels.contains(_normalize(label(item)))) return item;
    }
    return null;
  }

  /// Busca [name] en [items] sin importar tildes, mayúsculas ni puntuación
  /// ("Bogotá D.C." = "BOGOTA, D.C."). Si no hay coincidencia exacta acepta un
  /// prefijo ("Bogotá" → "BOGOTA, D.C."), pero solo si es único.
  static T? _matchByName<T>(
    List<T> items,
    String Function(T) label,
    String name,
  ) {
    final target = _normalize(name);
    if (target.isEmpty) return null;
    for (final item in items) {
      if (_normalize(label(item)) == target) return item;
    }
    final prefixed = items.where((item) {
      final candidate = _normalize(label(item));
      return candidate.startsWith('$target ') ||
          target.startsWith('$candidate ');
    }).toList();
    return prefixed.length == 1 ? prefixed.single : null;
  }

  static String _normalize(String value) {
    const accents = {
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'Ü': 'U',
      'Ñ': 'N',
    };
    final upper = value.toUpperCase().split('').map((c) => accents[c] ?? c);
    return upper.join().replaceAll(RegExp(r'[^A-Z0-9]+'), ' ').trim();
  }

  Future<ResponsePQRD> submitAnonima(String entityCode) async {
    final docObj = Documentos(
      contentType: state.tipoArchivo ?? '',
      documentos: state.contenidoArchivoBase64 ?? '',
      nombreArchivo: state.nombreArchivo ?? '',
    );
    final body = PqrdAnonimaPost(
      codigoEntidad: entityCode,
      descripcion: state.descripcion,
      documentos: docObj,
      idAsuntoInteres: state.asuntoInteres?.id ?? 0,
      idcLasificacion: state.clasificacionSolicitud?.id ?? 0,
      idSecretaria: state.secretaria?.idSecretaria ?? 0,
    );
    return _repository.insertPQRDAnonima(body);
  }

  Future<ResponsePQRD> submitIdentificada(String entityCode) async {
    final docObj = Documentos(
      contentType: state.tipoArchivo ?? '',
      documentos: state.contenidoArchivoBase64 ?? '',
      nombreArchivo: state.nombreArchivo ?? '',
    );
    final ciudadanoObj = Ciudadano(
      direccion: state.direccion,
      email: state.correoElectronico,
      identificacion: state.identificacion,
      primerApellido: state.primerApellido,
      primerNombre: state.primerNombre,
      segundoApellido: state.segundoApellido,
      segundoNombre: state.segundoNombre,
      telefono: state.telefonoCelular.isNotEmpty
          ? state.telefonoCelular
          : state.telefonoFijo,
      tipoDocumento: state.tipoDocumento?.id ?? 0,
    );
    final body = PqrdIdentificacionPost(
      // Sí/no de atención especial, coherente con la opción elegida: "NO" →
      // false. Antes era `atencionPreferencial != null`, siempre true porque el
      // select es obligatorio (el Kotlin manda siempre false: `// Reemplaza con
      // el valor real`, nunca completado).
      atencionEspecial: requiresSpecialAttention(state.atencionPreferencial),
      ciudad: state.ciudad?.id.toString() ?? '',
      ciudadano: ciudadanoObj,
      codigoEntidad: entityCode,
      departamento: state.departamento?.id.toString() ?? '',
      descripcion: state.descripcion,
      documentos: docObj,
      iDActividadEconomica: state.actividadEconomica?.id ?? 0,
      iDAsunto: state.asuntoInteres?.id ?? 0,
      iDAtencionEspecial: state.atencionPreferencial?.id ?? 0,
      iDAtencionPreferencial: state.atencionPreferencial?.id ?? 0,
      iDClasificacion: state.clasificacionSolicitud?.id ?? 0,
      iDDiscapacidad: state.discapacidad?.id ?? 0,
      iDEscolaridad: state.escolaridad?.id ?? 0,
      iDGenero: state.genero?.id ?? 0,
      iDGrupoEtnico: state.grupoEtnico?.id ?? 0,
      iDGrupoInteres: state.grupoInteres?.id ?? 0,
      iDMedioRespuesta: state.medioRespuesta?.id ?? 0,
      iDNivelExtrato: state.nivelEstrato?.id ?? 0,
      iDNivelSisben: state.nivelSisben?.id ?? 0,
      iDRangoEdad: state.rangoEdad?.id ?? 0,
      iDSecretaria: state.secretaria?.idSecretaria ?? 0,
      iDTipoSolicitante: state.tipoSolicitante?.id ?? 0,
      iDVulnerabilidad: state.vulnerabilidad?.id ?? 0,
      pais: state.pais.isNotEmpty ? state.pais : 'Colombia',
      razonSocial: state.razonSocial,
      recepcion: state.medioRespuesta?.descripcion ?? 'Correo Electronico',
    );
    return _repository.insertPQRDIdentificacion(body);
  }
}

final pqrdFormStateProvider =
    NotifierProvider<PqrdFormStateNotifier, PqrdFormState>(
      PqrdFormStateNotifier.new,
    );
