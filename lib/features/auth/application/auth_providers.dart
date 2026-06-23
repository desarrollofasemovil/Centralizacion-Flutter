import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/services/api_providers.dart';
import '../../../core/models/user_dto.dart';
import '../../../core/storage/user_preferences.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(authApiServiceProvider),
    ref.watch(userPreferencesProvider),
  ),
);

/// Sesión actual del usuario (null = sin sesión). Se hidrata desde
/// `UserPreferences` al construir y se actualiza con login/logout.
class SessionNotifier extends Notifier<UserDTO?> {
  @override
  UserDTO? build() => ref.read(authRepositoryProvider).currentUser();

  Future<LoginResult> login(String email, String password) async {
    final result = await ref.read(authRepositoryProvider).login(email, password);
    if (result.success) state = result.user;
    return result;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = null;
  }
}

final sessionProvider =
    NotifierProvider<SessionNotifier, UserDTO?>(SessionNotifier.new);
