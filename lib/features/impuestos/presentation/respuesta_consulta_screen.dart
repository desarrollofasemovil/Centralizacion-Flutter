import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/validation_response_dto.dart';
import '../../../core/municipality/municipality_repository.dart';
import '../../../core/review/review_prompt_service.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/utils/url_opener.dart';
import '../application/tax_results_notifier.dart';
import '../domain/tax.dart';
import 'widgets/tax_card.dart';

/// Puerto de `TaxResultsScreen` (RespuestaConsultaScreen.kt): lista de
/// facturas encontradas con pago PSE, descarga y compartir de PDF.
/// Toda la lógica vive en [TaxResultsNotifier].
class TaxResultsScreen extends ConsumerStatefulWidget {
  const TaxResultsScreen({
    required this.municipalityId,
    required this.taxes,
    required this.email,
    super.key,
  });

  final int municipalityId;
  final List<Tax> taxes;
  final String email;

  @override
  ConsumerState<TaxResultsScreen> createState() => _TaxResultsScreenState();
}

class _TaxResultsScreenState extends ConsumerState<TaxResultsScreen> {
  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handlePay(Tax tax) {
    final notifier = ref.read(taxResultsNotifierProvider.notifier);
    final mun = ref.read(municipalityProvider(widget.municipalityId)).value;
    if (mun == null) {
      _showSnack('Espere a que carguen los datos del municipio');
      return;
    }
    final matched = mun.municipalityProcedures
        .where((p) => p.procedures.id == tax.taxId)
        .firstOrNull;
    notifier.onPayClicked(
      tax: tax,
      email: widget.email,
      bankName: mun.bank.nameBank,
      municipalityId: widget.municipalityId,
      integrationType: matched?.integrationType ?? '0',
    );
  }

  void _handleRegisterPayment(Tax tax) {
    final mun = ref.read(municipalityProvider(widget.municipalityId)).value;
    if (mun == null) {
      _showSnack('Tenemos problemas con tu Alcadia, Intenta mas tarde');
      return;
    }
    final matched = mun.municipalityProcedures
        .where((p) => p.procedures.id == tax.taxId)
        .firstOrNull;
    if (matched == null) {
      _showSnack('Tenemos problemas con tu Alcadia, Intenta mas tarde');
      return;
    }
    if (tax.invoice.isEmpty || tax.entityCode.isEmpty) {
      _showSnack(
        'Algunos de los datos de tu información tiene problemas, Intenta mas tarde',
      );
      return;
    }
    ref
        .read(taxResultsNotifierProvider.notifier)
        .createHistoryPay(
          amount: tax.value,
          idImpuesto: tax.taxId.toString(),
          factura: tax.invoice,
          codigoEntidad: tax.entityCode,
          municipalityProceduresId: matched.id,
        );
  }

  Future<void> _openPdf(String path) async {
    final result = await OpenFilex.open(path, type: 'application/pdf');
    if (result.type != ResultType.done && mounted) {
      _showSnack('No se encontró una aplicación para abrir el PDF.');
    }
  }

