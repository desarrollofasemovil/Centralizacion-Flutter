// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_transaction_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatusTransactionDto _$StatusTransactionDtoFromJson(
  Map<String, dynamic> json,
) => StatusTransactionDto(
  transactionID: (json['TransactionID'] as num).toInt(),
  cus: json['CUS'] as String,
  factura: json['Factura'] as String,
  referencia: json['Referencia'] as String,
  total: (json['Total'] as num).toDouble(),
  impuesto: json['Impuesto'] as String,
  fechaTransaccion: json['FechaTransaccion'] as String,
  estadoTransaccion: json['EstadoTransaccion'] as String,
  medioPago: json['MedioPago'] as String,
);

Map<String, dynamic> _$StatusTransactionDtoToJson(
  StatusTransactionDto instance,
) => <String, dynamic>{
  'TransactionID': instance.transactionID,
  'CUS': instance.cus,
  'Factura': instance.factura,
  'Referencia': instance.referencia,
  'Total': instance.total,
  'Impuesto': instance.impuesto,
  'FechaTransaccion': instance.fechaTransaccion,
  'EstadoTransaccion': instance.estadoTransaccion,
  'MedioPago': instance.medioPago,
};
