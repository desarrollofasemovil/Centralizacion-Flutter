import 'package:flutter/material.dart';

/// Hoja de "Configuración adicional": acciones destructivas que se dejan fuera
/// de la lista principal para que no se toquen por accidente.
///
/// Solo avisa y delega: [onDeleteAccount] debe abrir la confirmación final
/// (`ImportantAlertDialog`), que es la que realmente protege el borrado.
class AdditionalSettingsSheet extends StatelessWidget {
  const AdditionalSettingsSheet({super.key, required this.onDeleteAccount});

  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Text(
              'Configuración adicional',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Estas acciones no se pueden deshacer.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onDeleteAccount,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: scheme.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 22,
                        color: scheme.error,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Eliminar mi cuenta',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: scheme.error,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
