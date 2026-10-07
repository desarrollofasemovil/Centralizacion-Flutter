import 'package:flutter/material.dart';

import '../../../../core/models/course_dto.dart';
import '../../domain/courses_state.dart';
import '../../../../core/widgets/app_top_bar.dart';

/// Vista de detalles de un curso (dirigida por estado, no es una ruta). Port de
/// `CourseDetailsScreen.kt`.
class CourseDetailsView extends StatelessWidget {
  const CourseDetailsView({
    super.key,
    required this.course,
    required this.parsed,
    required this.onBack,
    required this.onEnroll,
  });

  final CourseDTO course;
  final ParsedCourseDetails parsed;
  final VoidCallback onBack;
  final VoidCallback onEnroll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppTopBar(
        title: 'Detalles del Curso',
        backgroundColor: theme.colorScheme.surface,
        onBack: onBack,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((course.imageUrl ?? '').isNotEmpty)
                Image.network(
                  course.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    if (parsed.detailsMap.isNotEmpty) ...[
                      for (final entry in parsed.detailsMap.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  entry.key,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 7,
                                child: Text(
                                  entry.value,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Divider(height: 32),
                    ],
                    Text(
                      parsed.mainDescription,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: FilledButton(
            onPressed: onEnroll,
            child: const Text('Inscribirse'),
          ),
        ),
      ),
    );
  }
}
