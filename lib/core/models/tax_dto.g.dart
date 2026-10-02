// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tax_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaxQueryResponseDTO _$TaxQueryResponseDTOFromJson(Map<String, dynamic> json) =>
    TaxQueryResponseDTO(
      message: json['Mensaje'] as String?,
      information: (json['Informacion'] as List<dynamic>?)
          ?.map((e) => TaxInfoDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TaxQueryResponseDTOToJson(
  TaxQueryResponseDTO instance,
) => <String, dynamic>{
  'Mensaje': instance.message,
  'Informacion': instance.information,
};

TaxInfoDTO _$TaxInfoDTOFromJson(Map<String, dynamic> json) => TaxInfoDTO(
  entity: json['Entidad'] as String?,
  entityCode: json['CodigoEntidad'] as String?,
  document: json['Documento'] as String?,
  name: json['Nombre'] as String?,
  taxName: json['Impuesto'] as String?,
  taxId: (json['Id_Impuesto'] as num?)?.toInt(),
  value: (json['Valor'] as num?)?.toInt(),
  annualValue: (json['ValorAnual'] as num?)?.toInt(),
  semesterValue: (json['ValorSemestre'] as num?)?.toInt(),
  trimesterValue: (json['ValorTrimestre'] as num?)?.toInt(),
  partialValue: (json['ValorParcial'] as num?)?.toInt(),
  reference: json['Referencia'] as String?,
  dueDate: json['FechaVencimiento'] as String?,
  cadastralCode: json['CodigoCatastral'] as String?,
  detail: json['Detalle'] == null
      ? null
      : DetalleDTO.fromJson(json['Detalle'] as Map<String, dynamic>),
  facturaCode: json['Factura'] as String?,
);

Map<String, dynamic> _$TaxInfoDTOToJson(TaxInfoDTO instance) =>
    <String, dynamic>{
      'Entidad': instance.entity,
      'CodigoEntidad': instance.entityCode,
      'Documento': instance.document,
      'Nombre': instance.name,
      'Impuesto': instance.taxName,
      'Id_Impuesto': instance.taxId,
      'Valor': instance.value,
      'ValorAnual': instance.annualValue,
      'ValorSemestre': instance.semesterValue,
      'ValorTrimestre': instance.trimesterValue,
      'ValorParcial': instance.partialValue,
      'Referencia': instance.reference,
      'FechaVencimiento': instance.dueDate,
      'CodigoCatastral': instance.cadastralCode,
      'Detalle': instance.detail,
      'Factura': instance.facturaCode,
    };

DetalleDTO _$DetalleDTOFromJson(Map<String, dynamic> json) => DetalleDTO(
  url: json['Url'] as String?,
  portalUrl: json['PORTAL'] as String?,
);

Map<String, dynamic> _$DetalleDTOToJson(DetalleDTO instance) =>
    <String, dynamic>{'Url': instance.url, 'PORTAL': instance.portalUrl};

TaxQueryRequestDTO _$TaxQueryRequestDTOFromJson(Map<String, dynamic> json) =>
    TaxQueryRequestDTO(
      entityCode: json['CodigoEntidad'] as String?,
      queryData: json['DatoConsulta'] as String?,
      queryField: json['CampoConsulta'] as String?,
      taxId: (json['IDImpuesto'] as num?)?.toInt(),
      invoice: json['Factura'] as String?,
    );

Map<String, dynamic> _$TaxQueryRequestDTOToJson(TaxQueryRequestDTO instance) =>
    <String, dynamic>{
      'CodigoEntidad': instance.entityCode,
      'DatoConsulta': instance.queryData,
      'CampoConsulta': instance.queryField,
      'IDImpuesto': instance.taxId,
      'Factura': instance.invoice,
    };

BancolombiaGatewayRequestDTO _$BancolombiaGatewayRequestDTOFromJson(
  Map<String, dynamic> json,
) => BancolombiaGatewayRequestDTO(
  reference: json['Referencia'] as String?,
  invoice: json['Factura'] as String?,
  municipalityCode: json['CodigoMunicipio'] as String?,
  documentType: json['TipoDocumento'] as String?,
  identification: json['Identificacion'] as String?,
  name: json['Nombre'] as String?,
  total: (json['Total'] as num?)?.toInt(),
  taxId: (json['IDImpuesto'] as num?)?.toInt(),
  email: json['Email'] as String?,
  phone: json['Telefono'] as String?,
  paymentSource: (json['FuentePago'] as num?)?.toInt(),
  implementationType: (json['TipoImplementacion'] as num?)?.toInt(),
);

Map<String, dynamic> _$BancolombiaGatewayRequestDTOToJson(
  BancolombiaGatewayRequestDTO instance,
) => <String, dynamic>{
  'Referencia': instance.reference,
  'Factura': instance.invoice,
  'CodigoMunicipio': instance.municipalityCode,
  'TipoDocumento': instance.documentType,
  'Identificacion': instance.identification,
  'Nombre': instance.name,
  'Total': instance.total,
  'IDImpuesto': instance.taxId,
  'Email': instance.email,
  'Telefono': instance.phone,
  'FuentePago': instance.paymentSource,
  'TipoImplementacion': instance.implementationType,
};

BancolombiaGatewayResponseDTO _$BancolombiaGatewayResponseDTOFromJson(
  Map<String, dynamic> json,
) => BancolombiaGatewayResponseDTO(
  url: json['URL'] as String?,
  code: (json['Codigo'] as num?)?.toInt(),
  message: json['Mensaje'] as String?,
);

Map<String, dynamic> _$BancolombiaGatewayResponseDTOToJson(
  BancolombiaGatewayResponseDTO instance,
) => <String, dynamic>{
  'URL': instance.url,
  'Codigo': instance.code,
  'Mensaje': instance.message,
};

FintechTransactionRequestDTO _$FintechTransactionRequestDTOFromJson(
  Map<String, dynamic> json,
) => FintechTransactionRequestDTO(
  idTramite: (json['idTramite'] as num?)?.toInt(),
  pagador: json['pagador'] == null
      ? null
      : FintechPayerDTO.fromJson(json['pagador'] as Map<String, dynamic>),
  fuentePago: (json['fuentePago'] as num?)?.toInt() ?? 2,
  tipoImplementacion: (json['tipoImplementacion'] as num?)?.toInt() ?? 1,
  estadoUrl: json['estado_Url'] as bool? ?? true,
  url: json['url'] as String? ?? '',
  valorPagar: (json['valorPagar'] as num?)?.toInt(),
  factura: json['factura'] as String?,
  referencia: json['referencia'] as String?,
  descripcion: json['descripcion'] as String?,
);

Map<String, dynamic> _$FintechTransactionRequestDTOToJson(
  FintechTransactionRequestDTO instance,
) => <String, dynamic>{
  'idTramite': instance.idTramite,
  'pagador': instance.pagador,
  'fuentePago': instance.fuentePago,
  'tipoImplementacion': instance.tipoImplementacion,
  'estado_Url': instance.estadoUrl,
  'url': instance.url,
  'valorPagar': instance.valorPagar,
  'factura': instance.factura,
  'referencia': instance.referencia,
  'descripcion': instance.descripcion,
};

FintechPayerDTO _$FintechPayerDTOFromJson(Map<String, dynamic> json) =>
    FintechPayerDTO(
      documento: json['documento'] as String?,
      tipoDocumento: (json['tipoDocumento'] as num?)?.toInt(),
      nombreCompleto: json['nombre_Completo'] as String?,
      dv: (json['dv'] as num?)?.toInt() ?? 0,
      primerNombre: json['primernombre'] as String?,
      segundoNombre: json['segundonombre'] as String? ?? '',
      primerApellido: json['primerapellido'] as String?,
      segundoApellido: json['segundoapellido'] as String? ?? '',
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      direccion: json['direccion'] as String? ?? '',
    );

Map<String, dynamic> _$FintechPayerDTOToJson(FintechPayerDTO instance) =>
    <String, dynamic>{
      'documento': instance.documento,
      'tipoDocumento': instance.tipoDocumento,
      'nombre_Completo': instance.nombreCompleto,
      'dv': instance.dv,
      'primernombre': instance.primerNombre,
      'segundonombre': instance.segundoNombre,
      'primerapellido': instance.primerApellido,
      'segundoapellido': instance.segundoApellido,
      'telefono': instance.telefono,
      'email': instance.email,
      'direccion': instance.direccion,
    };

FintechTransactionResponseDTO _$FintechTransactionResponseDTOFromJson(
  Map<String, dynamic> json,
) => FintechTransactionResponseDTO(
  isSuccess: json['isSuccess'] as bool?,
  message: json['message'] as String?,
  result: json['result'] == null
      ? null
      : FintechResultDTO.fromJson(json['result'] as Map<String, dynamic>),
  state: (json['state'] as num?)?.toInt(),
);

Map<String, dynamic> _$FintechTransactionResponseDTOToJson(
  FintechTransactionResponseDTO instance,
) => <String, dynamic>{
  'isSuccess': instance.isSuccess,
  'message': instance.message,
  'result': instance.result,
  'state': instance.state,
};

FintechResultDTO _$FintechResultDTOFromJson(Map<String, dynamic> json) =>
    FintechResultDTO(
      idTransaccion: (json['idTransaccion'] as num?)?.toInt(),
      url: json['url'] as String?,
    );

Map<String, dynamic> _$FintechResultDTOToJson(FintechResultDTO instance) =>
    <String, dynamic>{
      'idTransaccion': instance.idTransaccion,
      'url': instance.url,
    };
