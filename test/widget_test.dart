import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tramiapp_flutter/app.dart';
import 'package:tramiapp_flutter/core/connectivity/connectivity_observer.dart';
import 'package:tramiapp_flutter/core/connectivity/connectivity_status.dart';
import 'package:tramiapp_flutter/core/flavor/flavors.dart';
import 'package:tramiapp_flutter/core/flavor/flavor_config.dart';
import 'package:tramiapp_flutter/core/storage/user_preferences.dart';
import 'package:tramiapp_flutter/core/remote_config/remote_config_service.dart';
import 'package:tramiapp_flutter/core/models/welcome_carousel_image_dto.dart';
import 'package:tramiapp_flutter/core/models/app_global_config_dto.dart';
import 'package:tramiapp_flutter/core/models/tourism_contribution_dto.dart';
import 'package:tramiapp_flutter/core/api/app_status.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class FakeFirebaseRemoteConfig implements FirebaseRemoteConfig {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// El plugin real de `connectivity_plus` lanza `MissingPluginException` en test.
class FakeConnectivityObserver implements ConnectivityObserver {
  @override
  Stream<ConnectivityStatus> observe() =>
      Stream.value(ConnectivityStatus.available);

  @override
  Future<ConnectivityStatus> current() async => ConnectivityStatus.available;
}

class FakeRemoteConfigService extends RemoteConfigService {
  FakeRemoteConfigService() : super(FakeFirebaseRemoteConfig());

  @override
  Future<void> init() async {}

  @override
  bool shouldSendToWelcome() => false;

  @override
  CarouselConfigDTO welcomeCarouselConfig() => CarouselConfigDTO(images: []);

  @override
  AppGlobalConfigDTO appGlobalConfig() => AppGlobalConfigDTO();

  @override
  TourismTaxConfigDTO getTourismTaxRates() => TourismTaxConfigDTO();

  @override
  AppStatus toAppStatus({int? currentBuildNumber}) =>
      const AppStatus(type: AppStatusType.operational);
}

void main() {
  testWidgets('TramiApp arranca y aterriza en Welcome (flavor municipios)',
      (tester) async {
    FlavorConfig.instance = flavorMunicipios;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          remoteConfigServiceProvider.overrideWithValue(FakeRemoteConfigService()),
          connectivityObserverProvider
              .overrideWithValue(FakeConnectivityObserver()),
        ],
        child: const TramiApp(),
      ),
    );
    await tester.pump();

    // El SplashScreen espera 3600 ms antes de navegar (`Future.delayed`). Sin
    // avanzar ese tiempo el test se quedaba en el splash y nunca llegaba a
    // Welcome — por eso fallaba aunque la app funciona.
    await tester.pump(const Duration(milliseconds: 3700));
    await tester.pump();

    // Animación de entrada del header de Welcome (fadeIn + slideInVertically).
    await tester.pump(const Duration(milliseconds: 800));

    // startDestination sin ubicación guardada → Welcome.
    expect(find.text('¡Bienvenido!'), findsOneWidget);
  });
}

