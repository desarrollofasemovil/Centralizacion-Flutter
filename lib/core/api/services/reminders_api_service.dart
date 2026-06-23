import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/create_reminders_by_user_dto.dart';
import '../../models/reminders_by_user_dto.dart';
import '../../models/validation_response_dto.dart';

part 'reminders_api_service.g.dart';

@RestApi()
abstract class RemindersApiService {
  factory RemindersApiService(Dio dio, {String baseUrl}) = _RemindersApiService;

  @GET('api/Reminders/Get/Reminders/ByUser/{userId}')
  Future<List<RemindersByUserDto>> getRemindersByUser(
    @Path('userId') int userId,
  );

  @POST('/api/Reminders/Create/Reminders')
  Future<RemindersByUserDto> createReminders(
    @Body() CreateReminderDto request,
  );

  @DELETE('/api/Reminders/Delete/{id}')
  Future<ValidationResponseDTO> deleteReminder(
    @Path('id') int id,
  );
}
