import 'support_enums.dart';

/// Estado de UI + formulario de la pantalla de Ayuda. Port de `SupportFormState.kt`
/// (`HelpUiState`, `SupportFormState`, `CategoryFormData`).
///
/// Adaptación respecto al original: los errores por campo se guardan planos en
/// cada `CategoryFormData` (con flags `clearX` en `copyWith`) en vez de objetos
/// de errores anidados, siguiendo el idiom de `courses_state.dart`.

// ---------------------------------------------------------------------------
// Estado global de la pantalla (uiState) — sella los diálogos Success/Error.
// ---------------------------------------------------------------------------
sealed class HelpUiState {
  const HelpUiState();
}

class HelpIdle extends HelpUiState {
  const HelpIdle();
}

class HelpLoading extends HelpUiState {
  const HelpLoading();
}

class HelpUnauthenticated extends HelpUiState {
  const HelpUnauthenticated();
}

class HelpSuccess extends HelpUiState {
  final String message;
  const HelpSuccess(this.message);
}

class HelpError extends HelpUiState {
  final String message;
  final bool isRetryable;
  const HelpError(this.message, this.isRetryable);
}

// ---------------------------------------------------------------------------
// Pasos del wizard.
// ---------------------------------------------------------------------------
enum FormStep { selectCategory, fillDetails }

// ---------------------------------------------------------------------------
// Datos del formulario por categoría.
// ---------------------------------------------------------------------------
sealed class CategoryFormData {
  const CategoryFormData();
}

class EmptyCategory extends CategoryFormData {
  const EmptyCategory();
}

class OtherCategory extends CategoryFormData {
  const OtherCategory();
}

class PaymentIssueData extends CategoryFormData {
  final TaxConcept? taxConcept;
  final PaymentIssueType? issueType;
  final PaymentMethod? paymentMethod;
  final String paymentDate;
  final String amountPaid;
  final String voucherReference;
  final String? taxConceptError;
  final String? issueTypeError;
  final String? paymentMethodError;
  final String? paymentDateError;
  final String? amountPaidError;
  final String? voucherReferenceError;

  const PaymentIssueData({
    this.taxConcept,
    this.issueType,
    this.paymentMethod,
    this.paymentDate = '',
    this.amountPaid = '',
    this.voucherReference = '',
    this.taxConceptError,
    this.issueTypeError,
    this.paymentMethodError,
    this.paymentDateError,
    this.amountPaidError,
    this.voucherReferenceError,
  });

  PaymentIssueData copyWith({
    TaxConcept? taxConcept,
    PaymentIssueType? issueType,
    PaymentMethod? paymentMethod,
    String? paymentDate,
    String? amountPaid,
    String? voucherReference,
    String? taxConceptError,
    String? issueTypeError,
    String? paymentMethodError,
    String? paymentDateError,
    String? amountPaidError,
    String? voucherReferenceError,
    bool clearTaxConceptError = false,
    bool clearIssueTypeError = false,
    bool clearPaymentMethodError = false,
    bool clearPaymentDateError = false,
    bool clearAmountPaidError = false,
    bool clearVoucherReferenceError = false,
  }) {
    return PaymentIssueData(
      taxConcept: taxConcept ?? this.taxConcept,
      issueType: issueType ?? this.issueType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      amountPaid: amountPaid ?? this.amountPaid,
      voucherReference: voucherReference ?? this.voucherReference,
      taxConceptError:
          clearTaxConceptError ? null : (taxConceptError ?? this.taxConceptError),
      issueTypeError:
          clearIssueTypeError ? null : (issueTypeError ?? this.issueTypeError),
      paymentMethodError: clearPaymentMethodError
          ? null
          : (paymentMethodError ?? this.paymentMethodError),
      paymentDateError: clearPaymentDateError
          ? null
          : (paymentDateError ?? this.paymentDateError),
      amountPaidError:
          clearAmountPaidError ? null : (amountPaidError ?? this.amountPaidError),
      voucherReferenceError: clearVoucherReferenceError
          ? null
          : (voucherReferenceError ?? this.voucherReferenceError),
    );
  }
}

class PaymentInquiryData extends CategoryFormData {
  final TaxConcept? taxConcept;
  final InquiryType? inquiryType;
  final String taxableEntityId;
  final String fiscalYear;
  final String? taxConceptError;
  final String? inquiryTypeError;
  final String? taxableEntityIdError;
  final String? fiscalYearError;

  const PaymentInquiryData({
    this.taxConcept,
    this.inquiryType,
    this.taxableEntityId = '',
    this.fiscalYear = '',
    this.taxConceptError,
    this.inquiryTypeError,
    this.taxableEntityIdError,
    this.fiscalYearError,
  });

