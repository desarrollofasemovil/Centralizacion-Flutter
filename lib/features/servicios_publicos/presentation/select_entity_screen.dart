// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'servicios_publicos_theme.dart';
import '../../../core/widgets/app_top_bar.dart';

class InstitutionItem {
  final String id;
  final String name;
  final String referenceId;
  final Color fallbackColor;

  const InstitutionItem({
    required this.id,
    required this.name,
    required this.referenceId,
    required this.fallbackColor,
  });
}

class SelectEntityScreen extends StatefulWidget {
  const SelectEntityScreen({required this.municipalityId, super.key});
  final int municipalityId;

  @override
  State<SelectEntityScreen> createState() => _SelectEntityScreenState();
}

class _SelectEntityScreenState extends State<SelectEntityScreen> {
  String _searchQuery = "";
  bool _isEntitiesExpanded = false;
  bool _isAlcaldiasExpanded = false;

  final List<InstitutionItem> _entities = const [
    InstitutionItem(id: "1", name: "E.S.P Madrid", referenceId: "ID: 3955X", fallbackColor: Colors.blue),
    InstitutionItem(id: "2", name: "EPM", referenceId: "ID: 5211X", fallbackColor: Colors.green),
    InstitutionItem(id: "3", name: "Acueducto Bogotá", referenceId: "ID: 1020X", fallbackColor: Colors.orange),
    InstitutionItem(id: "7", name: "Enel Colombia", referenceId: "ID: 9921X", fallbackColor: Colors.purple),
  ];

  final List<InstitutionItem> _alcaldias = const [
    InstitutionItem(id: "4", name: "Servicios públicos Girón", referenceId: "ID: 3955X", fallbackColor: Colors.teal),
    InstitutionItem(id: "5", name: "Servicios públicos Girardot", referenceId: "ID: 5211X", fallbackColor: Colors.red),
    InstitutionItem(id: "6", name: "Servicios públicos Copacabana", referenceId: "ID: 1234X", fallbackColor: Colors.pink),
    InstitutionItem(id: "8", name: "Servicios públicos Soacha", referenceId: "ID: 7788X", fallbackColor: Colors.amber),
  ];

  List<InstitutionItem> get _displayedEntities {
    final filtered = _searchQuery.trim().isEmpty
        ? _entities
        : _entities.where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    if (_isEntitiesExpanded || _searchQuery.trim().isNotEmpty) {
      return filtered;
    }
    return filtered.take(2).toList();
  }

  List<InstitutionItem> get _displayedAlcaldias {
    final filtered = _searchQuery.trim().isEmpty
        ? _alcaldias
        : _alcaldias.where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    if (_isAlcaldiasExpanded || _searchQuery.trim().isNotEmpty) {
      return filtered;
    }
    return filtered.take(2).toList();
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = Theme.of(context).brightness == Brightness.dark;
    final activeTheme = darkTheme ? ServiciosPublicosTheme.darkTheme : ServiciosPublicosTheme.lightTheme;

    return Theme(
      data: activeTheme,
      child: Scaffold(
        appBar: AppTopBar(
          title: 'Servicios Públicos',
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
          onBack: () => context.pop(),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Seleccionar Entidad',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar institución o servicio...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: darkTheme ? const Color(0xFF1C1C1E) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section 1: Entidades
            _buildSectionHeader(
              title: 'ENTIDADES DISPONIBLES',
              isExpanded: _isEntitiesExpanded || _searchQuery.trim().isNotEmpty,
              count: _entities.length,
              onToggle: () {
                setState(() {
                  _isEntitiesExpanded = !_isEntitiesExpanded;
                });
              },
            ),
            const SizedBox(height: 8),
            ..._displayedEntities.map((item) => _buildEntityItem(item)),
            const SizedBox(height: 24),

            // Section 2: Alcaldías
            _buildSectionHeader(
              title: 'ALCALDÍAS CON SERVICIOS PÚBLICOS',
              isExpanded: _isAlcaldiasExpanded || _searchQuery.trim().isNotEmpty,
              count: _alcaldias.length,
              onToggle: () {
                setState(() {
                  _isAlcaldiasExpanded = !_isAlcaldiasExpanded;
                });
              },
            ),
            const SizedBox(height: 8),
            ..._displayedAlcaldias.map((item) => _buildEntityItem(item)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required bool isExpanded,
    required int count,
    required VoidCallback onToggle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        if (_searchQuery.trim().isEmpty)
          GestureDetector(
            onTap: onToggle,
            child: Text(
              isExpanded ? 'Ocultar entidades' : 'Ver $count entidades',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: ServiciosPublicosTheme.primaryButton,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEntityItem(InstitutionItem item) {
    final darkTheme = Theme.of(context).brightness == Brightness.dark;
    final initials = item.name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase())
        .take(2)
        .join('');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: darkTheme ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: darkTheme ? 0 : 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: item.fallbackColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: item.fallbackColor,
            ),
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          item.referenceId,
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
        onTap: () {
          context.push('/municipality/${widget.municipalityId}/servicios-publicos/scanner-instructions');
        },
      ),
    );
  }
}
