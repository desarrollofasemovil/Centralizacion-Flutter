import 'package:flutter/foundation.dart';

import '../../../core/models/venue_dto.dart';

enum VenuesStatus { loading, available, error }

enum ReservationDialogType { success, error, warning }

/// Diálogo emergente de reservas (éxito / error / advertencia por reserva
/// activa). Equivalente a `ReservationDialogState`.
@immutable
class ReservationDialog {
  final ReservationDialogType type;
  final String title;
  final String message;
  final String disclaimer;
  final UserReservationStatusDTO? activeReservation;

  const ReservationDialog({
    required this.type,
    this.title = '',
    this.message = '',
    this.disclaimer = '',
    this.activeReservation,
  });
}

/// Estado del formulario de reserva. Port de `ReservationFormState`.
@immutable
class ReservationFormState {
  final String firstName;
  final String? firstNameError;
  final String lastName;
  final String? lastNameError;
  final String documentType;
  final String documentNumber;
  final String? documentNumberError;
  final String email;
  final String? emailError;
  final String phone;
  final String? phoneError;
  final String date;
  final String? dateError;
  final String time;
  final String? timeError;

  const ReservationFormState({
    this.firstName = '',
    this.firstNameError,
    this.lastName = '',
    this.lastNameError,
    this.documentType = 'Cédula de Ciudadanía',
    this.documentNumber = '',
    this.documentNumberError,
    this.email = '',
    this.emailError,
    this.phone = '',
    this.phoneError,
    this.date = '',
    this.dateError,
    this.time = '',
    this.timeError,
  });

  ReservationFormState copyWith({
    String? firstName,
    String? firstNameError,
    String? lastName,
    String? lastNameError,
    String? documentType,
    String? documentNumber,
    String? documentNumberError,
    String? email,
    String? emailError,
    String? phone,
    String? phoneError,
    String? date,
    String? dateError,
    String? time,
    String? timeError,
    bool clearFirstNameError = false,
    bool clearLastNameError = false,
    bool clearDocumentNumberError = false,
    bool clearEmailError = false,
    bool clearPhoneError = false,
    bool clearDateError = false,
    bool clearTimeError = false,
  }) {
    return ReservationFormState(
      firstName: firstName ?? this.firstName,
      firstNameError:
          clearFirstNameError ? null : (firstNameError ?? this.firstNameError),
      lastName: lastName ?? this.lastName,
      lastNameError:
          clearLastNameError ? null : (lastNameError ?? this.lastNameError),
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      documentNumberError: clearDocumentNumberError
          ? null
          : (documentNumberError ?? this.documentNumberError),
      email: email ?? this.email,
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      phone: phone ?? this.phone,
      phoneError: clearPhoneError ? null : (phoneError ?? this.phoneError),
      date: date ?? this.date,
      dateError: clearDateError ? null : (dateError ?? this.dateError),
      time: time ?? this.time,
      timeError: clearTimeError ? null : (timeError ?? this.timeError),
    );
  }
}

/// Estado de la pantalla de Escenarios. Equivalente a la máquina de estados
/// `VenuesUiState` (Loading / Available / Error) más el formulario.
@immutable
class VenuesUiState {
  final VenuesStatus status;
  final String errorMessage;
  final List<VenueDTO> venues;
  final VenueDTO? selectedVenue;
  final UserReservationStatusDTO? activeReservation;
  final ReservationDialog? dialog;
  final bool isSubmitting;
  final ReservationFormState formState;

  const VenuesUiState({
    this.status = VenuesStatus.loading,
    this.errorMessage = '',
    this.venues = const [],
    this.selectedVenue,
    this.activeReservation,
    this.dialog,
    this.isSubmitting = false,
    this.formState = const ReservationFormState(),
  });

  VenuesUiState copyWith({
    VenuesStatus? status,
    String? errorMessage,
    List<VenueDTO>? venues,
    VenueDTO? selectedVenue,
    UserReservationStatusDTO? activeReservation,
    ReservationDialog? dialog,
    bool? isSubmitting,
    ReservationFormState? formState,
    bool clearSelectedVenue = false,
    bool clearActiveReservation = false,
    bool clearDialog = false,
  }) {
    return VenuesUiState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      venues: venues ?? this.venues,
      selectedVenue:
          clearSelectedVenue ? null : (selectedVenue ?? this.selectedVenue),
      activeReservation: clearActiveReservation
          ? null
          : (activeReservation ?? this.activeReservation),
      dialog: clearDialog ? null : (dialog ?? this.dialog),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      formState: formState ?? this.formState,
    );
  }
}
