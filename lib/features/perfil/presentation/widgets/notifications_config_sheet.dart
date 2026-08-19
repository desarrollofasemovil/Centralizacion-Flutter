import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/local_reminder_scheduler.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/user_settings_notifier.dart';

/// Contenido del bottom sheet de configuración de notificaciones. Port de
/// `NotificationsContent` en `UserSettingsScreen.kt`.
class NotificationsConfigSheet extends ConsumerWidget {
  const NotificationsConfigSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(userSettingsNotifierProvider.notifier);
    final remindersActive = ref.watch(
      userSettingsNotifierProvider.select((s) => s.remindersActive),
    );
    final sendEmailActive = ref.watch(
      userSettingsNotifierProvider.select((s) => s.sendEmailActive),
    );
    final isLoggedIn = ref.watch(sessionProvider)?.loginStatus == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Text(
            'Configurar Notificaciones',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elige cómo quieres recibir las alertas de tus trámites.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _NotificationSwitchItem(
            title: 'Recordatorios Push',
            subtitle: 'Alertas en tu dispositivo',
            icon: Icons.alarm,
            checked: remindersActive,
            onChanged: (v) async {
              await notifier.toggleReminders(v);
              if (v) {
                await ref
                    .read(localReminderSchedulerProvider)
                    .ensureNotificationPermission();
              }
            },
          ),
          const SizedBox(height: 12),
          if (isLoggedIn)
            _NotificationSwitchItem(
              title: 'Notificaciones por Correo',
              subtitle: 'Resumen y alertas al email',
              icon: Icons.mail_outline,
              checked: sendEmailActive,
              onChanged: notifier.toggleSendEmail,
            )
          else
            const _GuestNotificationInfo(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _NotificationSwitchItem extends StatelessWidget {
  const _NotificationSwitchItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.checked,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(!checked),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: checked, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestNotificationInfo extends StatelessWidget {
  const _GuestNotificationInfo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Inicia sesión para activar los recordatorios por correo electrónico.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
