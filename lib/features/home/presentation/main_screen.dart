import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/municipality_dto.dart';
import '../../../core/models/user_dto.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/storage/user_preferences.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/login_bottom_sheet.dart';
import '../../tramites/application/tramite_mappers.dart';
import '../../tramites/domain/info_tramite.dart';
import '../application/main_viewmodel.dart';
import 'widgets/animated_section.dart';
import 'widgets/main_bottom_nav_bar.dart';
import 'widgets/main_header.dart';
import 'widgets/main_side_menu_options.dart';
import 'widgets/main_top_bar.dart';
import 'widgets/modal_form.dart';
import 'widgets/panic_countdown_dialog.dart';
import 'widgets/tramites_section.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({required this.municipality, super.key});

  final MunicipalityDTO municipality;

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPostLoginModalForm();
    });
  }

  void _checkPostLoginModalForm() {
    final loggedInUser = ref.read(sessionProvider);
    final prefs = ref.read(userPreferencesProvider);
    final isCompleted = prefs.modalFormCompleted();

    if (loggedInUser != null && !isCompleted) {
      ref
          .read(mainViewModelProvider(widget.municipality.id).notifier)
          .showModalForm(ModalFormMode.generic);
    }
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
        extra: {'taxId': action.taxId, 'title': name},
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
    ref.listen<String?>(
      mainViewModelProvider(widget.municipality.id).select((s) => s.urlToOpen),
      (prev, next) async {
        if (next != null && next.isNotEmpty) {
          final uri = Uri.parse(next);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
          notifier.clearUrlToOpen();
        }
      },
    );

    // Escuchar si el usuario inicia sesión para activar el modal
    ref.listen<UserDTO?>(sessionProvider, (prev, next) {
      if (next != null) {
        final isCompleted = ref
            .read(userPreferencesProvider)
            .modalFormCompleted();
        if (!isCompleted) {
          notifier.showModalForm(ModalFormMode.generic);
        }
      }
    });

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
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.construction, color: Colors.blue),
                SizedBox(width: 10),
                Text('¡Próximamente disponible!'),
              ],
            ),
            content: const Text(
              'Estamos trabajando para que esta función esté lista muy pronto. Te avisaremos cuando esté disponible. Síguenos en nuestras redes o visita nuestro sitio web.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  notifier.onInDevelopmentDialogDismiss();
                },
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      });
    }

    if (state.showExitDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.exit_to_app, color: Colors.blue),
                SizedBox(width: 10),
                Text('Atención'),
              ],
            ),
            content: const Text('Estás a punto de salir de esta pantalla.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  notifier.onExitDialogDismissed();
                },
                child: const Text('No, cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  notifier.onExitDialogDismissed();
                  final loc = ref
                      .read(userPreferencesProvider)
                      .getSavedLocation();
                  if (!loc.guardado) {
                    context.go(AppRoutes.welcome);
                  } else {
                    // Cierra la app o vuelve al selector
                    context.go(AppRoutes.welcome);
                  }
                },
                child: const Text('Sí, salir'),
              ),
            ],
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Configuraciones de usuario (Fase 2)'),
                ),
              );
            },
            onTermsClick: () async {
              Navigator.pop(context);
              final url =
                  widget.municipality.dataPrivacy ??
                  "https://www.1cero1.com/tratamientos.html";
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            goToHelp: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Soporte y Ayuda (Fase 2)')),
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
        body: Column(
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
                    color: theme.colorScheme.surface,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      child: Column(
                        children: [
                          if (domainModel.tramitesPrincipales.isNotEmpty ||
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
                                  if (t.accion is! AbrirUrl &&
                                      t.accion is! AbrirUrlDirecto &&
                                      t.accion is! AbrirBotonPanico) {
                                    _handleNavigation(t);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
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
                                  if (t.accion is! AbrirUrl &&
                                      t.accion is! AbrirUrlDirecto &&
                                      t.accion is! AbrirBotonPanico) {
                                    _handleNavigation(t);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
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
                            const SizedBox(height: 16),
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
        bottomNavigationBar: MainBottomNavBar(
          selectedRoute: state.selectedRoute,
          onTap: (index) async {
            if (index == 0) {
              notifier.onRouteChanged("inicio");
            } else if (index == 1) {
              final url = domainModel.newsUrl;
              if (url.isNotEmpty) {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            } else if (index == 2) {
              final url = domainModel.domain;
              if (url.isNotEmpty) {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
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

class _FooterSponsors extends StatelessWidget {
  const _FooterSponsors({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Bancolombia',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          width: 1,
          height: 24,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          color: color.withValues(alpha: 0.5),
        ),
        Image.asset(
          'assets/images/logo_101software.png',
          width: 100,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}
