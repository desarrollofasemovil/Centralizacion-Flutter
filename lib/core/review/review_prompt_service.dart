import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

import '../storage/user_preferences.dart';

/// Momentos de éxito (además del login) en los que se pide la reseña.
/// No existen en el Kotlin: se añadieron al migrar (FSM-59).
enum ReviewTrigger {
  pqrdFiled,
  taxQueryResults,
  courseRegistration,
  venueReservation,
  paymentApproved,
}

/// Lanza el flujo de reseña de la tienda.
abstract class ReviewLauncher {
  /// `true` si el flujo se ejecutó hasta el final. Google no informa si el
  /// diálogo llegó a mostrarse (aplica su propia cuota).
  Future<bool> launch();
}

/// Envuelve `in_app_review`. Sin disponibilidad (APK instalado a mano, web,
/// escritorio) o ante cualquier error devuelve `false` sin propagar.
class InAppReviewLauncher implements ReviewLauncher {
  InAppReviewLauncher(this._review);

  final InAppReview _review;

  @override
  Future<bool> launch() async {
    try {
      if (!await _review.isAvailable()) return false;
      await _review.requestReview();
      return true;
    } catch (e) {
      debugPrint('InAppReviewLauncher.launch error: $e');
      return false;
    }
  }
}

/// Decide cuándo pedir la reseña (port ampliado de `InAppReviewManager.kt`).
///
/// - Login nativo: a partir del 2.º inicio de sesión acumulado (umbral del
///   Kotlin). El contador persiste y sube en cada login.
/// - Momentos de éxito ([ReviewTrigger]): se pide directamente.
/// - Como mucho **un flujo completado por sesión de la app** (este objeto vive
///   lo que el `ProviderScope`). Si el flujo no se completa (sin
///   disponibilidad o error) el siguiente disparo reintenta.
class ReviewPromptService {
  ReviewPromptService(this._prefs, this._launcher);

  static const int loginThreshold = 2;

  final UserPreferences _prefs;
  final ReviewLauncher _launcher;

  bool _completedThisSession = false;
  bool _inFlight = false;

  /// Llamar tras cada login nativo (correo/clave) exitoso. El de Google no
  /// cuenta, igual que en el Kotlin.
  Future<bool> onSuccessfulLogin() async {
    await _prefs.incrementReviewLoginCount();
    if (_prefs.reviewLoginCount() < loginThreshold) return false;
    return _request();
  }

  Future<bool> onPositiveMoment(ReviewTrigger trigger) => _request();

  Future<bool> _request() async {
    if (_completedThisSession || _inFlight) return false;
    _inFlight = true;
    try {
      final completed = await _launcher.launch();
      if (completed) _completedThisSession = true;
      return completed;
    } catch (e) {
      debugPrint('ReviewPromptService._request error: $e');
      return false;
    } finally {
      _inFlight = false;
    }
  }
}

final reviewPromptServiceProvider = Provider<ReviewPromptService>(
  (ref) => ReviewPromptService(
    ref.watch(userPreferencesProvider),
    InAppReviewLauncher(InAppReview.instance),
  ),
);
