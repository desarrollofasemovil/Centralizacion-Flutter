import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/query_field.dart';
import '../../auth/application/auth_providers.dart';
import 'package:tramiapp_flutter/core/municipality/municipality_repository.dart';
import '../application/tax_notifier.dart';

class ConsultaImpuestoScreen extends ConsumerStatefulWidget {
  const ConsultaImpuestoScreen({required this.municipalityId, required this.taxId, required this.title, super.key});
  final int municipalityId;
  final int taxId;
  final String title;

  @override
  ConsumerState<ConsultaImpuestoScreen> createState() => _ConsultaImpuestoScreenState();
}

class _ConsultaImpuestoScreenState extends ConsumerState<ConsultaImpuestoScreen> {
  final _formKey = GlobalKey<FormState>();
  QueryField? _selectedField;
  final _documentCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _acceptsPolicies = false;
  bool _acceptsConditions = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _documentCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(sessionProvider);
      if (user != null) {
        _documentCtrl.text = user.nationalId;
        _emailCtrl.text = user.email;
      }
    });
  }

  Future<void> _handleQuery(String entityCode) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedField == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione el tipo de documento.')),
      );
      return;
    }
    if (!_acceptsPolicies || !_acceptsConditions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe aceptar las políticas y condiciones para continuar.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(taxNotifierProvider.notifier).getTaxes(
            entityCode: entityCode,
            queryData: _documentCtrl.text.trim(),
            queryField: _selectedField!.fieldName,
            taxId: widget.taxId,
          );

      if (!mounted) return;

      final state = ref.read(taxNotifierProvider);
      setState(() {
        _isLoading = false;
      });

      state.when(
        data: (taxes) {
          if (taxes.isEmpty) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Consulta sin resultados'),
                content: const Text('No se encontraron facturas asociadas a los datos ingresados.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            );
          } else {
            // Navigate to results screen, passing taxes and email
            context.push(
              '/municipality/${widget.municipalityId}/taxes/results',
              extra: {
                'taxes': taxes,
                'email': _emailCtrl.text.trim(),
              },
            );
          }
        },
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al consultar facturas: $e')),
          );
        },
        loading: () {},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de red: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final asyncMun = ref.watch(municipalityProvider(widget.municipalityId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      body: asyncMun.maybeWhen(
        data: (munDto) {
          final queryFields = munDto.queryFields;

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: scheme.primary.withValues(alpha: 0.1),
                        radius: 28,
                        child: Icon(Icons.description, size: 28, color: scheme.primary),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Consulta tus facturas y haz el pago de tus impuestos de manera rápida y segura.',
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Dropdown Tipo de documento
                  DropdownButtonFormField<QueryField>(
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Documento/Consulta',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedField,
                    items: queryFields.map((qf) {
                      return DropdownMenuItem<QueryField>(
                        value: qf,
                        child: Text(qf.queryFieldType),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedField = val;
                      });
                    },
                    validator: (v) => v == null ? 'Seleccione tipo de consulta' : null,
                  ),
                  const SizedBox(height: 16),
                  // Document number
                  TextFormField(
                    controller: _documentCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Número de documento o consulta',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese el número de consulta' : null,
                  ),
                  const SizedBox(height: 16),
                  // Email
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Ingrese su correo electrónico';
                      if (!v.contains('@')) return 'Correo electrónico inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Policies checkboxes
                  CheckboxListTile(
                    title: const Text(
                      'Acepto el tratamiento de datos personales de acuerdo con la política de privacidad.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _acceptsPolicies,
                    onChanged: (val) {
                      setState(() {
                        _acceptsPolicies = val ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text(
                      'Acepto las condiciones de uso y términos del servicio.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _acceptsConditions,
                    onChanged: (val) {
                      setState(() {
                        _acceptsConditions = val ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: () => _handleQuery(munDto.entityCode),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: const Text('Consultar'),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        orElse: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
