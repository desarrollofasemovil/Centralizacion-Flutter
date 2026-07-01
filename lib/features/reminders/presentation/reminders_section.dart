import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/municipality_procedure.dart';
import '../../../core/models/reminders_by_user_dto.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../application/reminders_notifier.dart';
import 'widgets/confirmation_dialog.dart';
import 'widgets/create_reminder_modal.dart';
import 'widgets/swipe_up_dismiss_box.dart';

/// Sección de Recordatorios de la Home. Port de `RemindersSection` del
/// `RemindersScreen.kt` original (carrusel de tarjetas + modal de creación).
class RemindersSection extends ConsumerStatefulWidget {
  const RemindersSection({super.key, required this.procedures});

  final List<MunicipalityProcedure> procedures;

  @override
  ConsumerState<RemindersSection> createState() => _RemindersSectionState();
}

class _RemindersSectionState extends ConsumerState<RemindersSection> {
  final PageController _pageController =
      PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openCreateModal() async {
    final notifier = ref.read(remindersNotifierProvider.notifier);
    notifier.toggleModal(true);
    await showCreateReminderModal(context, widget.procedures);
    notifier.toggleModal(false);
  }

  void _confirmDelete(int id) {
    showDialog<void>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Eliminar recordatorio',
        message:
            '¿Estás seguro de que deseas eliminar este recordatorio? Si está pendiente, la notificación se cancelará.',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(remindersNotifierProvider);
    final isLoggedIn = ref.watch(sessionProvider) != null;

    // Toast de un solo uso (equivalente al Channel<ReminderEvent>).
    ref.listen<String?>(
      remindersNotifierProvider.select((s) => s.toastMessage),
      (_, next) {
        if (next != null && next.isNotEmpty) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(next)));
          ref.read(remindersNotifierProvider.notifier).consumeToast();
        }
      },
    );

    final reminders = state.sortedReminders;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Recordatorios',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondary,
                    ),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    onPressed: isLoggedIn ? _openCreateModal : null,
                    icon: Icon(Icons.add, color: theme.colorScheme.primary),
                    tooltip: 'Crear recordatorio',
                  ),
                ),
              ],
            ),
          ),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Cargando recordatorios...'),
            )
          else if (reminders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _ErrorOrEmptyBox(state.error ?? 'No hay recordatorios'),
            ),
          if (reminders.isNotEmpty) ...[
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _pageController,
                itemCount: reminders.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final reminder = reminders[index];
                  final isExpired = state.expiredReminders
                      .any((r) => r.id == reminder.id);
                  final isActivated =
                      state.activatedReminders.contains(reminder.id);
                  final hasWarning =
                      state.remindersToDeleteWarning.contains(reminder.id);

                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double page = _currentPage.toDouble();
                      if (_pageController.hasClients &&
                          _pageController.position.haveDimensions) {
                        page = _pageController.page ?? page;
                      }
                      final delta = (index - page).abs();
                      final scale = 1 - (delta * 0.1).clamp(0.0, 0.1);
                      final opacity = 1 - (delta * 0.3).clamp(0.0, 0.3);
                      return Opacity(
                        opacity: opacity,
                        child: Transform.scale(scale: scale, child: child),
                      );
                    },
                    child: SwipeUpDismissBox(
                      onDismiss: () => _confirmDelete(reminder.id!),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        child: _ReminderCard(
                          reminder: reminder,
                          isExpired: isExpired,
                          isActivated: isActivated,
                          isActiveSendEmail: state.isActiveSendEmail,
                          showAutoDeleteWarning: hasWarning,
                          onTap: () => ref
                              .read(remindersNotifierProvider.notifier)
                              .onReminderClicked(reminder),
                          onDelete: () => _confirmDelete(reminder.id!),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (reminders.length > 1)
              _PagerDots(count: reminders.length, current: _currentPage),
          ],
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.isExpired,
    required this.isActivated,
    required this.isActiveSendEmail,
    required this.showAutoDeleteWarning,
    required this.onTap,
    required this.onDelete,
  });

  final RemindersByUserDto reminder;
  final bool isExpired;
  final bool isActivated;
  final bool isActiveSendEmail;
  final bool showAutoDeleteWarning;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = reminder.idProcedureMunicipalityNavigation;

    final title = (reminder.reminderName?.trim().isNotEmpty ?? false)
        ? reminder.reminderName!
        : (nav?.procedures.name ?? 'N/A');
    final muniName = nav?.municipality?.name;
    final nombreAlcaldia = (muniName != null && muniName.trim().isNotEmpty)
        ? 'Alcaldía de $muniName'
        : 'Alcaldía';
    final timeText =
        reminder.reminderTime != null ? 'a las ${reminder.reminderTime}' : '';

    final onVariant = theme.colorScheme.onSurfaceVariant;

    return Card(
      elevation: 2,
      color: isExpired
          ? theme.colorScheme.surfaceContainerHighest
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 150,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: onDelete,
                iconSize: 18,
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
            ),
            InkWell(
              onTap: onTap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isExpired
                                ? AppColors.gray600
                                : theme.colorScheme.primary
                                    .withValues(alpha: 0.15),
                          ),
                          child: Icon(
                            isExpired
                                ? Icons.notifications_off
                                : Icons.notifications_active,
                            size: 36,
                            color: isExpired
                                ? AppColors.gray900
                                : theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isExpired
                                      ? Colors.grey
                                      : theme.colorScheme.onSecondary,
                                ),
                              ),
                              if (reminder.reminderName?.trim().isNotEmpty ??
                                  false)
                                Text(
                                  nav?.procedures.name ?? 'Trámite',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: onVariant),
                                ),
                              Text(
                                nombreAlcaldia,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: onVariant),
                              ),
                              Text(
                                'Vencimiento: ${reminder.vigenciaDate ?? 'N/A'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: onVariant),
                              ),
                              Text(
                                'Hora: $timeText',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: onVariant),
                              ),
                              if (isActiveSendEmail)
                                Text(
                                  'Notificación por correo activa',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showAutoDeleteWarning)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        'Este recordatorio ya venció y se eliminará pronto.',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
            if (!showAutoDeleteWarning)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    size: 16,
                    color: Colors.grey.withValues(alpha: 0.8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PagerDots extends StatelessWidget {
  const _PagerDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    const maxIndicators = 3;
    final indicatorCount = count < maxIndicators ? count : maxIndicators;
    final activeIndex = count <= maxIndicators
        ? current
        : ((current / (count - 1)) * (maxIndicators - 1)).round();

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < indicatorCount; i++)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeIndex == i ? AppColors.loginBlue : Colors.grey.shade300,
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorOrEmptyBox extends StatelessWidget {
  const _ErrorOrEmptyBox(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outlineVariant;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(15),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(color: border),
      ),
    );
  }
}
