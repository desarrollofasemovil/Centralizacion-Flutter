import '../../../core/models/query_field.dart';

sealed class IntegrationTypeModel {
  const IntegrationTypeModel();
}

class TramitesporURL extends IntegrationTypeModel {
  final String urlPredial;
  final String urlIca;
  final String urlPqrds;
  final String urlDeclaracion;
  final String urlReteIca;

  const TramitesporURL({
    required this.urlPredial,
    required this.urlIca,
    required this.urlPqrds,
    required this.urlDeclaracion,
    required this.urlReteIca,
  });
}

class TramitesporAPP extends IntegrationTypeModel {
  final String codigoEntidad;
  final List<QueryField> campoConsulta;

  const TramitesporAPP({
    required this.codigoEntidad,
    required this.campoConsulta,
  });
}
