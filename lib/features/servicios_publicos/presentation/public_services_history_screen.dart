// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'servicios_publicos_theme.dart';

class HistoryItem {
  final String id;
  final String serviceName;
  final String date;
  final String amount;
  final bool isSuccess;
  final Color fallbackColor;

  const HistoryItem({
    required this.id,
    required this.serviceName,
    required this.date,
    required this.amount,
    required this.isSuccess,
    required this.fallbackColor,
  });
}

class PublicServicesHistoryScreen extends StatefulWidget {
  const PublicServicesHistoryScreen({required this.municipalityId, super.key});
  final int municipalityId;

  @override
  State<PublicServicesHistoryScreen> createState() => _PublicServicesHistoryScreenState();
}

class _PublicServicesHistoryScreenState extends State<PublicServicesHistoryScreen> {
  bool _isAmountVisible = true;

  final List<HistoryItem> _recentItems = const [
    HistoryItem(
      id: "1",
      serviceName: "Enel Colombia",
      date: "11 Marzo, 2026 • 09:15 AM",
      amount: "\$110.000",
      isSuccess: true,
      fallbackColor: Colors.purple,
    ),
    HistoryItem(
      id: "2",
      serviceName: "Acueducto Bogotá",
      date: "08 Oct, 2024 • 04:30 PM",
      amount: "\$50.000",
      isSuccess: true,
      fallbackColor: Colors.orange,
    ),
  ];

  final List<HistoryItem> _olderItems = const [
    HistoryItem(
      id: "3",
      serviceName: "EPM",
      date: "11 Febrero, 2026 • 09:15 AM",
      amount: "\$90.000",
      isSuccess: true,
      fallbackColor: Colors.green,
    ),
    HistoryItem(
      id: "4",
      serviceName: "E.S.P Madrid",
      date: "08 Febrero, 2026 • 04:30 PM",
      amount: "\$60.000",
      isSuccess: false,
      fallbackColor: Colors.blue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final darkTheme = Theme.of(context).brightness == Brightness.dark;
    final activeTheme = darkTheme ? ServiciosPublicosTheme.darkTheme : ServiciosPublicosTheme.lightTheme;

    return Theme(
      data: activeTheme,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Historial',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            // Resumen Anual
            _buildAnnualSummaryHeader(),
            const SizedBox(height: 24),

            // Sección: Recientes
            if (_recentItems.isNotEmpty) ...[
              _buildSectionTitle("RECIENTES"),
              const SizedBox(height: 8),
              ..._recentItems.map((item) => _buildTransactionCard(item)),
              const SizedBox(height: 24),
            ],

            // Sección: Febrero
            if (_olderItems.isNotEmpty) ...[
              _buildSectionTitle("FEBRERO"),
              const SizedBox(height: 8),
              ..._olderItems.map((item) => _buildTransactionCard(item)),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnnualSummaryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RESUMEN ANUAL',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
            ),
            const SizedBox(height: 4),
            Text(
              _isAmountVisible ? '\$250.000' : '****',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pagos realizados en 2026',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _isAmountVisible = !_isAmountVisible;
            });
          },
          icon: Icon(
            _isAmountVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
    );
  }

  Widget _buildTransactionCard(HistoryItem item) {
    final darkTheme = Theme.of(context).brightness == Brightness.dark;
    final initials = item.serviceName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase())
        .take(2)
        .join('');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: darkTheme ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: darkTheme ? 0 : 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: item.fallbackColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: item.fallbackColor),
          ),
        ),
        title: Text(
          item.serviceName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            item.date,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              item.amount,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: item.isSuccess ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.isSuccess ? 'ÉXITO' : 'CANCELADA',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: item.isSuccess ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          context.push(
            '/municipality/${widget.municipalityId}/servicios-publicos/bill-details',
            extra: {
              'entity': item.serviceName,
              'amount': item.amount,
              'date': item.date.split('•')[0].trim(),
              'state': item.isSuccess ? 'CONFIRMADO' : 'CANCELADA',
              'reference': '00293848${item.id}239',
              'fallbackColor': item.fallbackColor,
            },
          );
        },
      ),
    );
  }
}
