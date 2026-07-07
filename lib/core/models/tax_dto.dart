import 'package:json_annotation/json_annotation.dart';

part 'tax_dto.g.dart';

// ---------------------------------------------------------------------------
// TaxQueryResponseDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class TaxQueryResponseDTO {
  @JsonKey(name: 'Mensaje')
  final String? message;

  @JsonKey(name: 'Informacion')
  final List<TaxInfoDTO>? information;

  const TaxQueryResponseDTO({
    this.message,
    this.information,
  });

  factory TaxQueryResponseDTO.fromJson(Map<String, dynamic> json) =>
      _$TaxQueryResponseDTOFromJson(json);

  Map<String, dynamic> toJson() => _$TaxQueryResponseDTOToJson(this);
}

// ---------------------------------------------------------------------------
// TaxInfoDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class TaxInfoDTO {
  @JsonKey(name: 'Entidad')
  final String? entity;

  @JsonKey(name: 'CodigoEntidad')
  final String? entityCode;

  @JsonKey(name: 'Documento')
  final String? document;

  @JsonKey(name: 'Nombre')
  final String? name;

  @JsonKey(name: 'Impuesto')
  final String? taxName;

  @JsonKey(name: 'Id_Impuesto')
  final int? taxId;

  @JsonKey(name: 'Valor')
  final int? value;

  @JsonKey(name: 'ValorAnual')
  final int? annualValue;

  @JsonKey(name: 'ValorSemestre')
  final int? semesterValue;

  @JsonKey(name: 'ValorTrimestre')
  final int? trimesterValue;

  @JsonKey(name: 'ValorParcial')
  final int? partialValue;

  @JsonKey(name: 'Referencia')
  final String? reference;

  @JsonKey(name: 'FechaVencimiento')
  final String? dueDate;

  @JsonKey(name: 'CodigoCatastral')
  final String? cadastralCode;

  @JsonKey(name: 'Detalle')
  final DetalleDTO? detail;

  @JsonKey(name: 'Factura')
  final String? facturaCode;

  const TaxInfoDTO({
    this.entity,
    this.entityCode,
    this.document,
    this.name,
    this.taxName,
    this.taxId,
    this.value,
    this.annualValue,
    this.semesterValue,
    this.trimesterValue,
    this.partialValue,
    this.reference,
    this.dueDate,
    this.cadastralCode,
    this.detail,
    this.facturaCode,
  });

  factory TaxInfoDTO.fromJson(Map<String, dynamic> json) =>
      _$TaxInfoDTOFromJson(json);

  Map<String, dynamic> toJson() => _$TaxInfoDTOToJson(this);
}

// ---------------------------------------------------------------------------
// DetalleDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class DetalleDTO {
  @JsonKey(name: 'Url')
  final String? url;

  @JsonKey(name: 'PORTAL')
  final String? portalUrl;

  const DetalleDTO({
    this.url,
    this.portalUrl,
  });

  factory DetalleDTO.fromJson(Map<String, dynamic> json) =>
      _$DetalleDTOFromJson(json);

  Map<String, dynamic> toJson() => _$DetalleDTOToJson(this);
}

// ---------------------------------------------------------------------------
// TaxQueryRequestDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class TaxQueryRequestDTO {
  @JsonKey(name: 'CodigoEntidad')
  final String? entityCode;

  @JsonKey(name: 'DatoConsulta')
  final String? queryData;

  @JsonKey(name: 'CampoConsulta')
  final String? queryField;

  @JsonKey(name: 'IDImpuesto')
  final int? taxId;

  @JsonKey(name: 'Factura')
  final String? invoice;

  const TaxQueryRequestDTO({
    this.entityCode,
    this.queryData,
    this.queryField,
    this.taxId,
    this.invoice,
  });

  factory TaxQueryRequestDTO.fromJson(Map<String, dynamic> json) =>
      _$TaxQueryRequestDTOFromJson(json);

  Map<String, dynamic> toJson() => _$TaxQueryRequestDTOToJson(this);
}

// ---------------------------------------------------------------------------
// BancolombiaGatewayRequestDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class BancolombiaGatewayRequestDTO {
  @JsonKey(name: 'Referencia')
  final String? reference;

  @JsonKey(name: 'Factura')
  final String? invoice;

  @JsonKey(name: 'CodigoMunicipio')
  final String? municipalityCode;

  @JsonKey(name: 'TipoDocumento')
  final String? documentType;

  @JsonKey(name: 'Identificacion')
  final String? identification;

  @JsonKey(name: 'Nombre')
  final String? name;

  @JsonKey(name: 'Total')
  final int? total;

  @JsonKey(name: 'IDImpuesto')
  final int? taxId;

  @JsonKey(name: 'Email')
  final String? email;

  @JsonKey(name: 'Telefono')
  final String? phone;

  @JsonKey(name: 'FuentePago')
  final int? paymentSource;

  @JsonKey(name: 'TipoImplementacion')
  final int? implementationType;

  const BancolombiaGatewayRequestDTO({
    this.reference,
    this.invoice,
    this.municipalityCode,
    this.documentType,
    this.identification,
    this.name,
    this.total,
    this.taxId,
    this.email,
    this.phone,
    this.paymentSource,
    this.implementationType,
  });

  factory BancolombiaGatewayRequestDTO.fromJson(Map<String, dynamic> json) =>
      _$BancolombiaGatewayRequestDTOFromJson(json);

  Map<String, dynamic> toJson() => _$BancolombiaGatewayRequestDTOToJson(this);
}

