import 'package:flutter/material.dart';

import '../../../core/theme/design.dart';
import 'widgets/main_bottom_nav_bar.dart';
import 'widgets/main_header.dart';
import 'widgets/tramites_section.dart';

/// Esqueleto de la Home mientras se resuelve la config del municipio.
/// Refleja la estructura real (barra superior + header + lámina con secciones)
/// usando shimmer, en vez de un spinner genérico. Equivalente al estado
/// `MunicipalityUiState.Loading` del original (Compose), que mostraba el
/// `MainHeaderPlaceHolder` + `TramitesSection(isLoading = true)`.
class MainScreenSkeleton extends StatelessWidget {
  const MainScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final placeholderDesign = Design.fromThemeHex(
      alcaldiaName: '',
      shieldUrl: '',
    );

    return Scaffold(
      body: Column(
        children: [
          // Barra superior estática (sin acciones) con el mismo SafeArea.
          Container(
            color: primaryColor,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 8,
                  left: 10,
                  right: 15,
                  bottom: 5,
                ),
                child: SizedBox(
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.all(5),
                          child: ShimmerPlaceholder(
                            width: 35,
                            height: 35,
                            borderRadius: 18,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          MainHeader(design: placeholderDesign, isLoading: true),
          Expanded(
            child: Container(
              color: primaryColor,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Container(
                  color: theme.colorScheme.surface,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    child: Column(
                      children: [
                        TramitesSection(
                          titulo: "Trámites",
                          tramites: const [],
                          searchText: "",
                          isSearchActive: false,
                          isLoading: true,
                          onSearchTextChanged: (_) {},
                          onSearchToggled: () {},
                          onTramiteClick: (_) {},
                        ),
                        const SizedBox(height: 16),
                        TramitesSection(
                          titulo: "Otros trámites",
                          tramites: const [],
                          searchText: "",
                          isSearchActive: false,
                          isSearchable: false,
                          isLoading: true,
                          onSearchTextChanged: (_) {},
                          onSearchToggled: () {},
                          onTramiteClick: (_) {},
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
        selectedRoute: "inicio",
        onTap: (_) {},
      ),
    );
  }
}
