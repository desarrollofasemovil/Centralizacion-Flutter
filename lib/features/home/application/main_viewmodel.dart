import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_dto.dart';
import '../../../core/storage/user_preferences.dart';
import '../../auth/application/auth_providers.dart';
import '../../tramites/domain/info_tramite.dart';
import '../../../core/api/services/api_providers.dart';
import '../../../core/models/email_dto.dart';

enum ModalFormMode { generic, panicButton }

class MainUiState {
  final bool isLoading;
  final UserDTO? currentUser;
  final int? currentIdMunicipality;
  final String? currentMunicipalityName;
  final bool showLoginSuccessDialog;
  final bool isSearchActive;
  final String searchText;
  final bool showInDevelopmentDialog;
  final AbrirBotonPanico? pendingPanicAction;
  final ModalFormMode? modalMode;
  final String? urlToOpen;
  final bool showExitDialog;
  final bool isDarkTheme;
  final bool isSaved;
  final bool showChangeLocationDialog;
  final bool showPanicCountdownDialog;
  final bool isPqrdVisible;
  final String selectedRoute;

  const MainUiState({
    this.isLoading = true,
    this.currentUser,
    this.currentIdMunicipality = 0,
    this.currentMunicipalityName = "",
    this.showLoginSuccessDialog = false,
    this.isSearchActive = false,
    this.searchText = "",
    this.showInDevelopmentDialog = false,
    this.pendingPanicAction,
    this.modalMode,
    this.urlToOpen,
    this.showExitDialog = false,
    this.isDarkTheme = false,
    this.isSaved = false,
    this.showChangeLocationDialog = false,
    this.showPanicCountdownDialog = false,
    this.isPqrdVisible = false,
    this.selectedRoute = "",
  });

  MainUiState copyWith({
    bool? isLoading,
    UserDTO? currentUser,
    int? currentIdMunicipality,
    String? currentMunicipalityName,
    bool? showLoginSuccessDialog,
    bool? isSearchActive,
    String? searchText,
    bool? showInDevelopmentDialog,
    AbrirBotonPanico? pendingPanicAction,
    ModalFormMode? modalMode,
    String? urlToOpen,
    bool? showExitDialog,
    bool? isDarkTheme,
    bool? isSaved,
    bool? showChangeLocationDialog,
    bool? showPanicCountdownDialog,
    bool? isPqrdVisible,
    String? selectedRoute,
    bool clearPendingPanicAction = false,
    bool clearModalMode = false,
    bool clearUrlToOpen = false,
  }) {
    return MainUiState(
      isLoading: isLoading ?? this.isLoading,
      currentUser: currentUser ?? this.currentUser,
      currentIdMunicipality: currentIdMunicipality ?? this.currentIdMunicipality,
      currentMunicipalityName: currentMunicipalityName ?? this.currentMunicipalityName,
      showLoginSuccessDialog: showLoginSuccessDialog ?? this.showLoginSuccessDialog,
      isSearchActive: isSearchActive ?? this.isSearchActive,
      searchText: searchText ?? this.searchText,
      showInDevelopmentDialog: showInDevelopmentDialog ?? this.showInDevelopmentDialog,
      pendingPanicAction: clearPendingPanicAction ? null : (pendingPanicAction ?? this.pendingPanicAction),
      modalMode: clearModalMode ? null : (modalMode ?? this.modalMode),
      urlToOpen: clearUrlToOpen ? null : (urlToOpen ?? this.urlToOpen),
      showExitDialog: showExitDialog ?? this.showExitDialog,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      isSaved: isSaved ?? this.isSaved,
      showChangeLocationDialog: showChangeLocationDialog ?? this.showChangeLocationDialog,
      showPanicCountdownDialog: showPanicCountdownDialog ?? this.showPanicCountdownDialog,
      isPqrdVisible: isPqrdVisible ?? this.isPqrdVisible,
      selectedRoute: selectedRoute ?? this.selectedRoute,
    );
  }
}

class MainViewModel extends Notifier<MainUiState> {
  final int municipalityId;
  MainViewModel(this.municipalityId);

  UserPreferences get _prefs => ref.read(userPreferencesProvider);

  @override
  MainUiState build() {
    // Escuchar cambios en la sesión del usuario para actualizar el estado
    ref.listen<UserDTO?>(sessionProvider, (prev, next) {
      state = state.copyWith(currentUser: next);
    });

    try {
      final user = ref.read(sessionProvider);
      final location = _prefs.getSavedLocation();
      final isDark = _prefs.isDarkTheme();

      return MainUiState(
        isLoading: false,
        currentUser: user,
        currentIdMunicipality: municipalityId,
        currentMunicipalityName: location.municipio,
        isDarkTheme: isDark,
        isSaved: location.guardado && location.municipalityId == municipalityId,
      );
    } catch (e, stack) {
      // Fallback silently but prevent infinite loading screen
      dev.log(
        "Error initializing MainViewModel state",
        error: e,
        stackTrace: stack,
      );
      return const MainUiState(isLoading: false);
    }
  }

