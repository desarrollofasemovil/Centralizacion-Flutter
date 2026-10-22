import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/models/municipality_dto.dart';
import '../../../core/storage/user_preferences.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../auth/application/auth_providers.dart';
import '../../tramites/application/tramite_mappers.dart';
import '../../tramites/domain/info_tramite.dart';
import '../application/tutorial_providers.dart';
import '../domain/tutorial_config.dart';
import '../domain/tutorial_content.dart';
import 'tutorial_palette.dart';
import 'widgets/tutorial_illustrations.dart';

/// Tutorial de primer uso: carrusel de tarjetas a pantalla completa, solo
/// informativas. Diseño: Claude Design «Tutorial Trami» (2026-10-22).
///
/// Se cierra con `pop`; el resultado es el botón de la tarjeta de cuenta que
/// tocó (`login` / `signUp` piden a quien lo abrió que siga a esa pantalla) o
/// `null`. Ver `openTutorial`.
class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({
    super.key,
    required this.municipality,
    required this.origin,
  });

  final MunicipalityDTO municipality;
  final TutorialOrigin origin;

  /// Curva y duración del cambio de tarjeta (hoja de especificaciones).
  static const pageDuration = Duration(milliseconds: 350);
  static const pageCurve = Curves.easeOutCubic;

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final _pages = PageController();
  late final TutorialContent _content;
  late final TutorialConfig _config;
  late final TutorialPalette _palette;
  late final AnalyticsService _analytics;
  int _index = 0;

  List<TutorialCard> get _cards => _content.cards;
  bool get _isLast => _index == _cards.length - 1;
  int get _municipalityId => widget.municipality.id;

  @override
  void initState() {
    super.initState();
    final user = ref.read(sessionProvider);
    _content = buildTutorialContent(
      widget.municipality.toDomainModel(),
      hasSession: user != null && user.loginStatus,
    );
    _config = ref.read(tutorialConfigProvider);
    _palette = TutorialPalette.from(_content.primary);
    _analytics = ref.read(analyticsServiceProvider);

    // Visto en cuanto se abre: si la app se cierra a mitad de camino no vuelve
    // a tapar la Home (queda en Ayuda y Soporte).
    ref.read(userPreferencesProvider).markTutorialSeen();
    _analytics.logTutorialStarted(
      municipalityId: _municipalityId,
      origin: widget.origin,
      route: _content.route,
      totalSteps: _cards.length,
    );
    _logStepViewed();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _logStepViewed() => _analytics.logTutorialStepViewed(
    municipalityId: _municipalityId,
    origin: widget.origin,
    step: _index + 1,
    card: _cards[_index].id,
  );

  void _onPageChanged(int index) {
    setState(() => _index = index);
    _logStepViewed();
  }

  void _goTo(int index) => _pages.animateToPage(
    index,
    duration: TutorialScreen.pageDuration,
    curve: TutorialScreen.pageCurve,
  );

  void _skip() {
    _analytics.logTutorialSkipped(
      municipalityId: _municipalityId,
      origin: widget.origin,
      step: _index + 1,
      card: _cards[_index].id,
    );
    Navigator.of(context).pop();
  }

  void _finish(TutorialClose close) {
    _analytics.logTutorialCompleted(
      municipalityId: _municipalityId,
      origin: widget.origin,
      totalSteps: _cards.length,
      close: close,
    );
    Navigator.of(context).pop(close);
  }

  void _next() => _isLast ? _finish(TutorialClose.start) : _goTo(_index + 1);

  /// "Atrás" (botón o sistema): tarjeta anterior; en la primera, omitir.
  void _back() => _index == 0 ? _skip() : _goTo(_index - 1);

  @override
  Widget build(BuildContext context) {
    final p = _palette;
    final card = _cards[_index];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: TutorialPalette.surface,
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(
                  palette: p,
                  showBack: _index > 0,
                  onBack: _back,
                  onSkip: _skip,
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: _cards.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, i) => _TutorialPage(
                      card: _cards[i],
                      step: i + 1,
                      total: _cards.length,
                      content: _content,
                      copy: _config.copyFor(_cards[i], _content),
                      palette: p,
                    ),
                  ),
                ),
                if (card == TutorialCard.account)
                  _AccountControls(
                    palette: p,
                    index: _index,
                    total: _cards.length,
                    onLogin: () => _finish(TutorialClose.login),
                    onSignUp: () => _finish(TutorialClose.signUp),
                    onLater: () => _finish(TutorialClose.later),
                  )
                else
                  _Controls(
                    palette: p,
                    index: _index,
                    total: _cards.length,
                    isLast: _isLast,
                    onNext: _next,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Barra superior: Atrás / Omitir
// =============================================================================
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.palette,
    required this.showBack,
    required this.onBack,
    required this.onSkip,
  });

  final TutorialPalette palette;
  final bool showBack;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  /// Área táctil mínima (48 dp) alrededor del botón de atrás compartido.
  static const _touch = 48.0;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 8),
        child: Row(
          children: [
            if (showBack)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack,
                child: SizedBox.square(
                  dimension: _touch,
                  child: AppBackButton(
                    onPressed: onBack,
                    backgroundColor: p.tint10,
                    iconColor: p.primary,
                  ),
                ),
              )
            else
              const SizedBox.square(dimension: _touch),
            const Spacer(),
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                foregroundColor: p.primary,
                overlayColor: p.primary,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('Omitir'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Una tarjeta
// =============================================================================
class _TutorialPage extends StatelessWidget {
  const _TutorialPage({
    required this.card,
    required this.step,
    required this.total,
    required this.content,
    required this.copy,
    required this.palette,
  });

  final TutorialCard card;
  final int step;
  final int total;
  final TutorialContent content;
  final TutorialCopy copy;
  final TutorialPalette palette;

  @override
  Widget build(BuildContext context) {
    // Se anuncia «Paso 2 de 6.» y después el título y el texto.
    return Semantics(
      container: true,
      label: 'Paso $step de $total.',
      child: card == TutorialCard.pqrsdf
          ? _PqrsdfGuide(
              title: copy.title,
              tramite: content.pqrsdfTramite,
              palette: palette,
            )
          : Column(
              children: [
                // La ilustración es la que cede espacio: con letra grande se
                // encoge y el texto nunca se corta.
                Expanded(
                  child: ClipRect(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: TutorialIllustration(
                          card: card,
                          content: content,
                          palette: palette,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: _CardText(copy: copy),
                ),
              ],
            ),
    );
  }
}

class _CardText extends StatelessWidget {
  const _CardText({required this.copy});

  final TutorialCopy copy;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.title,
            style: text.headlineSmall?.copyWith(
              fontSize: 26,
              height: 32 / 26,
              fontWeight: FontWeight.w700,
              color: TutorialPalette.onSurface,
            ),
          ),
          if (copy.body.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              copy.body,
              style: text.bodyLarge?.copyWith(
                fontSize: 17,
                height: 25 / 17,
                color: TutorialPalette.onSurfaceVar,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// 5 · Guía de PQRSDF (sin ilustración)
// =============================================================================
const _pqrsdfLetters = <(String, String, String)>[
  ('P', 'Petición', 'pides algo a la alcaldía.'),
  ('Q', 'Queja', 'no te gustó la atención de un funcionario.'),
  ('R', 'Reclamo', 'un servicio no funcionó como debía.'),
  ('S', 'Sugerencia', 'propones una mejora.'),
  ('D', 'Denuncia', 'informas un hecho irregular.'),
  ('F', 'Felicitación', 'reconoces un buen servicio.'),
];

class _PqrsdfGuide extends StatelessWidget {
  const _PqrsdfGuide({
    required this.title,
    required this.tramite,
    required this.palette,
  });

  final String title;
  final InfoTramite? tramite;
  final TutorialPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final text = Theme.of(context).textTheme;
    final t = tramite;
    // Con letra grande, el respaldo es el scroll.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // El mismo círculo e ícono de PQRSDF de la Home.
              ExcludeSemantics(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: t?.color ?? const Color(0xFFC2F5E6),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: t == null
                      ? const Icon(Icons.support_agent, size: 26)
                      : SvgPicture.asset(t.icono, width: 26, height: 26),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: text.headlineSmall?.copyWith(
                    fontSize: 24,
                    height: 29 / 24,
                    fontWeight: FontWeight.w700,
                    color: TutorialPalette.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final (letter, word, meaning) in _pqrsdfLetters) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: p.tint10,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: p.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$word: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: TutorialPalette.onSurface,
                            ),
                          ),
                          TextSpan(text: meaning),
                        ],
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        height: 20 / 15,
                        color: TutorialPalette.cropText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 6),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _PqrsdfOption(
                    icon: Icons.badge_outlined,
                    title: 'Identificada',
                    body: 'Recibes un radicado y puedes hacer seguimiento.',
                    palette: p,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PqrsdfOption(
                    icon: Icons.visibility_off_outlined,
                    title: 'Anónima',
                    body:
                        'No dejas tus datos, pero no podrás consultar la '
                        'respuesta.',
                    palette: p,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PqrsdfOption extends StatelessWidget {
  const _PqrsdfOption({
    required this.icon,
    required this.title,
    required this.body,
    required this.palette,
  });

  final IconData icon;
  final String title;
  final String body;
  final TutorialPalette palette;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: TutorialPalette.panel,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: palette.primary),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            height: 19 / 15,
            fontWeight: FontWeight.w700,
            color: TutorialPalette.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(
            fontSize: 14,
            height: 19 / 14,
            color: TutorialPalette.onSurfaceVar,
          ),
        ),
      ],
    ),
  );
}

// =============================================================================
// Controles
// =============================================================================

/// Puntos del carrusel: el activo es una píldora de 24×8 en primario.
class _Dots extends StatelessWidget {
  const _Dots({
    required this.palette,
    required this.index,
    required this.total,
  });

  final TutorialPalette palette;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: i == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? palette.primary : TutorialPalette.dotOff,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ],
    ),
  );
}

