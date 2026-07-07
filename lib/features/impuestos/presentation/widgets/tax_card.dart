import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/tax.dart';

// Tokens fijos del original (CardImpuesto.kt): Gray300 para los botones
// circulares y el azul institucional del botón PSE (no es color de marca del
// municipio, por eso no sale del ColorScheme).
const _gray300 = Color(0xFFE0E0E0);
const _pseBlue = Color(0xFF004984);

/// Puerto de `CardImpuesto.kt` (`TaxCard`): tarjeta con borde primario,
/// datos del impuesto, botones circulares de PDF/compartir y botón
/// "Pagar por PSE".
class TaxCard extends StatefulWidget {
  const TaxCard({
    super.key,
    required this.tax,
    required this.isLoading,
    required this.onPayClick,
    required this.onPdfClick,
    required this.onShareClick,
    required this.onRegisterPayment,
  });

  final Tax tax;
  final bool isLoading;
  final ValueChanged<Tax> onPayClick;
  final ValueChanged<Tax> onPdfClick;
  final ValueChanged<Tax> onShareClick;
  final VoidCallback onRegisterPayment;

  @override
  State<TaxCard> createState() => _TaxCardState();
}

class _TaxCardState extends State<TaxCard> {
  // Anti doble-tap del original: se bloquea el botón hasta que el ViewModel
  // deja de cargar.
  bool _isClicked = false;

  @override
  void didUpdateWidget(covariant TaxCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading && _isClicked) {
      setState(() => _isClicked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tax = widget.tax;
    final payEnabled = !tax.isExpired && !widget.isLoading && !_isClicked;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 3,
      color: scheme.surfaceContainerLowest, // Compose `background`
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.primary, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información del impuesto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nombre: ${tax.name}',
                          style: theme.textTheme.bodyMedium),
                      Text('Impuesto: ${tax.taxName}',
                          style: theme.textTheme.bodyMedium),
                      Text('Factura: ${tax.invoice}',
                          style: theme.textTheme.bodyMedium),
                      Text('Fecha límite: ${tax.dueDate}',
                          style: theme.textTheme.bodyMedium),
                      Text(
                        'Total a pagar: ${formatCurrency(tax.value)}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Botones de acción (PDF, Compartir)
                Column(
                  children: [
                    _CircleActionButton(
                      onPressed: () => widget.onPdfClick(tax),
                      tooltip: 'Descargar PDF',
                      child: SvgPicture.asset(
                        'assets/images/icopdf.svg',
                        width: 38,
                        height: 38,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CircleActionButton(
                      onPressed: () => widget.onShareClick(tax),
                      tooltip: 'Compartir',
                      child: Image.asset(
                        'assets/images/icocompartir.png',
                        width: 38,
                        height: 38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (tax.isExpired) ...[
              const SizedBox(height: 12),
              Text(
                'Factura Vencida',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Botón de pago principal
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: payEnabled
                    ? () {
                        setState(() => _isClicked = true);
                        widget.onPayClick(tax);
                        widget.onRegisterPayment();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pseBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Pagar por PSE',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.onPressed,
    required this.tooltip,
    required this.child,
  });

  final VoidCallback onPressed;
  final String tooltip;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: _gray300,
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 60,
            height: 60,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
