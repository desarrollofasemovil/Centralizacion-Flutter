import '../../../core/models/secretaria.dart';
import '../../../core/models/asunto_interes.dart';
import '../../../core/models/clasificacion_solicitud.dart';
import '../../../core/models/tipo_solicitante.dart';
import '../../../core/models/atencion_preferencial.dart';
import '../../../core/models/medio_respuesta.dart';
import '../../../core/models/tipo_documento.dart';
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
import '../../../core/models/ciudad.dart';

class PqrdFormState {
  final Secretaria? secretaria;
  final AsuntoInteres? asuntoInteres;
  final ClasificacionSolicitud? clasificacionSolicitud;
  final TipoSolicitante? tipoSolicitante;
  final AtencionPreferencial? atencionPreferencial;
  final MedioRespuesta? medioRespuesta;

  final TipoDocumento? tipoDocumento;
  final String identificacion;
  final String primerNombre;
  final String segundoNombre;
  final String primerApellido;
  final String segundoApellido;
  final GrupoInteresPQRD? grupoInteres;
  final DiscapacidadPQRD? discapacidad;
  final GrupoEtnicoPQRD? grupoEtnico;
  final GeneroPQRD? genero;
  final RangoEdadPQRD? rangoEdad;
  final ActividadEconomicaPQRD? actividadEconomica;
  final NivelEstratoPQRD? nivelEstrato;
  final NivelSisbenPQRD? nivelSisben;
  final EscolaridadPQRD? escolaridad;
  final VulnerabilidadPQRD? vulnerabilidad;

  final String pais;
  final Departamento? departamento;
  final Ciudad? ciudad;
  final String razonSocial;
  final String correoElectronico;
  final String direccion;
  final String telefonoCelular;
  final String telefonoFijo;
  final String descripcion;

  final bool aceptaTratamientoDatos;
  final bool aceptaCondicionesUso;

  final String? nombreArchivo;
  final String? tipoArchivo;
  final String? contenidoArchivoBase64;

  const PqrdFormState({
    this.secretaria,
    this.asuntoInteres,
    this.clasificacionSolicitud,
    this.tipoSolicitante,
    this.atencionPreferencial,
    this.medioRespuesta,
    this.tipoDocumento,
    this.identificacion = '',
    this.primerNombre = '',
    this.segundoNombre = '',
    this.primerApellido = '',
    this.segundoApellido = '',
    this.grupoInteres,
    this.discapacidad,
    this.grupoEtnico,
    this.genero,
    this.rangoEdad,
    this.actividadEconomica,
    this.nivelEstrato,
    this.nivelSisben,
    this.escolaridad,
    this.vulnerabilidad,
    this.pais = 'Colombia',
    this.departamento,
    this.ciudad,
    this.razonSocial = '',
    this.correoElectronico = '',
    this.direccion = '',
    this.telefonoCelular = '',
    this.telefonoFijo = '',
    this.descripcion = '',
    this.aceptaTratamientoDatos = false,
    this.aceptaCondicionesUso = false,
    this.nombreArchivo,
    this.tipoArchivo,
    this.contenidoArchivoBase64,
  });

