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

/// `idStatusType` de un pago aprobado. Tabla `Availibity` de la API (igual en
/// producción y pruebas): 1 = APROBADA, 2 = COMENZADA, 3 = FALLIDA,
/// 4 = EXPIRADA.
const kPaymentStatusApproved = 1;

/// Estado por nombre, como el original (`HistoryPayViewModel.kt` /
/// `HistoryPayScreen.kt` comparan `statusType`, no el id).
extension PaymentHistoryStatus on PaymentHistoryDTO {
  /// Pago en curso en la pasarela: el que se sincroniza al refrescar.
  bool get isInProgress => statusType.trim().toUpperCase() == 'COMENZADA';

  /// Pago fallido: el único que se puede ocultar deslizando.
  bool get isFailed => statusType.trim().toUpperCase() == 'FALLIDA';
}
