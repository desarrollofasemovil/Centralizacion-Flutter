import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/remote_config/remote_config_service.dart';
import '../../../core/storage/user_preferences.dart';
import '../domain/tutorial_config.dart';
import '../domain/tutorial_videos.dart';

/// Interruptor y textos del tutorial (Remote Config `tutorial_config`). Si
/// Firebase no está disponible, [TutorialConfig.unavailable] (apagado).
final tutorialConfigProvider = Provider<TutorialConfig>((ref) {
  try {
    return ref.watch(remoteConfigServiceProvider).tutorialConfig();
  } catch (_) {
    return TutorialConfig.unavailable;
  }
});

/// Videos tutoriales (Remote Config `tutorial_videos`). Si Firebase no está
/// disponible, [TutorialVideosConfig.unavailable] (apagados).
final tutorialVideosConfigProvider = Provider<TutorialVideosConfig>((ref) {
  try {
    return ref.watch(remoteConfigServiceProvider).tutorialVideosConfig();
  } catch (_) {
    return TutorialVideosConfig.unavailable;
  }
});

/// Si la Home debe abrir el tutorial al entrar: encendido y nunca visto en esta
/// instalación (cambiar de municipio no lo repite).
bool shouldAutoShowTutorial(WidgetRef ref) =>
    ref.read(tutorialConfigProvider).enabled &&
    !ref.read(userPreferencesProvider).tutorialSeen();
