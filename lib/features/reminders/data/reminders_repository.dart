import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/services/api_providers.dart';
import '../../../core/api/services/reminders_api_service.dart';
import '../../../core/models/create_reminders_by_user_dto.dart';
import '../../../core/models/reminders_by_user_dto.dart';
import '../../../core/models/validation_response_dto.dart';

/// Capa de datos de Recordatorios. Envuelve [RemindersApiService]
/// (`api/Reminders/*`) — equivalente a `RemindersRepository` del original.
class RemindersRepository {
  RemindersRepository(this._api);

  final RemindersApiService _api;

  Future<List<RemindersByUserDto>> getRemindersByUser(int userId) =>
      _api.getRemindersByUser(userId);

  Future<RemindersByUserDto> createReminder(CreateReminderDto dto) =>
      _api.createReminders(dto);

  Future<ValidationResponseDTO> deleteReminder(int id) =>
      _api.deleteReminder(id);
}

final remindersRepositoryProvider = Provider<RemindersRepository>(
  (ref) => RemindersRepository(ref.watch(remindersApiServiceProvider)),
);
