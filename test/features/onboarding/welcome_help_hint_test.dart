import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tramiapp_flutter/app.dart';
import 'package:tramiapp_flutter/core/connectivity/connectivity_observer.dart';
import 'package:tramiapp_flutter/core/flavor/flavor_config.dart';
import 'package:tramiapp_flutter/core/flavor/flavors.dart';
import 'package:tramiapp_flutter/core/remote_config/remote_config_service.dart';
import 'package:tramiapp_flutter/core/storage/user_preferences.dart';
import 'package:tramiapp_flutter/features/tutorial/domain/tutorial_config.dart';
import 'package:tramiapp_flutter/features/tutorial/domain/tutorial_videos.dart';

import '../../widget_test.dart'
    show FakeConnectivityObserver, FakeRemoteConfigService;

/// Remote Config con los videos por defecto encendidos.
class _WithVideos extends FakeRemoteConfigService {
  @override
  TutorialVideosConfig tutorialVideosConfig() => const TutorialVideosConfig();

  @override
  TutorialConfig tutorialConfig() => TutorialConfig.unavailable;
}

const _badge = ValueKey('tutorial-help-badge');

/// Avanza el reloj en cuadros de 100 ms, como en un celular, para que los
/// timers (splash, globo) y las animaciones corran en el mismo orden que en la
/// app; con saltos grandes el globo se iba segundos más tarde.
Future<void> _advance(WidgetTester tester, Duration total) async {
  for (
    var t = Duration.zero;
    t < total;
    t += const Duration(milliseconds: 100)
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Arranca la app y espera a que Welcome termine su animación de entrada.
Future<void> _landOnWelcome(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  FlavorConfig.instance = flavorMunicipios;
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        remoteConfigServiceProvider.overrideWithValue(_WithVideos()),
        connectivityObserverProvider.overrideWithValue(
          FakeConnectivityObserver(),
        ),
      ],
      child: const TramiApp(),
    ),
  );
  // Splash (3,6 s) + espera de Welcome (0,5 s) + coreografía (1,6 s).
  await _advance(tester, const Duration(milliseconds: 6000));
}

void main() {
  testWidgets('la primera vez: globo de ayuda 5 s y luego solo el ?', (
    tester,
  ) async {
    await _landOnWelcome(tester);

    expect(find.text('¿Necesitas ayuda?'), findsOneWidget);
    expect(find.byTooltip('Ver tutorial: cómo pagar'), findsOneWidget);
    expect(find.byKey(_badge), findsOneWidget);

    // Se queda unos segundos (5 s desde que termina de entrar) y se va sola.
    await _advance(tester, const Duration(seconds: 4));
    expect(find.text('¿Necesitas ayuda?'), findsOneWidget);
    await _advance(tester, const Duration(seconds: 2));

    expect(find.text('¿Necesitas ayuda?'), findsNothing);
    expect(find.byTooltip('Ver tutorial: cómo pagar'), findsOneWidget);
    expect(find.byKey(_badge), findsOneWidget);
  });

  testWidgets('si cerró el aviso con la ×, no vuelve a salir', (tester) async {
    await _landOnWelcome(
      tester,
      prefs: {'aviso_video_bienvenida_cerrado': true},
    );

    expect(find.text('¿Necesitas ayuda?'), findsNothing);
    expect(find.byKey(_badge), findsOneWidget);
  });

  testWidgets('si ya vio el video: ni globo ni punto, solo el ?', (
    tester,
  ) async {
    await _landOnWelcome(
      tester,
      prefs: {'video_tutorial_bienvenida_visto': true},
    );

    expect(find.text('¿Necesitas ayuda?'), findsNothing);
    expect(find.byKey(_badge), findsNothing);
    expect(find.byTooltip('Ver tutorial: cómo pagar'), findsOneWidget);
  });

  testWidgets('Welcome ya no tiene «Iniciar sesión»', (tester) async {
    await _landOnWelcome(tester);
    expect(find.text('Iniciar sesión'), findsNothing);
  });
}
