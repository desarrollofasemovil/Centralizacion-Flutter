import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/services/api_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../auth/application/auth_providers.dart';
import '../../impuestos/domain/tax.dart';

class PaymentProcessingScreen extends ConsumerStatefulWidget {
  const PaymentProcessingScreen({
    required this.municipalityId,
    required this.paymentUrl,
    required this.tax,
    super.key,
  });

  final int municipalityId;
  final String paymentUrl;
  final Tax tax;

  @override
  ConsumerState<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends ConsumerState<PaymentProcessingScreen> {
  Timer? _statusTimer;
  String _statusMessage = 'Redirigiendo a la pasarela...';
  bool _isSuccess = false;
  bool _isError = false;
  String _errorMessage = '';
  bool _checkingNow = false;

  @override
  void initState() {
    super.initState();
    _launchGateway();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _launchGateway() async {
    final uri = Uri.parse(widget.paymentUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        setState(() {
          _statusMessage = 'No se pudo abrir la pasarela automáticamente. Por favor use el botón de abajo.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Use el botón de abajo para ir a la pasarela de pagos.';
      });
    }
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_isSuccess || _isError || _checkingNow) return;

    setState(() {
      _checkingNow = true;
    });

    try {
      final statusService = ref.read(statusOfPaymentsApiServiceProvider);
      
      // 1. Authenticate
      final token = await statusService.authenticate({
        "Username": "UserApp",
        "Password": "UserApp1cero1",
      });

      // Remove any double quotes if returned by API
      final cleanToken = token.replaceAll('"', '');

      // 2. Get status
      final statusDto = await statusService.getStatusOfPayment(
        'Bearer $cleanToken',
        widget.tax.entityCode,
        widget.tax.reference,
        widget.tax.taxId.toString(),
      );

      final stateStr = statusDto.estadoTransaccion.toLowerCase();

      if (stateStr.contains('aprob') || stateStr.contains('success') || stateStr.contains('acept')) {
        await _handlePaymentSuccess();
      } else if (stateStr.contains('rechaz') || stateStr.contains('cancel') || stateStr.contains('fail')) {
        setState(() {
          _isError = true;
          _errorMessage = 'El pago fue rechazado o cancelado en la pasarela.';
        });
        _statusTimer?.cancel();
      } else {
        // Still pending
        setState(() {
          _statusMessage = 'Pago en proceso. Estado actual: ${statusDto.estadoTransaccion}';
        });
      }
    } catch (e) {
      // In sandbox/dev environment, ignore API connection errors during polling
      // so it doesn't interrupt the simulator option.
    } finally {
      if (mounted) {
        setState(() {
          _checkingNow = false;
        });
      }
    }
  }

  Future<void> _handlePaymentSuccess() async {
    _statusTimer?.cancel();
    
    // Save to Payment History API
    try {
      final historyService = ref.read(paymentHistoryApiServiceProvider);
      final user = ref.read(sessionProvider);

      final body = {
        "userFirtName": user?.firstName ?? widget.tax.name,
        "amount": widget.tax.value.toDouble(),
        "paymentDate": DateTime.now().toIso8601String(),
        "status": true,
        "idStatusType": 1,
        "alcaldia": widget.tax.entity,
        "procedureName": widget.tax.taxName,
        "statusType": "Aprobado",
        "idimpuesto": widget.tax.taxId.toString(),
        "factura": widget.tax.invoice,
        "codigoEntidad": widget.tax.entityCode,
        "idUser": user?.id,
        "userId": user?.id,
      };

      await historyService.createPaymentHistory(body);
    } catch (_) {
      // Even if saving to remote history fails (offline or mockup), proceed with local success state.
    }

    if (mounted) {
      setState(() {
        _isSuccess = true;
        _statusMessage = '¡Pago Realizado con Éxito!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Procesando Pago'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        automaticallyImplyLeading: false, // Don't allow backing out easily
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isSuccess && !_isError) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    const Text(
                      'Redirección a Pasarela Segura',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _launchGateway,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Abrir Pasarela de Pagos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _checkingNow ? null : _checkPaymentStatus,
                      icon: _checkingNow
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text('Verificar Estado del Pago'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    const Divider(height: 48),
                    const Text(
                      '¿Modo Pruebas / Demostración?',
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _handlePaymentSuccess,
                      icon: const Icon(Icons.bug_report, color: Colors.green),
                      label: const Text('Simular Pago Aprobado (Exitoso)', style: TextStyle(color: Colors.green)),
                    ),
                  ] else if (_isSuccess) ...[
                    const Icon(Icons.check_circle, size: 72, color: Colors.green),
                    const SizedBox(height: 24),
                    const Text(
                      '¡Pago Exitoso!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.green),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'El pago de \$${widget.tax.value} para el concepto "${widget.tax.taxName}" ha sido procesado correctamente.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // Go back to municipality home
                        context.go(AppRoutes.municipalityPath(widget.municipalityId));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text('Volver al Inicio'),
                    ),
                  ] else ...[
                    const Icon(Icons.error, size: 72, color: Colors.red),
                    const SizedBox(height: 24),
                    const Text(
                      'Transacción Fallida',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.go(AppRoutes.municipalityPath(widget.municipalityId));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text('Volver al Inicio'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
