import '../../../core/models/tipo_documento.dart';

class CertificatesUiState {
  final bool isLoading;
  final TipoDocumento? tipoDocumento;
  final List<TipoDocumento> listTipoDocumento;
  final bool isValidationError;
  final String? messageError;
  final String? identificacionError;
  final String? ageError;
  final String? certificateIconPath;
  final int? idCertificate;
  final int procedureId;
  final String? titleCertificate;
  final String? certificateValue;
  final int currentStep;
  final bool isNextButtonEnabled;
  final bool showConfirmationSheet;

  // User Data
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

  // File Info
  final String? nombreArchivo;
  final String? tipoArchivo;
  final String? contenidoArchivoBase64;
  final String? urlTransaction;

  const CertificatesUiState({
    this.isLoading = false,
    this.tipoDocumento,
    this.listTipoDocumento = const [],
    this.isValidationError = false,
    this.messageError = '',
    this.identificacionError,
    this.ageError,
    this.certificateIconPath,
    this.idCertificate = 0,
    required this.procedureId,
    this.titleCertificate = '',
    this.certificateValue = '',
    this.currentStep = 1,
    this.isNextButtonEnabled = true,
    this.showConfirmationSheet = false,
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
  });

  CertificatesUiState copyWith({
    bool? isLoading,
    TipoDocumento? tipoDocumento,
    List<TipoDocumento>? listTipoDocumento,
    bool? isValidationError,
    String? messageError,
    String? identificacionError,
    String? ageError,
    String? certificateIconPath,
    int? idCertificate,
    int? procedureId,
    String? titleCertificate,
    String? certificateValue,
    int? currentStep,
    bool? isNextButtonEnabled,
    bool? showConfirmationSheet,
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
    String? urlTransaction,
  }) {
    return CertificatesUiState(
      isLoading: isLoading ?? this.isLoading,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      listTipoDocumento: listTipoDocumento ?? this.listTipoDocumento,
      isValidationError: isValidationError ?? this.isValidationError,
      messageError: messageError ?? this.messageError,
      identificacionError: identificacionError ?? this.identificacionError,
      ageError: ageError ?? this.ageError,
      certificateIconPath: certificateIconPath ?? this.certificateIconPath,
      idCertificate: idCertificate ?? this.idCertificate,
      procedureId: procedureId ?? this.procedureId,
      titleCertificate: titleCertificate ?? this.titleCertificate,
      certificateValue: certificateValue ?? this.certificateValue,
      currentStep: currentStep ?? this.currentStep,
      isNextButtonEnabled: isNextButtonEnabled ?? this.isNextButtonEnabled,
      showConfirmationSheet: showConfirmationSheet ?? this.showConfirmationSheet,
      identificacion: identificacion ?? this.identificacion,
      primerNombre: primerNombre ?? this.primerNombre,
      segundoNombre: segundoNombre ?? this.segundoNombre,
      primerApellido: primerApellido ?? this.primerApellido,
      segundoApellido: segundoApellido ?? this.segundoApellido,
      correoElectronico: correoElectronico ?? this.correoElectronico,
      direccion: direccion ?? this.direccion,
      telefonoCelular: telefonoCelular ?? this.telefonoCelular,
      descripcion: descripcion ?? this.descripcion,
      aceptaTratamientoDatos: aceptaTratamientoDatos ?? this.aceptaTratamientoDatos,
      aceptaCondicionesUso: aceptaCondicionesUso ?? this.aceptaCondicionesUso,
      age: age ?? this.age,
      nombreArchivo: nombreArchivo ?? this.nombreArchivo,
      tipoArchivo: tipoArchivo ?? this.tipoArchivo,
      contenidoArchivoBase64: contenidoArchivoBase64 ?? this.contenidoArchivoBase64,
      urlTransaction: urlTransaction ?? this.urlTransaction,
    );
  }
}

abstract class CertificatesResponseState {
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

class CertificatesFormErrorState {
  final bool tipoDocumentoError;
  final bool identificacionError;
  final bool primerNombreError;
  final bool primerApellidoError;
  final bool correoElectronicoError;
  final bool descripcionError;
  final bool telefonoCelularError;
  final bool rangoEdadError;
  final String? tipoArchivoError;

  const CertificatesFormErrorState({
    this.tipoDocumentoError = false,
    this.identificacionError = false,
    this.primerNombreError = false,
    this.primerApellidoError = false,
    this.correoElectronicoError = false,
    this.descripcionError = false,
    this.telefonoCelularError = false,
    this.rangoEdadError = false,
    this.tipoArchivoError,
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
    String? tipoArchivoError,
  }) {
    return CertificatesFormErrorState(
      tipoDocumentoError: tipoDocumentoError ?? this.tipoDocumentoError,
      identificacionError: identificacionError ?? this.identificacionError,
      primerNombreError: primerNombreError ?? this.primerNombreError,
      primerApellidoError: primerApellidoError ?? this.primerApellidoError,
      correoElectronicoError: correoElectronicoError ?? this.correoElectronicoError,
      descripcionError: descripcionError ?? this.descripcionError,
      telefonoCelularError: telefonoCelularError ?? this.telefonoCelularError,
      rangoEdadError: rangoEdadError ?? this.rangoEdadError,
      tipoArchivoError: tipoArchivoError ?? this.tipoArchivoError,
    );
  }
}
