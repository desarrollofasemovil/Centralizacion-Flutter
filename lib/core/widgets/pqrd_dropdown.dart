import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Dropdown estilizado de los formularios PQRD. Port de
/// `ui/screen/pqrds/components/CustomDropdownPqrds.kt`: campo outlined con
/// esquinas redondeadas (10), etiqueta flotante, flecha, borde primario al
/// enfocar y gris ([AppColors.gray400]) en reposo.
///
/// Usa `isExpanded: true` para que el valor seleccionado nunca desborde el
/// ancho del campo (el bug "RIGHT OVERFLOWED" del diseño anterior).
class PqrdDropdown<T> extends StatelessWidget {
  const PqrdDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.hint,
    this.enabled = true,
    this.validator,
  });

  final String label;
  final String? hint;
  final T? value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: width),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down),
        borderRadius: BorderRadius.circular(12),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: outline(AppColors.gray400),
          enabledBorder: outline(AppColors.gray400),
          focusedBorder: outline(scheme.primary, 2),
          disabledBorder: outline(AppColors.gray400),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  itemLabel(item),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: enabled ? onChanged : null,
        validator: validator,
      ),
    );
  }
}
