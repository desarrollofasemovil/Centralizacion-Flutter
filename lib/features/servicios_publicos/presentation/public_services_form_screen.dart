// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tramiapp_flutter/core/router/app_routes.dart';
import '../application/public_services_form_notifier.dart';
import 'servicios_publicos_theme.dart';

class PublicServicesFormScreen extends ConsumerStatefulWidget {
  const PublicServicesFormScreen({
    required this.municipalityId,
    required this.factura,
    required this.valor,
    required this.fechaVencimiento,
    super.key,
  });

  final int municipalityId;
  final String factura;
  final String valor;
  final String fechaVencimiento;

  @override
  ConsumerState<PublicServicesFormScreen> createState() => _PublicServicesFormScreenState();
}

class _PublicServicesFormScreenState extends ConsumerState<PublicServicesFormScreen> {
  late PublicServicesFamilyParam _familyParam;

  final _documentoCtrl = TextEditingController();
  final _primerNombreCtrl = TextEditingController();
  final _segundoNombreCtrl = TextEditingController();
  final _primerApellidoCtrl = TextEditingController();
  final _segundoApellidoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _isEditing = false;
  bool _aceptaPoliticaDatos = false;
  bool _aceptaCondicionesUso = false;

  @override
  void initState() {
    super.initState();
    _familyParam = PublicServicesFamilyParam(
      municipalityId: widget.municipalityId,
      param: PublicServicesFormParam(
        factura: widget.factura,
        valor: widget.valor,
        fechaVencimiento: widget.fechaVencimiento,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(publicServicesFormNotifierProvider(_familyParam));
      _updateControllers(state);
      _isEditing = (state.pagador.documento?.isEmpty ?? true);
    });
  }

  void _setText(TextEditingController controller, String? value) {
    controller.text = value ?? '';
  }

  void _updateControllers(PublicServicesFormState state) {
    _setText(_documentoCtrl, state.pagador.documento);
    _setText(_primerNombreCtrl, state.pagador.primerNombre);
    _setText(_segundoNombreCtrl, state.pagador.segundoNombre);
    _setText(_primerApellidoCtrl, state.pagador.primerApellido);
    _setText(_segundoApellidoCtrl, state.pagador.segundoApellido);
    _setText(_direccionCtrl, state.pagador.direccion);
    _setText(_telefonoCtrl, state.pagador.telefono);
    _setText(_emailCtrl, state.pagador.email);
  }

  @override
  void dispose() {
    _documentoCtrl.dispose();
    _primerNombreCtrl.dispose();
    _segundoNombreCtrl.dispose();
    _primerApellidoCtrl.dispose();
    _segundoApellidoCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  String _formatExpiryDate(String raw) {
    if (raw.length != 8) return raw;
    try {
      final year = raw.substring(0, 4);
      final monthIndex = int.parse(raw.substring(4, 6));
      final day = int.parse(raw.substring(6, 8));
      const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      if (monthIndex >= 1 && monthIndex <= 12) {
        return "$day ${months[monthIndex - 1]}, $year";
      }
    } catch (_) {}
    return raw;
  }

  String _formatCurrency(int amount) {
    return "\$${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = Theme.of(context).brightness == Brightness.dark;
    final activeTheme = darkTheme ? ServiciosPublicosTheme.darkTheme : ServiciosPublicosTheme.lightTheme;

    final state = ref.watch(publicServicesFormNotifierProvider(_familyParam));
    final notifier = ref.read(publicServicesFormNotifierProvider(_familyParam).notifier);

    // Sync input text fields on notifier state updates
    ref.listen<PublicServicesFormState>(
      publicServicesFormNotifierProvider(_familyParam),
      (previous, next) {
        _setText(_documentoCtrl, next.pagador.documento);
        _setText(_primerNombreCtrl, next.pagador.primerNombre);
        _setText(_segundoNombreCtrl, next.pagador.segundoNombre);
        _setText(_primerApellidoCtrl, next.pagador.primerApellido);
        _setText(_segundoApellidoCtrl, next.pagador.segundoApellido);
        _setText(_direccionCtrl, next.pagador.direccion);
        _setText(_telefonoCtrl, next.pagador.telefono);
        _setText(_emailCtrl, next.pagador.email);

        if (next.transactionResponse?.result?.url != null) {
          final url = next.transactionResponse!.result!.url!;
          final refId = next.factura;
          notifier.clearResponse();

          // Redirect to payment webview processing screen
          context.push(
            AppRoutes.pagosProcessingPath(widget.municipalityId),
            extra: {
              'url': url,
              'reference': refId,
              'entityCode': widget.municipalityId.toString(),
              'taxId': '1', // taxId for public services is 1
            },
          );
        }

        if (next.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red),
          );
          notifier.clearResponse();
        }
      },
    );

