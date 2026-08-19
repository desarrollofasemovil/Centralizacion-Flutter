import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/update_user_basic_info_dto.dart';
import '../../../core/models/user_dto.dart';
import '../../auth/application/auth_providers.dart';
import '../data/user_account_repository.dart';

/// Estado de la pantalla Editar Perfil. Port de `EditProfileUiState`.
class EditProfileState {
  final String firstName;
  final String middleName;
  final String lastName;
  final String secondLastName;
  final String nationalId;
  final String email;
  final String phoneNumber;
  final String address;
  final bool isLoading;

  /// null = idle · true = éxito · false = error.
  final bool? updateResult;
  final String? errorMessage;

  const EditProfileState({
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.secondLastName = '',
    this.nationalId = '',
    this.email = '',
    this.phoneNumber = '',
    this.address = '',
    this.isLoading = false,
    this.updateResult,
    this.errorMessage,
  });

  EditProfileState copyWith({
    String? firstName,
    String? middleName,
    String? lastName,
    String? secondLastName,
    String? nationalId,
    String? email,
    String? phoneNumber,
    String? address,
    bool? isLoading,
    bool? updateResult,
    String? errorMessage,
    bool clearUpdateResult = false,
    bool clearErrorMessage = false,
  }) {
    return EditProfileState(
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      secondLastName: secondLastName ?? this.secondLastName,
      nationalId: nationalId ?? this.nationalId,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      isLoading: isLoading ?? this.isLoading,
      updateResult: clearUpdateResult
          ? null
          : (updateResult ?? this.updateResult),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Lógica de Editar Perfil. Port de `EditProfileViewModel`.
class EditProfileNotifier extends Notifier<EditProfileState> {
  UserAccountRepository get _repo => ref.read(userAccountRepositoryProvider);

  int _currentUserId = 0;

  @override
  EditProfileState build() {
    final user = ref.read(sessionProvider);
    if (user == null) return const EditProfileState();
    _currentUserId = user.id;
    return EditProfileState(
      firstName: user.firstName,
      middleName: user.middleName ?? '',
      lastName: user.lastName,
      secondLastName: user.secondLastName ?? '',
      nationalId: user.nationalId,
      email: user.email,
      phoneNumber: user.phoneNumber,
      address: user.address,
    );
  }

  void onFieldChange(String field, String value) {
    state = switch (field) {
      'firstName' => state.copyWith(firstName: value),
      'middleName' => state.copyWith(middleName: value),
      'lastName' => state.copyWith(lastName: value),
      'secondLastName' => state.copyWith(secondLastName: value),
      'phoneNumber' => state.copyWith(phoneNumber: value),
      'address' => state.copyWith(address: value),
      _ => state,
    };
  }

  Future<void> updateProfile() async {
    if (_currentUserId == 0) return;

    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearUpdateResult: true,
    );

    try {
      final request = UpdateUserBasicInfoDTO(
        firstName: state.firstName,
        middleName: state.middleName,
        lastName: state.lastName,
        secondLastName: state.secondLastName,
        phoneNumber: state.phoneNumber,
        address: state.address,
      );

      final result = await _repo.updateBasicInfo(_currentUserId, request);

      if (result.booleanStatus) {
        await _updateLocalSession(request);
        state = state.copyWith(isLoading: false, updateResult: true);
      } else {
        state = state.copyWith(
          isLoading: false,
          updateResult: false,
          errorMessage: result.sentencesError,
        );
      }
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        updateResult: false,
        errorMessage: 'Error al actualizar el perfil',
      );
    }
  }

  Future<void> _updateLocalSession(UpdateUserBasicInfoDTO data) async {
    final current = ref.read(sessionProvider);
    if (current == null) return;
    final updated = UserDTO(
      id: current.id,
      address: data.address ?? current.address,
      documentType: current.documentType,
      documentTypeId: current.documentTypeId,
      email: current.email,
      firstName: data.firstName ?? current.firstName,
      lastName: data.lastName ?? current.lastName,
      loginStatus: current.loginStatus,
      middleName: data.middleName ?? current.middleName,
      nationalId: current.nationalId,
      password: current.password,
      phoneNumber: data.phoneNumber ?? current.phoneNumber,
      secondLastName: data.secondLastName ?? current.secondLastName,
      birthDate: current.birthDate,
      fixedMunicipality: current.fixedMunicipality,
      lastMunicipality: current.lastMunicipality,
    );
    await ref.read(sessionProvider.notifier).setSession(updated);
  }

  void resetUpdateStatus() {
    state = state.copyWith(clearUpdateResult: true, clearErrorMessage: true);
  }
}

final editProfileNotifierProvider =
    NotifierProvider<EditProfileNotifier, EditProfileState>(
      EditProfileNotifier.new,
    );