// ---------------------------------------------------------------------------
// BancolombiaGatewayResponseDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class BancolombiaGatewayResponseDTO {
  @JsonKey(name: 'URL')
  final String? url;

  @JsonKey(name: 'Codigo')
  final int? code;

  @JsonKey(name: 'Mensaje')
  final String? message;

  const BancolombiaGatewayResponseDTO({
    this.url,
    this.code,
    this.message,
  });

  factory BancolombiaGatewayResponseDTO.fromJson(Map<String, dynamic> json) =>
      _$BancolombiaGatewayResponseDTOFromJson(json);

  Map<String, dynamic> toJson() => _$BancolombiaGatewayResponseDTOToJson(this);
}

// ---------------------------------------------------------------------------
// FintechTransactionRequestDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class FintechTransactionRequestDTO {
  @JsonKey(name: 'idTramite')
  final int? idTramite;

  @JsonKey(name: 'pagador')
  final FintechPayerDTO? pagador;

  @JsonKey(name: 'fuentePago')
  final int? fuentePago;

  @JsonKey(name: 'tipoImplementacion')
  final int? tipoImplementacion;

  @JsonKey(name: 'estado_Url')
  final bool? estadoUrl;

  @JsonKey(name: 'url')
  final String? url;

  @JsonKey(name: 'valorPagar')
  final int? valorPagar;

  @JsonKey(name: 'factura')
  final String? factura;

  @JsonKey(name: 'referencia')
  final String? referencia;

  @JsonKey(name: 'descripcion')
  final String? descripcion;

  const FintechTransactionRequestDTO({
    this.idTramite,
    this.pagador,
    this.fuentePago = 2,
    this.tipoImplementacion = 1,
    this.estadoUrl = true,
    this.url = '',
    this.valorPagar,
    this.factura,
    this.referencia,
    this.descripcion,
  });

  factory FintechTransactionRequestDTO.fromJson(Map<String, dynamic> json) =>
      _$FintechTransactionRequestDTOFromJson(json);

  Map<String, dynamic> toJson() => _$FintechTransactionRequestDTOToJson(this);
}

// ---------------------------------------------------------------------------
// FintechPayerDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class FintechPayerDTO {
  @JsonKey(name: 'documento')
  final String? documento;

  @JsonKey(name: 'tipoDocumento')
  final int? tipoDocumento;

  @JsonKey(name: 'nombre_Completo')
  final String? nombreCompleto;

  @JsonKey(name: 'dv')
  final int? dv;

  @JsonKey(name: 'primernombre')
  final String? primerNombre;

  @JsonKey(name: 'segundonombre')
  final String? segundoNombre;

  @JsonKey(name: 'primerapellido')
  final String? primerApellido;

  @JsonKey(name: 'segundoapellido')
  final String? segundoApellido;

  @JsonKey(name: 'telefono')
  final String? telefono;

  @JsonKey(name: 'email')
  final String? email;

  @JsonKey(name: 'direccion')
  final String? direccion;

  const FintechPayerDTO({
    this.documento,
    this.tipoDocumento,
    this.nombreCompleto,
    this.dv = 0,
    this.primerNombre,
    this.segundoNombre = '',
    this.primerApellido,
    this.segundoApellido = '',
    this.telefono,
    this.email,
    this.direccion = '',
  });

  factory FintechPayerDTO.fromJson(Map<String, dynamic> json) =>
      _$FintechPayerDTOFromJson(json);

  Map<String, dynamic> toJson() => _$FintechPayerDTOToJson(this);
}

// ---------------------------------------------------------------------------
// FintechTransactionResponseDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class FintechTransactionResponseDTO {
  @JsonKey(name: 'isSuccess')
  final bool? isSuccess;

  @JsonKey(name: 'message')
  final String? message;

  @JsonKey(name: 'result')
  final FintechResultDTO? result;

  @JsonKey(name: 'state')
  final int? state;

  const FintechTransactionResponseDTO({
    this.isSuccess,
    this.message,
    this.result,
    this.state,
  });

  factory FintechTransactionResponseDTO.fromJson(Map<String, dynamic> json) =>
      _$FintechTransactionResponseDTOFromJson(json);

  Map<String, dynamic> toJson() => _$FintechTransactionResponseDTOToJson(this);
}

// ---------------------------------------------------------------------------
// FintechResultDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class FintechResultDTO {
  @JsonKey(name: 'idTransaccion')
  final int? idTransaccion;

  @JsonKey(name: 'url')
  final String? url;

  const FintechResultDTO({
    this.idTransaccion,
    this.url,
  });

  factory FintechResultDTO.fromJson(Map<String, dynamic> json) =>
      _$FintechResultDTOFromJson(json);

  Map<String, dynamic> toJson() => _$FintechResultDTOToJson(this);
}
