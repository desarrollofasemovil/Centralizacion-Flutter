import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/flavor/flavor_config.dart';
import '../../../core/models/user_dto.dart';
import '../../auth/application/auth_providers.dart';
import '../data/support_repository.dart';
import '../domain/help_state.dart';
import '../domain/support_enums.dart';
import '../domain/support_request.dart';
import '../domain/support_submission_result.dart';

/// Lógica de la pantalla de Ayuda. Port de `HelpViewModel.kt`.
///
/// Familia por nombre de municipio (para el asunto/contexto del correo).
///
/// Desviación cross-platform respecto al original: la metadata técnica del
/// correo (dispositivo/sistema) se toma de `dart:io` `Platform` en vez de
/// `Build.*`, para no añadir plugins nativos (`device_info_plus`/
/// `package_info_plus`). La versión de app queda como constante hasta cablear
/// `package_info_plus`.
class HelpNotifier extends Notifier<HelpState> {
  HelpNotifier(this.municipality);

  final String municipality;

  // TODO(soporte): cablear package_info_plus para la versión real de la app.
  static const String _appVersion = '1.0.0';

  SupportRepository get _repo => ref.read(supportRepositoryProvider);

  @override
  HelpState build() {
    // Reacciona a login/logout mientras la pantalla está abierta, sin pisar los
    // estados transitorios (Loading/Success/Error).
    ref.listen<UserDTO?>(sessionProvider, (_, next) {
      final authed = next != null && next.loginStatus;
      if (state.uiState is HelpUnauthenticated && authed) {
        state = state.copyWith(uiState: const HelpIdle());
      } else if (state.uiState is HelpIdle && !authed) {
        state = state.copyWith(uiState: const HelpUnauthenticated());
      }
    });

    final user = ref.read(sessionProvider);
    final authed = user != null && user.loginStatus;
    return HelpState(
      uiState: authed ? const HelpIdle() : const HelpUnauthenticated(),
    );
  }

  SupportFormState get _form => state.formState;

  void _setForm(SupportFormState next) =>
      state = state.copyWith(formState: next);

  // ---------------------------------------------------------------------------
  // Navegación del wizard
  // ---------------------------------------------------------------------------
  void selectCategory(String categoryCode) {
    final CategoryFormData initial = switch (categoryCode) {
      'PAYMENT_ISSUE' => const PaymentIssueData(),
      'PAYMENT_INQUIRY' => const PaymentInquiryData(),
      'TECHNICAL_ERROR' => const TechnicalErrorData(),
      'INFORMATION_REQUEST' => const InformationRequestData(),
      'OTHER' => const OtherCategory(),
      _ => const EmptyCategory(),
    };
    // No limpiar freeText: si el usuario ya escribió algo y cambia de categoría
    // no queremos perderlo.
    _setForm(_form.copyWith(
      step: FormStep.fillDetails,
      selectedCategoryCode: categoryCode,
      categoryData: initial,
    ));
  }

  void goBackToCategorySelection() {
    _setForm(_form.copyWith(
      step: FormStep.selectCategory,
      clearSelectedCategoryCode: true,
      categoryData: const EmptyCategory(),
    ));
  }

  void onFreeTextChanged(String text) {
    _setForm(_form.copyWith(freeText: text, clearFreeTextError: true));
  }

  // ---------------------------------------------------------------------------
  // Setters de campos (limpian el error del propio campo)
  // ---------------------------------------------------------------------------
  void _updatePaymentIssue(PaymentIssueData Function(PaymentIssueData) fn) {
    final d = _form.categoryData;
    if (d is PaymentIssueData) _setForm(_form.copyWith(categoryData: fn(d)));
  }

  void _updatePaymentInquiry(
      PaymentInquiryData Function(PaymentInquiryData) fn) {
    final d = _form.categoryData;
    if (d is PaymentInquiryData) _setForm(_form.copyWith(categoryData: fn(d)));
  }

  void _updateTechnicalError(
      TechnicalErrorData Function(TechnicalErrorData) fn) {
    final d = _form.categoryData;
    if (d is TechnicalErrorData) _setForm(_form.copyWith(categoryData: fn(d)));
  }

  void _updateInformationRequest(
      InformationRequestData Function(InformationRequestData) fn) {
    final d = _form.categoryData;
    if (d is InformationRequestData) {
      _setForm(_form.copyWith(categoryData: fn(d)));
    }
  }

