// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserReservationStatusDTO _$UserReservationStatusDTOFromJson(
  Map<String, dynamic> json,
) => UserReservationStatusDTO(
  venueName: json['venueName'] as String,
  startDate: json['startDate'] as String,
  endDate: json['endDate'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$UserReservationStatusDTOToJson(
  UserReservationStatusDTO instance,
) => <String, dynamic>{
  'venueName': instance.venueName,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'status': instance.status,
};

VenueDTO _$VenueDTOFromJson(Map<String, dynamic> json) => VenueDTO(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  address: json['address'] as String?,
  description: json['description'] as String?,
  capacity: (json['capacity'] as num?)?.toInt(),
  imageUrl: json['imageUrl'] as String?,
);

Map<String, dynamic> _$VenueDTOToJson(VenueDTO instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'address': instance.address,
  'description': instance.description,
  'capacity': instance.capacity,
  'imageUrl': instance.imageUrl,
};

ReservationRequestDTO _$ReservationRequestDTOFromJson(
  Map<String, dynamic> json,
) => ReservationRequestDTO(
  venuesMunicipalityId: (json['venuesMunicipalityId'] as num).toInt(),
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  documentType: json['documentType'] as String,
  documentNumber: json['documentNumber'] as String,
  phone: json['phone'] as String,
  email: json['email'] as String,
  date: json['date'] as String,
  time: json['time'] as String,
  municipalityEmail: json['municipalityEmail'] as String? ?? 'test@test.com',
);

Map<String, dynamic> _$ReservationRequestDTOToJson(
  ReservationRequestDTO instance,
) => <String, dynamic>{
  'venuesMunicipalityId': instance.venuesMunicipalityId,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'documentType': instance.documentType,
  'documentNumber': instance.documentNumber,
  'phone': instance.phone,
  'email': instance.email,
  'date': instance.date,
  'time': instance.time,
  'municipalityEmail': instance.municipalityEmail,
};

ReservationResponseDTO _$ReservationResponseDTOFromJson(
  Map<String, dynamic> json,
) => ReservationResponseDTO(
  reservationId: (json['reservationId'] as num?)?.toInt(),
  message: json['message'] as String?,
  disclaimer: json['disclaimer'] as String?,
);

Map<String, dynamic> _$ReservationResponseDTOToJson(
  ReservationResponseDTO instance,
) => <String, dynamic>{
  'reservationId': instance.reservationId,
  'message': instance.message,
  'disclaimer': instance.disclaimer,
};
