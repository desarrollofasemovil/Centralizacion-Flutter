import 'support_enums.dart';

/// Modelo central del dominio. Representa una solicitud de soporte estructurada.
/// Port de `domain/model/SupportRequest.kt` + `UserSupportContext.kt`.
class SupportRequest {
  final SupportCategory category;
  final UserSupportContext userContext;
  final String freeText;

  const SupportRequest({
    required this.category,
    required this.userContext,
    required this.freeText,
  });
}

/// Datos del usuario y su sesión, inyectados automáticamente en la solicitud.
class UserSupportContext {
  // Identidad del usuario
  final String fullName;
  final String email;
  final String nationalId;
  final String documentTypeName;
  final String? phoneNumber;
  final String address;

  // Contexto de navegación / negocio
  final String municipality;
  final String? department;
  final int? fixedMunicipalityId;
  final int? lastMunicipalityId;

  // Metadata técnica (útil para debugging de errores técnicos)
  final String appVersion;
  final String deviceModel;
  final String platformVersion;
  final int timestamp;

  const UserSupportContext({
    required this.fullName,
    required this.email,
    required this.nationalId,
    required this.documentTypeName,
    this.phoneNumber,
    required this.address,
    required this.municipality,
    this.department,
    required this.fixedMunicipalityId,
    required this.lastMunicipalityId,
    required this.appVersion,
    required this.deviceModel,
    required this.platformVersion,
    required this.timestamp,
  });
}

/// Categoría del problema. Determina qué campos contextuales están presentes.
/// Equivalente al `sealed class SupportCategory` de Kotlin.
sealed class SupportCategory {
  const SupportCategory();

  String get code;
  String get displayName;
}

class SupportPaymentIssue extends SupportCategory {
  final TaxConcept taxConcept;
  final String paymentDate; // dd/MM/yyyy
  final PaymentMethod paymentMethod;
  final String voucherReference;
  final String amountPaid;
  final PaymentIssueType issueType;

  const SupportPaymentIssue({
    required this.taxConcept,
    required this.paymentDate,
    required this.paymentMethod,
    required this.voucherReference,
    required this.amountPaid,
    required this.issueType,
  });

  @override
  String get code => 'PAYMENT_ISSUE';
  @override
  String get displayName => 'Problema con un pago realizado';
}

class SupportPaymentInquiry extends SupportCategory {
  final TaxConcept taxConcept;
  final String taxableEntityId;
  final String fiscalYear;
  final InquiryType inquiryType;

  const SupportPaymentInquiry({
    required this.taxConcept,
    required this.taxableEntityId,
    required this.fiscalYear,
    required this.inquiryType,
  });

  @override
  String get code => 'PAYMENT_INQUIRY';
  @override
  String get displayName => 'Duda sobre un valor a pagar';
}

class SupportTechnicalError extends SupportCategory {
  final String screenName;
  final String attemptedAction;
  final String? errorMessage;
  final ErrorFrequency frequency;

  const SupportTechnicalError({
    required this.screenName,
    required this.attemptedAction,
    required this.errorMessage,
    required this.frequency,
  });

  @override
  String get code => 'TECHNICAL_ERROR';
  @override
  String get displayName => 'Error técnico en la aplicación';
}

class SupportInformationRequest extends SupportCategory {
  final InformationType requestType;
  final TaxConcept? taxConcept;

  const SupportInformationRequest({
    required this.requestType,
    required this.taxConcept,
  });

  @override
  String get code => 'INFORMATION_REQUEST';
  @override
  String get displayName => 'Solicitud de información o trámite';
}

class SupportOther extends SupportCategory {
  const SupportOther();

  @override
  String get code => 'OTHER';
  @override
  String get displayName => 'Otro';
}
