import 'package:json_annotation/json_annotation.dart';

part 'payment_history_dto.g.dart';

@JsonSerializable()
class PaymentHistoryDTO {
  final int id;
  final String userFirtName;
  final double amount;
  final String paymentDate;
  final bool status;
  final int idStatusType;
  final String alcaldia;
  final String procedureName;
  final String statusType;
  final String idimpuesto;
  final String factura;
  final String codigoEntidad;

  const PaymentHistoryDTO({
    required this.id,
    required this.userFirtName,
    required this.amount,
    required this.paymentDate,
    required this.status,
    required this.idStatusType,
    required this.alcaldia,
    required this.procedureName,
    required this.statusType,
    required this.idimpuesto,
    required this.factura,
    required this.codigoEntidad,
  });

  factory PaymentHistoryDTO.fromJson(Map<String, dynamic> json) =>
      _$PaymentHistoryDTOFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentHistoryDTOToJson(this);
}

typedef PaymentHistoryListDTO = List<PaymentHistoryDTO>;

/// `idStatusType` de un pago aprobado (2 = rechazado, 3 = pendiente).
const kPaymentStatusApproved = 1;