  PqrdFormState copyWith({
    Secretaria? secretaria,
    AsuntoInteres? asuntoInteres,
    ClasificacionSolicitud? clasificacionSolicitud,
    TipoSolicitante? tipoSolicitante,
    AtencionPreferencial? atencionPreferencial,
    MedioRespuesta? medioRespuesta,
    TipoDocumento? tipoDocumento,
    String? identificacion,
    String? primerNombre,
    String? segundoNombre,
    String? primerApellido,
    String? segundoApellido,
    GrupoInteresPQRD? grupoInteres,
    DiscapacidadPQRD? discapacidad,
    GrupoEtnicoPQRD? grupoEtnico,
    GeneroPQRD? genero,
    RangoEdadPQRD? rangoEdad,
    ActividadEconomicaPQRD? actividadEconomica,
    NivelEstratoPQRD? nivelEstrato,
    NivelSisbenPQRD? nivelSisben,
    EscolaridadPQRD? escolaridad,
    VulnerabilidadPQRD? vulnerabilidad,
    String? pais,
    Departamento? departamento,
    Ciudad? ciudad,
    String? razonSocial,
    String? correoElectronico,
    String? direccion,
    String? telefonoCelular,
    String? telefonoFijo,
    String? descripcion,
    bool? aceptaTratamientoDatos,
    bool? aceptaCondicionesUso,
    String? nombreArchivo,
    String? tipoArchivo,
    String? contenidoArchivoBase64,
  }) {
    return PqrdFormState(
      secretaria: secretaria ?? this.secretaria,
      asuntoInteres: asuntoInteres ?? this.asuntoInteres,
      clasificacionSolicitud: clasificacionSolicitud ?? this.clasificacionSolicitud,
      tipoSolicitante: tipoSolicitante ?? this.tipoSolicitante,
      atencionPreferencial: atencionPreferencial ?? this.atencionPreferencial,
      medioRespuesta: medioRespuesta ?? this.medioRespuesta,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      identificacion: identificacion ?? this.identificacion,
      primerNombre: primerNombre ?? this.primerNombre,
      segundoNombre: segundoNombre ?? this.segundoNombre,
      primerApellido: primerApellido ?? this.primerApellido,
      segundoApellido: segundoApellido ?? this.segundoApellido,
      grupoInteres: grupoInteres ?? this.grupoInteres,
      discapacidad: discapacidad ?? this.discapacidad,
      grupoEtnico: grupoEtnico ?? this.grupoEtnico,
      genero: genero ?? this.genero,
      rangoEdad: rangoEdad ?? this.rangoEdad,
      actividadEconomica: actividadEconomica ?? this.actividadEconomica,
      nivelEstrato: nivelEstrato ?? this.nivelEstrato,
      nivelSisben: nivelSisben ?? this.nivelSisben,
      escolaridad: escolaridad ?? this.escolaridad,
      vulnerabilidad: vulnerabilidad ?? this.vulnerabilidad,
      pais: pais ?? this.pais,
      departamento: departamento ?? this.departamento,
      ciudad: ciudad ?? this.ciudad,
      razonSocial: razonSocial ?? this.razonSocial,
      correoElectronico: correoElectronico ?? this.correoElectronico,
      direccion: direccion ?? this.direccion,
      telefonoCelular: telefonoCelular ?? this.telefonoCelular,
      telefonoFijo: telefonoFijo ?? this.telefonoFijo,
      descripcion: descripcion ?? this.descripcion,
      aceptaTratamientoDatos: aceptaTratamientoDatos ?? this.aceptaTratamientoDatos,
      aceptaCondicionesUso: aceptaCondicionesUso ?? this.aceptaCondicionesUso,
      nombreArchivo: nombreArchivo ?? this.nombreArchivo,
      tipoArchivo: tipoArchivo ?? this.tipoArchivo,
      contenidoArchivoBase64: contenidoArchivoBase64 ?? this.contenidoArchivoBase64,
    );
  }
}

class PqrdDropdownOptionsState {
  final List<Secretaria> secretarias;
  final List<AsuntoInteres> asuntosInteres;
  final List<ClasificacionSolicitud> clasificacionesSolicitud;
  final List<TipoSolicitante> tiposSolicitante;
  final List<AtencionPreferencial> atencionesPreferenciales;
  final List<MedioRespuesta> mediosRespuesta;
  final List<TipoDocumento> tiposDocumento;
  final List<GrupoInteresPQRD> gruposInteres;
  final List<DiscapacidadPQRD> discapacidades;
  final List<GrupoEtnicoPQRD> gruposEtnicos;
  final List<GeneroPQRD> generos;
  final List<RangoEdadPQRD> rangosEdad;
  final List<ActividadEconomicaPQRD> actividadesEconomicas;
  final List<NivelEstratoPQRD> nivelesEstrato;
  final List<NivelSisbenPQRD> nivelesSisben;
  final List<EscolaridadPQRD> escolaridades;
  final List<VulnerabilidadPQRD> vulnerabilidades;
  final List<Departamento> departamentos;
  final List<Ciudad> ciudades;
  final bool isLoadingCiudades;
  final bool isLoading;

  const PqrdDropdownOptionsState({
    this.secretarias = const [],
    this.asuntosInteres = const [],
    this.clasificacionesSolicitud = const [],
    this.tiposSolicitante = const [],
    this.atencionesPreferenciales = const [],
    this.mediosRespuesta = const [],
    this.tiposDocumento = const [],
    this.gruposInteres = const [],
    this.discapacidades = const [],
    this.gruposEtnicos = const [],
    this.generos = const [],
    this.rangosEdad = const [],
    this.actividadesEconomicas = const [],
    this.nivelesEstrato = const [],
    this.nivelesSisben = const [],
    this.escolaridades = const [],
    this.vulnerabilidades = const [],
    this.departamentos = const [],
    this.ciudades = const [],
    this.isLoadingCiudades = false,
    this.isLoading = true,
  });

