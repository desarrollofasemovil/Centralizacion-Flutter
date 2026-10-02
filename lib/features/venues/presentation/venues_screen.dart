import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/venue_dto.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/circles_decoration.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../auth/application/auth_providers.dart';
import '../application/venues_notifier.dart';
import '../domain/venues_state.dart';
import 'widgets/reservation_form.dart';
import 'widgets/venue_item.dart';

/// Pantalla de Escenarios deportivos. Port de `VenuesScreen.kt`.
class VenuesScreen extends ConsumerStatefulWidget {
  const VenuesScreen({super.key, required this.param});

  final VenuesParam param;

  @override
  ConsumerState<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends ConsumerState<VenuesScreen> {
  bool _sheetOpen = false;

  VenuesNotifier get _notifier =>
      ref.read(venuesNotifierProvider(widget.param).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _showInstructionDialog(),
    );
  }

  void _showInstructionDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Acerca de reservas',
        icon: Icons.info_outline,
        message:
            'Bienvenido al sistema de reservas.\n\n'
            '1. Solo puedes reservar 1 escenario al día.\n'
            '2. Confirma tu reserva revisando tu correo electrónico.\n'
            '3. Si un espacio está ocupado, la aplicación te notificará.\n'
            '4. La alcaldía no se hace responsable por reservas sin confirmar.\n\n'
            'Para confirmación oficial, espera el correo o acércate presencialmente.',
        confirmButtonText: 'Entendido',
        onConfirm: () => Navigator.of(ctx).pop(),
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _showLoginWarning() {
    showDialog<void>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Atención',
        message:
            'Debes iniciar sesión para poder reservar un espacio deportivo.',
        icon: Icons.warning_amber_rounded,
        confirmButtonText: 'Entendido',
        onConfirm: () => Navigator.of(ctx).pop(),
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _onReserve(VenueDTO venue) {
    final loggedIn = ref.read(sessionProvider)?.loginStatus == true;
    if (loggedIn) {
      _notifier.onReserveClick(venue);
    } else {
      _showLoginWarning();
    }
  }

  Future<void> _openReservationSheet() async {
    _sheetOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ReservationForm(param: widget.param),
    );
    _sheetOpen = false;
    if (ref.read(venuesNotifierProvider(widget.param)).selectedVenue != null) {
      _notifier.onDismissBottomSheet();
    }
  }

  void _showReservationDialog(ReservationDialog dialog) {
    if (dialog.type == ReservationDialogType.warning &&
        dialog.activeReservation != null) {
      showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ActiveReservationView(reservation: dialog.activeReservation!),
                const SizedBox(height: 10),
                SizedBox(
                  width: MediaQuery.of(ctx).size.width * 0.8,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Entendido'),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ).then((_) => _notifier.onDismissDialog());
      return;
    }

    final isSuccess = dialog.type == ReservationDialogType.success;
    showDialog<void>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: dialog.title,
        message: isSuccess
            ? '${dialog.message}\n\n${dialog.disclaimer}'.trim()
            : dialog.message,
        icon: isSuccess ? Icons.info_outline : Icons.warning_amber_rounded,
        confirmButtonText: 'Entendido',
        onConfirm: () => Navigator.of(ctx).pop(),
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    ).then((_) => _notifier.onDismissDialog());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(venuesNotifierProvider(widget.param));

    // Abrir hoja de reserva cuando se selecciona un escenario.
    ref.listen<VenueDTO?>(
      venuesNotifierProvider(widget.param).select((s) => s.selectedVenue),
      (prev, next) {
        if (next != null && !_sheetOpen) {
          _openReservationSheet();
        } else if (next == null && _sheetOpen) {
          Navigator.of(context).pop();
        }
      },
    );

    // Diálogos (éxito / error / advertencia).
    ref.listen<ReservationDialog?>(
      venuesNotifierProvider(widget.param).select((s) => s.dialog),
      (prev, next) {
        if (next != null) _showReservationDialog(next);
      },
    );

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: AppBackButton(onPressed: () => context.pop()),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Espacios deportivos',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(child: _body(context, state)),
              ],
            ),
          ),
        ),
        // Adorno de círculos de la esquina superior (`circles`).
        const CirclesDecoration.branded(),
      ],
    );
  }

  Widget _body(BuildContext context, VenuesUiState state) {
    final theme = Theme.of(context);
    switch (state.status) {
      case VenuesStatus.loading:
        return const Center(child: CircularProgressIndicator.adaptive());
      case VenuesStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 72,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'No pudimos conectar con el servidor',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                FractionallySizedBox(
                  widthFactor: 0.7,
                  child: FilledButton(
                    onPressed: _notifier.retryInitialLoad,
                    child: const Text('Reintentar'),
                  ),
                ),
              ],
            ),
          ),
        );
      case VenuesStatus.available:
        if (state.venues.isEmpty) {
          return const Center(
            child: Text('No hay escenarios disponibles en este momento.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.venues.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (_, i) {
            final venue = state.venues[i];
            return VenueItem(venue: venue, onReserve: () => _onReserve(venue));
          },
        );
    }
  }
}
