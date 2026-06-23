import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/pqrd_anonima_post.dart';
import '../../models/pqrd_identificacion_post.dart';
import '../../models/response_pqrd.dart';
import '../../models/secretaria.dart';
import '../../models/asunto_interes.dart';
import '../../models/clasificacion_solicitud.dart';
import '../../models/tipo_solicitante.dart';
import '../../models/atencion_preferencial.dart';
import '../../models/medio_respuesta.dart';
import '../../models/tipo_documento.dart';
import '../../models/grupo_interes_pqrd.dart';
import '../../models/discapacidad_pqrd.dart';
import '../../models/grupo_etnico_pqrd.dart';
import '../../models/genero_pqrd.dart';
import '../../models/rango_edad_pqrd.dart';
import '../../models/actividad_economica_pqrd.dart';
import '../../models/nivel_estrato_pqrd.dart';
import '../../models/nivel_sisben_pqrd.dart';
import '../../models/escolaridad_pqrd.dart';
import '../../models/vulnerabilidad_pqrd.dart';
import '../../models/procedure_application_request.dart';
import '../../models/procedure_application_response.dart';

part 'pqrd_api_service.g.dart';

@RestApi()
abstract class PqrdApiService {
  factory PqrdApiService(Dio dio, {String baseUrl}) = _PqrdApiService;

  @POST('PQRD/InsertPQRDAnonima')
  Future<ResponsePQRD> insertPQRDAnonima(@Body() PqrdAnonimaPost body);

  @POST('PQRD/InsertPQRDIdentificacion')
  Future<ResponsePQRD> insertPQRDIdentificacion(@Body() PqrdIdentificacionPost body);

  @GET('SecretariaEntidad/ListSecretariaEntidad')
  Future<List<Secretaria>> listSecretariaEntidad(@Query('CodigoEntidad') String codigoEntidad);

  @GET('PQRD/ListAsuntoInteres')
  Future<List<AsuntoInteres>> listAsuntoInteres(@Query('CodigoEntidad') String codigoEntidad);

  @GET('PQRD/ListClasificacionSolicitud')
  Future<List<ClasificacionSolicitud>> listClasificacionSolicitud(@Query('CodigoEntidad') String codigoEntidad);

  @GET('PQRD/ListTipoSolicitante')
  Future<List<TipoSolicitante>> listTipoSolicitante(@Query('CodigoEntidad') String codigoEntidad);

  @GET('PQRD/ListAtencionPreferencial')
  Future<List<AtencionPreferencial>> listAtencionPreferencial(@Query('CodigoEntidad') String codigoEntidad);

  @GET('PQRD/ListMedioRespuesta')
  Future<List<MedioRespuesta>> listMedioRespuesta(@Query('CodigoEntidad') String codigoEntidad);

  @GET('PQRD/ListTipoDocumento')
  Future<List<TipoDocumento>> listTipoDocumento(@Query('CodigoEntidad') String codigoEntidad);

  @GET('PQRD/GetListGrupoInteresPQRD')
  Future<List<GrupoInteresPQRD>> getListGrupoInteresPQRD(@Query('CodigoEntidad') String codigoEntidad);

  @GET('PQRD/ListDiscapacidadPQRD')
  Future<List<DiscapacidadPQRD>> listDiscapacidadPQRD(@Query('CodigoEntidad') String codigoEntidad);

  @GET('PQRD/GetListGrupoEtnicoPQRD')
  Future<List<GrupoEtnicoPQRD>> getListGrupoEtnicoPQRD(@Query('CodigoEntidad') String codigoEntidad);

  @GET('PQRD/ListGeneroPQRD')
  Future<List<GeneroPQRD>> listGeneroPQRD(@Query('CodigoEntidad') String codigoEntidad);

  @GET('PQRD/ListRangoEdadPQRD')
  Future<List<RangoEdadPQRD>> listRangoEdadPQRD(@Query('CodigoEntidad') String codigoEntidad);

  @GET('PQRD/ListActividadEconomicaPQRD')
  Future<List<ActividadEconomicaPQRD>> listActividadEconomicaPQRD(@Query('CodigoEntidad') String codigoEntidad);

  @GET('PQRD/ListNivelEstractoPQRD')
  Future<List<NivelEstratoPQRD>> listNivelEstratoPQRD(@Query('CodigoEntidad') String codigoEntidad);

  @GET('PQRD/ListNivelSisbenPQRD')
  Future<List<NivelSisbenPQRD>> listNivelSisbenPQRD(@Query('CodigoEntidad') String codigoEntidad);

  @GET('PQRD/ListEscolaridadPQRD')
  Future<List<EscolaridadPQRD>> listEscolaridadPQRD(@Query('CodigoEntidad') String codigoEntidad);

  @GET('PQRD/ListVulnerabilidadPQRD')
  Future<List<VulnerabilidadPQRD>> listVulnerabilidadPQRD(@Query('CodigoEntidad') String codigoEntidad);
}

@RestApi()
abstract class ProcedureApplicationApiService {
  factory ProcedureApplicationApiService(Dio dio, {String baseUrl}) =
      _ProcedureApplicationApiService;

  @POST('Tramites/InsertarSolicitudTramite')
  Future<ProcedureApplicationResponse> insertSolicitudProcedure(
    @Body() ProcedureApplicationRequest request,
  );
}
