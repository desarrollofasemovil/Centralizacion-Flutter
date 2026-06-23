import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Capa de analíticas sobre Firebase Analytics (BACKEND §6/§9).
/// Centraliza el logueo de eventos en un solo lugar para mayor flexibilidad.
class AnalyticsService {
  AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (_) {}
  }

  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (_) {}
  }

  Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (_) {}
  }

  Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (_) {}
  }

  Future<void> setUserId(String id) async {
    try {
      await _analytics.setUserId(id: id);
    } catch (_) {}
  }

  Future<void> logModuleClick(String moduleName) async {
    await logEvent('click_module', parameters: {'module_name': moduleName});
  }

  Future<void> logProcedureStart(int procedureId, String name) async {
    await logEvent('procedure_start', parameters: {
      'procedure_id': procedureId,
      'procedure_name': name,
    });
  }

  Future<void> logProcedureSuccess(int procedureId, String name) async {
    await logEvent('procedure_success', parameters: {
      'procedure_id': procedureId,
      'procedure_name': name,
    });
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(FirebaseAnalytics.instance),
);
