import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/services/api_providers.dart';
import '../../../core/api/services/pqrd_api_service.dart';
import '../../../core/api/services/tax_api_service.dart';
import '../../../core/remote_config/remote_config_service.dart';
import '../../../core/models/user_dto.dart';
import '../../../core/models/tipo_documento.dart';
import '../../../core/models/procedure_application_request.dart';
import '../../../core/models/ciudadano.dart';
import '../../../core/models/documentos.dart';
import '../../../core/models/tax_dto.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/certificates_state.dart';

class CertificatesFamilyParam {
  final int taxId;
  final String entityCode;
  final String payValue;

  const CertificatesFamilyParam({
    required this.taxId,
    required this.entityCode,
    required this.payValue,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CertificatesFamilyParam &&
          runtimeType == other.runtimeType &&
          taxId == other.taxId &&
          entityCode == other.entityCode &&
          payValue == other.payValue;

  @override
  int get hashCode => Object.hash(taxId, entityCode, payValue);
}

class CertificatesNotifier extends Notifier<CertificatesUiState> {
  final CertificatesFamilyParam familyParam;
  CertificatesNotifier(this.familyParam);

  PqrdApiService get _pqrdApi => ref.read(pqrdApiServiceProvider);
  ProcedureApplicationApiService get _procedureApi =>
      ref.read(procedureApplicationApiServiceProvider);
  PaymentApiService get _paymentApi => ref.read(paymentApiServiceProvider);
  RemoteConfigService get _remoteConfig =>
      ref.read(remoteConfigServiceProvider);

  int get _taxId => familyParam.taxId;
  String get _entityCode => familyParam.entityCode;

  @override
  CertificatesUiState build() {
    final procedureIdTax = _getProcedureId(familyParam.taxId);
    final certificateName = _getCertificateName(familyParam.taxId);
    final iconPath = _getIconPath(familyParam.taxId);

    Future.microtask(() => loadDocumentTypes());

    return CertificatesUiState(
      procedureId: procedureIdTax,
      titleCertificate: certificateName,
      certificateIconPath: iconPath,
      certificateValue: familyParam.payValue,
    );
  }

  int _getProcedureId(int taxId) {
    switch (taxId) {
      case 11:
        return 43;
      case 12:
        return 26;
      case 13:
        return 269;
      case 14:
        return 20;
      default:
        return 0;
    }
  }

  String _getCertificateName(int taxId) {
    switch (taxId) {
      case 11:
        return "Certificado de Residencia";
      case 12:
        return "Certificado de Paz y Salvo";
      case 13:
        return "Contribución al turismo";
      case 14:
        return "Concepto de Uso del Suelo";
      default:
        return "Certificado";
    }
  }

  String _getIconPath(int taxId) {
    switch (taxId) {
      case 11:
        return "assets/images/icocertresidencia.svg";
      case 12:
        return "assets/images/icocertpazysalvo.svg";
      case 13:
        return "assets/images/icocertourism.svg";
      case 14:
        return "assets/images/icoconceptusodelsuelo.svg";
      default:
        return "assets/images/icocertresidencia.svg";
    }
  }

  Future<void> loadDocumentTypes() async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _pqrdApi.listTipoDocumento(_entityCode);
      if (result.isNotEmpty) {
        state = state.copyWith(isLoading: false, listTipoDocumento: result);
        final user = ref.read(sessionProvider);
        if (user != null) {
          autofillUserData(user);
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          messageError: "No se encontraron tipos de documento",
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        messageError: "Error al cargar los tipos de documento",
      );
    }
  }

  void autofillUserData(UserDTO user) {
    final userDocumentType = state.listTipoDocumento.firstWhere(
      (it) =>
          it.descripcion.toLowerCase() == user.documentType.name.toLowerCase(),
      orElse: () => state.listTipoDocumento.isNotEmpty
          ? state.listTipoDocumento.first
          : TipoDocumento(id: 0, descripcion: ''),
    );

    state = state.copyWith(
      identificacion: user.nationalId,
      primerNombre: user.firstName,
      segundoNombre: user.middleName ?? '',
      primerApellido: user.lastName,
      segundoApellido: user.secondLastName ?? '',
      correoElectronico: user.email,
      direccion: user.address,
      telefonoCelular: user.phoneNumber,
      tipoDocumento: userDocumentType.id != 0 ? userDocumentType : null,
    );
  }

  bool _isForeignDocument(String? description) {
    if (description == null) return false;
    final lower = description.toLowerCase();
    return lower == "pasaporte" ||
        lower == "cédula de extranjería" ||
        lower == "ce" ||
        lower == "pp" ||
        lower == "permiso especial de permanencia" ||
        lower == "visa";
  }

  void calculateCertificateValue() {
    final isTourismCertificate = state.procedureId == 269;
    if (!isTourismCertificate || state.tipoDocumento == null) {
      if (isTourismCertificate) {
        state = state.copyWith(certificateValue: "0");
      }
      return;
    }

    final ageInt = int.tryParse(state.age);
    final isForeign = _isForeignDocument(state.tipoDocumento!.descripcion);

    if (ageInt == null) {
      state = state.copyWith(certificateValue: "0");
      return;
    }

    final taxRates = _remoteConfig.getTourismTaxRates();
    final rates = isForeign ? taxRates.foreign : taxRates.national;

    int newCertificateValue = 0;
    if (ageInt >= 0 && ageInt <= 6) {
      newCertificateValue = 0;
    } else if (ageInt >= 7 && ageInt <= 14) {
      newCertificateValue = rates.child_7_14;
    } else if (ageInt >= 15 && ageInt <= 17) {
      newCertificateValue = rates.teen_15_17;
    } else if (ageInt >= 18) {
      newCertificateValue = rates.adult;
    }

    state = state.copyWith(certificateValue: newCertificateValue.toString());
  }

  void onIdentificacionChange(String value) {
    state = state.copyWith(identificacion: value);
    validateIdentificacion(value);
  }

  String? validateIdentificacion(String identificacion) {
    String? error;
    if (identificacion.trim().isEmpty) {
      error = "Por favor, introduce un documento.";
    } else if (identificacion.length < 4) {
      error = "La identificación debe tener al menos 4 caracteres.";
    } else if (identificacion.length > 20) {
      error = "La identificación no puede exceder los 20 caracteres.";
    }
    state = state.copyWith(identificacionError: error);
    return error;
  }

  void onTipoDocumentoChange(TipoDocumento tipoDocumento) {
    state = state.copyWith(
      isNextButtonEnabled: true,
      tipoDocumento: tipoDocumento,
    );
    calculateCertificateValue();
  }

  void onPrimerNombreChange(String value) {
    state = state.copyWith(isNextButtonEnabled: true, primerNombre: value);
  }

  void onSegundoNombreChange(String value) {
    state = state.copyWith(segundoNombre: value);
  }

  void onPrimerApellidoChange(String value) {
    state = state.copyWith(isNextButtonEnabled: true, primerApellido: value);
  }

  void onSegundoApellidoChange(String value) {
    state = state.copyWith(segundoApellido: value);
  }

  void correoElectronicoChange(String value) {
    state = state.copyWith(isNextButtonEnabled: true, correoElectronico: value);
  }

  void onDireccionChange(String value) {
    state = state.copyWith(isNextButtonEnabled: true, direccion: value);
  }

  void onTelefonoCelularChange(String value) {
    state = state.copyWith(isNextButtonEnabled: true, telefonoCelular: value);
  }

  void onAgeChange(String value) {
    final filtered = value.replaceAll(RegExp(r'\D'), '');
    state = state.copyWith(age: filtered, ageError: null);

    if (state.procedureId == 269) {
      calculateCertificateValue();
    }
  }

  void onDescripcionChange(String value) {
    state = state.copyWith(isNextButtonEnabled: true, descripcion: value);
  }

  void onTratamientoDatosAcepted(bool value) {
    state = state.copyWith(aceptaTratamientoDatos: value);
  }

  void onCondicionesUsoAcepted(bool value) {
    state = state.copyWith(aceptaCondicionesUso: value);
  }

  void onFileSelected({
    required String name,
    required String? mimeType,
    required String base64Content,
  }) {
    state = state.copyWith(
      nombreArchivo: name,
      tipoArchivo: mimeType ?? 'application/octet-stream',
      contenidoArchivoBase64: base64Content,
    );
  }

  void clearFile() {
    state = state.copyWith(
      nombreArchivo: null,
      tipoArchivo: null,
      contenidoArchivoBase64: null,
    );
  }

  bool validateStep1() {
    final hasDocType = state.tipoDocumento != null;
    final hasIdent = validateIdentificacion(state.identificacion) == null;
    final hasFirstName = state.primerNombre.trim().isNotEmpty;
    final hasLastName = state.primerApellido.trim().isNotEmpty;

    bool ageValid = true;
    if (state.procedureId == 269) {
      final ageInt = int.tryParse(state.age);
      if (state.age.trim().isEmpty) {
        state = state.copyWith(ageError: "La edad es requerida.");
        ageValid = false;
      } else if (ageInt == null || ageInt < 0 || ageInt > 120) {
        state = state.copyWith(
          ageError: "Por favor, introduce una edad válida (0-120).",
        );
        ageValid = false;
      }
    }

    return hasDocType && hasIdent && hasFirstName && hasLastName && ageValid;
  }

  bool validateStep2() {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final isEmailValid = emailRegex.hasMatch(state.correoElectronico);
    final isPhoneValid = state.telefonoCelular.trim().length == 10;
    final isDescValid = state.descripcion.trim().isNotEmpty;

    return isEmailValid && isPhoneValid && isDescValid;
  }

  void onNextStep() {
    if (state.currentStep == 1) {
      if (validateStep1()) {
        state = state.copyWith(currentStep: 2);
      }
    } else if (state.currentStep == 2) {
      if (validateStep2()) {
        state = state.copyWith(currentStep: 3);
      }
    }
  }

  void onPreviousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(
        currentStep: state.currentStep - 1,
        isNextButtonEnabled: true,
      );
    }
  }

  Future<CertificatesResponseState> submitSolicitudTramite() async {
    if (!state.aceptaTratamientoDatos) {
      return const CertificatesResponseError(
        "Debes aceptar la política de tratamiento de datos.",
      );
    }
    if (!state.aceptaCondicionesUso) {
      return const CertificatesResponseError(
        "Debes aceptar las condiciones de uso y políticas de privacidad.",
      );
    }

    ref.read(certificatesResponseStateProvider.notifier).setLoading();

    try {
      final ciudadano = Ciudadano(
        direccion: state.direccion,
        email: state.correoElectronico,
        identificacion: state.identificacion,
        primerApellido: state.primerApellido,
        primerNombre: state.primerNombre,
        segundoApellido: state.segundoApellido,
        segundoNombre: state.segundoNombre,
        telefono: state.telefonoCelular,
        tipoDocumento: state.tipoDocumento?.id ?? 0,
      );

      final documentos = Documentos(
        contentType: state.tipoArchivo ?? '',
        documentos: state.contenidoArchivoBase64 ?? '',
        nombreArchivo: state.nombreArchivo ?? '',
      );

      final request = ProcedureApplicationRequest(
        ciudadano: ciudadano,
        idTramite: _taxId,
        codigoEntidad: _entityCode,
        descripcion: state.descripcion,
        documentos: documentos,
        recepcion: "Correo Electronico",
      );

      final response = await _procedureApi.insertSolicitudProcedure(request);

      if (response.estado == "true") {
        final ticket = response.ticket;
        final referencia = ticket.replaceAll(RegExp(r'\D'), '');

        // Second step: Bancolombia Gateway
        final name =
            "${state.primerNombre} ${state.segundoNombre} ${state.primerApellido} ${state.segundoApellido}"
                .trim();
        const docType = "CC"; // Hardcoded matching Kotlin

        final transactionRequest = BancolombiaGatewayRequestDTO(
          reference: referencia,
          invoice: referencia,
          municipalityCode: _entityCode,
          documentType: docType,
          identification: state.identificacion,
          name: name,
          total: int.tryParse(state.certificateValue ?? '0') ?? 0,
          taxId: state.procedureId,
          email: state.correoElectronico,
          phone: state.telefonoCelular,
          paymentSource: 2,
          implementationType: 3,
        );

        final transactionResponse = await _paymentApi.createTransaction(
          transactionRequest,
        );

        final url = transactionResponse.url ?? '';
        if (url.isNotEmpty) {
          state = state.copyWith(urlTransaction: url);
          final successState = CertificatesResponseSuccess(
            urlTransaction: url,
            reference: referencia,
          );
          ref
              .read(certificatesResponseStateProvider.notifier)
              .setSuccess(successState);
          return successState;
        } else {
          final errorMessage =
              (transactionResponse.message?.isNotEmpty ?? false)
              ? transactionResponse.message!
              : "Error al registrar la transacción";
          final errorState = CertificatesResponseError(errorMessage);
          ref
              .read(certificatesResponseStateProvider.notifier)
              .setError(errorState.message);
          return errorState;
        }
      } else {
        final errorMsg =
            (response.mensaje != null && response.mensaje!.isNotEmpty)
            ? response.mensaje!
            : "Error al crear la solicitud.";
        ref.read(certificatesResponseStateProvider.notifier).setError(errorMsg);
        return CertificatesResponseError(errorMsg);
      }
    } catch (e) {
      final errorMsg = "Error: ${e.toString()}";
      ref.read(certificatesResponseStateProvider.notifier).setError(errorMsg);
      return CertificatesResponseError(errorMsg);
    }
  }
}

class CertificatesResponseStateNotifier
    extends Notifier<CertificatesResponseState> {
  @override
  CertificatesResponseState build() => const CertificatesResponseEmpty();

  void setLoading() {
    state = const CertificatesResponseLoading();
  }

  void setSuccess(CertificatesResponseSuccess successState) {
    state = successState;
  }

  void setError(String message) {
    state = CertificatesResponseError(message);
  }

  void reset() {
    state = const CertificatesResponseEmpty();
  }
}

final certificatesResponseStateProvider =
    NotifierProvider<
      CertificatesResponseStateNotifier,
      CertificatesResponseState
    >(CertificatesResponseStateNotifier.new);

final certificatesNotifierProvider = NotifierProvider.autoDispose
    .family<CertificatesNotifier, CertificatesUiState, CertificatesFamilyParam>(
      CertificatesNotifier.new,
    );
