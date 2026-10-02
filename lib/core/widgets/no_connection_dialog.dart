import 'package:flutter/material.dart';

/// Diálogo bloqueante sin conexión (port de `ui/components/NoConnectionDialog.kt`).
///
/// Es solo el contenido: quien lo monta pone la barrera y lo centra. No se
/// descarta tocando fuera ni con "atrás" (`onDismissRequest = {}` en el
/// original); "Entendido" solo se habilita cuando vuelve la conexión.
class NoConnectionDialog extends StatelessWidget {
  const NoConnectionDialog({
    required this.isConnectionRestored,
    required this.onDismiss,
    super.key,
  });

  final bool isConnectionRestored;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/icon_no_wifi.png',
                  width: 90,
                  height: 90,
                  semanticLabel: 'Sin conexión',
                ),
                const SizedBox(height: 16),
                Text(
                  'No estás conectado a internet',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Señor(a) ciudadano. Para un correcto funcionamiento de '
                  'nuestra App es necesario estar conectado a internet, por '
                  'favor verifique su conexión y vuelva a intentarlo.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isConnectionRestored ? onDismiss : null,
                    child: const Text('Entendido'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
