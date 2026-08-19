import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/services/api_providers.dart';
import '../../../core/models/query_field.dart';
import '../data/tax_repository.dart';
import '../domain/tax.dart';

final taxRepositoryProvider = Provider<TaxRepository>((ref) {
  return TaxRepository(
    ref.watch(taxApiServiceProvider),
    ref.watch(paymentApiServiceProvider),
    ref.watch(fintechPaymentsApiServiceProvider),
  );
});

/// Equivalente a `Patterns.EMAIL_ADDRESS` del original.
final _emailRegex = RegExp(r"^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$");

/// Puerto de `TaxQueryUiState` (TaxQueryViewModel.kt).
class TaxQueryState {
  final QueryField? selectedQueryField;
  final String documentNumber;
  final String email;
  final bool acceptsPolicies;
  final bool acceptsConditions;
  final bool isDropdownVisible;
  final bool isLoading;
  final String? queryError;
  final List<Tax>? querySuccess;
  final bool showNoResultsDialog;

  const TaxQueryState({
    this.selectedQueryField,
    this.documentNumber = '',
    this.email = '',
    this.acceptsPolicies = false,
    this.acceptsConditions = false,
    this.isDropdownVisible = false,
    this.isLoading = false,
    this.queryError,
    this.querySuccess,
    this.showNoResultsDialog = false,
  });

  /// Misma regla de `validateInputs()` del original: tipo de consulta
  /// seleccionado, documento no vacío, email válido y ambas políticas.
  bool get isQueryButtonEnabled =>
      selectedQueryField != null &&
      documentNumber.trim().isNotEmpty &&
      _emailRegex.hasMatch(email.trim()) &&
      acceptsPolicies &&
      acceptsConditions;

  TaxQueryState copyWith({
    QueryField? selectedQueryField,
    String? documentNumber,
    String? email,
    bool? acceptsPolicies,
    bool? acceptsConditions,
    bool? isDropdownVisible,
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
      acceptsPolicies: acceptsPolicies ?? this.acceptsPolicies,
      acceptsConditions: acceptsConditions ?? this.acceptsConditions,
      isDropdownVisible: isDropdownVisible ?? this.isDropdownVisible,
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

  void prefill({String? documentNumber, String? email}) {
    state = state.copyWith(
      documentNumber: documentNumber ?? state.documentNumber,
      email: email ?? state.email,
    );
  }

  void onDropdownVisibilityChanged(bool isVisible) {
    state = state.copyWith(isDropdownVisible: isVisible);
  }

  void onDocumentTypeChanged(QueryField value) {
    state = state.copyWith(selectedQueryField: value, isDropdownVisible: false);
  }

  void onDocumentNumberChanged(String value) {
    state = state.copyWith(documentNumber: value);
  }

  void onEmailChanged(String value) {
    state = state.copyWith(email: value);
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
    required String entityCode,
    required int taxId,
  }) async {
    if (!state.isQueryButtonEnabled || state.isLoading) return;
    state = state.copyWith(isLoading: true, clearQueryError: true);
    try {
      final taxes = await _repository.getTaxes(
        entityCode: entityCode,
        queryData: state.documentNumber.trim(),
        queryField: state.selectedQueryField!.fieldName,
        taxId: taxId,
      );
      if (taxes.isNotEmpty) {
        state = state.copyWith(isLoading: false, querySuccess: taxes);
      } else {
        state = state.copyWith(isLoading: false, showNoResultsDialog: true);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, queryError: e.toString());
    }
  }
}

final taxQueryNotifierProvider =
    NotifierProvider.autoDispose<TaxQueryNotifier, TaxQueryState>(
      TaxQueryNotifier.new,
    );
