import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tramiapp_flutter/core/models/course_dto.dart';
import 'package:tramiapp_flutter/core/models/document_type_dto.dart';
import 'package:tramiapp_flutter/core/models/user_dto.dart';
import 'package:tramiapp_flutter/core/notifications/local_reminder_scheduler.dart';
import 'package:tramiapp_flutter/core/notifications/registration_notifications.dart';
import 'package:tramiapp_flutter/core/storage/user_preferences.dart';
import 'package:tramiapp_flutter/features/cursos/application/courses_notifier.dart';
import 'package:tramiapp_flutter/features/cursos/data/courses_repository.dart';

import '../../helpers/fake_local_reminder_scheduler.dart';
import '../../support/spy_review_prompt_service.dart';
import 'package:tramiapp_flutter/core/review/review_prompt_service.dart';


class _FakeCoursesRepository implements CoursesRepository {
  bool failRegistration = false;

  @override
  Future<List<CourseDTO>> getCourses(int municipalityId, {int? courseId}) async =>
      [];

  @override
  Future<String> registerForCourse(
    CourseRegistrationRequestDTO payload,
  ) async {
    if (failRegistration) throw Exception('Cupo agotado');
    return 'Inscripción creada exitosamente';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingNotifications implements RegistrationNotifications {
  @override
  Future<bool> showCourseRegistration({
    required String courseTitle,
    required String userName,
  }) =>
      throw StateError('boom (síncrono)');

  @override
  Future<bool> showVenueReservation({
    required String venueTitle,
    required String userName,
    required String date,
    required String time,
  }) =>
      throw StateError('boom (síncrono)');
}

const _param = CoursesParam(
  municipalityId: 1,
  courseId: 0,
  municipalityEmail: '',
);

void main() {
  late FakeLocalReminderScheduler scheduler;
  late _FakeCoursesRepository repo;

  Future<ProviderContainer> makeContainer({
    List<Override> extra = const [],
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        coursesRepositoryProvider.overrideWithValue(repo),
        localReminderSchedulerProvider.overrideWithValue(scheduler),
        ...extra,
      ],
    );
    addTearDown(container.dispose);
    container.listen(coursesNotifierProvider(_param), (_, _) {});
    await Future<void>.delayed(Duration.zero); // microtask de loadCourses
    return container;
  }

  CoursesNotifier fillForm(ProviderContainer c, {String firstName = 'Ana'}) {
    final n = c.read(coursesNotifierProvider(_param).notifier);
    n.onRegisterClick(CourseDTO(id: 7, title: 'Yoga'));
    n.initForm(
      UserDTO(
        id: 1,
        address: 'Calle 1',
        documentType: DocumentTypeDTO(id: 1, name: 'Cédula de Ciudadanía'),
        documentTypeId: 1,
        email: 'ana@correo.co',
        firstName: firstName,
        lastName: 'Pérez',
        loginStatus: true,
        nationalId: '123456',
        password: '',
        phoneNumber: '3001234567',
        birthDate: '1990-01-01',
      ),
    );
    return n;
  }

  setUp(() {
    scheduler = FakeLocalReminderScheduler();
    repo = _FakeCoursesRepository();
  });

  test(
      'inscripción exitosa: notifica una vez con el título del curso y el primer nombre',
      () async {
    final c = await makeContainer();
    final n = fillForm(c);

    await n.submitRegistration();
    await Future<void>.delayed(Duration.zero);

    expect(c.read(coursesNotifierProvider(_param)).registrationSuccess, isTrue);
    expect(scheduler.shown, hasLength(1));
    final shown = scheduler.shown.single;
    final expected = courseRegistrationContent(
      courseTitle: 'Yoga',
      userName: 'Ana',
    );
    expect(shown.id, kCourseNotificationId);
    expect(shown.title, expected.title);
    expect(shown.body, expected.body);
    expect(shown.bigText, expected.bigText);
  });

  test('inscripción fallida: no notifica', () async {
    repo.failRegistration = true;
    final c = await makeContainer();
    final n = fillForm(c);

    await n.submitRegistration();
    await Future<void>.delayed(Duration.zero);

    final state = c.read(coursesNotifierProvider(_param));
    expect(state.registrationSuccess, isFalse);
    expect(state.error, 'Cupo agotado');
    expect(scheduler.shown, isEmpty);
  });

  test('formulario inválido: no envía ni notifica', () async {
    final c = await makeContainer();
    final n = fillForm(c, firstName: '');

    await n.submitRegistration();
    await Future<void>.delayed(Duration.zero);

    expect(c.read(coursesNotifierProvider(_param)).registrationSuccess, isFalse);
    expect(scheduler.shown, isEmpty);
  });

  test(
      'si la notificación falla, la inscripción igual queda en registrationSuccess == true',
      () async {
    scheduler.throwOnShow = UnsupportedError('web');
    final c = await makeContainer();
    final n = fillForm(c);

    await n.submitRegistration();
    await Future<void>.delayed(Duration.zero);

    final state = c.read(coursesNotifierProvider(_param));
    expect(state.registrationSuccess, isTrue);
    expect(state.error, isNull);
  });

  test(
      'si el servicio de notificaciones lanza de forma síncrona, el envío no se rompe',
      () async {
    final c = await makeContainer(
      extra: [
        registrationNotificationsProvider
            .overrideWithValue(_ThrowingNotifications()),
      ],
    );
    final n = fillForm(c);

    await n.submitRegistration();
    await Future<void>.delayed(Duration.zero);

    final state = c.read(coursesNotifierProvider(_param));
    expect(state.registrationSuccess, isTrue);
    expect(state.error, isNull);
  });

  test(
      'dos inscripciones seguidas usan el mismo id (la segunda reemplaza a la primera)',
      () async {
    final c = await makeContainer();
    final n = fillForm(c);
    await n.submitRegistration();
    n.onDialogDismiss();
    fillForm(c);
    await n.submitRegistration();
    await Future<void>.delayed(Duration.zero);

    expect(scheduler.shown, hasLength(2));
    expect(scheduler.shown.map((s) => s.id).toSet(), {kCourseNotificationId});
  });

  group('reseña de la tienda', () {
    test('al cerrar el diálogo de inscripción exitosa se pide la reseña',
        () async {
      final spy = SpyReviewPromptService();
      final c = await makeContainer(
        extra: [reviewPromptServiceProvider.overrideWithValue(spy)],
      );
      final n = fillForm(c);
      await n.submitRegistration();
      expect(spy.moments, isEmpty, reason: 'no mientras se ve el diálogo');

      n.onDialogDismiss();

      expect(spy.moments, [ReviewTrigger.courseRegistration]);
    });

    test('cerrar la hoja sin inscribirse no pide la reseña', () async {
      final spy = SpyReviewPromptService();
      final c = await makeContainer(
        extra: [reviewPromptServiceProvider.overrideWithValue(spy)],
      );
      repo.failRegistration = true;
      final n = fillForm(c);
      await n.submitRegistration();

      n.onDialogDismiss();

      expect(spy.moments, isEmpty);
    });
  });
}
