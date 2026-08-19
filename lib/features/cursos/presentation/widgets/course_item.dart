import 'package:flutter/material.dart';

import '../../../../core/models/course_dto.dart';

/// Tarjeta de curso en la lista. Port de `CourseItem.kt`.
class CourseItem extends StatelessWidget {
  const CourseItem({
    super.key,
    required this.course,
    required this.onDetails,
    required this.onEnroll,
  });

  final CourseDTO course;
  final VoidCallback onDetails;
  final VoidCallback onEnroll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              width: double.infinity,
              child: _CourseImage(url: course.imageUrl),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.description ?? 'Sin descripción',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _IconText(
                        icon: Icons.date_range,
                        text: _formatIsoDate(course.startDate),
                        color: theme.colorScheme.primary,
                      ),
                      _IconText(
                        icon: Icons.people,
                        text: '${course.availableSlots ?? 0} lugares',
                        color: theme.colorScheme.primary,
                        bold: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: onDetails,
                        child: Text(
                          'Ver detalles',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: onEnroll,
                        child: const Text('Inscribirse'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseImage extends StatelessWidget {
  const _CourseImage({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.school,
        size: 48,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator.adaptive());
      },
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({
    required this.icon,
    required this.text,
    required this.color,
    this.bold = false,
  });

  final IconData icon;
  final String text;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: bold ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
}

/// Formatea `yyyy-MM-ddTHH:mm:ssZ` a `dd/MM/yyyy` (local). Port de
/// `formatIsoDateToLocal`.
String _formatIsoDate(String? iso) {
  if (iso == null || iso.trim().isEmpty) return 'Por definir';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  final local = parsed.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year}';
}
