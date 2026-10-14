import 'package:json_annotation/json_annotation.dart';

part 'payment_history_dto.g.dart';

/// Un pago de `GET api/PaymentHistory/User/{id}` (`PaymentHistoryUserListDto`).
/// En la API todo es nullable salvo `id`, y la lista incluye a propósito los
/// pagos con `Status == null`: un `null` se lee como vacío para que un solo
/// registro incompleto no tumbe todo el historial.
@JsonSerializable()
class PaymentHistoryDTO {
  final int id;
  @JsonKey(defaultValue: '')
  final String userFirtName;
  @JsonKey(defaultValue: 0)
  final double amount;
  @JsonKey(defaultValue: '')
  final String paymentDate;
  @JsonKey(defaultValue: false)
  final bool status;
  @JsonKey(defaultValue: 0)
  final int idStatusType;
  @JsonKey(defaultValue: '')
  final String alcaldia;
  @JsonKey(defaultValue: '')
  final String procedureName;
  @JsonKey(defaultValue: '')
  final String statusType;
  @JsonKey(defaultValue: '')
  final String idimpuesto;
  @JsonKey(defaultValue: '')
  final String factura;
  @JsonKey(defaultValue: '')
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

/// Lee la respuesta de `GET api/PaymentHistory/User/{id}`.
///
/// Con pagos, la API devuelve la lista directa. **Sin pagos pendientes responde
/// `404` con un envelope** (`{codeStatus: 404, sentencesError: "Notfound"}`), no
/// con `[]` (API `docs/api/payment-history.md`). Tiparlo como lista hacía que
/// el historial vacío mostrara `DioException [unknown]: null`. El 404 es "sin
/// pagos"; cualquier otro envelope (p. ej. `400` por id inválido) es un error.
PaymentHistoryListDTO paymentHistoryFromResponse(Object? data) {
  if (data is List) {
    return [
      for (final item in data)
        item is PaymentHistoryDTO
            ? item
            : PaymentHistoryDTO.fromJson(item as Map<String, dynamic>),
    ];
  }
  if (data is Map && data['codeStatus'] == 404) return const [];
  throw StateError(
    data is Map
        ? 'Historial de pagos: ${data['sentencesError'] ?? data['codeStatus']}'
        : 'Historial de pagos: respuesta inesperada ($data)',
  );
}

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