  Future<UserDTO?> getEffectiveUser() async {
    final user = state.currentUser;
    if (user != null) return user;

    final guestJson = _prefs.getGuestUserDataJson();
    if (guestJson != null) {
      try {
        return UserDTO.fromJson(jsonDecode(guestJson) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void onSearchTextChanged(String text) {
    state = state.copyWith(searchText: text);
  }

  void onSearchToggled() {
    state = state.copyWith(
      isSearchActive: !state.isSearchActive,
      searchText: "",
    );
  }

  void dismissLoginSuccessDialog() {
    state = state.copyWith(showLoginSuccessDialog: false);
  }

  void onInDevelopmentDialogDismiss() {
    state = state.copyWith(showInDevelopmentDialog: false);
  }

  void showInDevelopment() {
    state = state.copyWith(showInDevelopmentDialog: true);
  }

  void onExitDialogDismissed() {
    state = state.copyWith(showExitDialog: false);
  }

  void onBackPressed() {
    if (state.isPqrdVisible) {
      state = state.copyWith(isPqrdVisible: false);
    } else {
      state = state.copyWith(showExitDialog: true);
    }
  }

  void togglePqrdVisible() {
    state = state.copyWith(isPqrdVisible: !state.isPqrdVisible);
  }

  void onPqrdsCancel() {
    state = state.copyWith(isPqrdVisible: false);
  }

  void showModalForm(ModalFormMode mode, {String? url}) {
    state = state.copyWith(
      modalMode: mode,
      urlToOpen: url,
    );
  }

  void onModalDismissed() {
    state = state.copyWith(
      clearModalMode: true,
      clearUrlToOpen: true,
      clearPendingPanicAction: true,
    );
  }

  Future<void> onModalConfirmed(UserDTO guestUser) async {
    // Si es un usuario invitado, guardar localmente sus datos
    final currentUser = state.currentUser;
    if (currentUser == null) {
      await _prefs.saveGuestUserDataJson(jsonEncode(guestUser.toJson()));
    }

    await _prefs.saveModalFormCompleted(true);

    final url = state.urlToOpen;
    final panicAction = state.pendingPanicAction;

    state = state.copyWith(
      clearModalMode: true,
      clearUrlToOpen: true,
    );

    if (panicAction != null) {
      // Activar diálogo de pánico directamente tras llenar los datos
      state = state.copyWith(showPanicCountdownDialog: true);
    } else if (url != null) {
      // Abrir URL pendiente
      state = state.copyWith(urlToOpen: url);
    }
  }

  void onTramiteClicked(InfoTramite tramite) {
    if (!tramite.isActive) {
      state = state.copyWith(showInDevelopmentDialog: true);
      return;
    }

    final action = tramite.accion;
    if (action is ShowPqrds) {
      state = state.copyWith(isPqrdVisible: !state.isPqrdVisible);
    } else if (action is AbrirUrl) {
      getEffectiveUser().then((userData) {
        if (userData != null) {
          state = state.copyWith(urlToOpen: action.url);
        } else {
          showModalForm(ModalFormMode.generic, url: action.url);
        }
      });
    } else if (action is AbrirUrlDirecto) {
      state = state.copyWith(urlToOpen: action.url);
    } else if (action is AbrirBotonPanico) {
      state = state.copyWith(pendingPanicAction: action);
      getEffectiveUser().then((userData) {
        if (userData != null) {
          state = state.copyWith(showPanicCountdownDialog: true);
        } else {
          showModalForm(ModalFormMode.panicButton);
        }
      });
    } else {
      // Para otras acciones nativas (NavegarANativo, NavegarAConsultaImpuesto, etc.),
      // la UI reaccionará de manera estándar o las resolverá directamente
    }
  }

  void onChangeLocationClicked() {
    state = state.copyWith(showChangeLocationDialog: true);
  }

  void onDismissChangeLocationDialog() {
    state = state.copyWith(showChangeLocationDialog: false);
  }

  Future<void> onConfirmChangeLocation() async {
    await _prefs.clearCurrentMunicipality();
    state = state.copyWith(showChangeLocationDialog: false);
  }

  void onRouteChanged(String route) {
    state = state.copyWith(selectedRoute: route);
  }

  void cancelPanicAlert() {
    state = state.copyWith(
      showPanicCountdownDialog: false,
      clearPendingPanicAction: true,
    );
  }

  Future<void> confirmAndSendPanicAlert(double? lat, double? lng) async {
    final action = state.pendingPanicAction;
    final user = await getEffectiveUser();

    if (action != null && user != null) {
      final name = "${user.firstName} ${user.lastName}";
      final phone = user.phoneNumber;
      final dni = user.nationalId;
      final email = user.email;

      final locationText = (lat != null && lng != null)
          ? "Mi ubicación es: http://maps.google.com/?q=$lat,$lng"
          : "No se pudo obtener la ubicación.";

      final locationCoordinates = (lat != null && lng != null)
          ? "$lat,$lng"
          : "No disponible";

      final message = "¡ALERTA DE PÁNICO!\n"
          "Necesito ayuda urgente.\n"
          "Mis datos:\n"
          "- Nombre: $name\n"
          "- Cédula: $dni\n"
          "- Teléfono: $phone\n\n"
          "$locationText";

      // Disparar WhatsApp URL
      final whatsappUrl = "${action.baseWhatsappUrl}&text=${Uri.encodeComponent(message)}";
      state = state.copyWith(urlToOpen: whatsappUrl);

      // Enviar Email de pánico si está configurado
      if (action.emailPanic.isNotEmpty) {
        try {
          final panicDto = PanicEmailDto(
            to: action.emailPanic,
            subject: "¡ALERTA DE PÁNICO! - $name",
            name: name,
            userEmail: email,
            phone: phone,
            locationCoordinates: locationCoordinates,
          );
          await ref.read(sendEmailsApiServiceProvider).sendPanicEmail(panicDto);
        } catch (_) {
          // Fallback silencioso igual que en Android
        }
      }
    }

    cancelPanicAlert();
  }

  void clearUrlToOpen() {
    state = state.copyWith(clearUrlToOpen: true);
  }
}

final mainViewModelProvider =
    NotifierProvider.family<MainViewModel, MainUiState, int>(
  MainViewModel.new,
);
