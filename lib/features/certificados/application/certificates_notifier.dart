import 'package:dio/dio.dart';
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
import '../../../core/utils/validators.dart';
import '../../auth/application/auth_providers.dart';
import '../../pagos/application/payment_history_registration.dart';
import '../domain/certificate_attachment.dart';
import '../domain/certificate_procedure.dart';
import '../domain/certificates_state.dart';

const _minIdentificacionLength = 4;
const _maxIdentificacionLength = 20;

/// Documentos de extranjero para el precio de `CERT_TURISMO`
/// (`isForeignDocument` del original).
const _foreignDocuments = {
  'pasaporte',
  'cédula de extranjería',
  'ce',
  'pp',
  'permiso especial de permanencia',
  'visa',
};

class CertificatesFamilyParam {
  final CertificateProcedure certificate;

  const CertificatesFamilyParam({required this.certificate});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CertificatesFamilyParam && certificate == other.certificate;

  @override
  int get hashCode => certificate.hashCode;
}

/// Puerto de `CertificatesViewModel.kt`.
class CertificatesNotifier extends Notifier<CertificatesUiState> {
  final CertificatesFamilyParam familyParam;
  CertificatesNotifier(this.familyParam);

  PqrdApiService get _pqrdApi => ref.read(pqrdApiServiceProvider);
  ProcedureApplicationApiService get _procedureApi =>
      ref.read(procedureApplicationApiServiceProvider);
  PaymentApiService get _paymentApi => ref.read(paymentApiServiceProvider);
  RemoteConfigService get _remoteConfig =>
      ref.read(remoteConfigServiceProvider);

  CertificateProcedure get _certificate => familyParam.certificate;
  String get _entityCode => _certificate.entityCode;

  @override
  CertificatesUiState build() {
    Future.microtask(loadDocumentTypes);

    return CertificatesUiState(
      gatewayTaxId: _certificate.gatewayTaxId,
      isAgePriced: _certificate.isAgePriced,
      titleCertificate: _certificate.title,
      certificateIconPath: _certificate.iconPath,
      certificateValue: _certificate.value,
    );
  }

