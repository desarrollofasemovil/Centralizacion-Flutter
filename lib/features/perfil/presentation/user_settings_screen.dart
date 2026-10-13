import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/login_bottom_sheet.dart';
import '../application/user_settings_notifier.dart';
import 'widgets/change_password_sheet.dart';
import 'widgets/notifications_config_sheet.dart';
import '../../../core/widgets/app_top_bar.dart';

/// Pantalla de Configuración de usuario. Port de `UserSettingsScreen.kt`.
///
/// Adaptación: se omite el coachmark de notificaciones (onboarding one-shot con
/// posicionamiento por coordenadas) — el resto de opciones se portan fielmente.
class UserSettingsScreen extends ConsumerWidget {
  const UserSettingsScreen({super.key, required this.municipalityId});

  final int municipalityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(userSettingsNotifierProvider.notifier);
    final user = ref.watch(sessionProvider);
    final isDark = ref.watch(themeIsDarkProvider);
    final isLoggedIn = user != null && user.loginStatus;
    final isDeleting = ref.watch(
      userSettingsNotifierProvider.select((s) => s.isDeleting),
    );

    // Mensajes transitorios → SnackBar.
    ref.listen<String?>(userSettingsNotifierProvider.select((s) => s.message), (
      prev,
      next,
    ) {
      if (next != null && next.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next)));
        notifier.consumeMessage();
      }
    });

    // Navegación a Welcome (cambio de municipio, logout, cuenta eliminada).
    ref.listen<bool>(
      userSettingsNotifierProvider.select((s) => s.navigateToWelcome),
      (prev, next) {
        if (next) {
          notifier.consumeNavigation();
          context.go(AppRoutes.welcome);
        }
      },
    );

    if (isDeleting) {
      return const _FullScreenLoader(
        message:
            'Estamos eliminando todos tus datos.\nPronto serás redireccionado.',
      );
    }

    return Scaffold(
      appBar: AppTopBar(
        title: 'Configuración',
        backgroundColor: theme.colorScheme.surface,
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  size: 64,
                  color: theme.colorScheme.surface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                (user != null && user.loginStatus)
                    ? '${user.firstName} ${user.lastName}'
                    : 'Invitado',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              // Modo oscuro
              _DarkModeRow(
                value: isDark,
                onChanged: (_) =>
                    ref.read(themeIsDarkProvider.notifier).toggle(),
              ),
              _SettingItem(
                icon: Icons.notifications_outlined,
                title: 'Notificaciones',
                onTap: () => _openNotifications(context),
              ),
              _SettingItem(
                icon: Icons.location_on_outlined,
                title: 'Cambiar de alcaldía',
                onTap: () => _confirmChangeLocation(context, notifier),
              ),
              if (isLoggedIn) ...[
                _SettingItem(
                  icon: Icons.edit_outlined,
                  title: 'Editar información',
                  onTap: () =>
                      context.push(AppRoutes.editProfilePath(municipalityId)),
                ),
                _SettingItem(
                  icon: Icons.lock_outline,
                  title: 'Cambiar contraseña',
                  onTap: () => _openChangePassword(context, notifier),
                ),
                _SettingItem(
                  icon: Icons.logout,
                  title: 'Cerrar sesión',
                  interactionColor: theme.colorScheme.error,
                  onTap: notifier.logout,
                ),
                const SizedBox(height: 15),
                TextButton.icon(
                  onPressed: () => _confirmDeleteAccount(context, notifier),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  icon: const Icon(Icons.warning_amber_rounded, size: 24),
                  label: const Text('Eliminar mi cuenta'),
                ),
              ] else
                _SettingItem(
                  icon: Icons.person_outline,
                  title: 'Iniciar sesión',
                  onTap: () => showLoginBottomSheet(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNotifications(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const NotificationsConfigSheet(),
    );
  }

  void _openChangePassword(
    BuildContext context,
    UserSettingsNotifier notifier,
  ) {
    notifier.resetPasswordForm();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const ChangePasswordSheet(),
    );
  }

  void _confirmChangeLocation(
    BuildContext context,
    UserSettingsNotifier notifier,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.swap_horiz, color: Theme.of(ctx).colorScheme.primary),
        title: const Text('Cambio de municipio'),
        content: const Text('¿Estás seguro que deseas cambiar de municipio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.confirmChangeLocation();
            },
            child: const Text('Sí, Cambiar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(
    BuildContext context,
    UserSettingsNotifier notifier,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(ctx).colorScheme.error,
        ),
        title: const Text('Eliminar Cuenta'),
        content: const Text(
          'Esta acción eliminará todos tus datos de forma permanente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.deleteAccount();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Widgets
// =============================================================================
class _DarkModeRow extends StatelessWidget {
  const _DarkModeRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            top: 14,
            right: 10,
            bottom: 6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _IconBubble(icon: Icons.dark_mode_outlined),
                  const SizedBox(width: 15),
                  Text(
                    'Modo oscuro',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
        Divider(
          indent: 72,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ],
    );
  }
}

class _SettingItem extends StatelessWidget {
  const _SettingItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.interactionColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? interactionColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                _IconBubble(icon: icon),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: theme.colorScheme.onSurface,
                ),
              ],
            ),
          ),
        ),
        Divider(
          indent: 72,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ],
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 22, color: theme.colorScheme.primary),
    );
  }
}

class _FullScreenLoader extends StatelessWidget {
  const _FullScreenLoader({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
