import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/services/api_providers.dart';
import '../../../core/api/services/auth_api_service.dart';
import '../../../core/models/update_password_request_dto.dart';
import '../../../core/models/update_user_basic_info_dto.dart';
import '../../../core/models/validation_response_dto.dart';

/// Capa de datos de la cuenta de usuario (editar perfil, cambio de contraseña,
/// eliminar cuenta). Envuelve [AuthApiService] — equivalente al subconjunto de
/// `AuthRepositoryImpl` usado por Ajustes/Editar perfil.
class UserAccountRepository {
  UserAccountRepository(this._api);

  final AuthApiService _api;

  Future<ValidationResponseDTO> updatePassword(
    int userId,
    String currentPassword,
    String newPassword,
  ) {
    return _api.updatePassword(
      userId,
      UpdatePasswordRequestDto(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
  }

  Future<ValidationResponseDTO> updateBasicInfo(
    int id,
    UpdateUserBasicInfoDTO body,
  ) {
    return _api.updateBasicInfo(id, body);
  }

  Future<ValidationResponseDTO> deleteUser(int id) => _api.deleteUser(id);
}

final userAccountRepositoryProvider = Provider<UserAccountRepository>(
  (ref) => UserAccountRepository(ref.watch(authApiServiceProvider)),
);
