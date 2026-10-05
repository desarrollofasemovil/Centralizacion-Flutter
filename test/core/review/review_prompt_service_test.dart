import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tramiapp_flutter/core/review/review_prompt_service.dart';
import 'package:tramiapp_flutter/core/storage/user_preferences.dart';

class _FakeLauncher implements ReviewLauncher {
  bool result = true;
  Object? error;
  Completer<void>? gate;
  int calls = 0;

  @override
  Future<bool> launch() async {
    calls++;
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserPreferences prefs;
  late _FakeLauncher launcher;
  late ReviewPromptService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = UserPreferences(await SharedPreferences.getInstance());
    launcher = _FakeLauncher();
    service = ReviewPromptService(prefs, launcher);
  });

  group('login nativo (regla del Kotlin)', () {
    test('primer login: incrementa a 1 y no lanza la reseña', () async {
      final launched = await service.onSuccessfulLogin();

      expect(launched, isFalse);
      expect(launcher.calls, 0);
      expect(prefs.reviewLoginCount(), 1);
    });

    test('segundo login: lanza la reseña', () async {
      await service.onSuccessfulLogin();
      final launched = await service.onSuccessfulLogin();

      expect(launched, isTrue);
      expect(launcher.calls, 1);
      expect(prefs.reviewLoginCount(), 2);
    });

    test('el contador persiste: una instancia nueva continúa la cuenta',
        () async {
      await service.onSuccessfulLogin();

      final reopened = ReviewPromptService(prefs, launcher);
      final launched = await reopened.onSuccessfulLogin();

      expect(launched, isTrue);
      expect(prefs.reviewLoginCount(), 2);
    });

    test('tercer login en la misma sesión: no relanza; el contador sigue',
        () async {
      await service.onSuccessfulLogin();
      await service.onSuccessfulLogin();
      final launched = await service.onSuccessfulLogin();

      expect(launched, isFalse);
      expect(launcher.calls, 1);
      expect(prefs.reviewLoginCount(), 3);
    });

    test('tercer login en otra sesión de la app: vuelve a pedirla', () async {
      await service.onSuccessfulLogin();
      await service.onSuccessfulLogin();

      final nextSession = ReviewPromptService(prefs, launcher);
      final launched = await nextSession.onSuccessfulLogin();

      expect(launched, isTrue);
      expect(launcher.calls, 2);
    });
  });

  group('momentos de éxito', () {
    test('cualquier disparador lanza la reseña sin depender del login',
        () async {
      for (final trigger in ReviewTrigger.values) {
        final fresh = ReviewPromptService(prefs, _FakeLauncher());
        expect(await fresh.onPositiveMoment(trigger), isTrue,
            reason: trigger.name);
      }
      expect(prefs.reviewLoginCount(), 0);
    });

    test('como mucho un flujo completado por sesión entre disparadores',
        () async {
      expect(await service.onPositiveMoment(ReviewTrigger.pqrdFiled), isTrue);
      expect(
        await service.onPositiveMoment(ReviewTrigger.paymentApproved),
        isFalse,
      );
      await service.onSuccessfulLogin();
      await service.onSuccessfulLogin();

      expect(launcher.calls, 1);
    });

    test('dos disparos simultáneos: solo se lanza un flujo', () async {
      launcher.gate = Completer<void>();
      final first = service.onPositiveMoment(ReviewTrigger.pqrdFiled);
      final second = service.onPositiveMoment(ReviewTrigger.taxQueryResults);
      launcher.gate!.complete();

      expect(await first, isTrue);
      expect(await second, isFalse);
      expect(launcher.calls, 1);
    });
  });

  group('fallos del flujo', () {
    test('sin disponibilidad (false): el siguiente disparo reintenta',
        () async {
      launcher.result = false;
      expect(await service.onPositiveMoment(ReviewTrigger.pqrdFiled), isFalse);

      launcher.result = true;
      expect(await service.onPositiveMoment(ReviewTrigger.pqrdFiled), isTrue);
      expect(launcher.calls, 2);
    });

    test('el launcher lanza excepción: no se propaga y se puede reintentar',
        () async {
      launcher.error = StateError('play');
      expect(await service.onPositiveMoment(ReviewTrigger.pqrdFiled), isFalse);

      launcher.error = null;
      expect(await service.onPositiveMoment(ReviewTrigger.pqrdFiled), isTrue);
    });
  });
}
