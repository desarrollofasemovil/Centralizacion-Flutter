// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'servicios_publicos_theme.dart';

class PublicServicesMenuScreen extends StatelessWidget {
  const PublicServicesMenuScreen({required this.municipalityId, super.key});
  final int municipalityId;

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
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Servicios Públicos',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Simplifica tus\nobligaciones.',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Accede a tus facturas y pagos de manera fácil y rápida.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Card 1: Seleccionar entidad
              _buildMenuCard(
                context,
                title: 'Seleccionar una entidad',
                description: 'Busca entre los prestadores de servicio disponibles.',
                icon: Icons.receipt_long_outlined,
                onTap: () {
                  context.push('/municipality/$municipalityId/servicios-publicos/select-entity');
                },
              ),
              const SizedBox(height: 16),

              // Card 2: Mis facturas
              _buildMenuCard(
                context,
                title: 'Mis facturas',
                description: 'Historial completo y estados de cuenta pendientes.',
                icon: Icons.bookmark_border_outlined,
                onTap: () {
                  context.push('/municipality/$municipalityId/servicios-publicos/history');
                },
              ),
              const SizedBox(height: 16),

              // Card 3: Recordatorio de pago (Dark card style)
              _buildReminderCard(context),

              const SizedBox(height: 40),

              // Security footer
              _buildSecurityFooter(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final iconBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF4F4F6);

    return Card(
      color: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: isDark ? 0 : 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: ServiciosPublicosTheme.primaryButton, size: 24),
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.grey, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context) {
    return Card(
      color: ServiciosPublicosTheme.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notificaciones activadas. Recibirás avisos para tus facturas.'),
              backgroundColor: ServiciosPublicosTheme.primaryButton,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Calendar watermark
              Positioned(
                bottom: -20,
                right: -20,
                child: Transform.rotate(
                  angle: 0.26, // approx 15 degrees
                  child: Icon(
                    Icons.calendar_month_outlined,
                    size: 120,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recordatorio de pago.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Automatiza tus recibos y nunca pierdas una fecha límite.',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
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

  Widget _buildSecurityFooter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFEBEBEB);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.security_outlined,
              color: ServiciosPublicosTheme.darkText,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pagos Seguros',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'Tu información financiera se encuentra cifrada bajo estándares internacionales.',
                  style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
