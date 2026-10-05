import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/update/in_app_update_service.dart';
import 'package:tramiapp_flutter/core/update/play_update_gateway.dart';

class _CountingService extends InAppUpdateService {
  _CountingService() : super(_NoopGateway(), enabled: false);

  int resumes = 0;

  @override
  Future<void> onResume() async => resumes++;
}

class _NoopGateway implements PlayUpdateGateway {
  @override
  Future<PlayUpdateState> check() async => PlayUpdateState.none;

  @override
  Future<void> startImmediate() async {}
}

void main() {
  testWidgets('resumed llama onResume una vez; otros estados no',
      (tester) async {
    final service = _CountingService();
    final observer = InAppUpdateLifecycleObserver(service);
    tester.binding.addObserver(observer);
    addTearDown(() => tester.binding.removeObserver(observer));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(service.resumes, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(service.resumes, 1);
  });
}