  Future<void> loadDocumentTypes() async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _pqrdApi.listTipoDocumento(_entityCode);
      if (!ref.mounted) return;
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
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        messageError: "Error al cargar los tipos de documento",
      );
    }
  }

  /// Llena los datos de la sesión. El tipo de documento solo se elige si
  /// coincide con uno del catálogo (sin tildes ni mayúsculas); si no, queda
  /// sin elegir, como en el original (antes caía en el primero de la lista y
  /// se podía radicar con un tipo equivocado).
  void autofillUserData(UserDTO user) {
    final wanted = normalizeForMatch(user.documentType.name);
    TipoDocumento? userDocumentType;
    for (final tipo in state.listTipoDocumento) {
      if (normalizeForMatch(tipo.descripcion) == wanted) {
        userDocumentType = tipo;
        break;
      }
    }

    state = state.copyWith(
      identificacion: user.nationalId,
      primerNombre: user.firstName,
      segundoNombre: user.middleName ?? '',
      primerApellido: user.lastName,
      segundoApellido: user.secondLastName ?? '',
      correoElectronico: user.email,
      direccion: user.address,
      telefonoCelular: user.phoneNumber,
      tipoDocumento: userDocumentType,
    );
  }

  bool _isForeignDocument(String? description) =>
      description != null &&
      _foreignDocuments.contains(description.trim().toLowerCase());

  void calculateCertificateValue() {
    final isTourismCertificate = state.isAgePriced;
    if (!isTourismCertificate || state.tipoDocumento == null) {
      if (isTourismCertificate) {
        state = state.copyWith(certificateValue: "0");
      }
      return;
    }

    final ageInt = int.tryParse(state.age);
    if (ageInt == null) {
      state = state.copyWith(certificateValue: "0");
      return;
    }

    final isForeign = _isForeignDocument(state.tipoDocumento!.descripcion);
    final taxRates = _remoteConfig.getTourismTaxRates();
    final rates = isForeign ? taxRates.foreign : taxRates.national;

    final int newCertificateValue;
    if (ageInt >= 0 && ageInt <= 6) {
      newCertificateValue = 0;
    } else if (ageInt >= 7 && ageInt <= 14) {
      newCertificateValue = rates.child_7_14;
    } else if (ageInt >= 15 && ageInt <= 17) {
      newCertificateValue = rates.teen_15_17;
    } else {
      newCertificateValue = rates.adult;
    }

    state = state.copyWith(certificateValue: newCertificateValue.toString());
  }

  void onIdentificacionChange(String value) {
    state = state.copyWith(identificacion: value);
    validateIdentificacion(value);
  }

  /// Valida y deja el mensaje en `identificacionError`. Devuelve el mensaje.
  String? validateIdentificacion(String identificacion) {
    String? error;
    if (identificacion.trim().isEmpty) {
      error = "Por favor, introduce un documento.";
    } else if (identificacion.length < _minIdentificacionLength) {
      error =
          "La identificación debe tener al menos $_minIdentificacionLength caracteres.";
    } else if (identificacion.length > _maxIdentificacionLength) {
      error =
          "La identificación no puede exceder los $_maxIdentificacionLength caracteres.";
    }
    state = state.copyWith(
      identificacionError: error,
      clearIdentificacionError: error == null,
      errors: state.errors.copyWith(identificacionError: error != null),
    );
    return error;
  }

  void onTipoDocumentoChange(TipoDocumento tipoDocumento) {
    state = state.copyWith(
      isNextButtonEnabled: true,
      tipoDocumento: tipoDocumento,
      errors: state.errors.copyWith(tipoDocumentoError: false),
    );
    calculateCertificateValue();
  }

  void onPrimerNombreChange(String value) {
    state = state.copyWith(
      isNextButtonEnabled: true,
      primerNombre: value,
      errors: state.errors.copyWith(primerNombreError: false),
    );
  }

  void onSegundoNombreChange(String value) {
    state = state.copyWith(segundoNombre: value);
  }

  void onPrimerApellidoChange(String value) {
    state = state.copyWith(
      isNextButtonEnabled: true,
      primerApellido: value,
      errors: state.errors.copyWith(primerApellidoError: false),
    );
  }

  void onSegundoApellidoChange(String value) {
    state = state.copyWith(segundoApellido: value);
  }

  void correoElectronicoChange(String value) {
    state = state.copyWith(
      isNextButtonEnabled: true,
      correoElectronico: value,
      errors: state.errors.copyWith(correoElectronicoError: false),
    );
  }

  void onDireccionChange(String value) {
    state = state.copyWith(isNextButtonEnabled: true, direccion: value);
  }

  void onTelefonoCelularChange(String value) {
    state = state.copyWith(
      isNextButtonEnabled: true,
      telefonoCelular: value,
      errors: state.errors.copyWith(telefonoCelularError: false),
    );
  }

  void onAgeChange(String value) {
    final filtered = value.replaceAll(RegExp(r'\D'), '');
    state = state.copyWith(age: filtered);

    if (state.isAgePriced) {
      state = state.copyWith(
        clearAgeError: true,
        errors: state.errors.copyWith(rangoEdadError: false),
      );
      calculateCertificateValue();
    }
  }

  void onDescripcionChange(String value) {
    state = state.copyWith(
      isNextButtonEnabled: true,
      descripcion: value,
      errors: value.trim().isNotEmpty
          ? state.errors.copyWith(descripcionError: false)
          : null,
    );
  }

  void onTratamientoDatosAcepted(bool value) {
    state = state.copyWith(aceptaTratamientoDatos: value);
  }

  void onCondicionesUsoAcepted(bool value) {
    state = state.copyWith(aceptaCondicionesUso: value);
  }

  /// Valida y adjunta un archivo. [readBase64] lee el contenido real en base64
  /// (la pantalla lo hace fuera del hilo de la UI); solo se llama si el archivo
  /// pasa la validación de tipo y tamaño.
  Future<void> attachFile({
    required String fileName,
    required int sizeBytes,
    required Future<String> Function() readBase64,
  }) async {
    final check = checkCertificateAttachment(
      fileName: fileName,
      sizeBytes: sizeBytes,
    );
    switch (check) {
      case AttachmentRejected(:final message):
        state = state.copyWith(fileError: message);
        return;
      case AttachmentAccepted(:final mimeType):
        try {
          final base64 = await readBase64();
          if (!ref.mounted) return;
          state = state.copyWith(
            nombreArchivo: fileName,
            tipoArchivo: mimeType,
            contenidoArchivoBase64: base64,
            clearFileError: true,
          );
        } catch (_) {
          if (!ref.mounted) return;
          state = state.copyWith(fileError: kAttachmentProcessError);
        }
    }
  }

  void onFilePickFailed() {
    state = state.copyWith(fileError: kAttachmentProcessError);
  }

  void clearFile() {
    state = state.copyWith(clearFile: true);
  }

  void clearFileError() {
    state = state.copyWith(clearFileError: true);
  }

  bool validateStep1() {
    var ageError = false;

    if (state.isAgePriced) {
      final ageInt = int.tryParse(state.age);
      String? ageErrorMsg;
      if (state.age.trim().isEmpty) {
        ageErrorMsg = "La edad es requerida.";
      } else if (ageInt == null || ageInt < 0 || ageInt > 120) {
        ageErrorMsg = "Por favor, introduce una edad válida (0-120).";
      }
      ageError = ageErrorMsg != null;
      state = state.copyWith(
        ageError: ageErrorMsg,
        clearAgeError: ageErrorMsg == null,
      );
      calculateCertificateValue();
    } else {
      // Los demás certificados no llevan edad.
      state = state.copyWith(age: '', clearAgeError: true);
    }

    final errors = state.errors.copyWith(
      tipoDocumentoError: state.tipoDocumento == null,
      identificacionError: state.identificacion.trim().isEmpty,
      primerNombreError: state.primerNombre.trim().isEmpty,
      primerApellidoError: state.primerApellido.trim().isEmpty,
      rangoEdadError: ageError,
    );
    state = state.copyWith(errors: errors);

    return !errors.tipoDocumentoError &&
        !errors.identificacionError &&
        !errors.primerNombreError &&
        !errors.primerApellidoError &&
        !ageError;
  }

  bool validateStep2() {
    final isEmailValid = isValidEmail(state.correoElectronico);
    final isPhoneValid =
        state.telefonoCelular.trim().isNotEmpty &&
        state.telefonoCelular.length == 10;

    final errors = state.errors.copyWith(
      correoElectronicoError:
          state.correoElectronico.trim().isEmpty || !isEmailValid,
      descripcionError: state.descripcion.trim().isEmpty,
      telefonoCelularError: !isPhoneValid,
    );
    state = state.copyWith(errors: errors);

    return !errors.correoElectronicoError &&
        !errors.descripcionError &&
        !errors.telefonoCelularError;
  }

  void onNextStep() {
    final identificacionError = validateIdentificacion(state.identificacion);
    if (state.currentStep == 1) {
      if (validateStep1() && identificacionError == null) {
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

  void resetSubmission() {
    state = state.copyWith(submission: const CertificatesResponseEmpty());
  }

  /// `InsertarSolicitudTramite` → registro en el historial (best-effort) →
  /// `Pasarela/CrearTransaccion`, en ese orden. El resultado queda en
  /// `state.submission`.
  Future<void> submitSolicitudTramite() async {
    if (state.submission is CertificatesResponseLoading) return;
    if (!state.aceptaTratamientoDatos) {
      state = state.copyWith(
        submission: const CertificatesResponseError(
          "Debes aceptar la política de tratamiento de datos.",
        ),
      );
      return;
    }
    if (!state.aceptaCondicionesUso) {
      state = state.copyWith(
        submission: const CertificatesResponseError(
          "Debes aceptar las condiciones de uso y políticas de privacidad.",
        ),
      );
      return;
    }

    state = state.copyWith(submission: const CertificatesResponseLoading());
    final result = await _submit(state);
    if (!ref.mounted) return;
    if (result is CertificatesResponseSuccess) {
      state = state.copyWith(urlTransaction: result.urlTransaction);
    }
    state = state.copyWith(submission: result);
  }

  Future<CertificatesResponseState> _submit(CertificatesUiState form) async {
    final String referencia;
    try {
      final response = await _procedureApi.insertSolicitudProcedure(
        ProcedureApplicationRequest(
          ciudadano: Ciudadano(
            direccion: form.direccion,
            email: form.correoElectronico,
            identificacion: form.identificacion,
            primerApellido: form.primerApellido,
            primerNombre: form.primerNombre,
            segundoApellido: form.segundoApellido,
            segundoNombre: form.segundoNombre,
            telefono: form.telefonoCelular,
            tipoDocumento: form.tipoDocumento?.id ?? 0,
          ),
          idTramite: _certificate.externalId,
          codigoEntidad: _entityCode,
          descripcion: form.descripcion,
          // Contenido real en base64; sin archivo, textos vacíos (el original
          // mandaba `ByteArray.toString()` y "null").
          documentos: Documentos(
            contentType: form.tipoArchivo ?? '',
            documentos: form.contenidoArchivoBase64 ?? '',
            nombreArchivo: form.nombreArchivo ?? '',
          ),
          recepcion: "Correo Electronico",
        ),
      );
      if (!response.estado) {
        final mensaje = response.mensaje;
        return CertificatesResponseError(
          (mensaje != null && mensaje.isNotEmpty)
              ? mensaje
              : "Error al crear la solicitud.",
        );
      }
      referencia = response.ticket.replaceAll(RegExp(r'\D'), '');
    } on DioException catch (e) {
      // Respuesta HTTP no exitosa: el original no tiene cuerpo que leer.
      if (e.response != null) {
        return const CertificatesResponseError("Error al crear la solicitud.");
      }
      return CertificatesResponseError("Error: ${e.message}");
    } catch (e) {
      return CertificatesResponseError("Error: $e");
    }

    final total = int.tryParse(form.certificateValue ?? '0') ?? 0;

    // Historial de pago antes de la transacción (decisión de Brayan: mismo
    // registro que impuestos y PSV). Sin sesión no hay a quién asociarlo.
    if (ref.read(sessionProvider) != null) {
      await registerPaymentHistory(
        ref,
        amount: total,
        idImpuesto: form.gatewayTaxId.toString(),
        factura: referencia,
        codigoEntidad: _entityCode,
        municipalityProceduresId: _certificate.municipalityProcedureId,
      );
      if (!ref.mounted) return const CertificatesResponseEmpty();
    }

    try {
      final name =
          "${form.primerNombre} ${form.segundoNombre} ${form.primerApellido} ${form.segundoApellido}"
              .trim();
      final transaction = await _paymentApi.createTransaction(
        BancolombiaGatewayRequestDTO(
          reference: referencia,
          invoice: referencia,
          municipalityCode: _entityCode,
          documentType: "CC", // Fijo, como en el original.
          identification: form.identificacion,
          name: name,
          total: total,
          taxId: form.gatewayTaxId,
          email: form.correoElectronico,
          phone: form.telefonoCelular,
          paymentSource: 2,
          implementationType: 3,
        ),
      );
      final url = transaction.url ?? '';
      if (url.isEmpty) {
        return CertificatesResponseError(
          "Error al registrar la transacción: ${transaction.message ?? ''}"
              .trim(),
        );
      }
      return CertificatesResponseSuccess(
        urlTransaction: url,
        reference: referencia,
      );
    } on DioException catch (e) {
      if (e.response != null) {
        return CertificatesResponseError(
          "Error al registrar la transacción: ${e.response?.statusMessage ?? ''}"
              .trim(),
        );
      }
      return CertificatesResponseError("Error: ${e.message}");
    } catch (e) {
      return CertificatesResponseError("Error: $e");
    }
  }
}

final certificatesNotifierProvider = NotifierProvider.autoDispose
    .family<CertificatesNotifier, CertificatesUiState, CertificatesFamilyParam>(
      CertificatesNotifier.new,
    );
