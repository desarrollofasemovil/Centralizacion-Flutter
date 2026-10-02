import '../../../core/api/services/pqrd_api_service.dart';
import '../../../core/api/services/generales_api_service.dart';
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
import '../../../core/models/pqrd_anonima_post.dart';
import '../../../core/models/pqrd_identificacion_post.dart';
import '../../../core/models/response_pqrd.dart';

class PqrdRepository {
  final PqrdApiService _pqrdApi;
  final GeneralesApiService _generalesApi;

  PqrdRepository(this._pqrdApi, this._generalesApi);

  Future<List<Secretaria>> listSecretariaEntidad(String codigoEntidad) =>
      _pqrdApi.listSecretariaEntidad(codigoEntidad);

  Future<List<AsuntoInteres>> listAsuntoInteres(String codigoEntidad) =>
      _pqrdApi.listAsuntoInteres(codigoEntidad);

  Future<List<ClasificacionSolicitud>> listClasificacionSolicitud(String codigoEntidad) =>
      _pqrdApi.listClasificacionSolicitud(codigoEntidad);

  Future<List<TipoSolicitante>> listTipoSolicitante(String codigoEntidad) =>
      _pqrdApi.listTipoSolicitante(codigoEntidad);

  Future<List<AtencionPreferencial>> listAtencionPreferencial(String codigoEntidad) =>
      _pqrdApi.listAtencionPreferencial(codigoEntidad);

  Future<List<MedioRespuesta>> listMedioRespuesta(String codigoEntidad) =>
      _pqrdApi.listMedioRespuesta(codigoEntidad);

  Future<List<TipoDocumento>> listTipoDocumento(String codigoEntidad) =>
      _pqrdApi.listTipoDocumento(codigoEntidad);

  Future<List<GrupoInteresPQRD>> getListGrupoInteresPQRD(String codigoEntidad) =>
      _pqrdApi.getListGrupoInteresPQRD(codigoEntidad);

  Future<List<DiscapacidadPQRD>> listDiscapacidadPQRD(String codigoEntidad) =>
      _pqrdApi.listDiscapacidadPQRD(codigoEntidad);

  Future<List<GrupoEtnicoPQRD>> getListGrupoEtnicoPQRD(String codigoEntidad) =>
      _pqrdApi.getListGrupoEtnicoPQRD(codigoEntidad);

  Future<List<GeneroPQRD>> listGeneroPQRD(String codigoEntidad) =>
      _pqrdApi.listGeneroPQRD(codigoEntidad);

  Future<List<RangoEdadPQRD>> listRangoEdadPQRD(String codigoEntidad) =>
      _pqrdApi.listRangoEdadPQRD(codigoEntidad);

  Future<List<ActividadEconomicaPQRD>> listActividadEconomicaPQRD(String codigoEntidad) =>
      _pqrdApi.listActividadEconomicaPQRD(codigoEntidad);

  Future<List<NivelEstratoPQRD>> listNivelEstratoPQRD(String codigoEntidad) =>
      _pqrdApi.listNivelEstratoPQRD(codigoEntidad);

  Future<List<NivelSisbenPQRD>> listNivelSisbenPQRD(String codigoEntidad) =>
      _pqrdApi.listNivelSisbenPQRD(codigoEntidad);

  Future<List<EscolaridadPQRD>> listEscolaridadPQRD(String codigoEntidad) =>
      _pqrdApi.listEscolaridadPQRD(codigoEntidad);

  Future<List<VulnerabilidadPQRD>> listVulnerabilidadPQRD(String codigoEntidad) =>
      _pqrdApi.listVulnerabilidadPQRD(codigoEntidad);

  Future<List<Departamento>> getDepartamentos() => _generalesApi.getDepartamentos();

  Future<List<Ciudad>> getCiudadesPorDepartamento(String deptoId) =>
      _generalesApi.getCiudadesPorDepartamento(deptoId);

  Future<ResponsePQRD> insertPQRDAnonima(PqrdAnonimaPost body) =>
      _pqrdApi.insertPQRDAnonima(body);

  Future<ResponsePQRD> insertPQRDIdentificacion(PqrdIdentificacionPost body) =>
      _pqrdApi.insertPQRDIdentificacion(body);
}
