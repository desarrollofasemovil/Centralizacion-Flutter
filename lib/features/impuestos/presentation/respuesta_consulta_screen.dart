import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';

import 'package:tramiapp_flutter/core/municipality/municipality_repository.dart';
import '../application/tax_notifier.dart';
import '../domain/tax.dart';

class TaxResultsScreen extends ConsumerStatefulWidget {
  const TaxResultsScreen({
    required this.municipalityId,
    required this.taxes,
    required this.email,
    super.key,
  });

  final int municipalityId;
  final List<Tax> taxes;
  final String email;

  @override
  ConsumerState<TaxResultsScreen> createState() => _TaxResultsScreenState();
}

class _TaxResultsScreenState extends ConsumerState<TaxResultsScreen> {
  bool _isDownloading = false;
  String _downloadMessage = '';

  Future<void> _handlePay(Tax tax, String bankName) async {
    setState(() {
      _isDownloading = true;
      _downloadMessage = 'Creando transacción de pago...';
    });

    try {
      final repo = ref.read(taxRepositoryProvider);
      // Retrieve the integrationType (or matching procedure integrationType) from municipalityDTO
      final asyncMun = ref.read(municipalityProvider(widget.municipalityId));
      final mun = asyncMun.value;
      final matchedProcedure = mun?.municipalityProcedures
          .firstWhere((p) => p.procedures.id == tax.taxId, orElse: () => throw Exception('Procedimiento no encontrado'));

      final integrationType = matchedProcedure?.integrationType ?? '0';

      final gatewayInfo = await repo.createTransaction(
        tax: tax,
        email: widget.email,
        bankName: bankName,
        municipalityId: widget.municipalityId,
        integrationType: integrationType,
      );

      setState(() {
        _isDownloading = false;
      });

      if (mounted) {
        // Navigate to payment processing screen with the gateway URL
        context.push(
          '/municipality/${widget.municipalityId}/pagos/processing',
          extra: {
            'paymentUrl': gatewayInfo.url,
            'tax': tax,
          },
        );
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar pasarela de pagos: $e')),
        );
      }
    }
  }

  Future<void> _handlePdfDownload(Tax tax) async {
    setState(() {
      _isDownloading = true;
      _downloadMessage = 'Descargando factura...';
    });

    try {
      final repo = ref.read(taxRepositoryProvider);
      final url = await repo.getInvoicePdfUrl(tax);

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/factura_${tax.invoice}.pdf';

      final dio = Dio();
      await dio.download(url, filePath);

      setState(() {
        _isDownloading = false;
      });

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo abrir el PDF: ${result.message}')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar factura: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final asyncMun = ref.watch(municipalityProvider(widget.municipalityId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturas Encontradas'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: widget.taxes.length,
            itemBuilder: (context, index) {
              final tax = widget.taxes[index];
              return _TaxCard(
                tax: tax,
                onPayClick: (bankName) => _handlePay(tax, bankName),
                onPdfClick: () => _handlePdfDownload(tax),
                municipalityBank: asyncMun.value?.bank.nameBank ?? 'Bancolombia',
              );
            },
          ),
          if (_isDownloading)
            Container(
              color: Colors.black45,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Text(
                            _downloadMessage,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TaxCard extends StatelessWidget {
  const _TaxCard({
    required this.tax,
    required this.onPayClick,
    required this.onPdfClick,
    required this.municipalityBank,
  });

  final Tax tax;
  final Function(String) onPayClick;
  final VoidCallback onPdfClick;
  final String municipalityBank;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isExpired = tax.isExpired;
    final currencyFormatter = NumberFormat.simpleCurrency(locale: 'es_CO', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tax.taxName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'VENCIDO',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Contribuyente:', tax.name),
            _buildDetailRow('Referencia:', tax.reference),
            _buildDetailRow('Factura:', tax.invoice),
            _buildDetailRow('Vencimiento:', tax.dueDate),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Valor a Pagar:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormatter.format(tax.value),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPdfClick,
                    icon: const Icon(Icons.download),
                    label: const Text('Descargar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                if (!isExpired) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onPayClick(municipalityBank),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Pagar'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
