// `Headers` lo definen tanto dio como retrofit; aquí usamos la anotación de
// retrofit, así que ocultamos la clase homónima de dio.
import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';

import '../../models/create_user_dto.dart';
import '../../models/document_type_dto.dart';
import '../../models/login_dto.dart';
import '../../models/update_password_by_forget_dto.dart';
import '../../models/update_password_request_dto.dart';
import '../../models/update_user_basic_info_dto.dart';
import '../../models/update_user_municipality_dto.dart';
import '../../models/user_dto.dart';
import '../../models/validation_response_dto.dart';

part 'auth_api_service.g.dart';

/// Servicio de auth/usuario del microservicio Centralización (BACKEND §3.1).
/// Base: `NetworkProvider.centralizacionApiUrl`.
///
/// Convención crítica: el éxito se evalúa por `booleanStatus`; en login el token
/// viaja en `sentencesError` cuando `booleanStatus == true` (BACKEND §4.2/§5.1).
@RestApi()
abstract class AuthApiService {
  factory AuthApiService(Dio dio, {String baseUrl}) = _AuthApiService;

  /// Login nativo (NO usa Firebase Auth).
  @POST('api/Auth')
  Future<ValidationResponseDTO> login(@Body() LoginDTO body);

  /// Registro.
  @POST('api/User/CreateUser')
  Future<ValidationResponseDTO> createUser(@Body() CreateUserDTO body);

  /// Trae el usuario completo tras login.
  @GET('/api/User/by-email/')
  Future<UserDTO?> getUserByEmail(@Query('email') String email);

  /// Tipos de documento.
  @GET('/api/DocumentType/GetDocumentTypes')
  Future<List<DocumentTypeDTO>> getDocumentTypes();

  /// Cambia `loginStatus` (sesión única). PUT con cuerpo vacío.
  @PUT('/api/User/ChangeStatusUser/{id}/status/{status}')
  @Headers(<String, dynamic>{'Content-Length': 0})
  Future<ValidationResponseDTO> changeStatusUser(
    @Path('id') int id,
    @Path('status') bool status,
  );

  /// Cambio de contraseña autenticado.
  @PUT('api/User/update-password/{userId}')
  Future<ValidationResponseDTO> updatePassword(
    @Path('userId') int userId,
    @Body() UpdatePasswordRequestDto body,
  );

  /// Recuperación por olvido.
  @PUT('api/User/updatePasswordByForget/{userId}')
  Future<ValidationResponseDTO> updatePasswordByForget(
    @Path('userId') int userId,
    @Body() UpdatePasswordByForgetDto body,
  );

  /// Editar perfil.
  @PUT('api/User/UpdateBasicInfo/{id}')
  Future<ValidationResponseDTO> updateBasicInfo(
    @Path('id') int id,
    @Body() UpdateUserBasicInfoDTO body,
  );

  /// Actualiza el municipio del usuario (clave white-label, §7).
  @PUT('api/User/{id}/update')
  Future<ValidationResponseDTO> updateUserMunicipality(
    @Path('id') int id,
    @Body() UpdateUserMunicipalityDTO body,
  );

  /// Eliminar cuenta.
  @DELETE('api/User/Delete/{id}')
  Future<ValidationResponseDTO> deleteUser(@Path('id') int id);
}
