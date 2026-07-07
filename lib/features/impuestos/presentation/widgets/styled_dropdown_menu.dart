import 'package:flutter/material.dart';

/// Puerto de `CustomAnimatedDropdownMenu.kt` (`StyledDropdownMenu`):
/// campo disparador de 55dp con radio 16 sobre `surfaceContainer` y un menú
/// que se expande/contrae animado (200 ms) debajo, con alto máximo de 200dp.
class StyledDropdownMenu<T> extends StatelessWidget {
  const StyledDropdownMenu({
    super.key,
    required this.selectedValue,
    required this.placeholderText,
    required this.isExpanded,
    required this.onExpandedChange,
    required this.options,
    required this.onOptionSelected,
    required this.itemToString,
  });

  final String selectedValue;
  final String placeholderText;
  final bool isExpanded;
  final ValueChanged<bool> onExpandedChange;
  final List<T> options;
  final ValueChanged<T> onOptionSelected;
  final String Function(T) itemToString;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onExpandedChange(!isExpanded),
            child: Container(
              height: 55,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      selectedValue.isEmpty ? placeholderText : selectedValue,
                      // bodyLarge (16sp), igual que el texto de los TextField:
                      // el bodySmall del original de Compose se veía muy
                      // pequeño en Flutter.
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: selectedValue.isEmpty
                            ? scheme.onSurface.withValues(alpha: 0.6)
                            : scheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Menú desplegable con animación de expansión (tween 200ms).
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: (isExpanded && options.isNotEmpty)
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 8,
                    color: scheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: options.map((option) {
                          return InkWell(
                            onTap: () => onOptionSelected(option),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Text(
                                itemToString(option),
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
