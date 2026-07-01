import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/services/api_providers.dart';
import '../../../core/api/services/emails_api_service.dart';
import '../../../core/models/create_reminders_by_user_dto.dart';
import '../../../core/models/email_dto.dart';
import '../../../core/models/municipality_procedure.dart';
import '../../../core/models/reminders_by_user_dto.dart';
import '../../../core/models/user_dto.dart';
import '../../../core/notifications/local_reminder_scheduler.dart';
import '../../../core/storage/user_preferences.dart';
import '../../auth/application/auth_providers.dart';
import '../data/reminders_repository.dart';
import '../domain/reminders_state.dart';

/// Lógica de Recordatorios (equivalente a `RemindersViewModel`).
///
/// Adaptaciones cross-platform respecto al original Android:
/// - La notificación local se programa con `flutter_local_notifications`
///   ([LocalReminderScheduler]) en vez de `AlarmManager` + `BroadcastReceiver`.
/// - "Agregar a Google Calendar" abre la URL de plantilla de Google Calendar
///   con `url_launcher` (funciona en iOS y Android) en vez de un `Intent`.
/// - Con `sendEmail` activo se envía un correo de confirmación al crear el
///   recordatorio (el original lo delegaba al `BroadcastReceiver` al dispararse
///   la alarma, que no es portable a un isolate de background en Flutter).
class RemindersNotifier extends Notifier<RemindersUiState> {
  RemindersRepository get _repo => ref.read(remindersRepositoryProvider);
  LocalReminderScheduler get _scheduler =>
      ref.read(localReminderSchedulerProvider);
  SendEmailsApiService get _emailApi => ref.read(sendEmailsApiServiceProvider);
  UserPreferences get _prefs => ref.read(userPreferencesProvider);

  UserDTO? _user;

  @override
  RemindersUiState build() {
    _user = ref.read(sessionProvider);
    ref.listen<UserDTO?>(sessionProvider, (_, next) {
      _user = next;
      _onUserChanged(next);
    });
    Future.microtask(() => _onUserChanged(_user));
    return RemindersUiState(
      isActiveSendEmail: _prefs.remindersSendIsVisible(),
    );
  }

  Future<void> _onUserChanged(UserDTO? user) async {
    if (user == null || !user.loginStatus) {
      state = state.copyWith(
        sessionExpired: true,
        error: 'Inicia sesión para agregar recordatorios',
        reminders: const [],
        sortedReminders: const [],
        isLoading: false,
      );
      return;
    }
    await _loadReminders(user);
  }

