// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'servicios_publicos_theme.dart';

class PublicServicesBillDetailsScreen extends StatelessWidget {
  const PublicServicesBillDetailsScreen({
    required this.municipalityId,
    required this.billDetails,
    super.key,
  });

  final int municipalityId;
  final Map<String, dynamic> billDetails;

  @override
  Widget build(BuildContext context) {
    final darkTheme = Theme.of(context).brightness == Brightness.dark;
    final activeTheme = darkTheme ? ServiciosPublicosTheme.darkTheme : ServiciosPublicosTheme.lightTheme;

    final entity = billDetails['entity'] as String? ?? 'E.S.P Madrid';
    final amount = billDetails['amount'] as String? ?? '\$110.000';
    final date = billDetails['date'] as String? ?? '24 Oct, 2023';
    final state = billDetails['state'] as String? ?? 'CONFIRMADO';
    final reference = billDetails['reference'] as String? ?? '002938481239';
    final fallbackColor = billDetails['fallbackColor'] as Color? ?? Colors.blue;

    final initials = entity
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase())
        .take(2)
        .join('');

    return Theme(
      data: activeTheme,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Detalle de Factura',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Bill Header Card
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: fallbackColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: fallbackColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    entity,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ref: $reference',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      color: ServiciosPublicosTheme.primaryButton,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Details card
            Card(
              color: darkTheme ? const Color(0xFF1C1C1E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: darkTheme ? 0 : 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDetailRow('Entidad:', entity),
                    const Divider(height: 24),
                    _buildDetailRow('Referencia:', reference),
                    const Divider(height: 24),
                    _buildDetailRow('Fecha de Pago:', date),
                    const Divider(height: 24),
                    _buildDetailRow('Estado:', state, isStatus: true),
                    const Divider(height: 24),
                    _buildDetailRow('Monto:', amount, isBold: true),
                    const Divider(height: 24),
                    _buildDetailRow('Método de Pago:', 'Visa **** 9012'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comprobante descargado en la galería.')),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Descargar comprobante'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: ServiciosPublicosTheme.primaryButton,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Compartiendo comprobante...')),
                );
              },
              icon: const Icon(Icons.share_outlined),
              label: const Text('Compartir comprobante'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Support options
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Abriendo soporte por Whatsapp...')),
                );
              },
              child: const Text('¿Necesitas ayuda? Contactar Soporte'),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reporte enviado al equipo de Trami App.')),
                );
              },
              child: const Text(
                'Reportar un problema con este pago',
                style: TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, bool isStatus = false}) {
    Widget valueWidget;
    if (isStatus) {
      final isSuccess = value == 'CONFIRMADO' || value == 'ÉXITO';
      valueWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSuccess ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSuccess ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
          ),
        ),
      );
    } else {
      valueWidget = Text(
        value,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14),
        ),
        valueWidget,
      ],
    );
  }
}
