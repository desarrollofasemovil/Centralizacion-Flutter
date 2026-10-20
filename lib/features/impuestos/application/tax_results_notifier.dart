import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/telemetry/non_fatal_reporter.dart';
import '../../pagos/application/payment_history_registration.dart';
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

  const TaxResultsState({
    this.paymentUrl,
    this.isLoading = false,
    this.loadingMessage = 'Cargando...',
    this.error,
    this.fileToOpenPath,
    this.fileToSharePath,
    this.genericUrlToOpen,
  });

  TaxResultsState copyWith({
    String? paymentUrl,
    bool? isLoading,
    String? loadingMessage,
    String? error,
    String? fileToOpenPath,
    String? fileToSharePath,
    String? genericUrlToOpen,
    bool clearPaymentUrl = false,
    bool clearError = false,
    bool clearFileToOpen = false,
    bool clearFileToShare = false,
    bool clearGenericUrl = false,
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
    );
  }
}

/// Puerto de `TaxResultsViewModel` — pago PSE, descarga/compartir de factura y
/// registro del historial de pago.
class TaxResultsNotifier extends Notifier<TaxResultsState> {
  @override
  TaxResultsState build() => const TaxResultsState();

  Future<void> _createTransaction({
    required Tax tax,
    required String email,
    required String bankName,
    required int municipalityId,
    required String integrationType,
    required String phone,
  }) async {
    try {
      final paymentInfo = await ref
          .read(taxRepositoryProvider)
          .createTransaction(
            tax: tax,
            email: email,
            bankName: bankName,
            municipalityId: municipalityId,
            integrationType: integrationType,
            phone: phone,
          );
      if (paymentInfo.url.trim().isEmpty) {
        // La pantalla ignora una URL vacía: sin este evento el pago se
        // quedaba en nada sin dejar rastro.
        _logPaymentError(
          municipalityId,
          PaymentStage.noUrl,
          reason: 'url_vacia',
        );
      }
      state = state.copyWith(
        isLoading: false,
        loadingMessage: 'Cargando...',
        paymentUrl: paymentInfo.url,
      );
    } catch (e) {
      _logPaymentError(municipalityId, PaymentStage.transaction, error: e);
      state = state.copyWith(
        isLoading: false,
        loadingMessage: 'Cargando...',
        error: e.toString(),
      );
    }
  }

  void _logPaymentError(
    int municipalityId,
    PaymentStage stage, {
    Object? error,
    String? reason,
  }) {
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .logPaymentError(
            municipalityId: municipalityId,
            origin: PaymentOrigin.taxQuery,
            stage: stage,
            error: error,
            reason: reason,
          ),
    );
  }

  /// "Pagar por PSE": un solo flujo secuencial, como el del pago sin
  /// validación. Primero se **espera** el registro del pago en el historial y
  /// después se pide la transacción.
  ///
  /// Antes el botón disparaba la transacción y el registro a la vez: la URL de
  /// la pasarela llevaba enseguida a la pantalla de procesamiento, el aviso
  /// del registro quedaba detrás sin verse y un fallo no dejaba rastro. El
  /// registro sigue siendo best-effort ([registerPaymentHistory]).
  ///
  /// [municipalityProceduresId] es `null` si el impuesto no corresponde a un
  /// trámite del municipio: entonces se paga sin registro, pero queda el rastro.
  Future<void> payTax({
    required Tax tax,
    required String email,
    required String bankName,
    required int municipalityId,
    required String integrationType,
    required int? municipalityProceduresId,
    String phone = '',
  }) async {
    if (tax.isExpired || state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      loadingMessage: 'Generando el pago...',
      clearError: true,
    );

    final procedureId = municipalityProceduresId;
    if (procedureId == null || tax.invoice.isEmpty || tax.entityCode.isEmpty) {
      ref.read(nonFatalReporterProvider).report(
        'Pago sin registro en el historial: faltan datos',
        context: {
          'municipalityProceduresId': procedureId,
          'idimpuesto': tax.taxId,
          'tieneFactura': tax.invoice.isNotEmpty,
          'tieneCodigoEntidad': tax.entityCode.isNotEmpty,
        },
      );
      _logPaymentError(
        municipalityId,
        PaymentStage.historyRegistration,
        reason: 'faltan_datos',
      );
    } else {
      await registerPaymentHistory(
        ref,
        municipalityId: municipalityId,
        origin: PaymentOrigin.taxQuery,
        amount: tax.value,
        idImpuesto: tax.taxId.toString(),
        factura: tax.invoice,
        codigoEntidad: tax.entityCode,
        municipalityProceduresId: procedureId,
      );
    }
    if (!ref.mounted) return;

    await _createTransaction(
      tax: tax,
      email: email,
      bankName: bankName,
      municipalityId: municipalityId,
      integrationType: integrationType,
      phone: phone,
    );
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
