import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/municipality_dto.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/storage/user_preferences.dart';
import '../../../core/utils/url_opener.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/login_bottom_sheet.dart';
import '../../reminders/presentation/reminders_section.dart';
import '../../tramites/application/tramite_mappers.dart';
import '../../tramites/domain/info_tramite.dart';
import '../application/main_viewmodel.dart';
import 'widgets/animated_section.dart';
import 'widgets/main_bottom_nav_bar.dart';
import 'widgets/main_header.dart';
import 'widgets/main_side_menu_options.dart';
import 'widgets/main_top_bar.dart';
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

    // Escuchar si hay alguna URL pendiente para abrir
    ref.listen<
      String?
    >(mainViewModelProvider(widget.municipality.id).select((s) => s.urlToOpen), (
      prev,
      next,
    ) async {
      if (next != null && next.isNotEmpty) {
        // Portal tributario / URLs de trámite: se abren en el navegador in-app
        // (Chrome Custom Tabs / Safari VC) tintado con el color del municipio,
        // igual que `abrirURL(context, url, colorPrimario)` del original.
        await abrirUrl(next, toolbarColor: theme.colorScheme.primary);
        notifier.clearUrlToOpen();
      }
    });

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

    // Diálogos informativos
    if (state.showInDevelopmentDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
        );
      });
    }

    if (state.showExitDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
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
                context.go(AppRoutes.welcome);
              } else {
                await SystemNavigator.pop();
              }
            },
          ),
        );
      });
    }

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
            currentMunicipalityName: state.currentMunicipalityName ?? "",
            showChangeLocationDialog: state.showChangeLocationDialog,
            onDismissDialog: notifier.onDismissChangeLocationDialog,
            onConfirmChangeLocation: () {
              notifier.onConfirmChangeLocation();
              context.go(AppRoutes.welcome);
            },
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
              Column(
                children: [
                  MainTopBar(
                    onMenuClicked: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    onBackClicked: () {
                      notifier.onBackPressed();
                    },
                  ),
                  MainHeader(
                    design: domainModel.design,
                    departamento: domainModel.departamento,
                    isLoading: state.isLoading,
                  ),
                  Expanded(
                    child: Container(
                      color: theme.colorScheme.primary,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Container(
                          // Fondo de página = `background` del original (White /
                          // Gray1000), no `surface` (ese es el fondo de las cards).
                          color: theme.colorScheme.surfaceContainerLowest,
                          child: SingleChildScrollView(
                            // contentPadding + verticalArrangement.spacedBy(10.dp) del
                            // LazyColumn original: 16 a los lados, 10 arriba y 10
                            // entre secciones.
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                            child: Column(
                              children: [
                                const MaintenanceInfoCard(),
                                if (ref
                                    .read(userPreferencesProvider)
                                    .remindersIsVisible()) ...[
                                  AnimatedSection(
                                    child: RemindersSection(
                                      procedures: widget
                                          .municipality
                                          .municipalityProcedures,
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
                                      tramites: domainModel.tramitesPrincipales,
                                      searchText: state.searchText,
                                      isSearchActive: state.isSearchActive,
                                      isLoading: state.isLoading,
                                      onSearchTextChanged:
                                          notifier.onSearchTextChanged,
                                      onSearchToggled: notifier.onSearchToggled,
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
              notifier.onRouteChanged("inicio");
            } else if (index == 1) {
              final url = domainModel.newsUrl;
              if (url.isNotEmpty) {
                await abrirUrl(url, toolbarColor: theme.colorScheme.primary);
              }
            } else if (index == 2) {
              final url = domainModel.domain;
              if (url.isNotEmpty) {
                await abrirUrl(url, toolbarColor: theme.colorScheme.primary);
              }
            } else if (index == 3) {
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
