import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/department.dart';
import '../../../core/router/app_routes.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/login_bottom_sheet.dart';
import '../../auth/presentation/widgets/footer_sponsors.dart';
import '../application/welcome_controller.dart';


class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

// Colores de acento del onboarding (de ui/theme/Color.kt).
const _kDotsActive = Color(0xFF4364CD); // buttoncolorslogin
const _kDotInactive = Color(0xFFE0E0E0); // Gray300

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  int _currentPage = 0;
  Timer? _timer;
  bool _searchFocused = false;
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    });
    _startCarouselTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _animate = true);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
          child: AnimatedOpacity(
            opacity: _animate ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 56),
                  // ── Header ───────────────────────────────────────────────
                  AnimatedSlide(
                    offset: _animate ? Offset.zero : const Offset(0, 0.15),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
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
                  const SizedBox(height: 20),
                  // ── Buscador de departamento + dropdown inline ───────────
                  _DepartmentSearch(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged:
                        ref.read(welcomeControllerProvider.notifier).onQueryChanged,
                    showDropdown: _searchFocused && filtered.isNotEmpty,
                    departments: filtered,
                    onSelected: _onDepartmentSelected,
                    textColor: scheme.onSurface,
                  ),
                  const SizedBox(height: 24),
                  // ── Carrusel de anuncios ─────────────────────────────────
                  _Carousel(
                    items: welcome.carouselImages,
                    height: carouselHeight,
                    controller: _pageController,
                    currentPage: _currentPage,
                    onPageChanged: (p) => setState(() => _currentPage = p),
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
              contentPadding:
                  EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              border: OutlineInputBorder(borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
          if (showDropdown)
            ConstrainedBox(
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
        child:
            const Center(child: CircularProgressIndicator(color: Colors.white)),
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
                  onTap: () async {
                    final url = item.clickUrl;
                    if (url.isNotEmpty) {
                      final uri = Uri.tryParse(url);
                      if (uri != null) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    }
                  },
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

