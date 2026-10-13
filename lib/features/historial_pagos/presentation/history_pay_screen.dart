import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/payment_history_dto.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/login_bottom_sheet.dart';
import '../../home/presentation/widgets/main_header.dart'
    show ShimmerPlaceholder;
import '../../../core/widgets/circles_decoration.dart';
import '../../../core/widgets/top_bar_navigation.dart';
import '../application/history_pay_notifier.dart';

class HistoryPayScreen extends ConsumerWidget {
  const HistoryPayScreen({required this.municipalityId, super.key});
  final int municipalityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final historyAsync = ref.watch(historyPayNotifierProvider);

    // Cabecera compartida `TopbarNavigation` + adorno de circulos, igual que
    // `HistoryPayScreen.kt`. Ese original NO tiene barra inferior: la barra de
    // la Home no se repite aqui.
    return Stack(
      children: [
        TopBarNavigationScaffold(
          iconAsset: 'assets/images/ico_calendar_history.svg',
          title: 'Historial de pagos',
          description:
              'Desliza hacia abajo y actualiza el estado de tus transacciones.',
          onRefresh: user == null ? null : () => _refresh(ref),
          body: _Frame(
            child: user == null
                ? _SessionCheckMessage(
                    onLogin: () => showLoginBottomSheet(context),
                  )
                : historyAsync.when(
                    data: (list) {
                      if (list.isEmpty) return const _EmptyHistoryMessage();
                      return ListView.separated(
                        padding: const EdgeInsets.all(8),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = list[index];
                          final card = _HistoryCard(
                            item: item,
                            dateText: _formatDate(item.paymentDate),
                          );
                          // Solo los pagos FALLIDA se pueden ocultar deslizando
                          // de derecha a izquierda (idStatusType 2).
                          if (item.idStatusType != 2) return card;
                          return Dismissible(
                            key: ValueKey('history-${item.id}'),
                            direction: DismissDirection.endToStart,
                            background: const _DeleteBackground(),
                            onDismissed: (_) => _hide(context, ref, item.id),
                            child: card,
                          );
                        },
                      );
                    },
                    loading: () => ListView.separated(
                      padding: const EdgeInsets.all(8),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, _) => const _HistoryItemPlaceholder(),
                    ),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error al cargar historial: $e',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref
                                  .read(historyPayNotifierProvider.notifier)
                                  .fetchHistory(),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const CirclesDecoration.branded(),
      ],
    );
  }

  /// Pull-to-refresh: sincroniza con el proveedor los pagos pendientes (antes
  /// el boton "Sync" de cada tarjeta) y recarga la lista.
  Future<void> _refresh(WidgetRef ref) async {
    final notifier = ref.read(historyPayNotifierProvider.notifier);
    final pending = (ref.read(historyPayNotifierProvider).value ?? const [])
        .where((p) => p.idStatusType == 3)
        .map((p) => p.id)
        .toList();
    for (final id in pending) {
      try {
        await notifier.syncPayment(id);
      } catch (_) {
        // Un pago que no se pueda sincronizar no bloquea el resto.
      }
    }
    await notifier.fetchHistory();
  }

  Future<void> _hide(BuildContext context, WidgetRef ref, int id) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(historyPayNotifierProvider.notifier);
    try {
      await notifier.deleteHistory(id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Historial eliminado.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error al eliminar registro: $e')),
      );
      await notifier.fetchHistory();
    }
  }

  String _formatDate(String rawDate) {
    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat('dd/MM/yyyy hh:mm a').format(parsed);
    } catch (_) {
      return rawDate;
    }
  }
}

String _money(double amount) {
  if (amount <= 0) return 'Cargando...';
  final digits = amount
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
  return '\$$digits';
}

String _orLoading(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Cargando...' : v;

/// Port de `SessionCheckMessage`: tarjeta del color primario con el aviso de
/// iniciar sesion y el boton invertido.
class _SessionCheckMessage extends StatelessWidget {
  const _SessionCheckMessage({required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // `Align` suelta el alto mínimo que el scaffold compartido le impone al
    // cuerpo (para llegar al fondo); sin él la tarjeta se estira a toda la
    // pantalla en vez de medir lo que mide su contenido.
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          color: scheme.primary,
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.cancel_outlined,
                      size: 38,
                      color: scheme.onPrimary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '¡Hola!, Por favor inicia sesión para ver tu historial de pagos.',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 16,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: ElevatedButton.icon(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHistoryMessage extends StatelessWidget {
  const _EmptyHistoryMessage();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          'No tienes pagos, aún...',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.grey),
        ),
      ),
    );
  }
}

/// Fondo rojo con papelera que se ve al deslizar un pago FALLIDA.
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete, color: Colors.white, size: 28),
    );
  }
}

/// Port de `HistoryCard`.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item, required this.dateText});
  final PaymentHistoryDTO item;
  final String dateText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final estado = item.statusType.trim().isEmpty
        ? 'DESCONOCIDO'
        : item.statusType;
    final (icon, color) = switch (estado.toUpperCase()) {
      'COMENZADA' => (Icons.hourglass_empty, const Color(0xFFFFC107)),
      'APROBADA' => (Icons.check_circle, const Color(0xFF4CAF50)),
      'FALLIDA' => (Icons.cancel, const Color(0xFFF44336)),
      _ => (Icons.help_outline, Colors.grey),
    };

    return Card(
      margin: EdgeInsets.zero,
      color: scheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _orLoading(item.procedureName),
                    style: theme.textTheme.headlineSmall,
                  ),
                  Text(
                    'Alcaldía de ${_orLoading(item.alcaldia)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        '👤 ${_orLoading(item.userFirtName)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '💰 ${_money(item.amount)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '📅 ${_orLoading(dateText)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 5),
                Text(
                  estado,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
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

/// Port de `HistoryItemPlaceholder` (carga inicial).
class _HistoryItemPlaceholder extends StatelessWidget {
  const _HistoryItemPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      color: Theme.of(context).colorScheme.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerPlaceholder(width: 160, height: 24),
            SizedBox(height: 4),
            ShimmerPlaceholder(width: 110, height: 16),
            SizedBox(height: 12),
            ShimmerPlaceholder(width: 120, height: 16),
            SizedBox(height: 8),
            ShimmerPlaceholder(width: 100, height: 16),
            SizedBox(height: 8),
            ShimmerPlaceholder(width: 90, height: 16),
          ],
        ),
      ),
    );
  }
}

/// Marco redondeado que envuelve el contenido en `HistoryPayScreen.kt`: un
/// borde del color del municipio al 20 % con radio 25 y, dentro, la superficie
/// clara con radio 20.
class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }
}
