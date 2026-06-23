import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/services/api_providers.dart';
import '../../../core/models/department.dart';
import '../../../core/models/municipality.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/storage/user_preferences.dart';

class SelectMunicipalityScreen extends ConsumerStatefulWidget {
  const SelectMunicipalityScreen({super.key});

  @override
  ConsumerState<SelectMunicipalityScreen> createState() =>
      _SelectMunicipalityScreenState();
}

class _SelectMunicipalityScreenState extends ConsumerState<SelectMunicipalityScreen> {
  List<Department> _departments = [];
  List<Municipality> _municipalities = [];
  Department? _selectedDepartment;
  Municipality? _selectedMunicipality;
  bool _savePreference = true;
  bool _isLoadingDeps = false;
  bool _isLoadingMuns = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _isLoadingDeps = true;
      _errorMessage = null;
    });
    try {
      final deps = await ref.read(municipalityApiServiceProvider).getDepartments();
      setState(() {
        _departments = deps;
        _isLoadingDeps = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudieron cargar los departamentos.';
        _isLoadingDeps = false;
      });
    }
  }

  Future<void> _loadMunicipalities(int departmentId) async {
    setState(() {
      _isLoadingMuns = true;
      _municipalities = [];
      _selectedMunicipality = null;
    });
    try {
      final muns = await ref
          .read(municipalityApiServiceProvider)
          .byDepartment(departmentId);
      setState(() {
        _municipalities = muns.where((m) => m.isActive).toList();
        _isLoadingMuns = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudieron cargar los municipios.';
        _isLoadingMuns = false;
      });
    }
  }

  Future<void> _confirmSelection() async {
    if (_selectedDepartment == null || _selectedMunicipality == null) return;

    final prefs = ref.read(userPreferencesProvider);
    await prefs.saveLocation(
      departmentId: _selectedDepartment!.id,
      municipalityId: _selectedMunicipality!.id,
      municipio: _selectedMunicipality!.name,
      guardar: _savePreference,
    );

    if (mounted) {
      context.go(AppRoutes.municipalityPath(_selectedMunicipality!.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Municipio'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selecciona tu ubicación para acceder a los trámites y servicios de tu alcaldía.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
            ],
            // Departamento dropdown
            _isLoadingDeps
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<Department>(
                    decoration: InputDecoration(
                      labelText: 'Departamento',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.map),
                    ),
                    value: _selectedDepartment,
                    items: _departments.map((dep) {
                      return DropdownMenuItem<Department>(
                        value: dep,
                        child: Text(dep.name),
                      );
                    }).toList(),
                    onChanged: (dep) {
                      setState(() {
                        _selectedDepartment = dep;
                      });
                      if (dep != null) {
                        _loadMunicipalities(dep.id);
                      }
                    },
                  ),
            const SizedBox(height: 20),
            // Municipio dropdown
            _isLoadingMuns
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<Municipality>(
                    decoration: InputDecoration(
                      labelText: 'Municipio',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.location_city),
                    ),
                    value: _selectedMunicipality,
                    disabledHint: const Text('Selecciona primero un departamento'),
                    items: _municipalities.isEmpty
                        ? null
                        : _municipalities.map((mun) {
                            return DropdownMenuItem<Municipality>(
                              value: mun,
                              child: Text(mun.name),
                            );
                          }).toList(),
                    onChanged: _selectedDepartment == null
                        ? null
                        : (mun) {
                            setState(() {
                              _selectedMunicipality = mun;
                            });
                          },
                  ),
            const SizedBox(height: 24),
            // Save checkbox
            CheckboxListTile(
              title: const Text('Recordar selección para siguientes inicios'),
              value: _savePreference,
              onChanged: (val) {
                setState(() {
                  _savePreference = val ?? true;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _selectedMunicipality == null ? null : _confirmSelection,
              child: const Text(
                'Ingresar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
