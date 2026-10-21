import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/models/municipality_procedure.dart';
import '../../../core/models/reminders_by_user_dto.dart';
import '../../../core/municipality/municipality_repository.dart';
import '../../../core/widgets/circles_decoration.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/top_bar_navigation.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/login_bottom_sheet.dart';
import '../application/reminders_notifier.dart';
import '../domain/reminder_schedule.dart';
import '../domain/reminders_state.dart';
import 'reminder_toast_listener.dart';
import 'widgets/create_reminder_modal.dart';

/// "Mis recordatorios": la lista completa, crear y eliminar. Reemplaza a la
/// sección (carrusel) que vivía en la Home y casi no se usaba; en la Home
/// queda solo un aviso cuando hay uno próximo (`UpcomingReminderBanner`).
///
/// Los recordatorios se guardan en el backend por usuario, así que sin sesión
/// (o como invitado) la pantalla explica el beneficio y ofrece iniciar sesión.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({required this.municipalityId, super.key});

  final int municipalityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(sessionProvider)?.loginStatus == true;
    final state = ref.watch(remindersNotifierProvider);
    final notifier = ref.read(remindersNotifierProvider.notifier);
    final procedures =
        ref
            .watch(municipalityProvider(municipalityId))
            .value
            ?.municipalityProcedures ??
        const <MunicipalityProcedure>[];

    return ReminderToastListener(
      child: Stack(
        children: [
          TopBarNavigationScaffold(
            iconAsset: 'assets/images/ico_calendar_history.svg',
            title: 'Mis recordatorios',
            description:
                'Te avisamos antes de que venzan tus pagos y trámites.',
            onRefresh: isLoggedIn ? notifier.reload : null,
            collapseOnlyWhenContentOverflows: true,
            bottomBar: isLoggedIn
                ? _CreateButton(
                    onPressed: () => _create(context, ref, procedures),
                  )
                : null,
            body: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: !isLoggedIn
                  ? _SignInCard(onLogin: () => showLoginBottomSheet(context))
                  : _RemindersBody(
                      state: state,
                      onRetry: notifier.reload,
                      onDelete: (id) => _confirmDelete(context, ref, id),
                    ),
            ),
          ),
          const CirclesDecoration.branded(),
        ],
      ),
    );
  }

  Future<void> _create(
    BuildContext context,
    WidgetRef ref,
    List<MunicipalityProcedure> procedures,
  ) async {
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .logReminderStarted(
            municipalityId: municipalityId,
            origin: ReminderOrigin.screen,
            hasSession: true,
          ),
    );
    final notifier = ref.read(remindersNotifierProvider.notifier);
    notifier.toggleModal(true);
    await showCreateReminderModal(context, procedures);
    notifier.toggleModal(false);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, int id) {
    showDialog<void>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Eliminar recordatorio',
        message:
            '¿Estás seguro de que deseas eliminar este recordatorio? Si está '
            'pendiente, la notificación se cancelará.',
        icon: Icons.delete,
        confirmButtonText: 'Eliminar',
        dismissButtonText: 'Cancelar',
        onConfirm: () {
          Navigator.of(ctx).pop();
          ref.read(remindersNotifierProvider.notifier).deleteReminder(id);
        },
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }
}

class _RemindersBody extends StatelessWidget {
  const _RemindersBody({
    required this.state,
    required this.onRetry,
    required this.onDelete,
  });

  final RemindersUiState state;
  final VoidCallback onRetry;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    final reminders = state.reminders;
    if (reminders.isEmpty) {
      if (state.isLoading) {
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final error = state.error;
      if (error != null) {
        return _Message(
          icon: Icons.cloud_off_outlined,
          title: 'No pudimos cargar tus recordatorios',
          text: error,
          action: TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        );
      }
      return const _Message(
        icon: Icons.notifications_none,
        title: 'Aún no tienes recordatorios',
        text:
            'Crea uno con el botón de abajo o desde tus facturas, con '
            '"Recordarme antes del vencimiento".',
      );
    }

    // Los próximos primero (por fecha); los vencidos al final.
    final expiredIds = {for (final r in state.expiredReminders) r.id};
    final sorted = [...reminders]
      ..sort((a, b) {
        final aExpired = expiredIds.contains(a.id) ? 1 : 0;
        final bExpired = expiredIds.contains(b.id) ? 1 : 0;
        if (aExpired != bExpired) return aExpired - bExpired;
        final aAt = reminderDateTime(a);
        final bAt = reminderDateTime(b);
        if (aAt == null || bAt == null) return 0;
        return aAt.compareTo(bAt);
      });
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        for (final reminder in sorted)
          _ReminderTile(
            reminder: reminder,
            isExpired: expiredIds.contains(reminder.id),
            now: now,
            onDelete: reminder.id == null ? null : () => onDelete(reminder.id!),
          ),
      ],
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.reminder,
    required this.isExpired,
    required this.now,
    required this.onDelete,
  });

  final RemindersByUserDto reminder;
  final bool isExpired;
  final DateTime now;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final procedureName =
        reminder.idProcedureMunicipalityNavigation?.procedures.name;
    final customName = reminder.reminderName?.trim() ?? '';
    final title = customName.isNotEmpty
        ? customName
        : (procedureName ?? 'Recordatorio');
    final showProcedure =
        customName.isNotEmpty &&
        procedureName != null &&
        procedureName != customName;

    final at = reminderDateTime(reminder);
    final whenText = at == null
        ? (reminder.vigenciaDate ?? '')
        : DateFormat('dd/MM/yyyy · HH:mm').format(at);
    final accent = isExpired ? scheme.outline : scheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: isExpired ? scheme.surfaceContainerHighest : scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
              ),
              child: Icon(
                isExpired
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_active_outlined,
                color: accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isExpired ? scheme.outline : scheme.onSurface,
                    ),
                  ),
                  if (showProcedure)
                    Text(
                      procedureName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        whenText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      _Chip(
                        text: isExpired
                            ? 'Vencido · se eliminará pronto'
                            : (at == null
                                  ? 'Programado'
                                  : relativeDayLabel(at, now: now)),
                        color: isExpired ? scheme.error : scheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Eliminar recordatorio',
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Mensaje centrado con ícono (vacío / error).
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.text,
    this.action,
  });

  final IconData icon;
  final String title;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.10),
            ),
            child: Icon(icon, size: 36, color: scheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

/// Sin sesión: tarjeta del color del municipio (como el aviso de Historial)
/// que explica para qué sirve y lleva a iniciar sesión.
class _SignInCard extends StatelessWidget {
  const _SignInCard({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.primary,
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.notifications_active_outlined,
              size: 36,
              color: scheme.onPrimary,
            ),
            const SizedBox(height: 12),
            Text(
              'Que no se te pase ningún pago',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Inicia sesión y te avisamos antes de que venzan tus impuestos y '
              'trámites. Tus recordatorios quedan guardados en tu cuenta.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimary.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onLogin,
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Iniciar sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.onPrimary,
                foregroundColor: scheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Fondo blanco como el cuerpo: el scaffold compartido pinta de primario
    // lo que no cubre el cuerpo.
    return ColoredBox(
      color: scheme.surfaceContainerLowest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add_alert_outlined),
              label: const Text('Crear recordatorio'),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
