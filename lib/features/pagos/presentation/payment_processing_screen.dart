import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/utils/url_opener.dart';
import '../application/payment_processing_notifier.dart';
import 'widgets/processing_indicator.dart';

/// Puerto de `PaymentProcessingScreen.kt` («Procesando tu pago»).
///
/// Solo se navega aquí cuando ya se tiene el link de la pasarela: al entrar se
/// abre la URL una única vez (Custom Tabs / Safari VC) y la pantalla queda de
/// fondo esperando a que el usuario vuelva. El botón "Verificar estado" se
/// desbloquea tras la cuenta regresiva y lleva al Historial de pagos.
class PaymentProcessingScreen extends ConsumerStatefulWidget {
  const PaymentProcessingScreen({
    required this.municipalityId,
    required this.paymentUrl,
    super.key,
  });

  final int municipalityId;
  final String paymentUrl;

  @override
  ConsumerState<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState
    extends ConsumerState<PaymentProcessingScreen> {
  @override
  void initState() {
    super.initState();
    // Abrimos la pasarela una única vez, justo al entrar a la pantalla, con
    // el header de la Custom Tab teñido del color primario (como el original).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.paymentUrl.trim().isNotEmpty && mounted) {
        abrirUrl(
          widget.paymentUrl,
          toolbarColor: Theme.of(context).colorScheme.primary,
        );
      }
    });
  }

  Future<void> _onCheckStatus() async {
    final shouldNavigate = await ref
        .read(paymentProcessingNotifierProvider.notifier)
        .onCheckStatusClick();
    if (shouldNavigate && mounted) {
      context.go(AppRoutes.pagosHistoryPath(widget.municipalityId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(paymentProcessingNotifierProvider);

    final checkLabel = state.isVerifying
        ? 'Verificando…'
        : state.secondsRemaining > 0
            ? 'Verificar estado (${state.secondsRemaining}s)'
            : 'Verificar estado del pago';

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Contenido centrado ──────────────────────────
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const ProcessingIndicator(size: 120),
                    const SizedBox(height: 40),
                    Text(
                      'Procesando tu pago',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        'Completa el pago en la pasarela. Cuando termines, '
                        'verifica el estado para ver el resultado en tu historial.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Acciones ────────────────────────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: state.isCheckEnabled ? _onCheckStatus : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                  ),
                  child: Text(checkLabel),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => context
                      .go(AppRoutes.municipalityPath(widget.municipalityId)),
                  child: const Text('Volver al inicio'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
