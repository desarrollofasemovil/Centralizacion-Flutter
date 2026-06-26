import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tramiapp_flutter/core/municipality/municipality_repository.dart';
import '../../impuestos/domain/tax.dart';
import '../application/psv_notifier.dart';
import '../domain/psv_state.dart';

class PsvWizard extends ConsumerStatefulWidget {
  const PsvWizard({
    required this.municipalityId,
    required this.taxId,
    required this.taxName,
    required this.entityCode,
    required this.dataPolicyUrl,
    required this.privacyPolicyUrl,
    super.key,
  });

  final int municipalityId;
  final int taxId;
  final String taxName;
  final String entityCode;
  final String dataPolicyUrl;
  final String privacyPolicyUrl;

  @override
  ConsumerState<PsvWizard> createState() => _PsvWizardState();
}

class _PsvWizardState extends ConsumerState<PsvWizard> {
  int _currentStep = 1;
  bool _isSubmitting = false;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  final _documentCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  final _invoiceCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _acceptsPolicies = false;
  bool _acceptsConditions = false;

  @override
  void dispose() {
    _documentCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _invoiceCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Prepopulate bank and clear state
      ref.read(psvFormNotifierProvider.notifier).reset();
      
      final asyncMun = ref.read(municipalityProvider(widget.municipalityId));
      asyncMun.whenData((mun) {
        ref.read(psvFormNotifierProvider.notifier).updateField(
          (s) => s.copyWith(selectedBank: mun.bank.nameBank),
        );
      });
    });
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_formKey1.currentState!.validate()) {
        ref.read(psvFormNotifierProvider.notifier).updateField((s) => s.copyWith(
              documentNumber: _documentCtrl.text.trim(),
              fullName: _nameCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
            ));
        setState(() {
          _currentStep = 2;
        });
      }
    } else if (_currentStep == 2) {
      if (_formKey2.currentState!.validate()) {
        final amt = int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
        ref.read(psvFormNotifierProvider.notifier).updateField((s) => s.copyWith(
              invoiceNumber: _invoiceCtrl.text.trim(),
              amount: amt,
              description: _descCtrl.text.trim(),
            ));
        setState(() {
          _currentStep = 3;
        });
      }
    }
  }

  void _prevStep() {
    setState(() {
      _currentStep = _currentStep - 1;
    });
  }

  Future<void> _submit(String bankName) async {
    if (!_acceptsPolicies || !_acceptsConditions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe aceptar las políticas y condiciones para continuar.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final state = ref.read(psvFormNotifierProvider);
      
      // Determine integrationType (matched procedure integrationType)
      final asyncMun = ref.read(municipalityProvider(widget.municipalityId));
      final mun = asyncMun.value;
      final matchedProcedure = mun?.municipalityProcedures.firstWhere(
        (p) => p.procedures.id == widget.taxId,
        orElse: () => throw Exception('Procedimiento no encontrado'),
      );
      final integrationType = matchedProcedure?.integrationType ?? 'psv';

      final gatewayInfo = await ref.read(psvFormNotifierProvider.notifier).submitPsv(
            municipalityId: widget.municipalityId,
            entityCode: widget.entityCode,
            taxId: widget.taxId,
            taxName: widget.taxName,
            integrationType: integrationType,
          );

      setState(() {
        _isSubmitting = false;
      });

      // Construct a mock Tax object to pass to the processing screen
      final taxMock = Tax(
        entity: 'Pago Sin Validación',
        entityCode: widget.entityCode,
        document: state.documentNumber,
        name: state.fullName,
        taxName: widget.taxName,
        taxId: widget.taxId,
        value: state.amount,
        invoice: state.invoiceNumber.isNotEmpty ? state.invoiceNumber : 'PSV',
        reference: state.invoiceNumber.isNotEmpty ? state.invoiceNumber : 'PSV',
        dueDate: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        queryField: 'Manual',
      );

      if (mounted) {
        context.push(
          '/municipality/${widget.municipalityId}/pagos/processing',
          extra: {
            'paymentUrl': gatewayInfo.url,
            'tax': taxMock,
          },
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar el pago: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(psvFormNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taxName),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Iniciando proceso de pago...'),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: _buildStepIndicator(_currentStep, scheme),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: _currentStep == 1
                        ? _buildStep1(state, scheme)
                        : _currentStep == 2
                            ? _buildStep2(state, scheme)
                            : _buildStep3(state, scheme),
                  ),
                ),
                _buildNavButtons(state, scheme),
              ],
            ),
    );
  }

  Widget _buildStepIndicator(int currentStep, ColorScheme scheme) {
    return Row(
      children: List.generate(5, (index) {
        if (index.isEven) {
          final stepNum = index ~/ 2 + 1;
          final isActive = stepNum <= currentStep;
          return CircleAvatar(
            radius: 16,
            backgroundColor: isActive ? scheme.primary : Colors.grey[300],
            foregroundColor: isActive ? scheme.onPrimary : Colors.black87,
            child: Text('$stepNum', style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        } else {
          return Expanded(
            child: Container(
              height: 2,
              color: Colors.grey[300],
            ),
          );
        }
      }),
    );
  }

  Widget _buildStep1(PsvFormState state, ColorScheme scheme) {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Información Personal',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingrese los datos del contribuyente que realiza el pago.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: state.documentType,
            decoration: const InputDecoration(
              labelText: 'Tipo de Documento',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'CC', child: Text('Cédula de Ciudadanía (CC)')),
              DropdownMenuItem(value: 'CE', child: Text('Cédula de Extranjería (CE)')),
              DropdownMenuItem(value: 'NIT', child: Text('Número de Identificación Tributaria (NIT)')),
              DropdownMenuItem(value: 'PP', child: Text('Pasaporte (PP)')),
            ],
            onChanged: (val) {
              if (val != null) {
                ref.read(psvFormNotifierProvider.notifier).updateField(
                      (s) => s.copyWith(documentType: val),
                    );
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _documentCtrl,
            decoration: const InputDecoration(
              labelText: 'Número de Documento',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese el número de documento' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre Completo',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese su nombre completo' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailCtrl,
            decoration: const InputDecoration(
              labelText: 'Correo Electrónico',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingrese su correo electrónico';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                return 'Ingrese un correo electrónico válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(
              labelText: 'Teléfono Celular',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese su teléfono celular' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(PsvFormState state, ColorScheme scheme) {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Detalles de Pago',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingrese los datos específicos del concepto o documento a pagar.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _invoiceCtrl,
            decoration: const InputDecoration(
              labelText: 'Número de Factura o Referencia',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese el número de factura o referencia' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountCtrl,
            decoration: const InputDecoration(
              labelText: 'Valor a Pagar (\$)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingrese el valor a pagar';
              final val = int.tryParse(v.replaceAll(RegExp(r'\D'), ''));
              if (val == null || val <= 0) return 'Ingrese un valor mayor a cero';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Descripción o Concepto (Opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(PsvFormState state, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Confirmación del Pago',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSummaryRow('Trámite/Concepto', widget.taxName),
                _buildSummaryRow('Contribuyente', state.fullName),
                _buildSummaryRow(state.documentType, state.documentNumber),
                _buildSummaryRow('Email', state.email),
                _buildSummaryRow('Teléfono', state.phone),
                const Divider(),
                _buildSummaryRow('Referencia', state.invoiceNumber),
                _buildSummaryRow('Descripción', state.description.isNotEmpty ? state.description : 'Sin descripción'),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total a Pagar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      '\$${state.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: scheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          color: scheme.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.account_balance, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Método de Pago Autorizado', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        state.selectedBank.toLowerCase() == 'coopcentral'
                            ? 'PSE Coopcentral Gateway'
                            : 'Bancolombia Gateway',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        CheckboxListTile(
          value: _acceptsPolicies,
          controlAffinity: ListTileControlAffinity.leading,
          title: Wrap(
            children: [
              const Text('Acepto la ', style: TextStyle(fontSize: 13)),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Abriendo política de datos: ${widget.dataPolicyUrl}')),
                  );
                },
                child: Text(
                  'Política de Tratamiento de Datos',
                  style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          onChanged: (val) {
            setState(() {
              _acceptsPolicies = val ?? false;
            });
          },
        ),
        CheckboxListTile(
          value: _acceptsConditions,
          controlAffinity: ListTileControlAffinity.leading,
          title: Wrap(
            children: [
              const Text('Acepto los ', style: TextStyle(fontSize: 13)),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Abriendo condiciones de uso: ${widget.privacyPolicyUrl}')),
                  );
                },
                child: Text(
                  'Términos y Condiciones de Uso',
                  style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          onChanged: (val) {
            setState(() {
              _acceptsConditions = val ?? false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButtons(PsvFormState state, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 1)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Anterior'),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep == 3 ? () => _submit(state.selectedBank) : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(_currentStep == 3 ? 'Pagar' : 'Siguiente'),
            ),
          ),
        ],
      ),
    );
  }
}
