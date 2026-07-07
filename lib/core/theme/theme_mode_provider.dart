import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/user_preferences.dart';

/// Estado reactivo del modo oscuro. Se siembra desde [UserPreferences] y permite
/// que el toggle de Ajustes cambie el tema en vivo (el `AlcaldiasScope` lo
/// observa). Sin esto, la pref se persistía pero el tema solo cambiaba al
/// reiniciar (la pref no notificaba a Riverpod).
class ThemeIsDarkNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(userPreferencesProvider).isDarkTheme();

  Future<void> toggle() async {
    final prefs = ref.read(userPreferencesProvider);
    await prefs.toggleTheme();
    state = prefs.isDarkTheme();
  }

  Future<void> set(bool dark) async {
    final prefs = ref.read(userPreferencesProvider);
    if (prefs.isDarkTheme() != dark) await prefs.toggleTheme();
    state = dark;
  }
}

final themeIsDarkProvider =
    NotifierProvider<ThemeIsDarkNotifier, bool>(ThemeIsDarkNotifier.new);
