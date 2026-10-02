import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/services/api_providers.dart';
import '../../../core/models/validation_response_dto.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/tax.dart';
import 'tax_notifier.dart';

/// Puerto de `TaxResultsUiState` (RespuestaConsultaViewModel.kt).
///
/// `paymentUrl`, `fileToOpenPath`, `fileToSharePath` y `genericUrlToOpen` son
/// eventos de un solo disparo: la pantalla los escucha con `ref.listen` y los
/// limpia con [TaxResultsNotifier.onFileActionHandled] /
/// [TaxResultsNotifier.onNavigationHandled].
class TaxResultsState {
  final String? paymentUrl;
  final bool isLoading;
  final String loadingMessage;
  final String? error;
  final String? fileToOpenPath;
  final String? fileToSharePath;
  final String? genericUrlToOpen;
  final ValidationResponseDTO? validationCreatePayment;

  const TaxResultsState({
    this.paymentUrl,
    this.isLoading = false,
    this.loadingMessage = 'Cargando...',
    this.error,
    this.fileToOpenPath,
    this.fileToSharePath,
    this.genericUrlToOpen,
    this.validationCreatePayment,
  });

  TaxResultsState copyWith({
    String? paymentUrl,
    bool? isLoading,
    String? loadingMessage,
    String? error,
    String? fileToOpenPath,
    String? fileToSharePath,
    String? genericUrlToOpen,
    ValidationResponseDTO? validationCreatePayment,
    bool clearPaymentUrl = false,
    bool clearError = false,
    bool clearFileToOpen = false,
    bool clearFileToShare = false,
    bool clearGenericUrl = false,
    bool clearValidation = false,
  }) {
    return TaxResultsState(
      paymentUrl: clearPaymentUrl ? null : (paymentUrl ?? this.paymentUrl),
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      error: clearError ? null : (error ?? this.error),
      fileToOpenPath: clearFileToOpen
          ? null
          : (fileToOpenPath ?? this.fileToOpenPath),
      fileToSharePath: clearFileToShare
          ? null
          : (fileToSharePath ?? this.fileToSharePath),
      genericUrlToOpen: clearGenericUrl
          ? null
          : (genericUrlToOpen ?? this.genericUrlToOpen),
      validationCreatePayment: clearValidation
          ? null
          : (validationCreatePayment ?? this.validationCreatePayment),
    );
  }
}

/// Puerto de `TaxResultsViewModel` — pago PSE, descarga/compartir de factura y
/// registro del historial de pago.
class TaxResultsNotifier extends Notifier<TaxResultsState> {
  @override
  TaxResultsState build() => const TaxResultsState();

  Future<void> onPayClicked({
    required Tax tax,
    required String email,
    required String bankName,
    required int municipalityId,
    required String integrationType,
  }) async {
    if (tax.isExpired) return;
    state = state.copyWith(
      isLoading: true,
      loadingMessage: 'Generando el pago...',
      clearError: true,
    );
    try {
      final paymentInfo = await ref
          .read(taxRepositoryProvider)
          .createTransaction(
            tax: tax,
            email: email,
            bankName: bankName,
            municipalityId: municipalityId,
            integrationType: integrationType,
          );
      state = state.copyWith(
        isLoading: false,
        loadingMessage: 'Cargando...',
        paymentUrl: paymentInfo.url,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        loadingMessage: 'Cargando...',
        error: e.toString(),
      );
    }
  }

  /// Registro previo del pago en el historial (status false, statusType 2),
  /// igual que `createHistoryPay` del original.
  Future<void> createHistoryPay({
    required int amount,
    required String idImpuesto,
    required String factura,
    required String codigoEntidad,
    required int municipalityProceduresId,
  }) async {
    try {
      final user = ref.read(sessionProvider);
      final now = DateTime.now();
      final formattedDate =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final body = {
        'userId': user?.id,
        'amount': amount,
        'paymentDate': formattedDate,
        'status': false,
        'municipalityProceduresId': municipalityProceduresId,
        'statusType': 2,
        'codigoEntidad': codigoEntidad,
        'factura': factura,
        'idimpuesto': idImpuesto,
      };
      final response = await ref
          .read(paymentHistoryApiServiceProvider)
          .createPaymentHistory(body);
      state = state.copyWith(validationCreatePayment: response);
    } catch (_) {
      state = state.copyWith(
        validationCreatePayment: ValidationResponseDTO(
          booleanStatus: false,
          sentencesError: 'Tenemos problemas crear historial.',
        ),
      );
    }
  }

  Future<void> onOpenPdfClicked(Tax tax) async {
    if (tax.isExpired) return;
    // Si el impuesto trae URL de portal, se abre esa URL en vez de descargar.
    final portalUrl = tax.portalUrl;
    if (portalUrl != null && portalUrl.trim().isNotEmpty) {
      state = state.copyWith(genericUrlToOpen: portalUrl);
      return;
    }
    state = state.copyWith(
      isLoading: true,
      loadingMessage: 'Descargando factura...',
      clearError: true,
    );
    try {
      final path = await ref
          .read(taxRepositoryProvider)
          .downloadInvoiceFile(tax);
      state = state.copyWith(
        isLoading: false,
        loadingMessage: 'Cargando...',
        fileToOpenPath: path,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        loadingMessage: 'Cargando...',
        error: e.toString(),
      );
    }
  }

  Future<void> onSharePdfClicked(Tax tax) async {
    if (tax.isExpired) return;
    state = state.copyWith(
      isLoading: true,
      loadingMessage: 'Descargando factura para compartir...',
      clearError: true,
    );
    try {
      final path = await ref
          .read(taxRepositoryProvider)
          .downloadInvoiceFile(tax);
      state = state.copyWith(
        isLoading: false,
        loadingMessage: 'Cargando...',
        fileToSharePath: path,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        loadingMessage: 'Cargando...',
        error: e.toString(),
      );
    }
  }

  void onFileActionHandled() {
    state = state.copyWith(clearFileToOpen: true, clearFileToShare: true);
  }

  void onNavigationHandled() {
    state = state.copyWith(clearPaymentUrl: true, clearGenericUrl: true);
  }

  void onErrorHandled() {
    state = state.copyWith(clearError: true);
  }
}

final taxResultsNotifierProvider =
    NotifierProvider.autoDispose<TaxResultsNotifier, TaxResultsState>(
      TaxResultsNotifier.new,
    );
