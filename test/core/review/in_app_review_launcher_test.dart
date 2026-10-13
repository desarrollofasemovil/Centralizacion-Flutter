import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:tramiapp_flutter/core/review/review_prompt_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.britannio.in_app_review');
  late List<String> calls;

  void mockPlugin({required bool available, bool requestThrows = false}) {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'isAvailable') return available;
      if (call.method == 'requestReview' && requestThrows) {
        throw PlatformException(code: 'play');
      }
      return null;
    });
  }

  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  final launcher = InAppReviewLauncher(InAppReview.instance);

  test('sin disponibilidad: devuelve false y no pide la reseña', () async {
    mockPlugin(available: false);

    expect(await launcher.launch(), isFalse);
    expect(calls, ['isAvailable']);
  });

  test('disponible: pide la reseña y devuelve true', () async {
    mockPlugin(available: true);

    expect(await launcher.launch(), isTrue);
    expect(calls, ['isAvailable', 'requestReview']);
  });

  test('requestReview falla: devuelve false sin propagar', () async {
    mockPlugin(available: true, requestThrows: true);

    expect(await launcher.launch(), isFalse);
  });
}