  PqrdDropdownOptionsState copyWith({
    List<Secretaria>? secretarias,
    List<AsuntoInteres>? asuntosInteres,
    List<ClasificacionSolicitud>? clasificacionesSolicitud,
    List<TipoSolicitante>? tiposSolicitante,
    List<AtencionPreferencial>? atencionesPreferenciales,
    List<MedioRespuesta>? mediosRespuesta,
    List<TipoDocumento>? tiposDocumento,
    List<GrupoInteresPQRD>? gruposInteres,
    List<DiscapacidadPQRD>? discapacidades,
    List<GrupoEtnicoPQRD>? gruposEtnicos,
    List<GeneroPQRD>? generos,
    List<RangoEdadPQRD>? rangosEdad,
    List<ActividadEconomicaPQRD>? actividadesEconomicas,
    List<NivelEstratoPQRD>? nivelesEstrato,
    List<NivelSisbenPQRD>? nivelesSisben,
    List<EscolaridadPQRD>? escolaridades,
    List<VulnerabilidadPQRD>? vulnerabilidades,
    List<Departamento>? departamentos,
    List<Ciudad>? ciudades,
    bool? isLoadingCiudades,
    bool? isLoading,
  }) {
    return PqrdDropdownOptionsState(
      secretarias: secretarias ?? this.secretarias,
      asuntosInteres: asuntosInteres ?? this.asuntosInteres,
      clasificacionesSolicitud: clasificacionesSolicitud ?? this.clasificacionesSolicitud,
      tiposSolicitante: tiposSolicitante ?? this.tiposSolicitante,
      atencionesPreferenciales: atencionesPreferenciales ?? this.atencionesPreferenciales,
      mediosRespuesta: mediosRespuesta ?? this.mediosRespuesta,
      tiposDocumento: tiposDocumento ?? this.tiposDocumento,
      gruposInteres: gruposInteres ?? this.gruposInteres,
      discapacidades: discapacidades ?? this.discapacidades,
      gruposEtnicos: gruposEtnicos ?? this.gruposEtnicos,
      generos: generos ?? this.generos,
      rangosEdad: rangosEdad ?? this.rangosEdad,
      actividadesEconomicas: actividadesEconomicas ?? this.actividadesEconomicas,
      nivelesEstrato: nivelesEstrato ?? this.nivelesEstrato,
      nivelesSisben: nivelesSisben ?? this.nivelesSisben,
      escolaridades: escolaridades ?? this.escolaridades,
      vulnerabilidades: vulnerabilidades ?? this.vulnerabilidades,
      departamentos: departamentos ?? this.departamentos,
      ciudades: ciudades ?? this.ciudades,
      isLoadingCiudades: isLoadingCiudades ?? this.isLoadingCiudades,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FormErrorState {
  final bool secretariaError;
  final bool asuntoInteresError;
  final bool clasificacionSolicitudError;
  final bool tipoSolicitanteError;
  final bool atencionPreferencialError;
  final bool medioRespuestaError;
  final bool tipoDocumentoError;
  final bool identificacionError;
  final bool primerNombreError;
  final bool primerApellidoError;
  final bool grupoInteresError;
  final bool discapacidadError;
  final bool grupoEtnicoError;
  final bool generoError;
  final bool rangoEdadError;
  final bool actividadEconomicaError;
  final bool nivelEstratoError;
  final bool nivelSisbenError;
  final bool escolaridadError;
  final bool vulnerabilidadError;
  final bool departamentoError;
  final bool ciudadError;
  final bool razonSocialError;
  final bool correoElectronicoError;
  final bool direccionError;
  final bool telefonoCelularError;
  final bool descripcionError;
  final String? tipoArchivoError;
  final bool aceptaTratamientoDatosError;
  final bool aceptaCondicionesUsoError;

  const FormErrorState({
    this.secretariaError = false,
    this.asuntoInteresError = false,
    this.clasificacionSolicitudError = false,
    this.tipoSolicitanteError = false,
    this.atencionPreferencialError = false,
    this.medioRespuestaError = false,
    this.tipoDocumentoError = false,
    this.identificacionError = false,
    this.primerNombreError = false,
    this.primerApellidoError = false,
    this.grupoInteresError = false,
    this.discapacidadError = false,
    this.grupoEtnicoError = false,
    this.generoError = false,
    this.rangoEdadError = false,
    this.actividadEconomicaError = false,
    this.nivelEstratoError = false,
    this.nivelSisbenError = false,
    this.escolaridadError = false,
    this.vulnerabilidadError = false,
    this.departamentoError = false,
    this.ciudadError = false,
    this.razonSocialError = false,
    this.correoElectronicoError = false,
    this.direccionError = false,
    this.telefonoCelularError = false,
    this.descripcionError = false,
    this.tipoArchivoError,
    this.aceptaTratamientoDatosError = false,
    this.aceptaCondicionesUsoError = false,
  });

  FormErrorState copyWith({
    bool? secretariaError,
    bool? asuntoInteresError,
    bool? clasificacionSolicitudError,
    bool? tipoSolicitanteError,
    bool? atencionPreferencialError,
    bool? medioRespuestaError,
    bool? tipoDocumentoError,
    bool? identificacionError,
    bool? primerNombreError,
    bool? primerApellidoError,
    bool? grupoInteresError,
    bool? discapacidadError,
    bool? grupoEtnicoError,
    bool? generoError,
    bool? rangoEdadError,
    bool? actividadEconomicaError,
    bool? nivelEstratoError,
    bool? nivelSisbenError,
    bool? escolaridadError,
    bool? vulnerabilidadError,
    bool? departamentoError,
    bool? ciudadError,
    bool? razonSocialError,
    bool? correoElectronicoError,
    bool? direccionError,
    bool? telefonoCelularError,
    bool? descripcionError,
    String? tipoArchivoError,
    bool? aceptaTratamientoDatosError,
    bool? aceptaCondicionesUsoError,
  }) {
    return FormErrorState(
      secretariaError: secretariaError ?? this.secretariaError,
      asuntoInteresError: asuntoInteresError ?? this.asuntoInteresError,
      clasificacionSolicitudError: clasificacionSolicitudError ?? this.clasificacionSolicitudError,
      tipoSolicitanteError: tipoSolicitanteError ?? this.tipoSolicitanteError,
      atencionPreferencialError: atencionPreferencialError ?? this.atencionPreferencialError,
      medioRespuestaError: medioRespuestaError ?? this.medioRespuestaError,
      tipoDocumentoError: tipoDocumentoError ?? this.tipoDocumentoError,
      identificacionError: identificacionError ?? this.identificacionError,
      primerNombreError: primerNombreError ?? this.primerNombreError,
      primerApellidoError: primerApellidoError ?? this.primerApellidoError,
      grupoInteresError: grupoInteresError ?? this.grupoInteresError,
      discapacidadError: discapacidadError ?? this.discapacidadError,
      grupoEtnicoError: grupoEtnicoError ?? this.grupoEtnicoError,
      generoError: generoError ?? this.generoError,
      rangoEdadError: rangoEdadError ?? this.rangoEdadError,
      actividadEconomicaError: actividadEconomicaError ?? this.actividadEconomicaError,
      nivelEstratoError: nivelEstratoError ?? this.nivelEstratoError,
      nivelSisbenError: nivelSisbenError ?? this.nivelSisbenError,
      escolaridadError: escolaridadError ?? this.escolaridadError,
      vulnerabilidadError: vulnerabilidadError ?? this.vulnerabilidadError,
      departamentoError: departamentoError ?? this.departamentoError,
      ciudadError: ciudadError ?? this.ciudadError,
      razonSocialError: razonSocialError ?? this.razonSocialError,
      correoElectronicoError: correoElectronicoError ?? this.correoElectronicoError,
      direccionError: direccionError ?? this.direccionError,
      telefonoCelularError: telefonoCelularError ?? this.telefonoCelularError,
      descripcionError: descripcionError ?? this.descripcionError,
      tipoArchivoError: tipoArchivoError ?? this.tipoArchivoError,
      aceptaTratamientoDatosError: aceptaTratamientoDatosError ?? this.aceptaTratamientoDatosError,
      aceptaCondicionesUsoError: aceptaCondicionesUsoError ?? this.aceptaCondicionesUsoError,
    );
  }
}
