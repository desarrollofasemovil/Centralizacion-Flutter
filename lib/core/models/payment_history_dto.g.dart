// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_history_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentHistoryDTO _$PaymentHistoryDTOFromJson(Map<String, dynamic> json) =>
    PaymentHistoryDTO(
      id: (json['id'] as num).toInt(),
      userFirtName: json['userFirtName'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: json['paymentDate'] as String,
      status: json['status'] as bool,
      idStatusType: (json['idStatusType'] as num).toInt(),
      alcaldia: json['alcaldia'] as String,
      procedureName: json['procedureName'] as String,
      statusType: json['statusType'] as String,
      idimpuesto: json['idimpuesto'] as String,
      factura: json['factura'] as String,
      codigoEntidad: json['codigoEntidad'] as String,
    );

Map<String, dynamic> _$PaymentHistoryDTOToJson(PaymentHistoryDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userFirtName': instance.userFirtName,
      'amount': instance.amount,
      'paymentDate': instance.paymentDate,
      'status': instance.status,
      'idStatusType': instance.idStatusType,
      'alcaldia': instance.alcaldia,
      'procedureName': instance.procedureName,
      'statusType': instance.statusType,
      'idimpuesto': instance.idimpuesto,
      'factura': instance.factura,
      'codigoEntidad': instance.codigoEntidad,
    };
