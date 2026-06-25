import 'package:flutter/material.dart';

/// Campo con búsqueda + lista filtrable — generaliza `DocumentTypeDropdown` y
/// `MunicipalitySearchField` del base: un `TextField` con typeahead que despliega
/// las coincidencias en una caja con borde, igual estilo (esquina 12, borde
/// primary/outline/error). Mientras [items] está vacío muestra un spinner.
class SearchableDropdown<T> extends StatefulWidget {
  const SearchableDropdown({
    super.key,
    required this.controller,
    required this.items,
    required this.itemLabel,
    required this.onSelected,
    required this.label,
    this.errorText,
    this.showLeadingSearch = false,
  });

  final TextEditingController controller;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onSelected;
  final String label;
  final String? errorText;
  final bool showLeadingSearch;

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final FocusNode _focus = FocusNode();
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _expanded = _focus.hasFocus));
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focus.dispose();
    super.dispose();
  }

  List<T> get _filtered {
    final q = widget.controller.text.toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items
        .where((e) => widget.itemLabel(e).toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasError = widget.errorText != null;
    final filtered = _filtered;
    final loading = widget.items.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            labelText: widget.label,
            filled: true,
            fillColor: scheme.surface,
            prefixIcon: widget.showLeadingSearch
                ? Icon(Icons.search, color: scheme.outline)
                : null,
            suffixIcon: loading
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.outline,
                      ),
                    ),
                  )
                : Icon(
                    _expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: scheme.outline,
                  ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? scheme.error : scheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? scheme.error : scheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
        if (_expanded && filtered.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outline),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final item = filtered[i];
                return ListTile(
                  dense: true,
                  title: Text(
                    widget.itemLabel(item),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onTap: () {
                    widget.controller.text = widget.itemLabel(item);
                    _focus.unfocus();
                    widget.onSelected(item);
                  },
                );
              },
            ),
          ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              widget.errorText!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.error),
            ),
          ),
      ],
    );
  }
}