  // Payment issue
  void setPaymentIssueTaxConcept(TaxConcept v) => _updatePaymentIssue(
      (d) => d.copyWith(taxConcept: v, clearTaxConceptError: true));
  void setPaymentIssueType(PaymentIssueType v) => _updatePaymentIssue(
      (d) => d.copyWith(issueType: v, clearIssueTypeError: true));
  void setPaymentIssueMethod(PaymentMethod v) => _updatePaymentIssue(
      (d) => d.copyWith(paymentMethod: v, clearPaymentMethodError: true));
  void setPaymentIssueDate(String v) => _updatePaymentIssue(
      (d) => d.copyWith(paymentDate: v, clearPaymentDateError: true));
  void setPaymentIssueAmount(String v) => _updatePaymentIssue(
      (d) => d.copyWith(amountPaid: v, clearAmountPaidError: true));
  void setPaymentIssueVoucher(String v) => _updatePaymentIssue(
      (d) => d.copyWith(voucherReference: v, clearVoucherReferenceError: true));

  // Payment inquiry
  void setPaymentInquiryTaxConcept(TaxConcept v) => _updatePaymentInquiry(
      (d) => d.copyWith(taxConcept: v, clearTaxConceptError: true));
  void setPaymentInquiryEntityId(String v) => _updatePaymentInquiry(
      (d) => d.copyWith(taxableEntityId: v, clearTaxableEntityIdError: true));
  void setPaymentInquiryFiscalYear(String v) => _updatePaymentInquiry(
      (d) => d.copyWith(fiscalYear: v, clearFiscalYearError: true));
  void setPaymentInquiryType(InquiryType v) => _updatePaymentInquiry(
      (d) => d.copyWith(inquiryType: v, clearInquiryTypeError: true));

  // Technical error
  void setTechnicalScreenName(String v) => _updateTechnicalError(
      (d) => d.copyWith(screenName: v, clearScreenNameError: true));
  void setTechnicalAttemptedAction(String v) => _updateTechnicalError(
      (d) => d.copyWith(attemptedAction: v, clearAttemptedActionError: true));
  void setTechnicalFrequency(ErrorFrequency v) => _updateTechnicalError(
      (d) => d.copyWith(frequency: v, clearFrequencyError: true));
  void setTechnicalErrorMessage(String v) =>
      _updateTechnicalError((d) => d.copyWith(errorMessage: v));

  // Information request
  void setInformationRequestType(InformationType v) => _updateInformationRequest(
      (d) => d.copyWith(requestType: v, clearRequestTypeError: true));
  void setInformationTaxConcept(TaxConcept v) =>
      _updateInformationRequest((d) => d.copyWith(taxConcept: v));

  // ---------------------------------------------------------------------------
  // Envío
  // ---------------------------------------------------------------------------
  Future<void> submit() async {
    final category = _validate();
    if (category == null) return; // _validate ya publicó los errores

    final user = ref.read(sessionProvider);
    if (user == null || !user.loginStatus) {
      state = state.copyWith(uiState: const HelpUnauthenticated());
      return;
    }

    final request = SupportRequest(
      category: category,
      userContext: _buildUserContext(user),
      freeText: _form.freeText.trim(),
    );

    state = state.copyWith(
      uiState: const HelpLoading(),
      formState: _form.copyWith(isSubmitting: true),
    );

    final result = await _repo.submit(request);

    _setForm(_form.copyWith(isSubmitting: false));

    switch (result) {
      case SupportSuccess():
        state = HelpState(uiState: HelpSuccess(result.confirmationMessage));
      case SupportFailureNetwork():
        state = state.copyWith(
          uiState: const HelpError(
            'Sin conexión a internet. Revisa tu red e inténtalo de nuevo.',
            true,
          ),
        );
      case SupportFailureServer():
        state = state.copyWith(uiState: HelpError(result.message, true));
      case SupportFailureValidation():
        state = state.copyWith(uiState: HelpError(result.message, false));
      case SupportFailureUnknown():
        state = state.copyWith(uiState: HelpError(result.message, true));
    }
  }

  void resetToIdle() => state = state.copyWith(uiState: const HelpIdle());

