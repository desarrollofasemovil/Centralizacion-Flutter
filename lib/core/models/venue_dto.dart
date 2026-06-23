import 'package:json_annotation/json_annotation.dart';

part 'venue_dto.g.dart';

// ---------------------------------------------------------------------------
// UserReservationStatusDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class UserReservationStatusDTO {
  @JsonKey(name: 'venueName')
  final String venueName;

  @JsonKey(name: 'startDate')
  final String startDate;

  @JsonKey(name: 'endDate')
  final String endDate;

  @JsonKey(name: 'status')
  final String status;

  const UserReservationStatusDTO({
    required this.venueName,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory UserReservationStatusDTO.fromJson(Map<String, dynamic> json) =>
      _$UserReservationStatusDTOFromJson(json);

  Map<String, dynamic> toJson() => _$UserReservationStatusDTOToJson(this);
}

// ---------------------------------------------------------------------------
// VenueDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class VenueDTO {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'address')
  final String? address;

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'capacity')
  final int? capacity;

  @JsonKey(name: 'imageUrl')
  final String? imageUrl;

  const VenueDTO({
    required this.id,
    required this.title,
    this.address,
    this.description,
    this.capacity,
    this.imageUrl,
  });

  factory VenueDTO.fromJson(Map<String, dynamic> json) =>
      _$VenueDTOFromJson(json);

  Map<String, dynamic> toJson() => _$VenueDTOToJson(this);
}

// ---------------------------------------------------------------------------
// ReservationRequestDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class ReservationRequestDTO {
  @JsonKey(name: 'venuesMunicipalityId')
  final int venuesMunicipalityId;

  @JsonKey(name: 'firstName')
  final String firstName;

  @JsonKey(name: 'lastName')
  final String lastName;

  @JsonKey(name: 'documentType')
  final String documentType;

  @JsonKey(name: 'documentNumber')
  final String documentNumber;

  @JsonKey(name: 'phone')
  final String phone;

  @JsonKey(name: 'email')
  final String email;

  @JsonKey(name: 'date')
  final String date;

  @JsonKey(name: 'time')
  final String time;

  @JsonKey(name: 'municipalityEmail')
  final String? municipalityEmail;

  const ReservationRequestDTO({
    required this.venuesMunicipalityId,
    required this.firstName,
    required this.lastName,
    required this.documentType,
    required this.documentNumber,
    required this.phone,
    required this.email,
    required this.date,
    required this.time,
    this.municipalityEmail = 'test@test.com',
  });

  factory ReservationRequestDTO.fromJson(Map<String, dynamic> json) =>
      _$ReservationRequestDTOFromJson(json);

  Map<String, dynamic> toJson() => _$ReservationRequestDTOToJson(this);
}

// ---------------------------------------------------------------------------
// ReservationResponseDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class ReservationResponseDTO {
  @JsonKey(name: 'reservationId')
  final int? reservationId;

  @JsonKey(name: 'message')
  final String? message;

  @JsonKey(name: 'disclaimer')
  final String? disclaimer;

  const ReservationResponseDTO({
    this.reservationId,
    this.message,
    this.disclaimer,
  });

  factory ReservationResponseDTO.fromJson(Map<String, dynamic> json) =>
      _$ReservationResponseDTOFromJson(json);

  Map<String, dynamic> toJson() => _$ReservationResponseDTOToJson(this);
}
