import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/municipality_dto.dart';
import '../../../core/models/municipality_procedure.dart';
import '../../../core/municipality/municipality_repository.dart';
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
    final design = designFromMunicipality(widget.municipality);
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(sessionProvider);

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
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Sobre el Municipio'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Alcaldía de ${widget.municipality.name}')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Soporte y Ayuda'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ayuda / Formulario (Fase 2)')),
                );
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
          ],
        ),
      ),
      body: _currentIndex == 0
          ? _buildHomeTab(context, scheme)
          : _currentIndex == 1
              ? const Center(child: Text('Mis Trámites (Fase 2)'))
              : _currentIndex == 2
                  ? const Center(child: Text('Noticias (Fase 2)'))
                  : const Center(child: Text('Perfil (Fase 2)')),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: scheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Servicios'),
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'Noticias'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Mi Perfil'),
        ],
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, ColorScheme scheme) {
    final procedures = widget.municipality.municipalityProcedures;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner or Welcome Message
          Container(
            padding: const EdgeInsets.all(20),
            color: scheme.primary.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Qué deseas hacer hoy?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Elige entre los trámites tributarios y de atención ciudadana del municipio.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          // Grid of Procedures
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: procedures.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No hay trámites habilitados por el momento.'),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.25,
                    ),
                    itemCount: procedures.length,
                    itemBuilder: (context, index) {
                      final proc = procedures[index];
                      return _buildProcedureCard(context, proc, scheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcedureCard(
    BuildContext context,
    MunicipalityProcedure proc,
    ColorScheme scheme,
  ) {
    final id = proc.procedures.id;
    final name = proc.procedures.name;

    // Resolve icons and colors based on ID (Motor de trámites FRONTEND §6)
    IconData icon = Icons.receipt;
    Color iconColor = scheme.primary;

    switch (id) {
      case 1: // Predial
        icon = Icons.home;
        iconColor = Colors.orange;
        break;
      case 2: // ICA
        icon = Icons.business;
        iconColor = Colors.purple;
        break;
      case 3: // Declaración
        icon = Icons.article;
        iconColor = Colors.blue;
        break;
      case 4: // PQRSDF
        icon = Icons.question_answer;
        iconColor = Colors.teal;
        break;
      case 5: // Servicios públicos
        icon = Icons.water_drop;
        iconColor = Colors.cyan;
        break;
      case 6: // Vehículos
        icon = Icons.directions_car;
        iconColor = Colors.indigo;
        break;
      case 7: // Retención ICA
        icon = Icons.percent;
        iconColor = Colors.deepOrange;
        break;
      case 10: // Botón Pánico
        icon = Icons.emergency;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.arrow_forward_ios;
        iconColor = Colors.grey;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _handleProcedureTap(context, proc),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 36, color: iconColor),
              const Spacer(),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleProcedureTap(BuildContext context, MunicipalityProcedure proc) {
    final id = proc.procedures.id;
    final name = proc.procedures.name;

    // Decision motor mapping (FRONTEND §6.3)
    if (id == 10 || name.toLowerCase().contains('pánico')) {
      // Panic Button Trigger
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Botón de pánico presionado (Fase 2)')),
      );
      return;
    }

    if (proc.integrationType.isEmpty && id == 4) {
      // PQRSDF native
      context.go(AppRoutes.pqrdPath(widget.municipality.id));
      return;
    }

    if (proc.integrationType.isNotEmpty) {
      if (proc.integrationType.startsWith('http')) {
        // Open URL
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Abriendo enlace externo: ${proc.integrationType}')),
        );
        return;
      }
    }

    // Default redirection
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Accediendo a: $name (Fase 3)')),
    );
  }
}
