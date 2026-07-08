import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pantalla de error cuando no se puede cargar la configuración del municipio.
/// Port fiel de `ui/components/ErrorMunicipalityScreen.kt` (`ErrorMuncipalityScreen`).
///
/// La muestra `AlcaldiasScope` cuando `municipalityProvider` cae en error
/// (equivalente a `AlcaldiasStateWrapper` → `ErrorMuncipalityScreen`, FRONTEND §2.1).
/// El botón "Salir" cierra la app (equivalente a `activity.finish()` del original).
class ErrorMunicipalityScreen extends StatelessWidget {
  const ErrorMunicipalityScreen({super.key, this.onExit});

  /// Acción del botón "Salir". Por defecto cierra la app (como el original).
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "El servicio no está disponible en este momento. \n\n"
                  "Por favor, inténtalo más tarde.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 30),
                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: ElevatedButton(
                    onPressed:
                        onExit ?? () => SystemNavigator.pop(animated: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: const Text("Salir", style: TextStyle(fontSize: 16)),
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
