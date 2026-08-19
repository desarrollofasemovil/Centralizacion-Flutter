import 'package:flutter/material.dart';

import '../../../../core/models/venue_dto.dart';

/// Tarjeta de escenario deportivo. Port de `VenueItem.kt`.
class VenueItem extends StatelessWidget {
  const VenueItem({super.key, required this.venue, required this.onReserve});

  final VenueDTO venue;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((venue.imageUrl ?? '').isNotEmpty)
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Image.network(
                venue.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.stadium,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator.adaptive()),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venue.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  venue.description ?? 'Sin descripción',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                _IconRow(
                  icon: Icons.location_on,
                  text: venue.address ?? 'No especificada',
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 4),
                _IconRow(
                  icon: Icons.people,
                  text: 'Capacidad: ${venue.capacity ?? 0}',
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: onReserve,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Reservar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconRow extends StatelessWidget {
  const _IconRow({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
      ],
    );
  }
}

/// Vista de reserva activa (dentro del diálogo de advertencia). Port de
/// `ActiveReservationView`.
class ActiveReservationView extends StatelessWidget {
  const ActiveReservationView({super.key, required this.reservation});

  final UserReservationStatusDTO reservation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 60,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Ya tienes una reserva activa',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Escenario: ${reservation.venueName}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Inicio: ${_format(reservation.startDate)}',
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            'Fin: ${_format(reservation.endDate)}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Estado: ${reservation.status}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Recuerda que solo puedes realizar una reserva. Podrás realizar una nueva reserva cuando expire este periodo.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Formatea `yyyy-MM-ddTHH:mm:ss` a `dd/MM/yyyy - hh:mm a`. Port de
/// `formatIsoDateToLocalVenues`.
String _format(String? iso) {
  if (iso == null || iso.trim().isEmpty) return 'Por definir';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  String two(int n) => n.toString().padLeft(2, '0');
  final hour12 = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final ampm = parsed.hour < 12 ? 'a. m.' : 'p. m.';
  return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year} - '
      '${two(hour12)}:${two(parsed.minute)} $ampm';
}
