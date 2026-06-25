import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/municipality_dto.dart';
import '../../../core/models/user_dto.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/storage/user_preferences.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/application/registration_draft.dart';
import '../../auth/presentation/login_bottom_sheet.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({required this.municipality, super.key});

  final MunicipalityDTO municipality;

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  bool _loginSheetShown = false;

  @override
  void initState() {
    super.initState();
    // Auto-show del bottom sheet de login cuando no hay sesión (paridad con la
    // orquestación de MainScreen.kt).
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowLogin());
  }

  void _maybeShowLogin() {
    if (!mounted || _loginSheetShown) return;
    if (ref.read(sessionProvider) == null) {
      _loginSheetShown = true;
      showLoginBottomSheet(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mainViewModelProvider(widget.municipality.id));
    final notifier = ref.read(mainViewModelProvider(widget.municipality.id).notifier);
    final theme = Theme.of(context);
    final domainModel = widget.municipality.toDomainModel();

    // Al volver del registro sin sesión, reabrir el sheet (flag del base).
    ref.listen<bool>(registrationSuccessProvider, (prev, next) {
      if (next) {
        ref.read(registrationSuccessProvider.notifier).state = false;
        _loginSheetShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showLoginBottomSheet(context);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        title: Row(
          children: [
            if (design.escudoUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: design.escudoUrl,
                width: 36,
                height: 36,
                errorWidget: (_, _, _) => const Icon(Icons.location_city),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    design.nombreAlcaldia,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Trámites y Servicios',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notificaciones (Fase 2)')),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: scheme.primary),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blue),
              ),
              accountName: Text(
                user != null
                    ? '${user.firstName} ${user.lastName}'
                    : 'Usuario Invitado',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(user?.email ?? 'invitado@tramiapp.gov.co'),
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
            if (user != null)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar Sesión'),
                onTap: () async {
                  await ref.read(sessionProvider.notifier).logout();
                  if (mounted) {
                    context.go(AppRoutes.welcome);
                  }
                },
              ),
            if (user == null)
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Iniciar Sesión'),
                onTap: () {
                  Navigator.pop(context);
                  showLoginBottomSheet(context);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Cambiar Municipio'),
              onTap: () async {
                final prefs = ref.read(userPreferencesProvider);
                await prefs.clearCurrentMunicipality();
                if (mounted) {
                  context.go(AppRoutes.welcome);
                }
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
                  final loc = ref.read(userPreferencesProvider).getSavedLocation();
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

    return Scaffold(
      key: _scaffoldKey,
      appBar: MainTopBar(
        onMenuClicked: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        onBackClicked: () {
          notifier.onBackPressed();
        },
      ),
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
            context.push(AppRoutes.loginOptions);
          },
          goToSettingsUser: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Configuraciones de usuario (Fase 2)')),
            );
          },
          onTermsClick: () async {
            Navigator.pop(context);
            final url = widget.municipality.dataPrivacy ?? "https://www.1cero1.com/tratamientos.html";
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
          MainHeader(
            design: domainModel.design,
            departamento: domainModel.departamento,
            isLoading: state.isLoading,
          ),
          Expanded(
            child: Container(
              color: theme.colorScheme.primary,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  color: theme.colorScheme.surface,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    child: Column(
                      children: [
                        if (domainModel.tramitesPrincipales.isNotEmpty || state.isLoading) ...[
                          TramitesSection(
                            titulo: "Trámites",
                            tramites: domainModel.tramitesPrincipales,
                            searchText: state.searchText,
                            isSearchActive: state.isSearchActive,
                            isLoading: state.isLoading,
                            onSearchTextChanged: notifier.onSearchTextChanged,
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
                          const SizedBox(height: 16),
                        ],
                        if (domainModel.otrosTramites.isNotEmpty || state.isLoading) ...[
                          TramitesSection(
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
                          const SizedBox(height: 16),
                        ],
                        if (domainModel.socialLinks.isNotEmpty || state.isLoading) ...[
                          TramitesSection(
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
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 10),
                        _FooterSponsors(color: theme.colorScheme.onSurface),
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
            context.go(AppRoutes.pagosHistoryPath(widget.municipality.id));
          }
        },
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
