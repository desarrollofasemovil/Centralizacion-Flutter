import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/course_dto.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/circles_decoration.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../auth/application/auth_providers.dart';
import '../application/courses_notifier.dart';
import '../domain/courses_state.dart';
import 'widgets/course_item.dart';
import 'widgets/course_details_view.dart';
import 'widgets/registration_form.dart';

/// Pantalla de Cursos. Port de `CoursesScreen.kt` — lista de cursos, vista de
/// detalles en el mismo destino (dirigida por estado) y hoja de inscripción.
class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key, required this.param});

  final CoursesParam param;

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  bool _sheetOpen = false;

  CoursesNotifier get _notifier =>
      ref.read(coursesNotifierProvider(widget.param).notifier);

  void _onEnroll(CourseDTO course) {
    final loggedIn = ref.read(sessionProvider)?.loginStatus == true;
    if (loggedIn) {
      _notifier.onRegisterClick(course);
    } else {
      _showLoginWarning();
    }
  }

  void _showLoginWarning() {
    showDialog<void>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Atención',
        message: 'Debes iniciar sesión para poder inscribirte a un curso.',
        icon: Icons.warning_amber_rounded,
        confirmButtonText: 'Entendido',
        onConfirm: () => Navigator.of(ctx).pop(),
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Future<void> _openRegistrationSheet() async {
    _sheetOpen = true;
    _notifier.initForm(ref.read(sessionProvider));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => RegistrationForm(param: widget.param),
    );
    _sheetOpen = false;
    // Si se cerró sin éxito, limpiar la selección.
    if (!ref.read(coursesNotifierProvider(widget.param)).registrationSuccess) {
      _notifier.onDialogDismiss();
    }
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Éxito',
        message: 'Te has inscrito al curso correctamente.',
        icon: Icons.check_circle,
        confirmButtonText: 'Entendido',
        onConfirm: () => Navigator.of(ctx).pop(),
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    ).then((_) => _notifier.onDialogDismiss());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coursesNotifierProvider(widget.param));
    final showingDetails =
        state.selectedCourseForDetails != null &&
        state.parsedCourseDetails != null;

    // Abrir la hoja de inscripción cuando se selecciona un curso.
    ref.listen<CourseDTO?>(
      coursesNotifierProvider(widget.param).select((s) => s.selectedCourse),
      (prev, next) {
        if (next != null && !_sheetOpen) _openRegistrationSheet();
      },
    );

    // Éxito de inscripción → cerrar hoja y mostrar diálogo.
    ref.listen<bool>(
      coursesNotifierProvider(
        widget.param,
      ).select((s) => s.registrationSuccess),
      (prev, next) {
        if (next == true) {
          if (_sheetOpen) Navigator.of(context).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Inscripción exitosa')));
          _showSuccessDialog();
        }
      },
    );

    // Errores de inscripción (con la lista ya cargada) → SnackBar.
    ref.listen<String?>(
      coursesNotifierProvider(widget.param).select((s) => s.error),
      (prev, next) {
        if (next != null && next.isNotEmpty && state.courses.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(next)));
        }
      },
    );

    return PopScope(
      canPop: !showingDetails,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && showingDetails) _notifier.closeCourseDetails();
      },
      child: showingDetails
          ? CourseDetailsView(
              course: state.selectedCourseForDetails!,
              parsed: state.parsedCourseDetails!,
              onBack: _notifier.closeCourseDetails,
              onEnroll: () => _onEnroll(state.selectedCourseForDetails!),
            )
          : Stack(
              children: [
                Scaffold(
                  appBar: AppTopBar(
                    title: 'Cursos',
                    backgroundColor: Colors.transparent,
                    onBack: () => context.pop(),
                  ),
                  body: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Expanded(child: _body(context, state))],
                    ),
                  ),
                ),
                // Adorno de círculos de la esquina superior (`circles`).
                const CirclesDecoration.branded(),
              ],
            ),
    );
  }

  Widget _body(BuildContext context, CoursesUiState state) {
    final theme = Theme.of(context);
    if (state.isLoading && state.courses.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (!state.isLoading && state.error != null && state.courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'No se pudieron cargar los cursos.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                state.error ?? 'Error desconocido',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _notifier.retryLoadCourses,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (!state.isLoading && state.courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No hay cursos disponibles en este momento.',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.courses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final course = state.courses[i];
        return CourseItem(
          course: course,
          onDetails: () => _notifier.onCourseDetailsClick(course),
          onEnroll: () => _onEnroll(course),
        );
      },
    );
  }
}