  // ---------------------------------------------------------------------------
  // Carga
  // ---------------------------------------------------------------------------
  Future<void> _loadReminders(UserDTO user) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final reminders = await _repo.getRemindersByUser(user.id);
      _checkExpired(reminders);
    } catch (_) {
      state = state.copyWith(
        error: 'Error cargando recordatorios',
        reminders: const [],
        sortedReminders: const [],
        isLoading: false,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Formulario
  // ---------------------------------------------------------------------------
  void toggleModal(bool show) {
    if (show) {
      state = state.copyWith(
        formState: state.formState.copyWith(
          isModalVisible: true,
          clearFormError: true,
        ),
      );
    } else {
      state = state.copyWith(formState: const CreateReminderState());
    }
  }

  void updateFormName(String name) => state = state.copyWith(
        formState: state.formState.copyWith(customName: name),
      );

  void updateFormProcedure(MunicipalityProcedure procedure) =>
      state = state.copyWith(
        formState: state.formState.copyWith(selectedProcedure: procedure),
      );

  void updateFormDate(int? millis) => state = state.copyWith(
        formState: state.formState.copyWith(selectedDateMillis: millis),
      );

  void updateFormTime(TimeOfDay time) => state = state.copyWith(
        formState: state.formState.copyWith(selectedTime: time),
      );

  void updateFormEmailToggle(bool enabled) => state = state.copyWith(
        formState: state.formState.copyWith(sendEmail: enabled),
      );

  void updateFormAddToCalendarToggle(bool enabled) => state = state.copyWith(
        formState: state.formState.copyWith(addToCalendar: enabled),
      );

  // ---------------------------------------------------------------------------
  // Crear
  // ---------------------------------------------------------------------------
  Future<void> validateAndSubmit() async {
    final form = state.formState;

    if (form.selectedProcedure == null) {
      state = state.copyWith(
        formState: form.copyWith(formError: 'Debes seleccionar un tipo de trámite.'),
      );
      return;
    }
    if (form.selectedDateMillis == null) {
      state = state.copyWith(
        formState: form.copyWith(formError: 'Debes seleccionar una fecha.'),
      );
      return;
    }

    // La fecha se guarda en UTC (igual que el original), la hora es local.
    final utc = DateTime.fromMillisecondsSinceEpoch(
      form.selectedDateMillis!,
      isUtc: true,
    );
    final target = DateTime(
      utc.year,
      utc.month,
      utc.day,
      form.selectedTime.hour,
      form.selectedTime.minute,
    );

    if (target.isBefore(DateTime.now())) {
      state = state.copyWith(
        formState: form.copyWith(formError: 'La fecha y hora deben ser futuras.'),
      );
      return;
    }

    await _createAndSchedule(
      procedure: form.selectedProcedure!,
      customName: form.customName,
      target: target,
      offset: form.offset,
      sendEmail: form.sendEmail,
      addToCalendar: form.addToCalendar,
    );
    toggleModal(false);
  }

  Future<void> _createAndSchedule({
    required MunicipalityProcedure procedure,
    required String customName,
    required DateTime target,
    required ReminderOffset offset,
    required bool sendEmail,
    required bool addToCalendar,
  }) async {
    final userId = _user?.id;
    if (userId == null) return;

    final procedureName = procedure.procedures.name;
    final notifyAt = target.subtract(offset.before);

    final title = customName.trim().isNotEmpty ? customName : procedureName;
    final content =
        'Recuerda realizar tu trámite: $procedureName antes de ${_pretty(target)}';

    final dateOnly = _isoDate(target);
    final timeOnly = _hhmm(target);

    try {
      final dto = CreateReminderDto(
        expirationDate: dateOnly,
        vigenciaDate: dateOnly,
        idUser: userId,
        idProcedureMunicipality: procedure.id,
        reminderType: 'EMAIL',
        reminderName: customName.trim().isNotEmpty ? customName : procedureName,
        reminderTime: timeOnly,
      );

      final created = await _repo.createReminder(dto);

      if (created.id == null) {
        _toast('Guardado, pero no se pudo programar la notificación…');
        return;
      }

      // Enriquecemos con el trámite seleccionado (el backend no lo devuelve).
      final enriched = _withNavigation(created, procedure);
      _checkExpired([...state.reminders, enriched]);

      final scheduled = await _scheduler.schedule(
        id: created.id!,
        title: title,
        body: content,
        dateTime: notifyAt,
      );

      if (scheduled) {
        _toggleActivated(created.id!);
        _toast('Recordatorio ${created.reminderName ?? title} programado con éxito.');
      } else {
        _toast('Se guardó, pero se necesitan permisos para notificar.');
      }

      if (sendEmail) {
        await _sendReminderEmail(title, content);
      }

      if (addToCalendar) {
        await _openGoogleCalendar(
          title: 'Recordatorio Trami App: $title',
          details: content,
          start: target,
        );
      }
    } catch (_) {
      state = state.copyWith(error: 'Error al crear recordatorio.');
    }
  }

  // ---------------------------------------------------------------------------
  // Click en tarjeta
  // ---------------------------------------------------------------------------
  Future<void> onReminderClicked(RemindersByUserDto reminder) async {
    final procedureName =
        reminder.idProcedureMunicipalityNavigation?.procedures.name ?? 'Trámite';
    _toast('Recordatorio para: $procedureName');

    if (state.isActiveSendEmail) {
      final title = 'Has programado un recordatorio, para $procedureName';
      final content =
          'Tienes un recordatorio pendiente antes del ${reminder.vigenciaDate ?? 'fecha límite'}';
      await _sendReminderEmail(title, content);
    }
  }

  // ---------------------------------------------------------------------------
  // Eliminar
  // ---------------------------------------------------------------------------
  Future<void> deleteReminder(int id) async {
    try {
      final response = await _repo.deleteReminder(id);
      if (response.booleanStatus) {
        await _scheduler.cancel(id);
        final updated = state.reminders.where((r) => r.id != id).toList();
        _checkExpired(updated);
        _toast('Recordatorio eliminado');
      } else {
        _toast('Error al eliminar: ${response.sentencesError}');
      }
    } catch (_) {
      _toast('Error de conexión');
    }
  }

  // ---------------------------------------------------------------------------
  // Vencimiento (réplica de checkRemindersExpired)
  // ---------------------------------------------------------------------------
  void _checkExpired(List<RemindersByUserDto> reminders) {
    final now = DateTime.now();

    final valid = <RemindersByUserDto>[];
    final expired = <RemindersByUserDto>[];
    final warningIds = <int>{};
    final toAutoDelete = <int>[];

    for (final r in reminders) {
      final dateStr = r.vigenciaDate;
      final parsed = dateStr == null ? null : DateTime.tryParse(dateStr);
      if (parsed == null) {
        valid.add(r);
        continue;
      }
      // Fin del día de vencimiento (equivalente a LocalTime.MAX).
      final expEnd = DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59);
      if (now.isAfter(expEnd)) {
        final hoursElapsed = now.difference(expEnd).inHours;
        if (hoursElapsed >= 24) {
          if (r.id != null) toAutoDelete.add(r.id!);
        } else {
          expired.add(r);
          if (r.id != null) warningIds.add(r.id!);
        }
      } else {
        valid.add(r);
      }
    }

    // Borrado automático silencioso de los vencidos hace más de 24h.
    for (final id in toAutoDelete) {
      unawaited(_autoDelete(id));
    }

    final visible = [...valid, ...expired];
    final sorted = [...visible]..sort((a, b) {
        final aw = warningIds.contains(a.id) ? 1 : 0;
        final bw = warningIds.contains(b.id) ? 1 : 0;
        if (aw != bw) return aw - bw; // los de advertencia al final
        return (b.id ?? 0).compareTo(a.id ?? 0); // luego por id desc
      });

    state = state.copyWith(
      reminders: visible,
      sortedReminders: sorted,
      expiredReminders: expired,
      remindersToDeleteWarning: warningIds,
      isLoading: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  Future<void> _sendReminderEmail(String subject, String body) async {
    final email = _user?.email;
    if (email == null || email.isEmpty) return;
    try {
      await _emailApi.sendEmail(EmailDto(to: email, subject: subject, body: body));
    } catch (_) {
      state = state.copyWith(error: 'Error al enviar el correo.');
    }
  }

  Future<void> _openGoogleCalendar({
    required String title,
    required String details,
    required DateTime start,
  }) async {
    final end = start.add(const Duration(hours: 1));
    final dates = '${_calendarStamp(start)}/${_calendarStamp(end)}';
    final uri = Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': title,
      'details': details,
      'dates': dates,
    });
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _toggleActivated(int id) {
    final set = {...state.activatedReminders};
    if (!set.add(id)) set.remove(id);
    state = state.copyWith(activatedReminders: set);
  }

  void _toast(String message) => state = state.copyWith(toastMessage: message);

  void consumeToast() => state = state.copyWith(clearToast: true);

  Future<void> _autoDelete(int id) async {
    try {
      await _repo.deleteReminder(id);
    } catch (_) {}
    await _scheduler.cancel(id);
  }

  RemindersByUserDto _withNavigation(
    RemindersByUserDto base,
    MunicipalityProcedure procedure,
  ) {
    return RemindersByUserDto(
      id: base.id,
      expirationDate: base.expirationDate,
      vigenciaDate: base.vigenciaDate,
      reminderType: base.reminderType,
      reminderName: base.reminderName,
      reminderTime: base.reminderTime,
      idProcedureMunicipalityNavigation: procedure,
      idUserNavigation: base.idUserNavigation,
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _isoDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
  String _hhmm(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';
  String _pretty(DateTime d) =>
      '${_two(d.day)}/${_two(d.month)}/${d.year} a las ${_hhmm(d)}';
  String _calendarStamp(DateTime d) =>
      '${d.year}${_two(d.month)}${_two(d.day)}T${_two(d.hour)}${_two(d.minute)}00';
}

final remindersNotifierProvider =
    NotifierProvider<RemindersNotifier, RemindersUiState>(
  RemindersNotifier.new,
);
