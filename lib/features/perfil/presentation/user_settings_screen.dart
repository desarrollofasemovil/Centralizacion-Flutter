import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/login_bottom_sheet.dart';
import '../application/user_settings_notifier.dart';
import 'widgets/additional_settings_sheet.dart';
import 'widgets/change_password_sheet.dart';
import 'widgets/notifications_config_sheet.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/important_alert_dialog.dart';

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
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppTopBar(
        title: 'Configuración',
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _rowPadding),
                child: isLoggedIn
                    ? _Greeting(firstName: user.firstName)
                    : Text(
                        'Invitado',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

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
                _SettingItem(
                  icon: Icons.tune,
                  title: 'Configuración adicional',
                  onTap: () => _openAdditionalSettings(context, notifier),
                ),
              ] else
                _SettingItem(
                  icon: Icons.person_outline,
                  title: 'Iniciar sesión',
                  // `UserSettingsScreen.kt` cierra el "Inicio de sesión
                  // exitoso" a los 1,5 s (no 2 como la Home).
                  onTap: () => showLoginBottomSheet(
                    context,
                    successDialogDuration: const Duration(milliseconds: 1500),
                  ),
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

  void _openAdditionalSettings(
    BuildContext context,
    UserSettingsNotifier notifier,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => AdditionalSettingsSheet(
        onDeleteAccount: () {
          Navigator.of(sheetContext).pop();
          _confirmDeleteAccount(context, notifier);
        },
      ),
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
      builder: (ctx) => ConfirmationDialog(
        title: 'Cambio de municipio',
        message: '¿Estás seguro que deseas cambiar de municipio?',
        icon: Icons.swap_horiz,
        // "Si, Cambiar" en el original; se corrige la tilde.
        confirmButtonText: 'Sí, Cambiar',
        dismissButtonText: 'Cancelar',
        onDismiss: () => Navigator.of(ctx).pop(),
        onConfirm: () {
          Navigator.of(ctx).pop();
          notifier.confirmChangeLocation();
        },
      ),
    );
  }

  void _confirmDeleteAccount(
    BuildContext context,
    UserSettingsNotifier notifier,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => ImportantAlertDialog(
        title: 'Eliminar Cuenta',
        // "de forma permanentemente" en el original; se corrige la errata.
        message: 'Esta acción eliminará todos tus datos de forma permanente.',
        confirmButtonText: 'Confirmar',
        onDismissRequest: () => Navigator.of(ctx).pop(),
        onConfirmRequest: () {
          Navigator.of(ctx).pop();
          notifier.deleteAccount();
        },
      ),
    );
  }
}

// =============================================================================
// Widgets
// =============================================================================
/// Saludo de la cabecera: "Hola," y el primer nombre del usuario.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // `firstName` puede traer varios nombres ("Brayan Andrés"): solo el primero.
    final name = firstName.trim().split(RegExp(r'\s+')).first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola,',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (name.isNotEmpty)
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

/// Padding horizontal común de las filas: el divisor arranca en el borde del
/// icono y termina en el borde derecho de la fila, usando este mismo valor.
const double _rowPadding = 10;

/// Fila de modo oscuro: idéntica a los demás items, con el icono sol/luna
/// animado y una píldora sol | luna en lugar de la flecha.
class _DarkModeRow extends StatelessWidget {
  const _DarkModeRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingItem(
      icon: value ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
      title: 'Modo oscuro',
      onTap: () => onChanged(!value),
      trailing: _ThemePill(isDark: value),
    );
  }
}

class _ThemePill extends StatelessWidget {
  const _ThemePill({required this.isDark});

  final bool isDark;

  static const _duration = Duration(milliseconds: 220);
  static const _thumb = 28.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inactive = scheme.onSurface.withValues(alpha: 0.5);
    return Semantics(
      toggled: isDark,
      label: 'Modo oscuro',
      excludeSemantics: true,
      child: Container(
        width: _thumb * 2 + 4,
        height: _thumb + 4,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular((_thumb + 4) / 2),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: _duration,
              curve: Curves.easeOutCubic,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: _thumb,
                height: _thumb,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Row(
              children: [
                _PillIcon(
                  icon: Icons.light_mode_outlined,
                  color: isDark ? inactive : scheme.onPrimary,
                  duration: _duration,
                ),
                _PillIcon(
                  icon: Icons.dark_mode_outlined,
                  color: isDark ? scheme.onPrimary : inactive,
                  duration: _duration,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PillIcon extends StatelessWidget {
  const _PillIcon({
    required this.icon,
    required this.color,
    required this.duration,
  });

  final IconData icon;
  final Color color;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _ThemePill._thumb,
      height: _ThemePill._thumb,
      child: Center(
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: color),
          duration: duration,
          builder: (_, value, _) => Icon(icon, size: 16, color: value),
        ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  const _SettingItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.interactionColor,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? interactionColor;

  /// Reemplaza la flecha final (p. ej. la píldora de modo oscuro).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _rowPadding,
              vertical: 12,
            ),
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
                trailing ??
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: theme.colorScheme.onSurface,
                    ),
              ],
            ),
          ),
        ),
        const _RowDivider(),
      ],
    );
  }
}

/// Divisor mínimo entre filas: del borde del icono al borde derecho.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: _rowPadding,
      endIndent: _rowPadding,
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.08),
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
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, anim) => RotationTransition(
          turns: Tween(begin: 0.85, end: 1.0).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Icon(
          icon,
          key: ValueKey(icon),
          size: 22,
          color: theme.colorScheme.primary,
        ),
      ),
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