  UserSupportContext _buildUserContext(UserDTO user) {
    final fullName = [
      user.firstName,
      user.middleName,
      user.lastName,
      user.secondLastName,
    ].where((e) => e != null && e.trim().isNotEmpty).join(' ');

    return UserSupportContext(
      fullName: fullName,
      email: user.email.isNotEmpty ? user.email : 'No registrado',
      nationalId: user.nationalId,
      documentTypeName: user.documentType.name,
      phoneNumber: user.phoneNumber,
      address: user.address,
      municipality: municipality,
      fixedMunicipalityId: user.fixedMunicipality,
      lastMunicipalityId: user.lastMunicipality,
      appVersion: '$_appVersion (${FlavorConfig.instance.appName})',
      deviceModel: _deviceModel(),
      platformVersion: _platformVersion(),
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  String _deviceModel() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iPhone/iPad';
    return Platform.operatingSystem;
  }

  String _platformVersion() {
    final os = Platform.isAndroid
        ? 'Android'
        : Platform.isIOS
            ? 'iOS'
            : Platform.operatingSystem;
    return '$os ${Platform.operatingSystemVersion}';
  }

  // ---------------------------------------------------------------------------
  // Validación (port de HelpViewModel.validate). Publica errores en el estado y
  // devuelve la categoría construida si todo es válido, o null si hay errores.
  // ---------------------------------------------------------------------------
  SupportCategory? _validate() {
    final freeTextError = _validateFreeText();

    final data = _form.categoryData;
    return switch (data) {
      PaymentIssueData() => _validatePaymentIssue(data, freeTextError),
      PaymentInquiryData() => _validatePaymentInquiry(data, freeTextError),
      TechnicalErrorData() => _validateTechnicalError(data, freeTextError),
      InformationRequestData() =>
        _validateInformationRequest(data, freeTextError),
      OtherCategory() => _validateOther(freeTextError),
      EmptyCategory() => () {
          _setForm(_form.copyWith(
              freeTextError: 'Selecciona una categoría primero.'));
          return null;
        }(),
    };
  }

  String? _validateFreeText() {
    if (_form.categoryData is OtherCategory && _form.freeText.trim().isEmpty) {
      return "Describe tu solicitud (este campo es obligatorio cuando eliges 'Otro').";
    }
    if (_form.freeText.length > 1000) {
      return 'La descripción no puede superar 1000 caracteres.';
    }
    return null;
  }

  SupportCategory? _validatePaymentIssue(
      PaymentIssueData d, String? freeTextError) {
    final voucherError = d.voucherReference.trim().isEmpty
        ? 'Indica el número de comprobante.'
        : (d.voucherReference.trim().length < 4
            ? 'El comprobante parece muy corto. Verifica el dato.'
            : null);

    final updated = d.copyWith(
      taxConceptError: d.taxConcept == null ? 'Selecciona el impuesto.' : null,
      issueTypeError: d.issueType == null ? 'Indica el tipo de problema.' : null,
      paymentMethodError:
          d.paymentMethod == null ? 'Indica cómo realizaste el pago.' : null,
      paymentDateError: _validatePaymentDate(d.paymentDate),
      amountPaidError: _validateAmount(d.amountPaid),
      voucherReferenceError: voucherError,
      clearTaxConceptError: d.taxConcept != null,
      clearIssueTypeError: d.issueType != null,
      clearPaymentMethodError: d.paymentMethod != null,
      clearPaymentDateError: _validatePaymentDate(d.paymentDate) == null,
      clearAmountPaidError: _validateAmount(d.amountPaid) == null,
      clearVoucherReferenceError: voucherError == null,
    );

    final hasErrors = updated.taxConceptError != null ||
        updated.issueTypeError != null ||
        updated.paymentMethodError != null ||
        updated.paymentDateError != null ||
        updated.amountPaidError != null ||
        updated.voucherReferenceError != null ||
        freeTextError != null;

    if (hasErrors) {
      _setForm(_form.copyWith(
        categoryData: updated,
        freeTextError: freeTextError,
        clearFreeTextError: freeTextError == null,
      ));
      return null;
    }
    return SupportPaymentIssue(
      taxConcept: d.taxConcept!,
      paymentDate: d.paymentDate.trim(),
      paymentMethod: d.paymentMethod!,
      voucherReference: d.voucherReference.trim(),
      amountPaid: d.amountPaid.trim(),
      issueType: d.issueType!,
    );
  }

  SupportCategory? _validatePaymentInquiry(
      PaymentInquiryData d, String? freeTextError) {
    final idError = d.taxableEntityId.trim().isEmpty
        ? 'Ingresa el ${d.taxConcept?.identifierLabel ?? 'identificador'}.'
        : (d.taxableEntityId.trim().length < 3
            ? 'El identificador parece muy corto. Verifica el dato.'
            : null);

    final updated = d.copyWith(
      taxConceptError: d.taxConcept == null ? 'Selecciona el impuesto.' : null,
      inquiryTypeError: d.inquiryType == null ? 'Indica el tipo de duda.' : null,
      taxableEntityIdError: idError,
      fiscalYearError: _validateFiscalYear(d.fiscalYear),
      clearTaxConceptError: d.taxConcept != null,
      clearInquiryTypeError: d.inquiryType != null,
      clearTaxableEntityIdError: idError == null,
      clearFiscalYearError: _validateFiscalYear(d.fiscalYear) == null,
    );

    final hasErrors = updated.taxConceptError != null ||
        updated.inquiryTypeError != null ||
        updated.taxableEntityIdError != null ||
        updated.fiscalYearError != null ||
        freeTextError != null;

    if (hasErrors) {
      _setForm(_form.copyWith(
        categoryData: updated,
        freeTextError: freeTextError,
        clearFreeTextError: freeTextError == null,
      ));
      return null;
    }
    return SupportPaymentInquiry(
      taxConcept: d.taxConcept!,
      taxableEntityId: d.taxableEntityId.trim(),
      fiscalYear: d.fiscalYear.trim(),
      inquiryType: d.inquiryType!,
    );
  }

  SupportCategory? _validateTechnicalError(
      TechnicalErrorData d, String? freeTextError) {
    final updated = d.copyWith(
      screenNameError:
          d.screenName.trim().isEmpty ? 'Indica en qué pantalla ocurrió.' : null,
      attemptedActionError: d.attemptedAction.trim().isEmpty
          ? 'Indica qué intentabas hacer.'
          : null,
      frequencyError:
          d.frequency == null ? 'Indica con qué frecuencia ocurre.' : null,
      clearScreenNameError: d.screenName.trim().isNotEmpty,
      clearAttemptedActionError: d.attemptedAction.trim().isNotEmpty,
      clearFrequencyError: d.frequency != null,
    );

    final hasErrors = updated.screenNameError != null ||
        updated.attemptedActionError != null ||
        updated.frequencyError != null ||
        freeTextError != null;

    if (hasErrors) {
      _setForm(_form.copyWith(
        categoryData: updated,
        freeTextError: freeTextError,
        clearFreeTextError: freeTextError == null,
      ));
      return null;
    }
    return SupportTechnicalError(
      screenName: d.screenName.trim(),
      attemptedAction: d.attemptedAction.trim(),
      errorMessage: d.errorMessage.trim().isEmpty ? null : d.errorMessage.trim(),
      frequency: d.frequency!,
    );
  }

  SupportCategory? _validateInformationRequest(
      InformationRequestData d, String? freeTextError) {
    final requestTypeError =
        d.requestType == null ? 'Indica qué tipo de solicitud es.' : null;

    if (requestTypeError != null || freeTextError != null) {
      _setForm(_form.copyWith(
        categoryData: d.copyWith(
          requestTypeError: requestTypeError,
          clearRequestTypeError: requestTypeError == null,
        ),
        freeTextError: freeTextError,
        clearFreeTextError: freeTextError == null,
      ));
      return null;
    }
    return SupportInformationRequest(
      requestType: d.requestType!,
      taxConcept: d.taxConcept,
    );
  }

  SupportCategory? _validateOther(String? freeTextError) {
    if (freeTextError != null) {
      _setForm(_form.copyWith(freeTextError: freeTextError));
      return null;
    }
    return const SupportOther();
  }

  // --- Validadores de campo ---
  String? _validatePaymentDate(String date) {
    if (date.trim().isEmpty) return 'Selecciona la fecha del pago.';
    final millis = _parseDateToMillis(date);
    if (millis == null) return 'El formato de fecha no es válido.';
    final now = DateTime.now();
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
    final parsed = DateTime.fromMillisecondsSinceEpoch(millis);
    if (parsed.isAfter(now)) return 'La fecha del pago no puede estar en el futuro.';
    if (parsed.isBefore(oneYearAgo)) {
      return 'La fecha del pago no puede ser anterior a un año.';
    }
    return null;
  }

  String? _validateAmount(String amount) {
    if (amount.trim().isEmpty) return 'Indica el monto pagado.';
    final digitsOnly = amount.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return 'El monto debe ser un número.';
    final value = int.tryParse(digitsOnly);
    if (value == null) return 'El monto ingresado no es válido.';
    if (value <= 0) return 'El monto debe ser mayor a cero.';
    if (value > 1000000000) return 'El monto parece demasiado alto. Verifica el dato.';
    if (value < 1000) return 'El monto parece demasiado bajo. Verifica el dato.';
    return null;
  }

  String? _validateFiscalYear(String year) {
    if (year.trim().isEmpty) return 'Selecciona la vigencia.';
    final numericYear = int.tryParse(year);
    if (numericYear == null) return 'El año fiscal no es válido.';
    final currentYear = DateTime.now().year;
    if (numericYear > currentYear) return 'La vigencia no puede ser futura.';
    if (numericYear < currentYear - 5) {
      return 'La vigencia es muy antigua. Contacta directamente al municipio.';
    }
    return null;
  }

  /// Parse dd/MM/yyyy → millis (o null si inválido).
  int? _parseDateToMillis(String date) {
    if (date.trim().isEmpty) return null;
    final parts = date.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final dt = DateTime(year, month, day);
    // Rechaza fechas normalizadas (p. ej. 31/02 → 03/03).
    if (dt.day != day || dt.month != month || dt.year != year) return null;
    return dt.millisecondsSinceEpoch;
  }
}

final helpNotifierProvider =
    NotifierProvider.family<HelpNotifier, HelpState, String>(HelpNotifier.new);
