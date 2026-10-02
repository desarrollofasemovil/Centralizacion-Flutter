import '../../../core/models/municipality_procedure.dart';
import '../../../core/theme/design.dart';
import '../../tramites/domain/info_tramite.dart';
import '../../tramites/domain/integration_type_model.dart';

class MunicipalityModel {
  final int idMunicipio;
  final String codigoEntidad;
  final String nombreMunicipio;
  final String departamento;
  final Design design;
  final IntegrationTypeModel tipoIntegracion;
  final String domain;
  final String bank;
  final String privacyPolicyUrl;
  final String dataPolicyUrl;
  final String newsUrl;
  final List<InfoTramite> tramitesPrincipales;
  final List<InfoTramite> otrosTramites;
  final List<InfoTramite> socialLinks;
  final List<MunicipalityProcedure> municipalityProcedures;
  final double? latitude;
  final double? longitude;
  final String? emailMunicipality;
  final String? emailPanic;
  final int? phone;

  const MunicipalityModel({
    required this.idMunicipio,
    required this.codigoEntidad,
    required this.nombreMunicipio,
    required this.departamento,
    required this.design,
    required this.tipoIntegracion,
    required this.domain,
    required this.bank,
    required this.privacyPolicyUrl,
    required this.dataPolicyUrl,
    required this.newsUrl,
    this.tramitesPrincipales = const [],
    this.otrosTramites = const [],
    this.socialLinks = const [],
    this.municipalityProcedures = const [],
    this.latitude,
    this.longitude,
    this.emailMunicipality,
    this.emailPanic,
    this.phone,
  });
}
