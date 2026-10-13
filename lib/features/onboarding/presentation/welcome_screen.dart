import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/url_opener.dart';

import '../../../core/models/department.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/login_bottom_sheet.dart';
import '../../../core/widgets/footer_sponsors.dart';
import '../application/welcome_controller.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

// Colores de acento del onboarding (de ui/theme/Color.kt).
const _kDotsActive = Color(0xFF4364CD); // buttoncolorslogin
const _kDotInactive = Color(0xFFE0E0E0); // Gray300

// Duración total de la coreografía de entrada (la animación más tardía del
// original es el carrusel: slideInVertically con delayMillis=800 + tween(800)
// => termina en 1600ms). El resto de Interval()s de abajo son proporciones de
// esos mismos delays/duraciones sobre esta ventana (WelcomeScreen.kt §header/
// búsqueda/anuncios).
const _kChoreographyDuration = Duration(milliseconds: 1600);

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  int _currentPage = 0;
  Timer? _timer;
  bool _searchFocused = false;

  late final AnimationController _entrance;

  // Header (HeaderWelcome): fadeIn(tween(900)) + slideInVertically(900),
  // sin delay — entra primero.
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  // Buscador de departamento: fadeIn(tween(800, delay=600)) +
  // slideInVertically(800, delay=600, initialOffsetY={ it }) — entra desde abajo.
  late final Animation<double> _searchFade;
  late final Animation<Offset> _searchSlide;

  // Carrusel de anuncios: fadeIn(tween(800, delay=100)) + scaleIn(800, delay=100)
  // + slideInVertically(800, delay=800, initialOffsetY={ -it }) — entra desde arriba.
  late final Animation<double> _carouselFade;
  late final Animation<double> _carouselScale;
  late final Animation<Offset> _carouselSlide;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    });
    _startCarouselTimer();

    _entrance = AnimationController(
      vsync: this,
      duration: _kChoreographyDuration,
    );

    _headerFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0, 900 / 1600, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(_headerFade);

    _searchFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(600 / 1600, 1400 / 1600, curve: Curves.easeOut),
    );
    _searchSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(_searchFade);

    _carouselFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(100 / 1600, 900 / 1600, curve: Curves.easeOut),
    );
    _carouselScale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(_carouselFade);
    _carouselSlide =
        Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entrance,
            curve: const Interval(800 / 1600, 1.0, curve: Curves.easeOut),
          ),
        );

    // Port de triggerAnimations() en WelcomeViewModel: delay antes de
    // arrancar la coreografía.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _entrance.forward();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entrance.dispose();
    _pageController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      final images = ref.read(welcomeControllerProvider).carouselImages;
      if (images.isEmpty || !_pageController.hasClients) return;
      final next = (_currentPage + 1) % images.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onDepartmentSelected(Department dep) {
    _searchController.text = dep.name;
    _searchFocus.unfocus();
    context.push(AppRoutes.selectMunicipalityPath(dep.id));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final welcome = ref.watch(welcomeControllerProvider);
    final user = ref.watch(sessionProvider);
    final filtered = welcome.filteredDepartments;
    final carouselHeight = MediaQuery.of(context).size.width - 44;

    return Scaffold(
      backgroundColor: scheme.primary,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _searchFocus.unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 56),
                // ── Header (HeaderWelcome: fadeIn + slideInVertically, sin delay) ──
                FadeTransition(
                  opacity: _headerFade,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: Column(
                      children: [
                        Text(
                          '¡Bienvenido!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // Si hay sesión, mostrar el nombre del usuario (port del
                        // header de WelcomeScreen.kt).
                        if (user != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            '${user.firstName} ${user.lastName}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          'Vamos a configurar tu aplicación\nElige tu departamento',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // ── Buscador de departamento + dropdown inline ───────────
                // fadeIn + slideInVertically(delay=600), entra desde abajo.
                FadeTransition(
                  opacity: _searchFade,
                  child: SlideTransition(
                    position: _searchSlide,
                    child: _DepartmentSearch(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      onChanged: ref
                          .read(welcomeControllerProvider.notifier)
                          .onQueryChanged,
                      showDropdown: _searchFocused && filtered.isNotEmpty,
                      departments: filtered,
                      onSelected: _onDepartmentSelected,
                      textColor: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // ── Carrusel de anuncios ─────────────────────────────────
                // fadeIn(delay=100) + scaleIn(delay=100) + slideInVertically
                // (delay=800), entra desde arriba.
                FadeTransition(
                  opacity: _carouselFade,
                  child: SlideTransition(
                    position: _carouselSlide,
                    child: ScaleTransition(
                      scale: _carouselScale,
                      child: _Carousel(
                        items: welcome.carouselImages,
                        height: carouselHeight,
                        controller: _pageController,
                        currentPage: _currentPage,
                        onPageChanged: (p) => setState(() => _currentPage = p),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // ── Footer patrocinadores ────────────────────────────────
                FooterSponsors(color: scheme.onPrimary),
                const SizedBox(height: 8),
                // ── Enlace discreto de login ─────────────────────────────
                TextButton(
                  onPressed: () => showLoginBottomSheet(context),
                  child: Text(
                    'Iniciar sesión',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      decoration: TextDecoration.underline,
                      decorationColor: scheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DepartmentSearch extends StatelessWidget {
  const _DepartmentSearch({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.showDropdown,
    required this.departments,
    required this.onSelected,
    required this.textColor,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool showDropdown;
  final List<Department> departments;
  final ValueChanged<Department> onSelected;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            style: TextStyle(color: textColor, fontSize: 15),
            decoration: const InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              hintText: 'Busca tu departamento...',
              hintStyle: TextStyle(color: Color(0xFF7E7E7E)),
              prefixIcon: Icon(Icons.search, color: Color(0xFF7E7E7E)),
              contentPadding: EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 12,
              ),
              border: OutlineInputBorder(borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
          // fadeIn(300) + expandVertically(300) / fadeOut + shrinkVertically.
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: !showDropdown
                  ? const SizedBox(width: double.infinity)
                  : ConstrainedBox(
                      key: const ValueKey('departments'),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: departments.length,
                        itemBuilder: (context, i) {
                          final dep = departments[i];
                          return ListTile(
                            dense: true,
                            title: Text(
                              dep.name,
                              style: TextStyle(color: textColor, fontSize: 15),
                            ),
                            onTap: () => onSelected(dep),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carrusel de anuncios
class _Carousel extends StatelessWidget {
  const _Carousel({
    required this.items,
    required this.height,
    required this.controller,
    required this.currentPage,
    required this.onPageChanged,
  });

  final List<({String imageUrl, String clickUrl})> items;
  final double height;
  final PageController controller;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  var page = currentPage.toDouble();
                  if (controller.hasClients &&
                      controller.position.haveDimensions) {
                    page = controller.page ?? page;
                  }
                  final diff = (page - index).abs();
                  final scale = (1 - diff * 0.1).clamp(0.85, 1.0);
                  final opacity = (1 - diff * 0.3).clamp(0.5, 1.0);
                  return Opacity(
                    opacity: opacity,
                    child: Transform.scale(scale: scale, child: child),
                  );
                },
                child: GestureDetector(
                  onTap: () => abrirUrl(
                    item.clickUrl,
                    toolbarColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Card(
                    elevation: 5,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Center(child: Icon(Icons.error_outline)),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            items.length,
            (i) => Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentPage == i ? _kDotsActive : _kDotInactive,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Aplican T&C',
          style: TextStyle(
            color: _kDotInactive,
            fontSize: 10,
            decoration: TextDecoration.underline,
          ),
        ),
      ],
    );
  }
}
