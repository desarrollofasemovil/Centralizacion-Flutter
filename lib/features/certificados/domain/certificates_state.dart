import '../../../core/models/tipo_documento.dart';

/// Puerto de `CertificatesUiState` (CertificatesViewModel.kt).
///
/// Los campos opcionales se limpian con sus banderas `clearX` en [copyWith]:
/// `x ?? this.x` solo no puede volver a `null` (convención del repo, ver
/// `CLAUDE.md`).
class CertificatesUiState {
  final bool isLoading;
  final TipoDocumento? tipoDocumento;
  final List<TipoDocumento> listTipoDocumento;
  final String? messageError;

  /// Mensaje bajo "Identificación" (`validateIdentificacion`).
  final String? identificacionError;

  /// Mensaje bajo "Edad" (solo `CERT_TURISMO`).
  final String? ageError;

  /// Errores por campo (`FormErrorState` del original). Los textos viven en la
  /// pantalla, como en Kotlin.
  final CertificatesFormErrorState errors;

  /// Mensaje de un adjunto rechazado; se muestra una vez (el `Toast` del
  /// original) y se limpia con `clearFileError`.
  final String? fileError;

  final String? certificateIconPath;

  /// `IDImpuesto` de la pasarela (`CrearTransaccion`).
  final int gatewayTaxId;

  /// `CERT_TURISMO`: valor por edad y tipo de documento.
  final bool isAgePriced;
  final String? titleCertificate;
  final String? certificateValue;
  final int currentStep;
  final bool isNextButtonEnabled;

  // Datos del ciudadano
  final String identificacion;
  final String primerNombre;
  final String segundoNombre;
  final String primerApellido;
  final String segundoApellido;
  final String correoElectronico;
  final String direccion;
  final String telefonoCelular;
  final String descripcion;
  final bool aceptaTratamientoDatos;
  final bool aceptaCondicionesUso;
  final String age;

  // Adjunto
  final String? nombreArchivo;
  final String? tipoArchivo;
  final String? contenidoArchivoBase64;
  final String? urlTransaction;

  /// Envío de la solicitud. Vive aquí (dentro del notifier `autoDispose.family`)
  /// y no en un provider global, para que un resultado no se cuele en el
  /// siguiente certificado que se abra.
  final CertificatesResponseState submission;

  const CertificatesUiState({
    this.isLoading = false,
    this.tipoDocumento,
    this.listTipoDocumento = const [],
    this.messageError,
    this.identificacionError,
    this.ageError,
    this.errors = const CertificatesFormErrorState(),
    this.fileError,
    this.certificateIconPath,
    required this.gatewayTaxId,
    this.isAgePriced = false,
    this.titleCertificate = '',
    this.certificateValue = '',
    this.currentStep = 1,
    this.isNextButtonEnabled = true,
    this.identificacion = '',
    this.primerNombre = '',
    this.segundoNombre = '',
    this.primerApellido = '',
    this.segundoApellido = '',
    this.correoElectronico = '',
    this.direccion = '',
    this.telefonoCelular = '',
    this.descripcion = '',
    this.aceptaTratamientoDatos = false,
    this.aceptaCondicionesUso = false,
    this.age = '',
    this.nombreArchivo,
    this.tipoArchivo,
    this.contenidoArchivoBase64,
    this.urlTransaction,
    this.submission = const CertificatesResponseEmpty(),
  });

  bool get hasFile => (nombreArchivo ?? '').isNotEmpty;

