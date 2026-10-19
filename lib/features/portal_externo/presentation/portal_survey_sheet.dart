import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_service.dart';
import '../application/portal_visit_tracker.dart';

/// Microencuesta al volver de un portal externo: "¿Pudiste hacer tu pago?".
/// Un toque responde; solo "Tuve un problema" pide un segundo toque (el
/// motivo). Cerrarla sin responder se registra como descartada.
///
/// No existe en el original Kotlin: es nueva de la Fase 2 de analítica.
Future<void> showPortalSurveySheet(
  BuildContext context, {
  required PortalSurveyRequest request,
  required PortalVisitTracker tracker,
}) async {
  var step = PortalSurveyStep.question;
  final answered = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => PortalSurveySheet(
      tramiteName: request.visit.tramite.nombre,
      onStepChanged: (s) => step = s,
      onAnswered: (answer, problem) =>
          tracker.onSurveyAnswered(request, answer, problem: problem),
    ),
  );
  if (answered != true) tracker.onSurveyDismissed(request, step);
}

class PortalSurveySheet extends StatefulWidget {
  const PortalSurveySheet({
    required this.tramiteName,
    required this.onAnswered,
    this.onStepChanged,
    super.key,
  });

  final String tramiteName;
  final void Function(PortalSurveyAnswer answer, PortalSurveyProblem? problem)
  onAnswered;
  final ValueChanged<PortalSurveyStep>? onStepChanged;

  @override
  State<PortalSurveySheet> createState() => _PortalSurveySheetState();
}

class _PortalSurveySheetState extends State<PortalSurveySheet> {
  bool _askingProblem = false;

  static const _answers = [
    (PortalSurveyAnswer.paid, 'Sí, pagué', Icons.check_circle_outline),
    (
      PortalSurveyAnswer.checkedNotPaid,
      'Consulté, pero no pagué',
      Icons.receipt_long_outlined,
    ),
    (PortalSurveyAnswer.problem, 'Tuve un problema', Icons.error_outline),
    (
      PortalSurveyAnswer.justBrowsing,
      'Solo estaba mirando',
      Icons.visibility_outlined,
    ),
  ];

  static const _problems = [
    (PortalSurveyProblem.invoiceNotFound, 'No encontré mi factura'),
    (PortalSurveyProblem.pageFailed, 'La página no cargó o falló'),
    (PortalSurveyProblem.paymentRejected, 'El pago fue rechazado'),
    (PortalSurveyProblem.noPaymentMethod, 'No tenía cómo pagar'),
    (PortalSurveyProblem.other, 'Otro'),
  ];

  void _answer(PortalSurveyAnswer answer, [PortalSurveyProblem? problem]) {
    if (answer == PortalSurveyAnswer.problem && problem == null) {
      setState(() => _askingProblem = true);
      widget.onStepChanged?.call(PortalSurveyStep.problem);
      return;
    }
    widget.onAnswered(answer, problem);
    final messenger = ScaffoldMessenger.maybeOf(context);
    Navigator.of(context).pop(true);
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('¡Gracias! Tu respuesta nos ayuda a mejorar.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final title = _askingProblem ? '¿Qué pasó?' : '¿Pudiste hacer tu pago?';
    final subtitle = _askingProblem
        ? 'Elige lo que más se parezca.'
        : 'Cuéntanos cómo te fue en el portal de ${widget.tramiteName}.';

    final options = _askingProblem
        ? [
            for (final (problem, label) in _problems)
              _OptionButton(
                label: label,
                onTap: () => _answer(PortalSurveyAnswer.problem, problem),
              ),
          ]
        : [
            for (final (answer, label, icon) in _answers)
              _OptionButton(
                label: label,
                icon: icon,
                onTap: () => _answer(answer),
              ),
          ];

    // Desplazable: en pantallas bajas las cinco opciones del motivo no caben.
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Cerrar',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            for (final option in options) ...[
              option,
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({required this.label, required this.onTap, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        side: BorderSide(color: scheme.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
