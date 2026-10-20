import 'package:flutter/material.dart';

import '../../../core/models/municipality_procedure.dart';
import '../../../core/models/reminders_by_user_dto.dart';

/// Antelación con la que se dispara la notificación respecto a la fecha límite.
/// Equivalente al enum `ReminderOffset` del `RemindersViewModel` original.
enum ReminderOffset {
  none('Recordar a la hora del evento', Duration.zero),
  sixHours('6 horas antes', Duration(hours: 6)),
  twelveHours('12 horas antes', Duration(hours: 12)),
  oneDay('1 día antes', Duration(days: 1)),
  oneWeek('1 semana antes', Duration(days: 7));

  const ReminderOffset(this.label, this.before);

  final String label;
  final Duration before;
}

/// Antelación por defecto del recordatorio de una factura: 1 día antes de
/// [target]; si ese momento ya pasó (vence mañana temprano), a la hora del
/// evento para no programar un aviso en el pasado.
ReminderOffset defaultInvoiceReminderOffset(
  DateTime target, {
  required DateTime now,
}) {
  final dayBefore = target.subtract(ReminderOffset.oneDay.before);
  return dayBefore.isAfter(now) ? ReminderOffset.oneDay : ReminderOffset.none;
}

/// Desde dónde se creó un recordatorio: la sección general (Home) o el botón
/// "Recordarme" de una factura. `value` es el que va a la analítica.
enum ReminderOrigin {
  general('general'),
  invoice('factura');

  const ReminderOrigin(this.value);

  final String value;
}

/// Estado del formulario de creación (bottom sheet). Equivalente a
/// `CreateReminderState`.
@immutable
class CreateReminderState {
  final bool isModalVisible;
  final String customName;
  final MunicipalityProcedure? selectedProcedure;
  final int? selectedDateMillis;
  final TimeOfDay selectedTime;
  final bool sendEmail;
  final bool addToCalendar;
  final String? formError;
  final ReminderOffset offset;
  final ReminderOrigin origin;

  const CreateReminderState({
    this.isModalVisible = false,
    this.customName = '',
    this.selectedProcedure,
    this.selectedDateMillis,
    this.selectedTime = const TimeOfDay(hour: 8, minute: 0),
    this.sendEmail = false,
    this.addToCalendar = false,
    this.formError,
    this.offset = ReminderOffset.none,
    this.origin = ReminderOrigin.general,
  });

  CreateReminderState copyWith({
    bool? isModalVisible,
    String? customName,
    MunicipalityProcedure? selectedProcedure,
    int? selectedDateMillis,
    TimeOfDay? selectedTime,
    bool? sendEmail,
    bool? addToCalendar,
    String? formError,
    ReminderOffset? offset,
    ReminderOrigin? origin,
    bool clearFormError = false,
  }) {
    return CreateReminderState(
      isModalVisible: isModalVisible ?? this.isModalVisible,
      customName: customName ?? this.customName,
      selectedProcedure: selectedProcedure ?? this.selectedProcedure,
      selectedDateMillis: selectedDateMillis ?? this.selectedDateMillis,
      selectedTime: selectedTime ?? this.selectedTime,
      sendEmail: sendEmail ?? this.sendEmail,
      addToCalendar: addToCalendar ?? this.addToCalendar,
      formError: clearFormError ? null : (formError ?? this.formError),
      offset: offset ?? this.offset,
      origin: origin ?? this.origin,
    );
  }
}

/// Estado de la UI de Recordatorios. Equivalente a `RemindersUiState`.
@immutable
class RemindersUiState {
  final bool isLoading;
  final List<RemindersByUserDto> reminders;
  final List<RemindersByUserDto> sortedReminders;
  final String? error;
  final List<RemindersByUserDto> expiredReminders;
  final Set<int> activatedReminders;
  final Set<int> remindersToDeleteWarning;
  final bool sessionExpired;
  final bool isActiveSendEmail;
  final CreateReminderState formState;

  /// Evento transitorio (Toast). La UI lo muestra y luego llama a
  /// `consumeToast()` — equivalente al `Channel<ReminderEvent>` del original.
  final String? toastMessage;

  const RemindersUiState({
    this.isLoading = false,
    this.reminders = const [],
    this.sortedReminders = const [],
    this.error,
    this.expiredReminders = const [],
    this.activatedReminders = const {},
    this.remindersToDeleteWarning = const {},
    this.sessionExpired = false,
    this.isActiveSendEmail = false,
    this.formState = const CreateReminderState(),
    this.toastMessage,
  });

  RemindersUiState copyWith({
    bool? isLoading,
    List<RemindersByUserDto>? reminders,
    List<RemindersByUserDto>? sortedReminders,
    String? error,
    List<RemindersByUserDto>? expiredReminders,
    Set<int>? activatedReminders,
    Set<int>? remindersToDeleteWarning,
    bool? sessionExpired,
    bool? isActiveSendEmail,
    CreateReminderState? formState,
    String? toastMessage,
    bool clearError = false,
    bool clearToast = false,
  }) {
    return RemindersUiState(
      isLoading: isLoading ?? this.isLoading,
      reminders: reminders ?? this.reminders,
      sortedReminders: sortedReminders ?? this.sortedReminders,
      error: clearError ? null : (error ?? this.error),
      expiredReminders: expiredReminders ?? this.expiredReminders,
      activatedReminders: activatedReminders ?? this.activatedReminders,
      remindersToDeleteWarning:
          remindersToDeleteWarning ?? this.remindersToDeleteWarning,
      sessionExpired: sessionExpired ?? this.sessionExpired,
      isActiveSendEmail: isActiveSendEmail ?? this.isActiveSendEmail,
      formState: formState ?? this.formState,
      toastMessage: clearToast ? null : (toastMessage ?? this.toastMessage),
    );
  }
}
