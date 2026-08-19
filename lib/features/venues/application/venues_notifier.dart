import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_dto.dart';
import '../../../core/models/venue_dto.dart';
import '../../auth/application/auth_providers.dart';
import '../data/venues_repository.dart';
import '../domain/venues_state.dart';

/// Parámetro de la familia de Escenarios.
@immutable
class VenuesParam {
  final int municipalityId;
  final int venueId;
  final String municipalityEmail;

  const VenuesParam({
    required this.municipalityId,
    required this.venueId,
    required this.municipalityEmail,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VenuesParam &&
          municipalityId == other.municipalityId &&
          venueId == other.venueId &&
          municipalityEmail == other.municipalityEmail;

  @override
  int get hashCode => Object.hash(municipalityId, venueId, municipalityEmail);
}

/// Lógica de Escenarios deportivos. Port de `VenuesViewModel`.
class VenuesNotifier extends Notifier<VenuesUiState> {
  VenuesNotifier(this.param);

  final VenuesParam param;

  VenuesRepository get _repo => ref.read(venuesRepositoryProvider);

  @override
  VenuesUiState build() {
    Future.microtask(() => _initForm(ref.read(sessionProvider)));
    return const VenuesUiState(status: VenuesStatus.loading);
  }

  Future<void> _initForm(UserDTO? user) async {
    final docNumber = user?.nationalId ?? '';
    state = state.copyWith(
      formState: ReservationFormState(
        firstName: user?.firstName ?? '',
        lastName: user?.lastName ?? '',
        documentType: 'Cédula de Ciudadanía',
        documentNumber: docNumber,
        email: user?.email ?? '',
        phone: user?.phoneNumber ?? '',
      ),
    );

    if (param.municipalityId > 0 && docNumber.isNotEmpty) {
      await _verifyEligibility(docNumber, showWarningOnInit: true);
    } else if (param.municipalityId <= 0) {
      state = state.copyWith(
        status: VenuesStatus.error,
        errorMessage: 'ID de municipio inválido.',
      );
    } else {
      await _loadVenues();
    }
  }

  Future<void> _verifyEligibility(
    String documentNumber, {
    bool showWarningOnInit = false,
  }) async {
    state = state.copyWith(status: VenuesStatus.loading);
    try {
      final active = await _repo.checkUserStatus(documentNumber);
      await _loadVenues(active: active, showWarning: showWarningOnInit);
    } catch (e) {
      state = state.copyWith(
        status: VenuesStatus.error,
        errorMessage: _message(e, 'Error al verificar elegibilidad'),
      );
    }
  }

  Future<void> _loadVenues({
    UserReservationStatusDTO? active,
    bool showWarning = false,
  }) async {
    try {
      final venues = await _repo.getVenues(param.municipalityId, param.venueId);
      state = state.copyWith(
        status: VenuesStatus.available,
        venues: venues,
        activeReservation: active,
        clearActiveReservation: active == null,
        dialog: (showWarning && active != null)
            ? ReservationDialog(
                type: ReservationDialogType.warning,
                activeReservation: active,
              )
            : null,
        clearDialog: !(showWarning && active != null),
      );
    } catch (e) {
      state = state.copyWith(
        status: VenuesStatus.error,
        errorMessage: _message(e, 'Error al cargar escenarios'),
      );
    }
  }

  void retryInitialLoad() {
    final docNumber = state.formState.documentNumber;
    if (param.municipalityId > 0 && docNumber.isNotEmpty) {
      _verifyEligibility(docNumber, showWarningOnInit: true);
    } else if (param.municipalityId > 0) {
      _loadVenues();
    } else {
      state = state.copyWith(
        status: VenuesStatus.error,
        errorMessage: 'ID de municipio inválido.',
      );
    }
  }

  // --- Acciones ---
  void onReserveClick(VenueDTO venue) {
    if (state.status != VenuesStatus.available) return;
    final active = state.activeReservation;
    if (active != null) {
      state = state.copyWith(
        dialog: ReservationDialog(
          type: ReservationDialogType.warning,
          activeReservation: active,
        ),
      );
    } else {
      state = state.copyWith(selectedVenue: venue);
    }
  }

  void onDismissBottomSheet() {
    state = state.copyWith(
      clearSelectedVenue: true,
      formState: state.formState.copyWith(
        clearDateError: true,
        clearTimeError: true,
      ),
    );
  }

  void onDismissDialog() {
    final wasSuccess = state.dialog?.type == ReservationDialogType.success;
    state = state.copyWith(clearDialog: true);
    if (wasSuccess) {
      final doc = state.formState.documentNumber;
      if (doc.isNotEmpty) _silentFetchEligibility(doc);
    }
  }

  Future<void> _silentFetchEligibility(String documentNumber) async {
    try {
      final active = await _repo.checkUserStatus(documentNumber);
      state = state.copyWith(
        activeReservation: active,
        clearActiveReservation: active == null,
      );
    } catch (_) {}
  }

  // --- Campos ---
  void onFirstNameChange(String v) => _updateForm(
    state.formState.copyWith(firstName: v, clearFirstNameError: true),
  );
  void onLastNameChange(String v) => _updateForm(
    state.formState.copyWith(lastName: v, clearLastNameError: true),
  );
  void onDocumentNumberChange(String v) => _updateForm(
    state.formState.copyWith(documentNumber: v, clearDocumentNumberError: true),
  );
  void onEmailChange(String v) =>
      _updateForm(state.formState.copyWith(email: v, clearEmailError: true));
  void onPhoneChange(String v) =>
      _updateForm(state.formState.copyWith(phone: v, clearPhoneError: true));
  void onDateChange(String v) =>
      _updateForm(state.formState.copyWith(date: v, clearDateError: true));
  void onTimeChange(String v) =>
      _updateForm(state.formState.copyWith(time: v, clearTimeError: true));

  void _updateForm(ReservationFormState next) =>
      state = state.copyWith(formState: next);

  Future<void> submitReservation() async {
    if (!_validate()) return;
    final venue = state.selectedVenue;
    if (venue == null) return;

    final venues = state.venues;
    final f = state.formState;
    state = state.copyWith(isSubmitting: true);

    final request = ReservationRequestDTO(
      venuesMunicipalityId: venue.id,
      firstName: f.firstName,
      lastName: f.lastName,
      documentType: f.documentType,
      documentNumber: f.documentNumber,
      phone: f.phone,
      email: f.email,
      date: f.date,
      time: f.time,
      municipalityEmail: param.municipalityEmail.trim().isEmpty
          ? 'test@test.com'
          : param.municipalityEmail,
    );

    try {
      final response = await _repo.createReservation(request);
      state = state.copyWith(
        status: VenuesStatus.available,
        venues: venues,
        isSubmitting: false,
        clearSelectedVenue: true,
        dialog: ReservationDialog(
          type: ReservationDialogType.success,
          title: '¡Reserva Exitosa!',
          message: response.message ?? 'Tu reserva ha sido procesada.',
          disclaimer: response.disclaimer ?? '',
        ),
      );
    } catch (e) {
      state = state.copyWith(
        status: VenuesStatus.available,
        venues: venues,
        isSubmitting: false,
        selectedVenue: venue,
        dialog: ReservationDialog(
          type: ReservationDialogType.error,
          title: 'Aviso de Validación',
          message: _message(
            e,
            'La reserva se encuentra ocupada o hubo un error.',
          ),
        ),
      );
    }
  }

  bool _validate() {
    var valid = true;
    var f = state.formState;

    if (f.firstName.trim().isEmpty) {
      f = f.copyWith(firstNameError: 'El primer nombre es requerido');
      valid = false;
    } else if (f.firstName.length > 100) {
      f = f.copyWith(firstNameError: 'Nombre muy largo');
      valid = false;
    } else if (!RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñ ]+$').hasMatch(f.firstName)) {
      f = f.copyWith(firstNameError: 'Solo letras permitidas');
      valid = false;
    }

    if (f.lastName.trim().isEmpty) {
      f = f.copyWith(lastNameError: 'El apellido es requerido');
      valid = false;
    }
    if (f.documentNumber.trim().isEmpty) {
      f = f.copyWith(documentNumberError: 'El documento es requerido');
      valid = false;
    } else if (!RegExp(r'^\d+$').hasMatch(f.documentNumber)) {
      f = f.copyWith(documentNumberError: 'Solo números permitidos');
      valid = false;
    }
    if (f.email.trim().isEmpty) {
      f = f.copyWith(emailError: 'El email es requerido');
      valid = false;
    } else if (!f.email.contains('@')) {
      f = f.copyWith(emailError: 'Email no válido');
      valid = false;
    }
    if (f.phone.trim().isEmpty) {
      f = f.copyWith(phoneError: 'El celular es requerido');
      valid = false;
    } else if (f.phone.length < 7) {
      f = f.copyWith(phoneError: 'Número de celular inválido');
      valid = false;
    } else if (!RegExp(r'^\d+$').hasMatch(f.phone)) {
      f = f.copyWith(phoneError: 'Solo números permitidos');
      valid = false;
    }
    if (f.date.trim().isEmpty) {
      f = f.copyWith(dateError: 'La fecha es requerida');
      valid = false;
    }
    if (f.time.trim().isEmpty) {
      f = f.copyWith(timeError: 'La hora es requerida');
      valid = false;
    }
    state = state.copyWith(formState: f);
    return valid;
  }

  String _message(Object e, String fallback) {
    if (e is Exception) {
      final s = e.toString().replaceFirst('Exception: ', '');
      return s.isEmpty ? fallback : s;
    }
    return fallback;
  }
}

final venuesNotifierProvider =
    NotifierProvider.family<VenuesNotifier, VenuesUiState, VenuesParam>(
      VenuesNotifier.new,
    );
