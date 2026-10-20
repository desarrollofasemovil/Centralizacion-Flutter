import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/api/services/api_providers.dart';
import '../../../core/models/query_field.dart';
import '../../../core/utils/validators.dart';
import '../data/tax_repository.dart';
import '../domain/tax.dart';

final taxRepositoryProvider = Provider<TaxRepository>((ref) {
  return TaxRepository(
    ref.watch(taxApiServiceProvider),
    ref.watch(paymentApiServiceProvider),
    ref.watch(fintechPaymentsApiServiceProvider),
  );
});

final _tenDigits = RegExp(r'^\d{10}$');

/// Puerto de `TaxQueryUiState` (TaxQueryViewModel.kt).
class TaxQueryState {
  final QueryField? selectedQueryField;
  final String documentNumber;
  final String email;

  /// Opcional: viaja a la pasarela con el resto de los datos del pagador.
  final String phone;
  final bool acceptsPolicies;
  final bool acceptsConditions;
  final bool isLoading;
  final String? queryError;
  final List<Tax>? querySuccess;
  final bool showNoResultsDialog;

  const TaxQueryState({
    this.selectedQueryField,
    this.documentNumber = '',
    this.email = '',
    this.phone = '',
    this.acceptsPolicies = false,
    this.acceptsConditions = false,
    this.isLoading = false,
    this.queryError,
    this.querySuccess,
    this.showNoResultsDialog = false,
  });

  /// El teléfono es opcional: vacío vale; si se escribe, 10 dígitos (la misma
  /// regla del celular de Certificados).
  bool get isPhoneValid => phone.isEmpty || _tenDigits.hasMatch(phone);

  /// Misma regla de `validateInputs()` del original: tipo de consulta
  /// seleccionado, documento no vacío, email válido y ambas políticas; más el
  /// teléfono, que solo se valida si se escribió.
  bool get isQueryButtonEnabled =>
      selectedQueryField != null &&
      documentNumber.trim().isNotEmpty &&
      isValidEmail(email) &&
      isPhoneValid &&
      acceptsPolicies &&
      acceptsConditions;

  TaxQueryState copyWith({
    QueryField? selectedQueryField,
    String? documentNumber,
    String? email,
    String? phone,
    bool? acceptsPolicies,
    bool? acceptsConditions,
    bool? isLoading,
    String? queryError,
    List<Tax>? querySuccess,
    bool? showNoResultsDialog,
    bool clearQueryError = false,
    bool clearQuerySuccess = false,
  }) {
    return TaxQueryState(
      selectedQueryField: selectedQueryField ?? this.selectedQueryField,
      documentNumber: documentNumber ?? this.documentNumber,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      acceptsPolicies: acceptsPolicies ?? this.acceptsPolicies,
      acceptsConditions: acceptsConditions ?? this.acceptsConditions,
      isLoading: isLoading ?? this.isLoading,
      queryError: clearQueryError ? null : (queryError ?? this.queryError),
      querySuccess: clearQuerySuccess
          ? null
          : (querySuccess ?? this.querySuccess),
      showNoResultsDialog: showNoResultsDialog ?? this.showNoResultsDialog,
    );
  }
}

/// Puerto de `TaxQueryViewModel` — toda la lógica del formulario de consulta.
class TaxQueryNotifier extends Notifier<TaxQueryState> {
  @override
  TaxQueryState build() => const TaxQueryState();

  TaxRepository get _repository => ref.read(taxRepositoryProvider);

  /// El celular del perfil se precarga solo si ya cumple la regla de 10
  /// dígitos: un valor con otro formato dejaría el botón deshabilitado por un
  /// campo que es opcional.
  void prefill({String? documentNumber, String? email, String? phone}) {
    state = state.copyWith(
      documentNumber: documentNumber ?? state.documentNumber,
      email: email ?? state.email,
      phone: phone != null && _tenDigits.hasMatch(phone) ? phone : null,
    );
  }

  /// Deja seleccionado el primer tipo de documento que trae la API, sin pisar
  /// una elección ya hecha. Casi siempre hay uno solo.
  void preselectQueryField(List<QueryField> options) {
    if (state.selectedQueryField != null || options.isEmpty) return;
    state = state.copyWith(selectedQueryField: options.first);
  }

  void onDocumentTypeChanged(QueryField value) {
    state = state.copyWith(selectedQueryField: value);
  }

  void onDocumentNumberChanged(String value) {
    state = state.copyWith(documentNumber: value);
  }

  void onEmailChanged(String value) {
    state = state.copyWith(email: value);
  }

  void onPhoneChanged(String value) {
    state = state.copyWith(phone: value);
  }

  void onAcceptsPoliciesChanged(bool accepted) {
    state = state.copyWith(acceptsPolicies: accepted);
  }

  void onAcceptsConditionsChanged(bool accepted) {
    state = state.copyWith(acceptsConditions: accepted);
  }

  void onQueryHandled() {
    state = state.copyWith(clearQuerySuccess: true, clearQueryError: true);
  }

  void onNoResultsDialogDismissed() {
    state = state.copyWith(showNoResultsDialog: false);
  }

  Future<void> onQueryClicked({
    required int municipalityId,
    required String entityCode,
    required int taxId,
  }) async {
    if (!state.isQueryButtonEnabled || state.isLoading) return;
    state = state.copyWith(isLoading: true, clearQueryError: true);
    final queryField = state.selectedQueryField!.fieldName;
    final analytics = ref.read(analyticsServiceProvider);
    unawaited(
      analytics.logTaxQuerySent(
        municipalityId: municipalityId,
        taxId: taxId,
        entityCode: entityCode,
        queryField: queryField,
      ),
    );
    try {
      final taxes = await _repository.getTaxes(
        entityCode: entityCode,
        queryData: state.documentNumber.trim(),
        queryField: queryField,
        taxId: taxId,
      );
      unawaited(
        analytics.logTaxQueryResult(
          municipalityId: municipalityId,
          taxId: taxId,
          outcome: taxes.isNotEmpty
              ? TaxQueryOutcome.found
              : TaxQueryOutcome.noDebt,
          count: taxes.length,
          totalValue: taxes.fold(0, (sum, t) => sum + t.value),
        ),
      );
      if (taxes.isNotEmpty) {
        state = state.copyWith(isLoading: false, querySuccess: taxes);
      } else {
        state = state.copyWith(isLoading: false, showNoResultsDialog: true);
      }
    } catch (e) {
      unawaited(
        analytics.logTaxQueryResult(
          municipalityId: municipalityId,
          taxId: taxId,
          outcome: TaxQueryOutcome.error,
          error: e,
        ),
      );
      state = state.copyWith(isLoading: false, queryError: e.toString());
    }
  }
}

final taxQueryNotifierProvider =
    NotifierProvider.autoDispose<TaxQueryNotifier, TaxQueryState>(
      TaxQueryNotifier.new,
    );
