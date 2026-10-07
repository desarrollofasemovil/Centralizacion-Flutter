import 'package:flutter/material.dart';

import '../../../../core/widgets/slide_switcher.dart';

/// Calendario mensual embebido con navegación por deslizamiento. Port de
/// `ui/components/CalendarCustomReminder.kt`.
class CalendarCustomReminder extends StatefulWidget {
  const CalendarCustomReminder({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<CalendarCustomReminder> createState() => _CalendarCustomReminderState();
}

class _CalendarCustomReminderState extends State<CalendarCustomReminder> {
  static const _months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  late DateTime _viewMonth; // primer día del mes visible
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onHorizontalDragUpdate: (d) => _dragOffset += d.delta.dx,
      onHorizontalDragEnd: (_) {
        const threshold = 50.0;
        if (_dragOffset > threshold) {
          _changeMonth(-1);
        } else if (_dragOffset < -threshold) {
          _changeMonth(1);
        }
        _dragOffset = 0;
      },
      child: Container(
        color: theme.colorScheme.surface,
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.keyboard_arrow_left),
                ),
                Text(
                  '${_months[_viewMonth.month - 1]} ${_viewMonth.year}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.keyboard_arrow_right),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // AnimatedContent "calendar_month_animation" (solo slide).
            SlideSwitcher(
              index: _viewMonth.year * 12 + _viewMonth.month,
              fade: false,
              child: _CalendarGrid(
                yearMonth: _viewMonth,
                selectedDate: widget.selectedDate,
                onDateSelected: widget.onDateSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.yearMonth,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime yearMonth;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateTime(yearMonth.year, yearMonth.month + 1, 0).day;
    // Dart: lunes=1 … domingo=7; el original desplaza para empezar en lunes.
    final offset = DateTime(yearMonth.year, yearMonth.month, 1).weekday - 1;
    final totalSlots = daysInMonth + offset;
    final rows = (totalSlots + 6) ~/ 7;

    const dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              for (final d in dayLabels)
                Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (int row = 0; row < rows; row++)
            Row(
              children: [
                for (int col = 0; col < 7; col++)
                  Expanded(
                    child: _dayCell(
                      context,
                      row * 7 + col - offset + 1,
                      daysInMonth,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _dayCell(BuildContext context, int dayValue, int daysInMonth) {
    if (dayValue < 1 || dayValue > daysInMonth) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final date = DateTime(yearMonth.year, yearMonth.month, dayValue);
    final isSelected =
        date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;

    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: GestureDetector(
          onTap: () => onDateSelected(date),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
            ),
            alignment: Alignment.center,
            child: Text(
              '$dayValue',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
