import 'package:json_annotation/json_annotation.dart';

part 'status_transaction_dto.g.dart';

@JsonSerializable()
class StatusTransactionDto {
  @JsonKey(name: 'TransactionID')
  final int transactionID;

  @JsonKey(name: 'CUS')
  final String cus;

  @JsonKey(name: 'Factura')
  final String factura;

  @JsonKey(name: 'Referencia')
  final String referencia;

  @JsonKey(name: 'Total')
  final double total;

  @JsonKey(name: 'Impuesto')
  final String impuesto;

  @JsonKey(name: 'FechaTransaccion')
  final String fechaTransaccion;

  @JsonKey(name: 'EstadoTransaccion')
  final String estadoTransaccion;

  @JsonKey(name: 'MedioPago')
  final String medioPago;

  const StatusTransactionDto({
    required this.transactionID,
    required this.cus,
    required this.factura,
    required this.referencia,
    required this.total,
    required this.impuesto,
    required this.fechaTransaccion,
    required this.estadoTransaccion,
    required this.medioPago,
  });

  factory StatusTransactionDto.fromJson(Map<String, dynamic> json) =>
      _$StatusTransactionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$StatusTransactionDtoToJson(this);
}
