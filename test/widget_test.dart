import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tramiapp_flutter/app.dart';
import 'package:tramiapp_flutter/core/flavor/flavors.dart';
import 'package:tramiapp_flutter/core/flavor/flavor_config.dart';
import 'package:tramiapp_flutter/core/storage/user_preferences.dart';

void main() {
  testWidgets('TramiApp arranca y aterriza en Welcome (flavor municipios)',
      (tester) async {
    FlavorConfig.instance = flavorMunicipios;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const TramiApp(),
      ),
    );
    await tester.pumpAndSettle();

    // startDestination sin ubicación guardada → Welcome.
    expect(find.text('Bienvenido'), findsOneWidget);
  });
}