const _buttonText = TextStyle(fontSize: 17, fontWeight: FontWeight.w500);

class _Controls extends StatelessWidget {
  const _Controls({
    required this.palette,
    required this.index,
    required this.total,
    required this.isLast,
    required this.onNext,
  });

  final TutorialPalette palette;
  final int index;
  final int total;
  final bool isLast;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            _Dots(palette: p, index: index, total: total),
            const SizedBox(width: 16),
            // Con letra muy grande el botón cede antes que desbordar.
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor: TutorialPalette.onPrimary,
                    minimumSize: const Size(136, 52),
                    padding: const EdgeInsets.only(left: 26, right: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    textStyle: _buttonText,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          isLast ? 'Empezar' : 'Siguiente',
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isLast ? Icons.check : Icons.arrow_forward,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta 7: Iniciar sesión / Crear cuenta / Ahora no.
class _AccountControls extends StatelessWidget {
  const _AccountControls({
    required this.palette,
    required this.index,
    required this.total,
    required this.onLogin,
    required this.onSignUp,
    required this.onLater,
  });

  final TutorialPalette palette;
  final int index;
  final int total;
  final VoidCallback onLogin;
  final VoidCallback onSignUp;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(26),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 16,
            child: Center(
              child: _Dots(palette: p, index: index, total: total),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onLogin,
            style: FilledButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor: TutorialPalette.onPrimary,
              minimumSize: const Size.fromHeight(52),
              shape: pill,
              textStyle: _buttonText,
            ),
            icon: const Icon(Icons.person, size: 22),
            label: const Text('Iniciar sesión'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onSignUp,
            style: OutlinedButton.styleFrom(
              foregroundColor: p.primary,
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: p.primary, width: 1.5),
              shape: pill,
              textStyle: _buttonText,
            ),
            child: const Text('Crear cuenta'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onLater,
            style: TextButton.styleFrom(
              foregroundColor: p.primary,
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: const Text('Ahora no'),
          ),
        ],
      ),
    );
  }
}
