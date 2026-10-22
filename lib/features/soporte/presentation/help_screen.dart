import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/widgets/dialog_typography.dart';
import '../../../core/utils/url_opener.dart';

import '../../auth/presentation/login_bottom_sheet.dart';
import '../../tutorial/application/tutorial_providers.dart';
import '../../tutorial/domain/tutorial_videos.dart';
import '../../tutorial/presentation/tutorial_launcher.dart';
import '../../tutorial/presentation/video_tutorial_launcher.dart';
import '../../../core/municipality/municipality_repository.dart';
import '../../tramites/application/tramite_mappers.dart';
import '../application/help_notifier.dart';
import '../domain/help_state.dart';
import 'widgets/support_form_wizard.dart';
import '../../../core/widgets/app_top_bar.dart';

/// Pantalla de Ayuda y Soporte. Port de `HelpScreen.kt`.
///
/// Dos categorías: información sobre impuestos (glosario, tiempos, tratamiento
/// de datos, sitio oficial) y soporte técnico (wizard → correo).
class HelpScreen extends ConsumerWidget {
  const HelpScreen({
    super.key,
    required this.municipalityId,
    required this.municipality,
    required this.portal,
  });

  /// Para abrir el tutorial de esta alcaldía.
  final int municipalityId;

  /// Nombre del municipio (contexto del correo de soporte).
  final String municipality;

  /// URL del sitio web oficial de la alcaldía.
  final String portal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uiState =
        ref.watch(helpNotifierProvider(municipality).select((s) => s.uiState));
    final notifier = ref.read(helpNotifierProvider(municipality).notifier);
    final tutorialEnabled = ref.watch(tutorialConfigProvider).enabled;
    final videos = _videos(ref);