  PaymentInquiryData copyWith({
    TaxConcept? taxConcept,
    InquiryType? inquiryType,
    String? taxableEntityId,
    String? fiscalYear,
    String? taxConceptError,
    String? inquiryTypeError,
    String? taxableEntityIdError,
    String? fiscalYearError,
    bool clearTaxConceptError = false,
    bool clearInquiryTypeError = false,
    bool clearTaxableEntityIdError = false,
    bool clearFiscalYearError = false,
  }) {
    return PaymentInquiryData(
      taxConcept: taxConcept ?? this.taxConcept,
      inquiryType: inquiryType ?? this.inquiryType,
      taxableEntityId: taxableEntityId ?? this.taxableEntityId,
      fiscalYear: fiscalYear ?? this.fiscalYear,
      taxConceptError:
          clearTaxConceptError ? null : (taxConceptError ?? this.taxConceptError),
      inquiryTypeError:
          clearInquiryTypeError ? null : (inquiryTypeError ?? this.inquiryTypeError),
      taxableEntityIdError: clearTaxableEntityIdError
          ? null
          : (taxableEntityIdError ?? this.taxableEntityIdError),
      fiscalYearError:
          clearFiscalYearError ? null : (fiscalYearError ?? this.fiscalYearError),
    );
  }
}

class TechnicalErrorData extends CategoryFormData {
  final String screenName;
  final String attemptedAction;
  final String errorMessage;
  final ErrorFrequency? frequency;
  final String? screenNameError;
  final String? attemptedActionError;
  final String? frequencyError;

  const TechnicalErrorData({
    this.screenName = '',
    this.attemptedAction = '',
    this.errorMessage = '',
    this.frequency,
    this.screenNameError,
    this.attemptedActionError,
    this.frequencyError,
  });

  TechnicalErrorData copyWith({
    String? screenName,
    String? attemptedAction,
    String? errorMessage,
    ErrorFrequency? frequency,
    String? screenNameError,
    String? attemptedActionError,
    String? frequencyError,
    bool clearScreenNameError = false,
    bool clearAttemptedActionError = false,
    bool clearFrequencyError = false,
  }) {
    return TechnicalErrorData(
      screenName: screenName ?? this.screenName,
      attemptedAction: attemptedAction ?? this.attemptedAction,
      errorMessage: errorMessage ?? this.errorMessage,
      frequency: frequency ?? this.frequency,
      screenNameError:
          clearScreenNameError ? null : (screenNameError ?? this.screenNameError),
      attemptedActionError: clearAttemptedActionError
          ? null
          : (attemptedActionError ?? this.attemptedActionError),
      frequencyError:
          clearFrequencyError ? null : (frequencyError ?? this.frequencyError),
    );
  }
}

class InformationRequestData extends CategoryFormData {
  final InformationType? requestType;
  final TaxConcept? taxConcept;
  final String? requestTypeError;

  const InformationRequestData({
    this.requestType,
    this.taxConcept,
    this.requestTypeError,
  });

  InformationRequestData copyWith({
    InformationType? requestType,
    TaxConcept? taxConcept,
    String? requestTypeError,
    bool clearRequestTypeError = false,
  }) {
    return InformationRequestData(
      requestType: requestType ?? this.requestType,
      taxConcept: taxConcept ?? this.taxConcept,
      requestTypeError:
          clearRequestTypeError ? null : (requestTypeError ?? this.requestTypeError),
    );
  }
}

// ---------------------------------------------------------------------------
// Estado del formulario.
// ---------------------------------------------------------------------------
class SupportFormState {
  final FormStep step;
  final String? selectedCategoryCode;
  final CategoryFormData categoryData;
  final String freeText;
  final String? freeTextError;
  final bool isSubmitting;

  const SupportFormState({
    this.step = FormStep.selectCategory,
    this.selectedCategoryCode,
    this.categoryData = const EmptyCategory(),
    this.freeText = '',
    this.freeTextError,
    this.isSubmitting = false,
  });

  SupportFormState copyWith({
    FormStep? step,
    String? selectedCategoryCode,
    CategoryFormData? categoryData,
    String? freeText,
    String? freeTextError,
    bool? isSubmitting,
    bool clearSelectedCategoryCode = false,
    bool clearFreeTextError = false,
  }) {
    return SupportFormState(
      step: step ?? this.step,
      selectedCategoryCode: clearSelectedCategoryCode
          ? null
          : (selectedCategoryCode ?? this.selectedCategoryCode),
      categoryData: categoryData ?? this.categoryData,
      freeText: freeText ?? this.freeText,
      freeTextError:
          clearFreeTextError ? null : (freeTextError ?? this.freeTextError),
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

// ---------------------------------------------------------------------------
// Estado combinado (uiState + formState) expuesto por el notifier.
// ---------------------------------------------------------------------------
class HelpState {
  final HelpUiState uiState;
  final SupportFormState formState;

  const HelpState({
    this.uiState = const HelpIdle(),
    this.formState = const SupportFormState(),
  });

  HelpState copyWith({
    HelpUiState? uiState,
    SupportFormState? formState,
  }) {
    return HelpState(
      uiState: uiState ?? this.uiState,
      formState: formState ?? this.formState,
    );
  }
}
