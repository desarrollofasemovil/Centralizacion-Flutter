import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Deja rastro de un fallo que la app absorbe a propósito (best-effort) para
/// que no pase en silencio. En la app va a Crashlytics como **no fatal**; en
/// debug además sale por consola.
///
/// [context] son pares clave/valor de diagnóstico. **Nunca datos personales**:
/// ni correo, ni documento, ni nombre, ni teléfono.
abstract interface class NonFatalReporter {
  void report(
    String reason, {
    Map<String, Object?> context = const {},
    Object? error,
    StackTrace? stackTrace,
  });
}

class CrashlyticsNonFatalReporter implements NonFatalReporter {
  const CrashlyticsNonFatalReporter();

  @override
  void report(
    String reason, {
    Map<String, Object?> context = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    final details = [for (final e in context.entries) '${e.key}=${e.value}'];
    if (kDebugMode) debugPrint('[no fatal] $reason ${details.join(' ')}');
    try {
      FirebaseCrashlytics.instance.recordError(
        error ?? reason,
        stackTrace ?? StackTrace.current,
        reason: reason,
        information: details,
        fatal: false,
      );
    } catch (_) {
      // Sin Firebase inicializado (tests, config incompleta): solo consola.
    }
  }
}

final nonFatalReporterProvider = Provider<NonFatalReporter>(
  (ref) => const CrashlyticsNonFatalReporter(),
);