    // Diálogos Success / Error.
    ref.listen<HelpUiState>(
      helpNotifierProvider(municipality).select((s) => s.uiState),
      (prev, next) {
        if (next is HelpSuccess) {
          _showSuccessDialog(context, next.message, notifier.resetToIdle);
        } else if (next is HelpError) {
          _showErrorDialog(context, next, notifier.resetToIdle);
        }
      },
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppTopBar(
        title: 'Ayuda y Soporte',
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        top: false,
        // Todo el contenido 2 sp más grande (también etiquetas, hints y
        // errores de los campos). Los diálogos y el login se abren con el
        // `context` de la pantalla, por fuera, y conservan su tamaño.
        child: Theme(
          data: theme.copyWith(
            textTheme: theme.textTheme.apply(fontSizeDelta: 2),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HelpCategorySection(
                  title: 'Sobre mis Impuestos',
                  children: [
                    if (tutorialEnabled) ...[
                      _TutorialButton(
                        onPressed: () => openTutorial(
                          context,
                          municipalityId: municipalityId,
                          origin: TutorialOrigin.help,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    for (final video in videos) ...[
                      _HelpButton(
                        icon: Icons.play_circle_outline,
                        label: 'Video: ${video.title}',
                        onPressed: () => openTutorialVideo(
                          context,
                          video: video,
                          origin: VideoPlace.help,
                          municipalityId: municipalityId,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const _GlossarySection(),
                    const SizedBox(height: 12),
                    const _ExpandableInfoCard(
                      icon: Icons.schedule,
                      title: 'Tiempos de Compensación',
                      body: _paymentTimingText,
                    ),
                    const SizedBox(height: 12),
                    const _ExpandableInfoCard(
                      icon: Icons.lock,
                      title: 'Tratamiento de Datos',
                      body: _privacyText,
                    ),
                    const SizedBox(height: 12),
                    _OfficialPortalButton(portal: portal),
                  ],
                ),
                const SizedBox(height: 16),
                _HelpCategorySection(
                  title: 'Soporte Técnico',
                  children: [
                    if (uiState is HelpUnauthenticated)
                      _UnauthenticatedSupportState(
                        onLogin: () => showLoginBottomSheet(context),
                      )
                    else
                      SupportFormWizard(municipality: municipality),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Videos tutoriales para esta alcaldía. Los que dependen de sus trámites
  /// (p. ej. cursos y reservas) esperan a que cargue su información; la
  /// alcaldía ya está en caché porque se llega desde su Home.
  List<TutorialVideo> _videos(WidgetRef ref) {
    final config = ref.watch(tutorialVideosConfigProvider);
    if (!config.enabled) return const [];
    final municipality = ref
        .watch(municipalityProvider(municipalityId))
        .value
        ?.toDomainModel();
    return config.videosFor(VideoPlace.help, municipality: municipality);
  }

  // `HandleUiStateDialogs` de `HelpScreen.kt`: el original usa el `AlertDialog`
  // de Material 3 (no los diálogos de marca), así que aquí también —está en la
  // lista de excepciones de `test/core/dialog_parity_test.dart`—. Solo se
  // alinean título y texto con el `Type.kt` (headlineSmall / bodyMedium).
  void _showSuccessDialog(
      BuildContext context, String message, VoidCallback onDismiss) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.mark_email_read_outlined,
            color: Theme.of(ctx).colorScheme.primary),
        title: const Text('¡Solicitud enviada!'),
        titleTextStyle: _dialogTitleStyle(ctx),
        content: Text(message),
        contentTextStyle: _dialogTextStyle(ctx),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    ).then((_) => onDismiss());
  }

  void _showErrorDialog(
      BuildContext context, HelpError error, VoidCallback onDismiss) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.error_outline, color: Theme.of(ctx).colorScheme.error),
        title: const Text('Error al enviar'),
        titleTextStyle: _dialogTitleStyle(ctx),
        content: Text(error.message),
        contentTextStyle: _dialogTextStyle(ctx),
        actions: [
          if (error.isRetryable)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(error.isRetryable ? 'Reintentar' : 'Aceptar'),
          ),
        ],
      ),
    ).then((_) => onDismiss());
  }

  TextStyle _dialogTitleStyle(BuildContext context) => DialogTypography
      .headlineSmall
      .copyWith(color: Theme.of(context).colorScheme.onSurface);

  TextStyle _dialogTextStyle(BuildContext context) => DialogTypography
      .bodyMedium
      .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
}

// =============================================================================
// Estructura
// =============================================================================
class _HelpCategorySection extends StatelessWidget {
  const _HelpCategorySection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

// =============================================================================
// Categoría 1 — glosario, tiempos, privacidad, portal
// =============================================================================
const _glossaryTerms = <(String, String)>[
  (
    'Referencia Catastral',
    'Código alfanumérico único asignado por el IGAC que identifica un predio de forma inequívoca en el catastro municipal. Se compone de: departamento, municipio, zona, sector, manzana y predio.'
  ),
  (
    'Vigencia',
    'Año fiscal al que corresponde la obligación tributaria. El impuesto predial se cobra anualmente; pagar en la vigencia correcta evita intereses de mora.'
  ),
  (
    'Impuesto Predial',
    'Gravamen municipal que recae sobre el avalúo catastral de los bienes inmuebles ubicados en el municipio. Su tarifa la fija el Concejo Municipal dentro de los límites de ley.'
  ),
  (
    'ICA',
    'Impuesto de Industria y Comercio. Grava las actividades industriales, comerciales y de servicios que se realizan en la jurisdicción del municipio, independientemente de dónde se celebren los contratos.'
  ),
  (
    'Avalúo Catastral',
    'Valor oficial del predio determinado por el IGAC o la entidad catastral habilitada, utilizado como base gravable del impuesto predial.'
  ),
  (
    'Interés de Mora',
    'Cargo adicional que se genera cuando el impuesto no se cancela dentro de las fechas límite establecidas por el municipio. Se calcula sobre el capital en mora.'
  ),
];

const _paymentTimingText =
    'Una vez realizado el pago en su entidad bancaria, la conciliación con la '
    'plataforma municipal puede tomar entre 1 y 3 días hábiles.\n\n'
    '• PSE / Pasarela en línea: acreditación en 24 h hábiles.\n'
    '• Pago en banco (ventanilla): hasta 3 días hábiles tras el cierre del lote.\n'
    '• Corresponsal bancario: hasta 48 h hábiles.\n\n'
    'Si transcurrido este tiempo su pago no aparece reflejado, use el formulario '
    'de Soporte Técnico indicando el número de referencia y el comprobante de pago.';

const _privacyText =
    'De conformidad con la Ley 1581 de 2012 y el Decreto 1377 de 2013, los datos '
    'personales recopilados en esta plataforma serán tratados por la Alcaldía y '
    'la entidad prestadora del servicio exclusivamente para:\n\n'
    '• Gestión y recaudo de obligaciones tributarias.\n'
    '• Notificaciones.\n'
    '• Atención de solicitudes de soporte técnico.\n\n'
    'Los datos no serán cedidos a terceros sin su consentimiento explícito, salvo '
    'obligación legal. Usted puede ejercer los derechos de Habeas Data '
    'contactando al correo oficial del municipio.\n'
    'Para conocer más por favor visitar el sitio web oficial de la alcaldía en la '
    'sección "Políticas y tratamiento de datos".';

class _GlossarySection extends StatefulWidget {
  const _GlossarySection();

  @override
  State<_GlossarySection> createState() => _GlossarySectionState();
}

class _GlossarySectionState extends State<_GlossarySection> {
  int? _expandedTerm;

  @override
  Widget build(BuildContext context) {
    return _ExpandableInfoCard.custom(
      icon: Icons.info,
      title: 'Glosario de Términos',
      child: Column(
        children: [
          for (var i = 0; i < _glossaryTerms.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _GlossaryTermItem(
              term: _glossaryTerms[i].$1,
              definition: _glossaryTerms[i].$2,
              expanded: _expandedTerm == i,
              onToggle: () => setState(
                  () => _expandedTerm = _expandedTerm == i ? null : i),
            ),
          ],
        ],
      ),
    );
  }
}

class _GlossaryTermItem extends StatelessWidget {
  const _GlossaryTermItem({
    required this.term,
    required this.definition,
    required this.expanded,
    required this.onToggle,
  });

  final String term;
  final String definition;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onToggle,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        term,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
                if (expanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      definition,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfficialPortalButton extends StatelessWidget {
  const _OfficialPortalButton({required this.portal});

  final String portal;

  Future<void> _open(BuildContext context) =>
      abrirUrl(portal, toolbarColor: Theme.of(context).colorScheme.primary);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton.icon(
      onPressed: () => _open(context),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        side: BorderSide(color: theme.colorScheme.primary),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(Icons.language, size: 20, color: theme.colorScheme.primary),
      label: Text(
        'Sitio web oficial',
        style: theme.textTheme.titleSmall
            ?.copyWith(color: theme.colorScheme.onSurface),
      ),
    );
  }
}

/// «Ver tutorial de la app»: mismo estilo que «Sitio web oficial», con la
/// etiqueta «NUEVO» del diseño.
class _TutorialButton extends StatelessWidget {
  const _TutorialButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _HelpButton(
          icon: Icons.play_lesson_outlined,
          label: 'Ver tutorial de la app',
          onPressed: onPressed,
        ),
        Positioned(
          right: -6,
          top: -10,
          child: ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'NUEVO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .3,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Botón con contorno del estilo de «Sitio web oficial»: tutorial y videos.
class _HelpButton extends StatelessWidget {
  const _HelpButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        side: BorderSide(color: scheme.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 20, color: scheme.primary),
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleSmall?.copyWith(color: scheme.onSurface),
      ),
    );
  }
}

// =============================================================================
// Categoría 2 — estado no autenticado
// =============================================================================
class _UnauthenticatedSupportState extends StatelessWidget {
  const _UnauthenticatedSupportState({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 8),
        Icon(Icons.person,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
        const SizedBox(height: 12),
        Text(
          'Inicia sesión para enviar un reporte',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Para garantizar la trazabilidad de tu solicitud, necesitamos '
            'verificar tu identidad antes de enviar un reporte de soporte técnico.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onLogin,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Iniciar Sesión'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// =============================================================================
// Componente reutilizable — tarjeta expandible
// =============================================================================
class _ExpandableInfoCard extends StatefulWidget {
  const _ExpandableInfoCard({
    required this.icon,
    required this.title,
    required this.body,
  }) : child = null;

  /// Variante con contenido arbitrario (usada por el glosario).
  const _ExpandableInfoCard.custom({
    required this.icon,
    required this.title,
    required this.child,
  }) : body = null;

  final IconData icon;
  final String title;
  final String? body;
  final Widget? child;

  @override
  State<_ExpandableInfoCard> createState() => _ExpandableInfoCardState();
}

class _ExpandableInfoCardState extends State<_ExpandableInfoCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(widget.icon,
                        size: 20, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: theme.colorScheme.onSurface),
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding:
                    const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                child: widget.child ??
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.body ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.3,
                          color: theme.colorScheme.onSurfaceVariant,
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
