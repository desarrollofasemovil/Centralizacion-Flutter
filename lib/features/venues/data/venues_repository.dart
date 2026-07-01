import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/api/network_provider.dart';
import '../../../core/api/services/api_providers.dart';
import '../../../core/api/services/venues_api_service.dart';
import '../../../core/models/venue_dto.dart';

/// Capa de datos de Escenarios deportivos. Envuelve [VenueApiService] —
/// equivalente a `VenueRepositoryImpl`.
class VenuesRepository {
  VenuesRepository(this._api, this._dio);

  final VenueApiService _api;
  final Dio _dio;

  Future<List<VenueDTO>> getVenues(int municipalityId, int venueId) async {
    final response = await _api.getVenues(municipalityId, venueId);
    if (!response.booleanStatus) {
      throw Exception(response.sentencesError ?? 'Error al obtener escenarios');
    }
    return response.result ?? const [];
  }

  /// Verifica si el usuario ya tiene una reserva activa. Un 204 (sin contenido)
  /// significa que está libre (`null`). Usamos Dio directo para poder inspeccionar
  /// el status code, ya que el 204 no trae cuerpo parseable.
  Future<UserReservationStatusDTO?> checkUserStatus(String documentNumber) async {
    final url =
        '${NetworkProvider.centralizacionApiUrl}api/reservations/user/$documentNumber/status';
    final response = await _dio.get<dynamic>(url);
    final data = response.data;
    if (response.statusCode == 204 || data == null) return null;
    if (data is Map<String, dynamic>) {
      if (data.isEmpty) return null;
      return UserReservationStatusDTO.fromJson(data);
    }
    return null;
  }

  /// Crea la reserva. Devuelve el [ReservationResponseDTO]; lanza con el mensaje
  /// del backend si falla la regla de negocio (cooldown / solapamiento).
  Future<ReservationResponseDTO> createReservation(
      ReservationRequestDTO request) async {
    final response = await _api.sendReservation(request);
    if (!response.booleanStatus || response.result == null) {
      throw Exception(response.sentencesError ?? 'No se pudo completar la reserva.');
    }
    return response.result!;
  }
}

final venuesRepositoryProvider = Provider<VenuesRepository>(
  (ref) => VenuesRepository(
    ref.watch(venueApiServiceProvider),
    ref.watch(dioProvider),
  ),
);
