import 'package:flutter/material.dart';

/// Indicador de paso individual — puerto de `StepIndicator`: círculo de 32,
/// activo `primary/onPrimary`, inactivo `surface/onSurface`.
class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.stepNumber,
    required this.isActive,
  });

  final int stepNumber;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? scheme.primary : scheme.surface,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$stepNumber',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isActive ? scheme.onPrimary : scheme.onSurface,
            ),
      ),
    );
  }
}

/// Fila de los 3 indicadores de paso — puerto de `SignUpStepRow(activeStep)`.
class SignUpStepRow extends StatelessWidget {
  const SignUpStepRow({super.key, required this.activeStep});

  final int activeStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StepIndicator(stepNumber: 1, isActive: activeStep == 1),
        const SizedBox(width: 50),
        StepIndicator(stepNumber: 2, isActive: activeStep == 2),
        const SizedBox(width: 50),
        StepIndicator(stepNumber: 3, isActive: activeStep == 3),
      ],
    );
  }
}

/// Botón de volver del registro — puerto de `SignUpBackButton`: ícono circular
/// con fondo `primary` y flecha `onPrimary`.
class SignUpBackButton extends StatelessWidget {
  const SignUpBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onPressed,
      icon: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.arrow_back_ios_new, size: 18, color: scheme.onPrimary),
      ),
    );
  }
}
