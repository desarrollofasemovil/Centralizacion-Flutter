import 'package:flutter/material.dart';

import 'policy_checkboxes.dart';

/// Diálogo de aceptación de políticas antes de radicar una solicitud.
/// Port fiel de `ui/components/ConfirmationPoliciesDialog.kt`.
///
/// Reutiliza [PolicyCheckboxRow] (de `policy_checkboxes.dart`). El botón
/// "Radicar" solo se habilita cuando ambas casillas están marcadas.
class ConfirmationPoliciesDialog extends StatelessWidget {
  const ConfirmationPoliciesDialog({
    super.key,
    required this.aceptaTratamientoDatos,
    required this.onAceptaTratamientoDatosChange,
    required this.aceptaCondicionesUso,
    required this.onAceptaCondicionesUsoChange,
    required this.onDismiss,
    required this.onConfirm,
    this.dataPolicyUrl = "",
    this.privacyPolicyUrl = "",
  });

  final bool aceptaTratamientoDatos;
  final ValueChanged<bool> onAceptaTratamientoDatosChange;
  final bool aceptaCondicionesUso;
  final ValueChanged<bool> onAceptaCondicionesUsoChange;
  final VoidCallback onDismiss;
  final VoidCallback onConfirm;
  final String dataPolicyUrl;
  final String privacyPolicyUrl;

  // Equivalente a `Gray600` del tema original.
  static const Color _gray600 = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConfirmEnabled = aceptaTratamientoDatos && aceptaCondicionesUso;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Políticas y Condiciones",
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "El usuario acepta expresamente que la notificación de la decisión se "
              "hará vía electrónica de conformidad a la ley 1437 de 2011, la cual se "
              "realizará al correo electrónico suministrado por el solicitante.",
              textAlign: TextAlign.justify,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            PolicyCheckboxRow(
              text:
                  "Acepto y autorizo la política de tratamiento de datos personales",
              linkText: "tratamiento de datos personales",
              url: dataPolicyUrl,
              checked: aceptaTratamientoDatos,
              onChanged: onAceptaTratamientoDatosChange,
            ),
            const SizedBox(height: 16),
            Text(
              "Ley de Protección de Datos Personales: La autorización suministrada "
              "en el presente formulario faculta al Municipio para que dé a sus datos "
              "aquí recopilados el tratamiento señalado en la “Política de Privacidad "
              "para el Tratamiento de Datos Personales”...",
              textAlign: TextAlign.justify,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            PolicyCheckboxRow(
              text:
                  "Acepto las condiciones de uso y las políticas de privacidad",
              linkText: "políticas de privacidad",
              url: privacyPolicyUrl,
              checked: aceptaCondicionesUso,
              onChanged: onAceptaCondicionesUsoChange,
            ),
            const SizedBox(height: 21),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                  width: 150,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ElevatedButton(
                      onPressed: onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gray600,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        "Cancelar",
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isConfirmEnabled ? onConfirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: Text("Radicar", style: theme.textTheme.titleSmall),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
