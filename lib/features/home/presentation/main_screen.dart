import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/analytics/municipality_tracker.dart';
import '../../../core/models/municipality_dto.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/storage/user_preferences.dart';
import '../../../core/utils/url_opener.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/login_bottom_sheet.dart';
import '../../portal_externo/application/portal_visit_tracker.dart';
import '../../portal_externo/presentation/portal_survey_sheet.dart';
import '../../reminders/presentation/reminder_toast_listener.dart';
import '../../reminders/presentation/reminders_section.dart';
import '../../tramites/application/tramite_mappers.dart';
import '../../tramites/domain/info_tramite.dart';
import '../application/main_viewmodel.dart';
import 'widgets/animated_section.dart';
import 'widgets/external_link_dialog.dart';
import 'widgets/main_bottom_nav_bar.dart';
import 'widgets/main_collapsing_header.dart';
import 'widgets/main_side_menu_options.dart';
import 'widgets/maintenance_info_card.dart';
import 'widgets/modal_form.dart';
import '../../../core/widgets/circles_decoration.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/panic_countdown_dialog.dart';
import 'widgets/tramites_section.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({required this.municipality, super.key});

  final MunicipalityDTO municipality;

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Detecta el regreso desde un portal externo (Custom Tab) para medir la
  /// visita y, si toca, mostrar la microencuesta (ver [PortalVisitTracker]).
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _trackMunicipality();
    final tracker = ref.read(portalVisitTrackerProvider.notifier);
    _lifecycle = AppLifecycleListener(
      onHide: tracker.onAppHidden,
      onResume: tracker.onAppResumed,
    );
    // Tras el primer frame, cuando ya escucha la encuesta pendiente: resuelve
    // una visita que quedó abierta si Android cerró la app en el portal.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) tracker.restorePendingVisit();
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// Abre [pending] y, si viene de un trámite con portal externo, registra la
  /// visita.
  Future<bool> _openPendingUrl(PendingUrl pending, Color toolbarColor) async {
    final tramite = pending.tramite;
    final tracker = ref.read(portalVisitTrackerProvider.notifier);
    if (tramite != null) {
      tracker.onPortalOpened(
        tramite,
        municipalityId: widget.municipality.id,
        url: pending.url,
      );
    }
    final opened = await abrirUrl(pending.url, toolbarColor: toolbarColor);
    if (!opened && tramite != null) tracker.onPortalOpenFailed();
    return opened;
  }

  @override
  void didUpdateWidget(covariant MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.municipality.id != widget.municipality.id) {
      _trackMunicipality();
    }
  }

  /// Propiedad de usuario `municipio` + tópico FCM del municipio (ver
  /// [MunicipalityTracker]); el original lo disparaba desde `MainScreen.kt`.
  void _trackMunicipality() {
    ref
        .read(municipalityTrackerProvider)
        .onMunicipalityShown(
          id: widget.municipality.id,
          name: widget.municipality.name,
        );
  }

  void _logBottomNav(BottomNavDestination destination) {
    ref
        .read(analyticsServiceProvider)
        .logBottomNavClick(destination, municipalityId: widget.municipality.id);
  }

  void _handleNavigation(InfoTramite tramite) {
    final name = tramite.nombre;
    final action = tramite.accion;

    // Navegación "hacia adelante": usamos push para conservar la pila y que el
    // gesto/botón Atrás regrese a la Home (equivalente a navController.navigate
    // del original, que apila). Las vueltas a Home tras pagar/enviar siguen con go.
    if (action is ShowPqrds) {
      context.push(AppRoutes.pqrdPath(widget.municipality.id));
    } else if (action is NavegarANativo) {
      context.push(action.ruta);
    } else if (action is NavegarACertificado) {
      context.push(
        AppRoutes.certificadosPath(action.municipalityId),
        extra: action.certificate,
      );
    } else if (action is NavegarAPagoSinValidacion) {
      context.push(
        AppRoutes.pagosPsvPath(widget.municipality.id),
        extra: {
          'taxId': action.taxId,
          'taxName': action.taxName,
          'entityCode': action.entityCode,
          'dataPolicyUrl': action.dataPolicyUrl,
          'privacyPolicyUrl': action.privacyPolicyUrl,
        },
      );
    } else if (action is NavegarAConsultaImpuesto) {
      context.push(
        AppRoutes.taxesPath(widget.municipality.id),
        extra: {
          'taxId': action.taxId,
          'title': name,
          'dataPolicyUrl': action.dataPolicyUrl,
          'privacyPolicyUrl': action.privacyPolicyUrl,
        },
      );
    } else if (action is NavegarACursos) {
      context.push(
        AppRoutes.cursosPath(widget.municipality.id),
        extra: {
          'courseId': action.courseId,
          'emailMunicipalities': action.emailMunicipalities,
        },
      );
    } else if (action is NavegarAvenues) {
      context.push(
        AppRoutes.venuesPath(widget.municipality.id),
        extra: {
          'venueId': action.venueId,
          'emailMunicipalities': action.emailMunicipalities,
        },
      );
    } else {
      // Si es un trámite no mapeado (Cursos, Reservas, etc.), mostrar diálogo de próximamente
      ref
          .read(mainViewModelProvider(widget.municipality.id).notifier)
          .showInDevelopment();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mainViewModelProvider(widget.municipality.id));
    final notifier = ref.read(
      mainViewModelProvider(widget.municipality.id).notifier,
    );
    final theme = Theme.of(context);
    final domainModel = widget.municipality.toDomainModel();

    // Escuchar si hay alguna URL pendiente para abrir (`MainEvent.OpenUrl`).
    ref.listen<PendingUrl?>(
      mainViewModelProvider(widget.municipality.id).select((s) => s.urlToOpen),
      (prev, next) {
        if (next == null || next.url.isEmpty) return;
        // Se consume ya (evento de un solo uso): un repintado no la reabre y el
        // estado no se queda con una URL vieja si la Home se desmonta durante
        // el aviso.
        notifier.clearUrlToOpen();
        // Portal tributario / URLs de trámite: se abren en el navegador in-app
        // (Chrome Custom Tabs / Safari VC) tintado con el color del municipio,
        // igual que `abrirURL(context, url, colorPrimario)` del original; con
        // el aviso de sitio externo delante si `showWarning`.
        final toolbarColor = theme.colorScheme.primary;
        openPendingUrl(
          context,
          next,
          opener: (_) => _openPendingUrl(next, toolbarColor),
        );
      },
    );

    // Regreso de un portal externo con encuesta pendiente: se muestra solo si
    // la Home está al frente (no encima de otro diálogo o pantalla).
    ref.listen<PortalSurveyRequest?>(
      portalVisitTrackerProvider.select((s) => s.survey),
      (prev, next) {
        if (next == null) return;
        if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
        final tracker = ref.read(portalVisitTrackerProvider.notifier);
        final request = tracker.takeSurvey();
        if (request == null) return;
        showPortalSurveySheet(context, request: request, tracker: tracker);
      },
    );

    // Nota: el ModalForm NO se muestra automáticamente al entrar/iniciar sesión.
    // Igual que en el original (MainViewModel.kt), solo lo dispara
    // onTramiteClicked cuando el trámite requiere datos y no hay usuario.

    // Escuchar cambios en la visibilidad del modal de formulario
    ref.listen<ModalFormMode?>(
      mainViewModelProvider(widget.municipality.id).select((s) => s.modalMode),
      (prev, next) {
        if (next != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (ctx) => ModalForm(
              mode: next,
              dataPolicyUrl: widget.municipality.dataProcessingPrivacy ?? "",
              privacyPolicyUrl: widget.municipality.dataPrivacy ?? "",
              onDismiss: () {
                Navigator.of(ctx).pop();
              },
              onConfirm: (guestUser) {
                Navigator.of(ctx).pop();
                notifier.onModalConfirmed(guestUser);
              },
            ),
          ).then((_) {
            final currentMode = ref
                .read(mainViewModelProvider(widget.municipality.id))
                .modalMode;
            if (currentMode == next) {
              notifier.onModalDismissed();
            }
          });
        }
      },
    );

    // Escuchar cambios en la visibilidad del contador de pánico
    ref.listen<bool>(
      mainViewModelProvider(
        widget.municipality.id,
      ).select((s) => s.showPanicCountdownDialog),
      (prev, next) {
        if (next) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => PanicCountdownDialog(
              onDismiss: () {
                Navigator.of(ctx).pop();
                notifier.cancelPanicAlert();
              },
              onConfirm: () {
                Navigator.of(ctx).pop();
                final lat = widget.municipality.latitude != null
                    ? double.tryParse(widget.municipality.latitude!)
                    : null;
                final lng = widget.municipality.longitude != null
                    ? double.tryParse(widget.municipality.longitude!)
                    : null;
                notifier.confirmAndSendPanicAlert(lat, lng);
              },
            ),
          );
        }
      },
    );

    // Diálogos informativos.
    //
    // ⚠️ Van por `ref.listen`, NO por `if (state.showX) addPostFrameCallback(...)`
    // dentro del `build`. Ese patrón dispara un `showDialog` en CADA repintado
    // mientras el flag siga en `true` —y la Home repinta por cualquier cosa: el
    // teclado, el tema, la sesión, el carrusel—, así que se apilaban dos o tres
    // diálogos idénticos. Con el de salida eso significaba que "Sí, salir"
    // cerraba uno y navegaba, y los duplicados que quedaban detrás volvían a
    // ejecutar `context.go(...)` desde un contexto ya desmontado: es la vía por
    // la que pulsar Atrás en la Home terminaba, de forma intermitente, en la
    // pantalla de Bienvenida. `ref.listen` corre una sola vez por transición.
    ref.listen<bool>(
      mainViewModelProvider(
        widget.municipality.id,
      ).select((s) => s.showInDevelopmentDialog),
      (prev, next) {
        if (!next) return;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => ConfirmationDialog(
            title: '¡Próximamente disponible!',
            message:
                'Estamos trabajando para que esta función esté lista muy pronto. Te avisaremos cuando esté disponible. Síguenos en nuestras redes o visita nuestro sitio web.',
            icon: Icons.construction,
            confirmButtonText: 'Entendido',
            onConfirm: () {
              Navigator.of(ctx).pop();
              notifier.onInDevelopmentDialogDismiss();
            },
            onDismiss: () {},
          ),
        ).then((_) {
          // El diálogo se puede cerrar también por el gesto Atrás del sistema.
          // Sin esto el flag se quedaría en `true` y el diálogo no volvería a
          // salir nunca (la transición false→true ya no ocurriría).
          if (!mounted) return;
          if (ref
              .read(mainViewModelProvider(widget.municipality.id))
              .showInDevelopmentDialog) {
            notifier.onInDevelopmentDialogDismiss();
          }
        });
      },
    );

    // "Cambio de municipio" del menú lateral (`MainSideMenuOptions.kt`). Ojo:
    // en el original la opción "Cambiar de alcaldía" del menú está comentada,
    // así que hoy nada lo abre (igual aquí); se deja portado para cuando vuelva.
    ref.listen<bool>(
      mainViewModelProvider(
        widget.municipality.id,
      ).select((s) => s.showChangeLocationDialog),
      (prev, next) {
        if (!next) return;
        final name = ref
            .read(mainViewModelProvider(widget.municipality.id))
            .currentMunicipalityName;
        showDialog<void>(
          context: context,
          builder: (ctx) => ConfirmationDialog(
            title: 'Cambio de municipio',
            message:
                'Tu ubicación actual es ${(name == null || name.isEmpty) ? 'Trami App' : name}. Al confirmar, podrás seleccionar un nuevo municipio. ¿Deseas hacer el cambio?',
            icon: Icons.swap_horiz,
            confirmButtonText: 'Cambiar',
            dismissButtonText: 'Cancelar',
            onDismiss: () => Navigator.of(ctx).pop(),
            onConfirm: () {
              Navigator.of(ctx).pop();
              notifier.onConfirmChangeLocation();
              if (context.mounted) context.go(AppRoutes.welcome);
            },
          ),
        ).then((_) {
          // Cancelar, toque fuera o Atrás: resetear el flag (ver arriba).
          if (!mounted) return;
          if (ref
              .read(mainViewModelProvider(widget.municipality.id))
              .showChangeLocationDialog) {
            notifier.onDismissChangeLocationDialog();
          }
        });
      },
    );

    ref.listen<bool>(
      mainViewModelProvider(
        widget.municipality.id,
      ).select((s) => s.showExitDialog),
      (prev, next) {
        if (!next) return;
        showDialog<void>(
          context: context,
          // `ConfirmationDialog` compartido (cabecera de color + ícono), igual
          // que el original; antes era un `AlertDialog` suelto sin el estilo
          // del resto de diálogos de la app.
          builder: (ctx) => ConfirmationDialog(
            title: 'Atención',
            message: 'Estas a punto de salir de esta pantalla.',
            icon: Icons.exit_to_app,
            confirmButtonText: 'Si, salir',
            dismissButtonText: 'No, cancelar',
            onDismiss: () {
              Navigator.of(ctx).pop();
              notifier.onExitDialogDismissed();
            },
            onConfirm: () async {
              Navigator.of(ctx).pop();
              notifier.onExitDialogDismissed();
              // Puerto de `onConfirmExit`: si no hay municipio guardado vuelve
              // al Welcome; si lo hay, cierra la app (`MainEvent.FinishApp`).
              final loc = ref.read(userPreferencesProvider).getSavedLocation();
              if (!loc.guardado) {
                // El pop del diálogo puede haber desmontado esta pantalla: sin
                // el guarda, `context.go` operaría sobre un elemento muerto.
                if (context.mounted) context.go(AppRoutes.welcome);
              } else {
                await SystemNavigator.pop();
              }
            },
          ),
        ).then((_) {
          // Cerrado con el gesto Atrás: resetear el flag (ver arriba).
          if (!mounted) return;
          if (ref
              .read(mainViewModelProvider(widget.municipality.id))
              .showExitDialog) {
            notifier.onExitDialogDismissed();
          }
        });
      },
    );

    // Home es la raíz del flujo de alcaldías: el gesto/botón Atrás del sistema no
    // debe salir de la app, sino reproducir el BackHandler del original (cancelar
    // PQRD si está visible o mostrar el diálogo de salida).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        notifier.onBackPressed();
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(35)),
          ),
          child: MainSideMenuOptions(
            user: state.currentUser,
            onLoginSuccess: () {
              Navigator.pop(context); // Cerrar drawer
              showLoginBottomSheet(context);
            },
            goToSettingsUser: () {
              Navigator.pop(context);
              context.push(AppRoutes.settingsPath(widget.municipality.id));
            },
            onTermsClick: () async {
              Navigator.pop(context);
              final url =
                  widget.municipality.dataPrivacy ??
                  "https://www.1cero1.com/tratamientos.html";
              await abrirUrl(url, toolbarColor: theme.colorScheme.primary);
            },
            goToHelp: () {
              Navigator.pop(context);
              context.push(
                AppRoutes.helpPath(widget.municipality.id),
                extra: {
                  'municipality': domainModel.nombreMunicipio,
                  'portal': domainModel.domain,
                },
              );
            },
            onLogoutSuccess: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await ref.read(sessionProvider.notifier).logout();
              messenger.showSnackBar(
                const SnackBar(content: Text('Sesión cerrada correctamente')),
              );
            },
          ),
        ),
        // Un toque en cualquier zona vacía cierra el teclado, igual que el
        // `clickable(indication = null) { focusManager.clearFocus() }` que
        // envuelve el contenido en `MainScreenContent`.
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  // Barra + escudo/nombre/departamento: se recoge al hacer
                  // scroll, como la cabecera de Historial de pagos.
                  final header = MainHeaderDelegate.measured(
                    context,
                    design: domainModel.design,
                    departamento: domainModel.departamento,
                    isLoading: state.isLoading,
                    onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                    onBack: notifier.onBackPressed,
                    topInset: MediaQuery.paddingOf(context).top,
                    width: constraints.maxWidth,
                  );
                  return CustomScrollView(
                    slivers: [
                      SliverPersistentHeader(pinned: true, delegate: header),
                      SliverToBoxAdapter(
                        child: ConstrainedBox(
                          // La lámina llega al fondo aunque el contenido sea
                          // corto, y deja margen de scroll para recoger la
                          // cabecera.
                          constraints: BoxConstraints(
                            minHeight:
                                (constraints.maxHeight - header.minExtent)
                                    .clamp(0.0, double.infinity),
                          ),
                          // Franja primaria tras las esquinas redondeadas.
                          child: ColoredBox(
                            color: theme.colorScheme.primary,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                              child: Container(
                                // Fondo de página = `background` del original
                                // (White / Gray1000), no `surface` (ese es el
                                // fondo de las cards).
                                color: theme.colorScheme.surfaceContainerLowest,
                                // contentPadding + spacedBy(10.dp) del LazyColumn
                                // original: 16 a los lados, 10 arriba y 10 entre
                                // secciones.
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  10,
                                  16,
                                  0,
                                ),
                                child: Column(
                                  children: [
                                    const MaintenanceInfoCard(),
                                    if (ref
                                        .read(userPreferencesProvider)
                                        .remindersIsVisible()) ...[
                                      AnimatedSection(
                                        child: ReminderToastListener(
                                          child: RemindersSection(
                                            procedures: widget
                                                .municipality
                                                .municipalityProcedures,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                    if (domainModel
                                            .tramitesPrincipales
                                            .isNotEmpty ||
                                        state.isLoading) ...[
                                      AnimatedSection(
                                        child: TramitesSection(
                                          titulo: "Trámites",
                                          tramites:
                                              domainModel.tramitesPrincipales,
                                          searchText: state.searchText,
                                          isSearchActive: state.isSearchActive,
                                          isLoading: state.isLoading,
                                          onSearchTextChanged:
                                              notifier.onSearchTextChanged,
                                          onSearchToggled:
                                              notifier.onSearchToggled,
                                          onTramiteClick: (t) {
                                            notifier.onTramiteClicked(t);
                                            if (t.isActive &&
                                                t.accion is! AbrirUrl &&
                                                t.accion is! AbrirUrlDirecto &&
                                                t.accion is! AbrirBotonPanico) {
                                              _handleNavigation(t);
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                    if (domainModel.otrosTramites.isNotEmpty ||
                                        state.isLoading) ...[
                                      AnimatedSection(
                                        delayMillis: 300,
                                        child: TramitesSection(
                                          titulo: "Otros trámites",
                                          tramites: domainModel.otrosTramites,
                                          searchText: state.searchText,
                                          isSearchActive: false,
                                          isSearchable: false,
                                          isLoading: state.isLoading,
                                          onSearchTextChanged: (_) {},
                                          onSearchToggled: () {},
                                          onTramiteClick: (t) {
                                            notifier.onTramiteClicked(t);
                                            if (t.isActive &&
                                                t.accion is! AbrirUrl &&
                                                t.accion is! AbrirUrlDirecto &&
                                                t.accion is! AbrirBotonPanico) {
                                              _handleNavigation(t);
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                    if (domainModel.socialLinks.isNotEmpty ||
                                        state.isLoading) ...[
                                      AnimatedSection(
                                        delayMillis: 400,
                                        child: TramitesSection(
                                          titulo: "Canales",
                                          tramites: domainModel.socialLinks,
                                          searchText: state.searchText,
                                          isSearchActive: false,
                                          isSearchable: false,
                                          isLoading: state.isLoading,
                                          onSearchTextChanged: (_) {},
                                          onSearchToggled: () {},
                                          onTramiteClick: (t) {
                                            notifier.onTramiteClicked(t);
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                    const SizedBox(height: 10),
                                    AnimatedSection(
                                      delayMillis: 100,
                                      child: _FooterSponsors(
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Adorno de círculos de la esquina superior derecha (`circles`).
              const CirclesDecoration.home(),
            ],
          ),
        ),
        bottomNavigationBar: MainBottomNavBar(
          selectedRoute: state.selectedRoute,
          onTap: (index) async {
            if (index == 0) {
              _logBottomNav(BottomNavDestination.inicio);
              notifier.onRouteChanged("inicio");
            } else if (index == 1) {
              final url = domainModel.newsUrl;
              if (url.isNotEmpty) {
                _logBottomNav(BottomNavDestination.noticias);
                await abrirUrl(url, toolbarColor: theme.colorScheme.primary);
              }
            } else if (index == 2) {
              final url = domainModel.domain;
              if (url.isNotEmpty) {
                _logBottomNav(BottomNavDestination.portal);
                await abrirUrl(url, toolbarColor: theme.colorScheme.primary);
              }
            } else if (index == 3) {
              _logBottomNav(BottomNavDestination.historial);
              context.push(AppRoutes.pagosHistoryPath(widget.municipality.id));
            }
          },
        ),
      ),
    );
  }
}

/// Puerto de `FooterSponsors.kt`: ambos logos son vectores monocromos que el
/// original tinta con el color recibido (`Icon(tint = color)`) dentro de un
/// Row de 30dp de alto. Sin tinte, los SVG (fill blanco) se ven blancos.
class _FooterSponsors extends StatelessWidget {
  const _FooterSponsors({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tint = ColorFilter.mode(color, BlendMode.srcIn);
    return Padding(
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        height: 30,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/icobancolombia.svg',
              width: 102,
              colorFilter: tint,
              fit: BoxFit.contain,
            ),
            Container(
              width: 1,
              height: 30,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: color,
            ),
            SvgPicture.asset(
              'assets/images/ico101software.svg',
              width: 100,
              colorFilter: tint,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
