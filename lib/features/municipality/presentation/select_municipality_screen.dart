import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/api/services/api_providers.dart';
import '../../../core/models/municipality.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/storage/user_preferences.dart';

/// Selección de municipio — puerto fiel de `selectmunicipality/SelectMunScreen.kt`
/// + `components/SelectMunicipality.kt` (fuente de verdad en `codebase/`). Paso 2
/// del onboarding: recibe el `departmentId` elegido en Welcome, carga sus
/// municipios y los presenta con un buscador de autocompletar sobre fondo de
/// marca, con botones "Cancelar / Continuar".
class SelectMunicipalityScreen extends ConsumerStatefulWidget {
  const SelectMunicipalityScreen({super.key, required this.departmentId});

  final int departmentId;

  @override
  ConsumerState<SelectMunicipalityScreen> createState() =>
      _SelectMunicipalityScreenState();
}

// Colores de acento (de ui/theme/Color.kt).
const _kContinue = Color(0xFF2196F3);
const _kCheckbox = Color(0xFF1E88E5); // Blue

class _SelectMunicipalityScreenState
    extends ConsumerState<SelectMunicipalityScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<Municipality> _municipalities = [];
  Municipality? _selectedMunicipality;
  String _query = '';
  bool _searchFocused = false;
  bool _isLoading = false;
  bool _animate = false;
  bool _savePreference = true;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    });
    _loadMunicipalities();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _animate = true);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadMunicipalities() async {
    setState(() => _isLoading = true);
    try {
      final muns = await ref
          .read(municipalityApiServiceProvider)
          .byDepartment(widget.departmentId);
      if (!mounted) return;
      setState(() {
        _municipalities = muns.where((m) => m.isActive).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// Filtro sin acentos + case-insensitive, ordenado por nombre (replica
  /// `filteredMunicipalities` del SelectMunViewModel).
  List<Municipality> get _filteredMunicipalities {
    final list = _query.trim().isEmpty
        ? [..._municipalities]
        : _municipalities
            .where((m) =>
                _removeAccents(m.name).contains(_removeAccents(_query)))
            .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  void _onMunicipalitySelected(Municipality mun) {
    setState(() {
      _selectedMunicipality = mun;
      _searchController.text = mun.name;
      _query = mun.name;
    });
    _searchFocus.unfocus();
  }

  Future<void> _confirmSelection() async {
    final mun = _selectedMunicipality;
    if (mun == null) return;
    final prefs = ref.read(userPreferencesProvider);
    await prefs.saveLocation(
      departmentId: widget.departmentId,
      municipalityId: mun.id,
      municipio: mun.name,
      guardar: _savePreference,
    );
    if (mounted) context.go(AppRoutes.municipalityPath(mun.id));
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filteredMunicipalities;

    return Scaffold(
      backgroundColor: scheme.primary,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _searchFocus.unfocus(),
          child: Column(
            children: [
              Expanded(
                child: AnimatedOpacity(
                  opacity: _animate ? 1 : 0,
                  duration: const Duration(milliseconds: 500),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        SvgPicture.asset(
                          'assets/images/newtramiapp.svg',
                          width: 100,
                          height: 50,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'Ahora, elige tu municipio de\nresidencia',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _MunicipalitySearch(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onChanged: (v) => setState(() => _query = v),
                          isLoading: _isLoading,
                          showDropdown:
                              _searchFocused && filtered.isNotEmpty,
                          municipalities: filtered,
                          onSelected: _onMunicipalitySelected,
                          textColor: scheme.onSurface,
                        ),
                        const SizedBox(height: 16),
                        _SaveCheckbox(
                          value: _savePreference,
                          onChanged: (v) =>
                              setState(() => _savePreference = v),
                          color: scheme.onPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Barra inferior: Cancelar / Continuar ───────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 8, 26, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _cancel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF212121),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text('Cancelar',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _selectedMunicipality == null
                              ? null
                              : _confirmSelection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kContinue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                _kContinue.withValues(alpha: 0.4),
                            disabledForegroundColor:
                                Colors.white.withValues(alpha: 0.7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text('Continuar',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _removeAccents(String input) {
    const withAccents = 'áàäâãéèëêíìïîóòöôõúùüûñ';
    const without = 'aaaaaeeeeiiiiooooouuuun';
    var s = input.toLowerCase();
    for (var i = 0; i < withAccents.length; i++) {
      s = s.replaceAll(withAccents[i], without[i]);
    }
    return s;
  }
}

/// Tarjeta blanca con buscador + dropdown inline (replica `SelectMunicipio`).
class _MunicipalitySearch extends StatelessWidget {
  const _MunicipalitySearch({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.isLoading,
    required this.showDropdown,
    required this.municipalities,
    required this.onSelected,
    required this.textColor,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool isLoading;
  final bool showDropdown;
  final List<Municipality> municipalities;
  final ValueChanged<Municipality> onSelected;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            style: TextStyle(color: textColor, fontSize: 15),
            decoration: const InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              hintText: 'Buscar municipio...',
              hintStyle: TextStyle(color: Color(0xFF7E7E7E)),
              prefixIcon: Icon(Icons.search, color: Color(0xFF7E7E7E)),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              border: OutlineInputBorder(borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            )
          else if (showDropdown)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: municipalities.length,
                itemBuilder: (context, i) {
                  final mun = municipalities[i];
                  return ListTile(
                    dense: true,
                    title: Text(
                      mun.name,
                      style: TextStyle(color: textColor, fontSize: 15),
                    ),
                    onTap: () => onSelected(mun),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Checkbox "Guardar selección" — puerto de `CheckboxSaveSelection.kt`.
class _SaveCheckbox extends StatelessWidget {
  const _SaveCheckbox({
    required this.value,
    required this.onChanged,
    required this.color,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? true),
              activeColor: _kCheckbox,
              checkColor: Colors.white,
              side: BorderSide(color: color.withValues(alpha: 0.7)),
            ),
            Expanded(
              child: Text(
                'Guardar selección para futuros accesos.',
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