  Future<void> _sharePdf(String path) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path, mimeType: 'application/pdf')]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(taxResultsNotifierProvider);
    final notifier = ref.read(taxResultsNotifierProvider.notifier);
    final asyncMun = ref.watch(municipalityProvider(widget.municipalityId));

    // Eventos de un solo disparo (LaunchedEffect del original).
    ref.listen(taxResultsNotifierProvider, (previous, next) {
      final paymentUrl = next.paymentUrl;
      if (paymentUrl != null && paymentUrl.isNotEmpty) {
        notifier.onNavigationHandled();
        // Pasamos a la pantalla de estado del pago (abre la pasarela allí).
        context.push(
          '/municipality/${widget.municipalityId}/pagos/processing',
          extra: {'paymentUrl': paymentUrl},
        );
      }
      final genericUrl = next.genericUrlToOpen;
      if (genericUrl != null && genericUrl.isNotEmpty) {
        notifier.onNavigationHandled();
        abrirUrl(genericUrl, toolbarColor: scheme.primary);
      }
      final fileToOpen = next.fileToOpenPath;
      final fileToShare = next.fileToSharePath;
      if (fileToOpen != null || fileToShare != null) {
        notifier.onFileActionHandled();
        if (fileToOpen != null) _openPdf(fileToOpen);
        if (fileToShare != null) _sharePdf(fileToShare);
      }
      final error = next.error;
      if (error != null && previous?.error != error) {
        notifier.onErrorHandled();
        _showSnack('Error: $error');
      }
    });

    // Reseña de la tienda al volver atrás tras ver facturas (FSM-59). Solo en
    // un pop: salir con `go` (p. ej. "Verificar estado" del pago) no cuenta,
    // y no se interrumpe mientras revisa, descarga o paga.
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && widget.taxes.isNotEmpty) {
          unawaited(
            ref
                .read(reviewPromptServiceProvider)
                .onPositiveMoment(ReviewTrigger.taxQueryResults),
          );
        }
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Center(child: AppBackButton(onPressed: () => context.pop())),
          ),
          title: Text(
            'Facturas Encontradas',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Stack(
          children: [
            if (asyncMun.isLoading)
              const Center(child: CircularProgressIndicator.adaptive())
            else if (asyncMun.hasError)
              const Center(
                child: Text('Error al cargar los datos del municipio.'),
              ),
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: widget.taxes.length,
              itemBuilder: (context, index) {
                final tax = widget.taxes[index];
                return _AnimatedEntry(
                  delay: Duration(milliseconds: index * 100),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TaxCard(
                      tax: tax,
                      isLoading: state.isLoading,
                      onPayClick: _handlePay,
                      onPdfClick: notifier.onOpenPdfClicked,
                      onShareClick: notifier.onSharePdfClicked,
                      onRegisterPayment: () => _handleRegisterPayment(tax),
                    ),
                  ),
                );
              },
            ),
            // Alerta inferior con el resultado del registro en el historial.
            if (state.validationCreatePayment != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _ValidationAlert(
                    validation: state.validationCreatePayment!,
                  ),
                ),
              ),
            // Diálogo modal de carga (DownloadingDialog del original).
            if (state.isLoading)
              _DownloadingDialog(message: state.loadingMessage),
          ],
        ),
      ),
    );
  }
}

/// Entrada animada de cada tarjeta: fade + slide vertical de 500 ms con
/// retardo escalonado (100 ms por ítem), como el original.
class _AnimatedEntry extends StatefulWidget {
  const _AnimatedEntry({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.5),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 500),
        child: widget.child,
      ),
    );
  }
}

/// Puerto de `ValidationAlert`: tarjeta de éxito/error del registro de pago.
class _ValidationAlert extends StatelessWidget {
  const _ValidationAlert({required this.validation});

  final ValidationResponseDTO validation;

  @override
  Widget build(BuildContext context) {
    final success = validation.booleanStatus;
    final backgroundColor = success
        ? const Color(0xFFE6F4EA)
        : const Color(0xFFFFE5E5);
    final iconTint = success ? const Color(0xFF2E7D32) : Colors.red;
    // Mejora sobre el original (usaba texto blanco en éxito, ilegible sobre
    // fondo claro): el texto usa el mismo verde/rojo del ícono.
    final textColor = success ? const Color(0xFF2E7D32) : Colors.red;

    return Card(
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(success ? Icons.check_circle : Icons.error, color: iconTint),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                validation.sentencesError,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Puerto de `DownloadingDialog`: overlay modal no descartable con spinner.
class _DownloadingDialog extends StatelessWidget {
  const _DownloadingDialog({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          const ModalBarrier(dismissible: false, color: Colors.black45),
          Center(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator.adaptive(),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
