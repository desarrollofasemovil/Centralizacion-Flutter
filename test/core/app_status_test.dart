import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/api/app_status.dart';

void main() {
  late ProviderContainer container;
  AppStatusNotifier notifier() => container.read(appStatusProvider.notifier);
  AppStatus status() => container.read(appStatusProvider);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('estado inicial es operational', () {
    expect(status().type, AppStatusType.operational);
  });

  test('un SERVER_ERROR activo NO se limpia con OPERATIONAL', () {
    notifier().updateStatus(
      const AppStatus(type: AppStatusType.serverError, isBlocking: true),
    );
    notifier().updateStatus(const AppStatus(type: AppStatusType.operational));
    expect(status().type, AppStatusType.serverError);
  });

  test('un FORCE_UPDATE nunca lo tapa un SERVER_ERROR', () {
    notifier().updateStatus(const AppStatus(type: AppStatusType.forceUpdate));
    notifier().updateStatus(const AppStatus(type: AppStatusType.serverError));
    expect(status().type, AppStatusType.forceUpdate);
  });

  test('maintenance sí reemplaza operational', () {
    notifier().updateStatus(const AppStatus(type: AppStatusType.maintenance));
    expect(status().type, AppStatusType.maintenance);
  });

  test('setNonBlockingError baja el bloqueo de un SERVER_ERROR', () {
    notifier().updateStatus(
      const AppStatus(type: AppStatusType.serverError, isBlocking: true),
    );
    notifier().setNonBlockingError();
    expect(status().type, AppStatusType.serverError);
    expect(status().isBlocking, isFalse);
  });

  test('clearStatus vuelve a operational', () {
    notifier().updateStatus(const AppStatus(type: AppStatusType.maintenance));
    notifier().clearStatus();
    expect(status().type, AppStatusType.operational);
  });
}
