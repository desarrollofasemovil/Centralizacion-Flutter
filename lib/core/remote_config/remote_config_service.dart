import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_status.dart';
import '../models/app_global_config_dto.dart';
import '../models/welcome_carousel_image_dto.dart';
import '../models/tourism_contribution_dto.dart';

/// Número de build actual de la app, usado por `force_update`.
/// TODO(fase-1): leer de `package_info_plus` en vez de esta constante. Se deja
/// alto para no disparar force_update por accidente en desarrollo.
const int kAppBuildNumber = 999999;

/// Lectura de Firebase Remote Config (BACKEND §6.1). Mantiene EXACTAS las 4
/// keys porque las define el mismo backoffice compartido entre apps.
class RemoteConfigService {
  RemoteConfigService(this._rc);

  final FirebaseRemoteConfig _rc;

  static const keyWelcomeCarousel = 'welcome_carousel_images';
  static const keyAppStatus = 'app_status_config';
  static const keySendToWelcome = 'send_to_welcome';
  static const keyTourismTaxRates = 'tourism_tax_rates';

  Future<void> init() async {
    await _rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 40),
        minimumFetchInterval: const Duration(seconds: 120),
      ),
    );
    await _rc.setDefaults(const {
      keyAppStatus: '{"status":"operational"}',
      keySendToWelcome: false,
      keyWelcomeCarousel: '{"images":[]}',
      keyTourismTaxRates: '{}',
    });
    await _rc.fetchAndActivate();
  }

  bool shouldSendToWelcome() => _rc.getBool(keySendToWelcome);

  CarouselConfigDTO welcomeCarouselConfig() {
    final raw = _rc.getString(keyWelcomeCarousel);
    if (raw.isEmpty) return CarouselConfigDTO(images: []);
    try {
      return CarouselConfigDTO.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return CarouselConfigDTO(images: []);
    }
  }

  AppGlobalConfigDTO appGlobalConfig() {
    final raw = _rc.getString(keyAppStatus);
    if (raw.isEmpty) return AppGlobalConfigDTO();
    try {
      return AppGlobalConfigDTO.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppGlobalConfigDTO();
    }
  }

  TourismTaxConfigDTO getTourismTaxRates() {
    final raw = _rc.getString(keyTourismTaxRates);
    if (raw.isEmpty) return TourismTaxConfigDTO();
    try {
      return TourismTaxConfigDTO.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return TourismTaxConfigDTO();
    }
  }


  /// Traduce el config remoto a un [AppStatus]. Regla de oro (§6.1): primero
  /// `force_update` por versión, luego `maintenance`/`server_error`.
  AppStatus toAppStatus({int currentBuildNumber = kAppBuildNumber}) {
    final cfg = appGlobalConfig();
    if (currentBuildNumber < cfg.minVersionCode) {
      return AppStatus(
        type: AppStatusType.forceUpdate,
        title: cfg.title,
        message: cfg.message,
        isBlocking: true,
      );
    }
    switch (cfg.status) {
      case 'maintenance':
        return AppStatus(
          type: AppStatusType.maintenance,
          title: cfg.title,
          message: cfg.message,
          isBlocking: !cfg.dismissible,
        );
      case 'server_error':
        return AppStatus(
          type: AppStatusType.serverError,
          title: cfg.title,
          message: cfg.message,
          isBlocking: !cfg.dismissible,
        );
      default:
        return const AppStatus(type: AppStatusType.operational);
    }
  }
}

/// Servicio de Remote Config. Comparte el singleton `FirebaseRemoteConfig.instance`
/// que `bootstrap` ya inicializó (`init()`).
final remoteConfigServiceProvider = Provider<RemoteConfigService>(
  (ref) => RemoteConfigService(FirebaseRemoteConfig.instance),
);

/// `send_to_welcome` de Remote Config — lo consume `startDestination`.
/// `bootstrap` lo fija tras `fetchAndActivate` con `.set(...)`.
class SendToWelcomeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final sendToWelcomeProvider =
    NotifierProvider<SendToWelcomeNotifier, bool>(SendToWelcomeNotifier.new);
