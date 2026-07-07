import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Inputs reutilizables del formulario de soporte. Port de
/// `help/components/SupportFormInputs.kt` (DatePickerField, MoneyTextField,
/// FiscalYearDropdown) + el helper `EnumDropdown` del wizard.

const _fieldRadius = 10.0;

OutlineInputBorder _border() =>
    OutlineInputBorder(borderRadius: BorderRadius.circular(_fieldRadius));

// =============================================================================
// 1) DatePickerField — selector de fecha (dd/MM/yyyy) con rango acotado.
// =============================================================================
class DatePickerField extends StatefulWidget {
  const DatePickerField({
    super.key,
    required this.value,
    required this.onDateSelected,
    required this.label,
    this.placeholder = 'Toca para seleccionar',
    this.errorText,
  });

  final String value;
  final ValueChanged<String> onDateSelected;
  final String label;
  final String placeholder;
  final String? errorText;

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant DatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static DateTime _todayEnd() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, 23, 59, 59);
  }

  static DateTime _oneYearAgo() {
    final n = DateTime.now();
    return DateTime(n.year - 1, n.month, n.day);
  }

  DateTime? _parse(String v) {
    final parts = v.split('/');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  String _format(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  Future<void> _pick(BuildContext context) async {
    final initial = _parse(widget.value) ?? DateTime.now();
    final first = _oneYearAgo();
    final last = _todayEnd();
    final safeInitial = initial.isBefore(first)
        ? first
        : (initial.isAfter(last) ? last : initial);

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: first,
      lastDate: last,
      helpText: 'Selecciona la fecha del pago',
    );
    if (picked != null) widget.onDateSelected(_format(picked));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      readOnly: true,
      onTap: () => _pick(context),
      controller: _controller,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.placeholder,
        errorText: widget.errorText,
        border: _border(),
        suffixIcon: Icon(Icons.calendar_month, color: theme.colorScheme.primary),
      ),
    );
  }
}

// =============================================================================
// 2) MoneyTextField — input numérico con separador de miles automático.
// =============================================================================
class MoneyTextField extends StatefulWidget {
  const MoneyTextField({
    super.key,
    required this.value,
    required this.onValueChanged,
    required this.label,
    this.placeholder = '0',
    this.errorText,
    this.maxDigits = 12,
  });

  /// Valor crudo (solo dígitos).
  final String value;
  final ValueChanged<String> onValueChanged;
  final String label;
  final String placeholder;
  final String? errorText;
  final int maxDigits;

  @override
  State<MoneyTextField> createState() => _MoneyTextFieldState();
}

class _MoneyTextFieldState extends State<MoneyTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _group(widget.value));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _group(String digits) {
    if (digits.isEmpty) return '';
    final buf = StringBuffer();
    final reversed = digits.split('').reversed.toList();
    for (var i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) buf.write('.');
      buf.write(reversed[i]);
    }
    return buf.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      style: theme.textTheme.bodyMedium,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _ThousandsFormatter(widget.maxDigits),
      ],
      onChanged: (text) => widget.onValueChanged(text.replaceAll('.', '')),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.placeholder,
        errorText: widget.errorText,
        border: _border(),
        prefixText: '\$ ',
      ),
    );
  }
}

/// Formatea el texto insertando puntos como separadores de miles y limita el
/// número de dígitos. Mantiene el cursor al final tras reformatear.
class _ThousandsFormatter extends TextInputFormatter {
  _ThousandsFormatter(this.maxDigits);
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);
    final formatted = _MoneyTextFieldState._group(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// =============================================================================
// 3) FiscalYearDropdown — selector de año fiscal acotado (año actual - N).
// =============================================================================
class FiscalYearDropdown extends StatelessWidget {
  const FiscalYearDropdown({
    super.key,
    required this.value,
    required this.onValueChanged,
    required this.label,
    this.errorText,
    this.yearsBack = 5,
  });

  final String value;
  final ValueChanged<String> onValueChanged;
  final String label;
  final String? errorText;
  final int yearsBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentYear = DateTime.now().year;
    final years = [for (var i = 0; i <= yearsBack; i++) '${currentYear - i}'];
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      isExpanded: true,
      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Selecciona el año',
        errorText: errorText,
        border: _border(),
      ),
      items: [
        for (final y in years)
          DropdownMenuItem(value: y, child: Text(y)),
      ],
      onChanged: (v) {
        if (v != null) onValueChanged(v);
      },
    );
  }
}

// =============================================================================
// 4) EnumDropdown — dropdown genérico para enums / opciones tipadas.
// =============================================================================
class EnumDropdown<T> extends StatelessWidget {
  const EnumDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.displayName,
    required this.onSelected,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final List<T> options;
  final T? selected;
  final String Function(T) displayName;
  final ValueChanged<T> onSelected;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<T>(
      initialValue: selected,
      isExpanded: true,
      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Selecciona una opción',
        errorText: errorText,
        border: _border(),
      ),
      items: [
        for (final o in options)
          DropdownMenuItem(value: o, child: Text(displayName(o))),
      ],
      onChanged: enabled
          ? (v) {
              if (v != null) onSelected(v);
            }
          : null,
    );
  }
}