  CertificatesUiState copyWith({
    bool? isLoading,
    TipoDocumento? tipoDocumento,
    List<TipoDocumento>? listTipoDocumento,
    String? messageError,
    String? identificacionError,
    bool clearIdentificacionError = false,
    String? ageError,
    bool clearAgeError = false,
    CertificatesFormErrorState? errors,
    String? fileError,
    bool clearFileError = false,
    String? certificateIconPath,
    int? gatewayTaxId,
    bool? isAgePriced,
    String? titleCertificate,
    String? certificateValue,
    int? currentStep,
    bool? isNextButtonEnabled,
    String? identificacion,
    String? primerNombre,
    String? segundoNombre,
    String? primerApellido,
    String? segundoApellido,
    String? correoElectronico,
    String? direccion,
    String? telefonoCelular,
    String? descripcion,
    bool? aceptaTratamientoDatos,
    bool? aceptaCondicionesUso,
    String? age,
    String? nombreArchivo,
    String? tipoArchivo,
    String? contenidoArchivoBase64,
    bool clearFile = false,
    String? urlTransaction,
    bool clearUrlTransaction = false,
    CertificatesResponseState? submission,
  }) {
    return CertificatesUiState(
      isLoading: isLoading ?? this.isLoading,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      listTipoDocumento: listTipoDocumento ?? this.listTipoDocumento,
      messageError: messageError ?? this.messageError,
      identificacionError: clearIdentificacionError
          ? null
          : identificacionError ?? this.identificacionError,
      ageError: clearAgeError ? null : ageError ?? this.ageError,
      errors: errors ?? this.errors,
      fileError: clearFileError ? null : fileError ?? this.fileError,
      certificateIconPath: certificateIconPath ?? this.certificateIconPath,
      gatewayTaxId: gatewayTaxId ?? this.gatewayTaxId,
      isAgePriced: isAgePriced ?? this.isAgePriced,
      titleCertificate: titleCertificate ?? this.titleCertificate,
      certificateValue: certificateValue ?? this.certificateValue,
      currentStep: currentStep ?? this.currentStep,
      isNextButtonEnabled: isNextButtonEnabled ?? this.isNextButtonEnabled,
      identificacion: identificacion ?? this.identificacion,
      primerNombre: primerNombre ?? this.primerNombre,
      segundoNombre: segundoNombre ?? this.segundoNombre,
      primerApellido: primerApellido ?? this.primerApellido,
      segundoApellido: segundoApellido ?? this.segundoApellido,
      correoElectronico: correoElectronico ?? this.correoElectronico,
      direccion: direccion ?? this.direccion,
      telefonoCelular: telefonoCelular ?? this.telefonoCelular,
      descripcion: descripcion ?? this.descripcion,
      aceptaTratamientoDatos:
          aceptaTratamientoDatos ?? this.aceptaTratamientoDatos,
      aceptaCondicionesUso: aceptaCondicionesUso ?? this.aceptaCondicionesUso,
      age: age ?? this.age,
      nombreArchivo: clearFile ? null : nombreArchivo ?? this.nombreArchivo,
      tipoArchivo: clearFile ? null : tipoArchivo ?? this.tipoArchivo,
      contenidoArchivoBase64: clearFile
          ? null
          : contenidoArchivoBase64 ?? this.contenidoArchivoBase64,
      urlTransaction: clearUrlTransaction
          ? null
          : urlTransaction ?? this.urlTransaction,
      submission: submission ?? this.submission,
    );
  }
}

sealed class CertificatesResponseState {
  const CertificatesResponseState();
}

class CertificatesResponseEmpty extends CertificatesResponseState {
  const CertificatesResponseEmpty();
}

class CertificatesResponseLoading extends CertificatesResponseState {
  const CertificatesResponseLoading();
}

class CertificatesResponseSuccess extends CertificatesResponseState {
  final String urlTransaction;
  final String reference;

  const CertificatesResponseSuccess({
    required this.urlTransaction,
    required this.reference,
  });
}

class CertificatesResponseError extends CertificatesResponseState {
  final String message;

  const CertificatesResponseError(this.message);
}

/// Errores por campo (`FormErrorState` del original).
class CertificatesFormErrorState {
  final bool tipoDocumentoError;
  final bool identificacionError;
  final bool primerNombreError;
  final bool primerApellidoError;
  final bool correoElectronicoError;
  final bool descripcionError;
  final bool telefonoCelularError;
  final bool rangoEdadError;

  const CertificatesFormErrorState({
    this.tipoDocumentoError = false,
    this.identificacionError = false,
    this.primerNombreError = false,
    this.primerApellidoError = false,
    this.correoElectronicoError = false,
    this.descripcionError = false,
    this.telefonoCelularError = false,
    this.rangoEdadError = false,
  });

  CertificatesFormErrorState copyWith({
    bool? tipoDocumentoError,
    bool? identificacionError,
    bool? primerNombreError,
    bool? primerApellidoError,
    bool? correoElectronicoError,
    bool? descripcionError,
    bool? telefonoCelularError,
    bool? rangoEdadError,
  }) {
    return CertificatesFormErrorState(
      tipoDocumentoError: tipoDocumentoError ?? this.tipoDocumentoError,
      identificacionError: identificacionError ?? this.identificacionError,
      primerNombreError: primerNombreError ?? this.primerNombreError,
      primerApellidoError: primerApellidoError ?? this.primerApellidoError,
      correoElectronicoError:
          correoElectronicoError ?? this.correoElectronicoError,
      descripcionError: descripcionError ?? this.descripcionError,
      telefonoCelularError: telefonoCelularError ?? this.telefonoCelularError,
      rangoEdadError: rangoEdadError ?? this.rangoEdadError,
    );
  }
}
