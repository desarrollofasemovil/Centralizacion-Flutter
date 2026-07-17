import 'package:flutter/material.dart';

/// Indicador de pasos compartido. Port fiel de `ui/components/StepIndicator.kt`:
/// una fila de círculos (uno por paso) que se rellenan con el color primario y
/// muestran un check cuando el paso está activo/completado, unidos por líneas
/// que también se pintan de primario a medida que se avanza. Debajo de cada
/// círculo va la etiqueta ("Paso 1", "Paso 2", …).
///
/// Centraliza el indicador que estaba duplicado en los wizards (PQRD,
/// certificados, pagos y registro).
class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.currentStep,
    this.stepCount = 3,
    this.labelBuilder,
  });

  /// Paso actual (1-based). Un paso `n` se considera activo si `currentStep >= n`.
  final int currentStep;

  /// Cantidad total de pasos.
  final int stepCount;

  /// Etiqueta por paso. Por defecto "Paso N".
  final String Function(int step)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final children = <Widget>[];

    for (var step = 1; step <= stepCount; step++) {
      children.add(
        _StepDot(
          label: labelBuilder?.call(step) ?? 'Paso $step',
          isActive: currentStep >= step,
        ),
      );
      if (step < stepCount) {
        children.add(
          Expanded(
            child: Padding(
              // Alinea la línea con el centro vertical del círculo (32 / 2).
              padding: const EdgeInsets.only(top: 15),
              child: Container(
                height: 2,
                color: currentStep > step
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.15),
              ),
            ),
          ),
        );
      }
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent =
        isActive ? scheme.primary : scheme.onSurface.withValues(alpha: 0.5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? scheme.primary : Colors.transparent,
            border: Border.all(color: accent, width: 2),
          ),
          child: isActive
              ? Icon(Icons.check, size: 18, color: scheme.onPrimary)
              : null,
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: accent)),
      ],
    );
  }
}