    final isPayEnabled = notifier.isFormValid() && _aceptaPoliticaDatos && _aceptaCondicionesUso && !state.isLoading;

    return Theme(
      data: activeTheme,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Resumen de cobro',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary card
                    _buildSummaryCard(context, state),
                    const SizedBox(height: 24),

                    // Payer details header with toggle edit button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Datos del pagador',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton.filled(
                          onPressed: () {
                            setState(() {
                              _isEditing = !_isEditing;
                            });
                          },
                          icon: Icon(_isEditing ? Icons.lock_open : Icons.edit, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: ServiciosPublicosTheme.primaryButton,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Payer form fields card
                    _buildFormCard(context, state, notifier),
                    const SizedBox(height: 16),

                    // Checkboxes
                    Row(
                      children: [
                        Checkbox(
                          value: _aceptaPoliticaDatos,
                          onChanged: (val) {
                            setState(() {
                              _aceptaPoliticaDatos = val ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Acepto la política de tratamiento de datos personales.',
                            style: TextStyle(fontSize: 13, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _aceptaCondicionesUso,
                          onChanged: (val) {
                            setState(() {
                              _aceptaCondicionesUso = val ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Acepto las Condiciones de Uso y las políticas de privacidad.',
                            style: TextStyle(fontSize: 13, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton.icon(
                      onPressed: isPayEnabled
                          ? () {
                              notifier.updatePayerField((p) => p.copy(
                                    documento: _documentoCtrl.text.trim(),
                                    primerNombre: _primerNombreCtrl.text.trim(),
                                    segundoNombre: _segundoNombreCtrl.text.trim(),
                                    primerApellido: _primerApellidoCtrl.text.trim(),
                                    segundoApellido: _segundoApellidoCtrl.text.trim(),
                                    direccion: _direccionCtrl.text.trim(),
                                    telefono: _telefonoCtrl.text.trim(),
                                    email: _emailCtrl.text.trim(),
                                  ));
                              notifier.submitTransaction();
                            }
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Ir a pagar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: isPayEnabled ? ServiciosPublicosTheme.primaryButton : Colors.grey[300],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, PublicServicesFormState state) {
    final darkTheme = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: darkTheme ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: darkTheme ? 0 : 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ServiciosPublicosTheme.primaryButton.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long, color: ServiciosPublicosTheme.primaryButton),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Concepto de cobro',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSummaryRow('Referencia:', state.factura),
            const Divider(height: 24),
            _buildSummaryRow('Vencimiento:', _formatExpiryDate(state.fechaVencimiento)),
            const Divider(height: 24),
            _buildSummaryRow('Valor a Pagar:', _formatCurrency(state.valorPagar), isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
            color: isBold ? ServiciosPublicosTheme.primaryButton : null,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(
    BuildContext context,
    PublicServicesFormState state,
    PublicServicesFormNotifier notifier,
  ) {
    final darkTheme = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: darkTheme ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: darkTheme ? 0 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFormField(
              controller: _documentoCtrl,
              label: 'Documento',
              enabled: _isEditing,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    controller: _primerNombreCtrl,
                    label: 'Primer Nombre',
                    enabled: _isEditing,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFormField(
                    controller: _segundoNombreCtrl,
                    label: 'Segundo Nombre',
                    enabled: _isEditing,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    controller: _primerApellidoCtrl,
                    label: 'Primer Apellido',
                    enabled: _isEditing,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFormField(
                    controller: _segundoApellidoCtrl,
                    label: 'Segundo Apellido',
                    enabled: _isEditing,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFormField(
              controller: _direccionCtrl,
              label: 'Dirección',
              enabled: _isEditing,
            ),
            const SizedBox(height: 12),
            _buildFormField(
              controller: _telefonoCtrl,
              label: 'Teléfono',
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildFormField(
              controller: _emailCtrl,
              label: 'Correo Electrónico',
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
