import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/municipality/municipality_repository.dart';
import '../../../core/review/review_prompt_service.dart';
import '../../../core/utils/url_opener.dart';
import '../application/tax_results_notifier.dart';
import '../domain/tax.dart';
import 'widgets/tax_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../tramites/domain/procedure_identity.dart';

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
    final mun = ref.read(municipalityProvider(widget.municipalityId)).value;
    if (mun == null) {
      _showSnack('Espere a que carguen los datos del municipio');
      return;
    }
    // `tax.taxId` es el `Id_Impuesto` de apidatamovil: se cruza con el
    // `externalId` del trámite, no con su `id` (cambia entre entornos).
    final matched = findTaxProcedureByExternalId(
      mun.municipalityProcedures,
      tax.taxId,
    );
    // Registro en el historial y transacción, en ese orden (ver `payTax`).
    ref
        .read(taxResultsNotifierProvider.notifier)
        .payTax(
          tax: tax,
          email: widget.email,
          bankName: mun.bank.nameBank,
          municipalityId: widget.municipalityId,
          integrationType: matched?.integrationType ?? '0',
          municipalityProceduresId: matched?.id,
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
        appBar: AppTopBar(
          title: 'Facturas Encontradas',
          backgroundColor: Colors.transparent,
          centerTitle: true,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
          onBack: () => context.pop(),
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
                    ),
                  ),
                );
              },
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
