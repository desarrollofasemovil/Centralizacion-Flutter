import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/municipality_procedure.dart';
import '../../../../core/widgets/enter_transition.dart';
import '../../application/reminders_notifier.dart';
import 'calendar_custom_reminder.dart';

/// Muestra el bottom sheet de creación de recordatorio. Port de
/// `CreateReminderModalBottom` del `RemindersScreen.kt`.
Future<void> showCreateReminderModal(
  BuildContext context,
  List<MunicipalityProcedure> procedures,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _CreateReminderSheet(procedures: procedures),
  );
}

class _CreateReminderSheet extends ConsumerWidget {
  const _CreateReminderSheet({required this.procedures});

  final List<MunicipalityProcedure> procedures;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(remindersNotifierProvider.notifier);
    final form = ref.watch(
      remindersNotifierProvider.select((s) => s.formState),
    );

    final initialDate = form.selectedDateMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(
            form.selectedDateMillis!,
            isUtc: true,
          )
        : DateTime.now();

    // Padding inferior para no quedar tapado por el teclado (iOS/Android).
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                'Añadir recordatorio',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    TextField(
                      textInputAction: TextInputAction.next,
                      style: theme.textTheme.titleSmall,
                      onChanged: notifier.updateFormName,
                      decoration: InputDecoration(
                        labelText: 'Nombre del recordatorio',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SearchableProcedureDropdown(
                      procedures: procedures,
                      selected: form.selectedProcedure,
                      onSelected: notifier.updateFormProcedure,
                    ),
                    const SizedBox(height: 4),
                    Material(
                      elevation: 1,
                      borderRadius: BorderRadius.circular(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CalendarCustomReminder(
                          selectedDate: initialDate,
                          onDateSelected: (date) {
                            final millis = DateTime.utc(
                              date.year,
                              date.month,
                              date.day,
                            ).millisecondsSinceEpoch;
                            notifier.updateFormDate(millis);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _TimePickerField(
                      time: form.selectedTime,
                      onSelected: notifier.updateFormTime,
                    ),
                    if (form.formError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          form.formError!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    _ToggleRow(
                      icon: Icons.calendar_month,
                      label: 'Agregar a Google Calendar',
                      value: form.addToCalendar,
                      onChanged: notifier.updateFormAddToCalendarToggle,
                    ),
                    if (form.addToCalendar)
                      _ToggleRow(
                        icon: Icons.email_outlined,
                        label: 'Recordatorio por correo',
                        value: form.sendEmail,
                        onChanged: notifier.updateFormEmailToggle,
                      ),
                    const SizedBox(height: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final ok = await notifier.validateAndSubmit();
                        if (ok) navigator.pop();
                      },
                      child: const Text('Crear recordatorio'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 30, color: theme.colorScheme.primary),
          const SizedBox(width: 5),
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({required this.time, required this.onSelected});

  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hora',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              foregroundColor: theme.colorScheme.onSurface,
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
                builder: (ctx, child) => MediaQuery(
                  data: MediaQuery.of(
                    ctx,
                  ).copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                ),
              );
              if (picked != null) onSelected(picked);
            },
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}

/// Dropdown con buscador de trámites. Port de `SearchableProcedureDropdown`.
class _SearchableProcedureDropdown extends StatefulWidget {
  const _SearchableProcedureDropdown({
    required this.procedures,
    required this.selected,
    required this.onSelected,
  });

  final List<MunicipalityProcedure> procedures;
  final MunicipalityProcedure? selected;
  final ValueChanged<MunicipalityProcedure> onSelected;

  @override
  State<_SearchableProcedureDropdown> createState() =>
      _SearchableProcedureDropdownState();
}

class _SearchableProcedureDropdownState
    extends State<_SearchableProcedureDropdown> {
  late final TextEditingController _controller;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.selected?.procedures.name ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<MunicipalityProcedure> get _filtered {
    final q = _controller.text.trim().toLowerCase();
    if (q.isEmpty) return widget.procedures;
    return widget.procedures
        .where((p) => p.procedures.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = theme.colorScheme.surfaceContainerHighest.withValues(
      alpha: 0.5,
    );
    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          EnterTransition(
            offsetDp: -30,
            child: TextField(
              controller: _controller,
              onChanged: (_) => setState(() => _expanded = true),
              onTap: () => setState(() => _expanded = true),
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Selecciona un trámite',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: widget.procedures.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          _expanded
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                        ),
                        onPressed: () => setState(() => _expanded = !_expanded),
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
          // fadeIn() + expandVertically() / fadeOut() + shrinkVertically()
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: !_expanded
                  ? const SizedBox(width: double.infinity)
                  : ConstrainedBox(
                      key: const ValueKey('procedures'),
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: _filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                'No se encontraron trámites',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall,
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) {
                                final p = _filtered[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    p.procedures.name,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  onTap: () {
                                    _controller.text = p.procedures.name;
                                    FocusScope.of(context).unfocus();
                                    setState(() => _expanded = false);
                                    widget.onSelected(p);
                                  },
                                );
                              },
                            ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
