import 'package:flutter/material.dart';
import '../../../tramites/domain/info_tramite.dart';
import 'tramite_card.dart';

class TramitesSection extends StatelessWidget {
  final String titulo;
  final List<InfoTramite> tramites;
  final String searchText;
  final bool isSearchActive;
  final bool isSearchable;
  final bool isLoading;
  final ValueChanged<String> onSearchTextChanged;
  final VoidCallback onSearchToggled;
  final ValueChanged<InfoTramite> onTramiteClick;

  const TramitesSection({
    super.key,
    required this.titulo,
    required this.tramites,
    required this.searchText,
    required this.isSearchActive,
    this.isSearchable = true,
    required this.isLoading,
    required this.onSearchTextChanged,
    required this.onSearchToggled,
    required this.onTramiteClick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSecondaryColor = theme.colorScheme.onSecondary;

    final filtered = tramites.where((t) {
      if (!isSearchActive || searchText.isEmpty) return true;
      return t.nombre.toLowerCase().contains(searchText.toLowerCase());
    }).toList();

    // Chunking function helper
    List<List<T>> chunk<T>(List<T> list, int size) {
      final chunks = <List<T>>[];
      for (var i = 0; i < list.length; i += size) {
        final end = (i + size < list.length) ? i + size : list.length;
        chunks.add(list.sublist(i, end));
      }
      return chunks;
    }

    final rows = chunk(filtered, 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: !isSearchActive
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          titulo,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: onSecondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : TextField(
                        onChanged: onSearchTextChanged,
                        style: TextStyle(
                          color: onSecondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        decoration: InputDecoration(
                          hintText: "Buscar trámites...",
                          hintStyle: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          border: InputBorder.none,
                        ),
                        autofocus: true,
                      ),
              ),
              if (isSearchable)
                IconButton(
                  onPressed: onSearchToggled,
                  icon: Icon(
                    isSearchActive ? Icons.close : Icons.search,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: isLoading
              ? Column(
                  children: List.generate(2, (_) {
                    return Row(
                      children: List.generate(3, (_) {
                        return const Expanded(
                          child: TramiteCardPlaceholder(),
                        );
                      }),
                    );
                  }),
                )
              : Column(
                  children: rows.map((filaDeTramites) {
                    final emptySlots = 3 - filaDeTramites.length;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...filaDeTramites.map((tramite) {
                          return Expanded(
                            child: TramiteCard(
                              cardinfo: tramite,
                              onClick: () => onTramiteClick(tramite),
                            ),
                          );
                        }),
                        ...List.generate(emptySlots, (_) => const Expanded(child: SizedBox())),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
