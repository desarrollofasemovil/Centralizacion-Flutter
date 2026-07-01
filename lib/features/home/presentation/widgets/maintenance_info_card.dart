import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/app_status.dart';

/// Banner de estado de la app (mantenimiento / actualización forzada / error de
/// servidor). Port de `CardInfoMaintence` (`utils/CardStatusInfo.kt`).
///
/// Se muestra en la Home cuando el estado no es `operational` y no es bloqueante
/// (el bloqueo total lo maneja una pantalla completa aparte). Los colores son
/// semánticos de estado (no de marca), por eso van fijos.
class MaintenanceInfoCard extends ConsumerWidget {
  const MaintenanceInfoCard({super.key});

  static const _appId = 'com.tramites1cero1.centralizacion';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(appStatusProvider);
    if (status.type == AppStatusType.operational || status.isBlocking) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final style = _styleFor(status.type, theme);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: style.background,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: style.content),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(style.icon, color: style.content, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            status.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: style.content,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status.message,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.black.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _actionButton(context, ref, status.type, style),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    WidgetRef ref,
    AppStatusType type,
    _CardStyle style,
  ) {
    void dismiss() => ref.read(appStatusProvider.notifier).clearStatus();

    switch (type) {
      case AppStatusType.forceUpdate:
        return FilledButton(
          style: FilledButton.styleFrom(backgroundColor: style.content),
          onPressed: _openStore,
          child: const Text('Actualizar Ahora'),
        );
      case AppStatusType.serverError:
        return FilledButton(
          style: FilledButton.styleFrom(backgroundColor: style.content),
          onPressed: dismiss,
          child: const Text('Reintentar'),
        );
      case AppStatusType.maintenance:
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: style.content,
            side: BorderSide(color: style.content),
          ),
          onPressed: dismiss,
          child: const Text('Entendido'),
        );
      case AppStatusType.operational:
        return const SizedBox.shrink();
    }
  }

  Future<void> _openStore() async {
    final market = Uri.parse('market://details?id=$_appId');
    final web =
        Uri.parse('https://play.google.com/store/apps/details?id=$_appId');
    try {
      if (!await launchUrl(market, mode: LaunchMode.externalApplication)) {
        await launchUrl(web, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }

  _CardStyle _styleFor(AppStatusType type, ThemeData theme) {
    switch (type) {
      case AppStatusType.serverError:
        return const _CardStyle(
          background: Color(0xFFFDECEA),
          content: Color(0xFFB71C1C),
          icon: Icons.cloud_off,
        );
      case AppStatusType.maintenance:
        return const _CardStyle(
          background: Color(0xFFFFF8E1),
          content: Color(0xFFF57F17),
          icon: Icons.build,
        );
      case AppStatusType.forceUpdate:
        return const _CardStyle(
          background: Color(0xFFE3F2FD),
          content: Color(0xFF0D47A1),
          icon: Icons.system_update,
        );
      case AppStatusType.operational:
        return _CardStyle(
          background: theme.colorScheme.surfaceContainerHighest,
          content: theme.colorScheme.onSurfaceVariant,
          icon: Icons.warning,
        );
    }
  }
}

class _CardStyle {
  const _CardStyle({
    required this.background,
    required this.content,
    required this.icon,
  });

  final Color background;
  final Color content;
  final IconData icon;
}
