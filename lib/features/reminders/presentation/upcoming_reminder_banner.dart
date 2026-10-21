import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/application/auth_providers.dart';
import '../application/reminders_notifier.dart';
import '../domain/reminder_schedule.dart';

/// Aviso de la Home cuando hay un recordatorio en los próximos 7 días
/// ("Tienes un recordatorio mañana"). Reemplaza a la sección de
/// Recordatorios: sin sesión o sin nada próximo no ocupa espacio. Al tocarlo
/// se abre "Mis recordatorios".
class UpcomingReminderBanner extends ConsumerWidget {
  const UpcomingReminderBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(sessionProvider)?.loginStatus == true;
    final reminders = ref.watch(
      remindersNotifierProvider.select((s) => s.reminders),
    );
    if (!isLoggedIn) return const SizedBox.shrink();

    final now = DateTime.now();
    final next = nextUpcomingReminder(reminders, now: now);
    final at = next == null ? null : reminderDateTime(next);
    if (next == null || at == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = (next.reminderName?.trim().isNotEmpty ?? false)
        ? next.reminderName!.trim()
        : (next.idProcedureMunicipalityNavigation?.procedures.name ??
              'Recordatorio');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary,
                  ),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    size: 22,
                    color: scheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tienes un recordatorio ${relativeDayLabel(at, now: now)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        '$name · ${DateFormat('HH:mm').format(at)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
