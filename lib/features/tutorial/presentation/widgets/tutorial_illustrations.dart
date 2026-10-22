import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../tramites/domain/info_tramite.dart';
import '../../domain/tutorial_content.dart';
import '../tutorial_palette.dart';

/// Ilustración de una tarjeta: una forma suave en `tint10` y, encima, un
/// recorte de la app reconstruido con datos ficticios, con íconos satélite.
/// Medidas en dp del diseño (composiciones de unos 312×300); quien la monta la
/// encoge con `FittedBox` si no cabe.
///
/// Es decorativa: el texto va con escala fija (1.0) y sin semántica.
class TutorialIllustration extends StatelessWidget {
  const TutorialIllustration({
    super.key,
    required this.card,
    required this.content,
    required this.palette,
  });

  final TutorialCard card;
  final TutorialContent content;
  final TutorialPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final child = switch (card) {
      TutorialCard.welcome => _Welcome(p, content.shieldUrl),
      TutorialCard.taxesInApp => _InvoiceInApp(p),
      TutorialCard.taxesPortal => _Portal(p, content.portalTaxTramite),
      TutorialCard.remindersInApp => _ReminderOnInvoice(p),
      TutorialCard.remindersPortal => _MyReminders(p),
      TutorialCard.tramites => _Tramites(p, content.tramites),
      TutorialCard.historyInApp => _HistoryInApp(p, content.alcaldia),
      TutorialCard.historyPortal => _HistoryPortal(p, content.alcaldia),
      TutorialCard.account => _Account(p),
      // La 5 no tiene ilustración: la guía es el contenido.
      TutorialCard.pqrsdf => const SizedBox.shrink(),
    };
    return ExcludeSemantics(
      child: IgnorePointer(
        child: MediaQuery.withNoTextScaling(
          // Una línea por defecto: el recorte mide lo mismo con cualquier
          // nombre de alcaldía o de trámite (los trámites de la 4 van a dos).
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: TutorialPalette.cropText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: child,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Piezas comunes
// =============================================================================

/// Rectángulo redondeado en `tint10`, girado [degrees].
class _Shape extends StatelessWidget {
  const _Shape({
    required this.color,
    required this.width,
    required this.height,
    required this.radius,
    this.degrees = 0,
  });

  final Color color;
  final double width;
  final double height;
  final double radius;
  final double degrees;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: degrees * math.pi / 180,
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}

/// Círculo blanco con sombra y un ícono en primario.
class _Satellite extends StatelessWidget {
  const _Satellite(this.icon, this.color, {this.size = 56, this.iconSize = 30});

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: TutorialPalette.satelliteShadow,
    ),
    alignment: Alignment.center,
    child: Icon(icon, size: iconSize, color: color),
  );
}

/// Círculo de un trámite como en la Home: su color y su SVG sin teñir.
class _TramiteCircle extends StatelessWidget {
  const _TramiteCircle({required this.size, this.tramite});

  final double size;

  /// `null` = el círculo genérico del diseño (sin un trámite que mostrar).
  final InfoTramite? tramite;

  @override
  Widget build(BuildContext context) {
    final t = tramite;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: t?.color ?? const Color(0xFFB3DCE6),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: t == null
          ? Icon(
              Icons.home_work_outlined,
              size: size / 2,
              color: const Color(0xFF222222),
            )
          : SvgPicture.asset(t.icono, width: size / 2, height: size / 2),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText(this.icon, this.text, {this.iconSize = 16, this.style});

  final IconData icon;
  final String text;
  final double iconSize;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: iconSize, color: TutorialPalette.cropMuted),
      const SizedBox(width: 6),
      Flexible(
        child: Text(text, style: style ?? const TextStyle(fontSize: 12.5)),
      ),
    ],
  );
}

/// Botón de "Recordarme…" resaltado: fondo `tint10` y contorno primario de 2.
class _HighlightedReminder extends StatelessWidget {
  const _HighlightedReminder(this.p, this.label, {this.center = true});

  final TutorialPalette p;
  final String label;
  final bool center;

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: p.tint10,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: p.primary, width: 2),
    ),
    child: Row(
      mainAxisAlignment: center
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        Icon(Icons.notifications_active_outlined, size: 18, color: p.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: p.primary,
            ),
          ),
        ),
      ],
    ),
  );
}

// =============================================================================
// 1 · Bienvenida
// =============================================================================
class _Welcome extends StatelessWidget {
  const _Welcome(this.p, this.shieldUrl);

  final TutorialPalette p;
  final String shieldUrl;

  @override
  Widget build(BuildContext context) {
    const fallback = Icon(Icons.location_city, size: 48, color: Colors.grey);
    return ConstrainedBox(
      // Mínimo del diseño; si el recorte crece (letras largas), crece la
      // composición y el `FittedBox` de la tarjeta la encoge.
      constraints: const BoxConstraints(minWidth: 300, minHeight: 300),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(color: p.tint10, shape: BoxShape.circle),
          ),
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(color: p.tint20, shape: BoxShape.circle),
          ),
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  offset: Offset(0, 8),
                  blurRadius: 24,
                  color: Color(0x2E001E32),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: 108,
                height: 108,
                child: shieldUrl.trim().isEmpty
                    ? fallback
                    : CachedNetworkImage(
                        imageUrl: shieldUrl,
                        fit: BoxFit.contain,
                        errorWidget: (_, _, _) => fallback,
                      ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 42,
            child: _Satellite(
              Icons.receipt_long_outlined,
              p.primary,
              size: 64,
              iconSize: 34,
            ),
          ),
          Positioned(
            right: 14,
            top: 26,
            child: _Satellite(
              Icons.notifications_outlined,
              p.primary,
              size: 64,
              iconSize: 34,
            ),
          ),
          Positioned(
            right: 30,
            bottom: 30,
            child: _Satellite(
              Icons.description_outlined,
              p.primary,
              size: 64,
              iconSize: 34,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 2A · Factura en la app
// =============================================================================
class _InvoiceInApp extends StatelessWidget {
  const _InvoiceInApp(this.p);

  final TutorialPalette p;

  @override
  Widget build(BuildContext context) {
    Widget roundAction(IconData icon, Color color, double size) => Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFEEEEEE),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 2),
            blurRadius: 6,
            color: Color(0x2E000000),
          ),
        ],
      ),
      child: Icon(icon, size: size, color: color),
    );

    return ConstrainedBox(
      // Mínimo del diseño; si el recorte crece (letras largas), crece la
      // composición y el `FittedBox` de la tarjeta la encoge.
      constraints: const BoxConstraints(minWidth: 312, minHeight: 300),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 16,
            top: 20,
            child: _Shape(
              color: p.tint10,
              width: 280,
              height: 260,
              radius: 40,
              degrees: -6,
            ),
          ),
          Container(
            width: 268,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: p.primary),
              borderRadius: BorderRadius.circular(16),
              boxShadow: TutorialPalette.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      // Como en la factura real, una línea larga baja a dos.
                      child: DefaultTextStyle.merge(
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 18 / 12.5,
                          color: TutorialPalette.cropText,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nombre: María Pérez'),
                            Text('Impuesto: Impuesto Predial Unificado'),
                            Text('Factura: 00012345'),
                            Text('Fecha límite: 30/11/2026'),
                            Text(
                              'Total a pagar: 245.000 \$',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        roundAction(
                          Icons.picture_as_pdf,
                          const Color(0xFFE53935),
                          24,
                        ),
                        const SizedBox(height: 8),
                        roundAction(Icons.share, const Color(0xFF111111), 22),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.primary,
                    borderRadius: BorderRadius.circular(21),
                    boxShadow: const [
                      BoxShadow(
                        offset: Offset(0, 3),
                        blurRadius: 8,
                        color: Color(0x2E000000),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Pagar por PSE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 30,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_active_outlined,
                        size: 18,
                        color: p.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Recordarme antes del vencimiento',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: p.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 4,
            top: 6,
            child: _Satellite(Icons.verified_user_outlined, p.primary),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 2B · Portal externo
// =============================================================================
class _Portal extends StatelessWidget {
  const _Portal(this.p, this.tramite);

  final TutorialPalette p;
  final InfoTramite? tramite;

  @override
  Widget build(BuildContext context) {
    Widget bar(Color color, double widthFactor) => FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 7,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
    Widget dot(Color color, double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    return ConstrainedBox(
      // Mínimo del diseño; si el recorte crece (letras largas), crece la
      // composición y el `FittedBox` de la tarjeta la encoge.
      constraints: const BoxConstraints(minWidth: 312, minHeight: 280),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            top: 20,
            bottom: 20,
            child: Container(
              decoration: BoxDecoration(
                color: p.tint10,
                borderRadius: BorderRadius.circular(120),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      offset: Offset(0, 6),
                      blurRadius: 16,
                      color: Color(0x1F001E32),
                    ),
                  ],
                ),
                child: _TramiteCircle(size: 88, tramite: tramite),
              ),
              const SizedBox(width: 6),
              // Línea punteada + flecha: «te llevamos al portal».
              for (var i = 0; i < 3; i++) ...[
                dot(p.primary, 3),
                const SizedBox(width: 2),
              ],
              Icon(Icons.arrow_forward, size: 30, color: p.primary),
              const SizedBox(width: 6),
              Container(
                width: 150,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      offset: Offset(0, 10),
                      blurRadius: 28,
                      color: Color(0x2E001E32),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 28,
                      color: const Color(0xFFF1F3F4),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          dot(TutorialPalette.dotOff, 6),
                          const SizedBox(width: 3),
                          dot(TutorialPalette.dotOff, 6),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              height: 16,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.lock,
                                    size: 10,
                                    color: TutorialPalette.onSurfaceVar,
                                  ),
                                  SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      'pagos.alcaldia.gov.co',
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: TutorialPalette.onSurfaceVar,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Portal de pagos',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: TutorialPalette.onSurface,
                            ),
                          ),
                          const SizedBox(height: 7),
                          bar(p.tint20, .9),
                          const SizedBox(height: 7),
                          bar(p.tint10, .7),
                          const SizedBox(height: 7),
                          bar(p.tint10, .8),
                          const SizedBox(height: 11),
                          Container(
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: p.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Pagar',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 3A · «Recordarme» en la factura + aviso de la Home
// =============================================================================
class _ReminderOnInvoice extends StatelessWidget {
  const _ReminderOnInvoice(this.p);

  final TutorialPalette p;

  /// Las líneas de la factura que quedan atrás: el texto del recorte al 55 %
  /// sobre blanco, ya mezclado (sin opacidad).
  static const _faded = Color(0xFF8A8B8E);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      // Mínimo del diseño; si el recorte crece (letras largas), crece la
      // composición y el `FittedBox` de la tarjeta la encoge.
      constraints: const BoxConstraints(minWidth: 312, minHeight: 300),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 6,
            top: 16,
            child: _Shape(
              color: p.tint10,
              width: 300,
              height: 270,
              radius: 44,
              degrees: 4,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 272,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: p.primary),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: TutorialPalette.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Fecha límite: 30/11/2026',
                      style: TextStyle(fontSize: 12.5, color: _faded),
                    ),
                    const Text(
                      'Total a pagar: 245.000 \$',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _faded,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _HighlightedReminder(p, 'Recordarme antes del vencimiento'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: 272,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: TutorialPalette.cardShadow,
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.tint10,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: p.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active_outlined,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tienes un recordatorio en 2 días',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: TutorialPalette.onSurface,
                              ),
                            ),
                            Text(
                              'Pagar predial · 08:00',
                              style: TextStyle(
                                fontSize: 12,
                                color: TutorialPalette.cropMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 20, color: p.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 4,
            child: _Satellite(Icons.alarm, p.primary),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 3B · Mis recordatorios
// =============================================================================
class _MyReminders extends StatelessWidget {
  const _MyReminders(this.p);

  final TutorialPalette p;

  @override
  Widget build(BuildContext context) {
    Widget item(String title, String tax, String date, String chip) =>
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: TutorialPalette.panel,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: p.tint20,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  size: 19,
                  color: p.primary,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: TutorialPalette.onSurface,
                      ),
                    ),
                    Text(
                      tax,
                      style: const TextStyle(
                        fontSize: 11,
                        color: TutorialPalette.cropMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            date,
                            style: const TextStyle(
                              fontSize: 11,
                              color: TutorialPalette.cropMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: p.tint20,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            chip,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: p.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    return ConstrainedBox(
      // Mínimo del diseño; si el recorte crece (letras largas), crece la
      // composición y el `FittedBox` de la tarjeta la encoge.
      constraints: const BoxConstraints(minWidth: 312, minHeight: 310),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 10,
            top: 10,
            child: _Shape(
              color: p.tint10,
              width: 292,
              height: 290,
              radius: 44,
              degrees: -4,
            ),
          ),
          Container(
            width: 272,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: p.primary,
              borderRadius: BorderRadius.circular(18),
              boxShadow: TutorialPalette.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.event_note_outlined,
                          size: 22,
                          color: p.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Flexible(
                        child: Text(
                          'Mis recordatorios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      item(
                        'Pagar predial',
                        'Impuesto Predial Unificado',
                        '31/10/2026 · 08:00',
                        'en 10 días',
                      ),
                      const SizedBox(height: 8),
                      item(
                        'Pagar Industria y Comercio',
                        'Impuesto de Industria y Comercio',
                        '21/10/2027 · 08:00',
                        'en 365 días',
                      ),
                      const SizedBox(height: 12),
                      // Anillo de enfoque `tint20` de 3, separado 2.
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(color: p.tint20, width: 3),
                          borderRadius: BorderRadius.circular(19),
                        ),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: p.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_alert_outlined,
                                size: 19,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Crear recordatorio',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 4 · Trámites
// =============================================================================
class _Tramites extends StatelessWidget {
  const _Tramites(this.p, this.tramites);

  final TutorialPalette p;
  final List<InfoTramite> tramites;

  @override
  Widget build(BuildContext context) {
    final Widget grid;
    if (tramites.length == 1) {
      final t = tramites.single;
      grid = Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            _TramiteCircle(size: 100, tramite: t),
            const SizedBox(height: 8),
            Text(
              t.nombre,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 14,
                color: TutorialPalette.onSurface,
              ),
            ),
          ],
        ),
      );
    } else {
      grid = Wrap(
        alignment: WrapAlignment.center,
        runSpacing: 12,
        children: [
          for (final t in tramites)
            SizedBox(
              width: 88,
              child: Column(
                children: [
                  _TramiteCircle(size: 62, tramite: t),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 28,
                    child: Text(
                      t.nombre,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 14 / 11.5,
                        color: TutorialPalette.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return ConstrainedBox(
      // Mínimo del diseño; si el recorte crece (letras largas), crece la
      // composición y el `FittedBox` de la tarjeta la encoge.
      constraints: const BoxConstraints(minWidth: 312, minHeight: 300),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 14,
            top: 14,
            child: _Shape(color: p.tint10, width: 284, height: 272, radius: 48),
          ),
          Container(
            width: 284,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: TutorialPalette.cardShadow,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
              decoration: BoxDecoration(
                color: TutorialPalette.panel,
                borderRadius: BorderRadius.circular(14),
              ),
              child: grid,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 6A · Historial con «Recordarme el próximo pago»
// =============================================================================
class _HistoryInApp extends StatelessWidget {
  const _HistoryInApp(this.p, this.alcaldia);

  final TutorialPalette p;
  final String alcaldia;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      // Mínimo del diseño; si el recorte crece (letras largas), crece la
      // composición y el `FittedBox` de la tarjeta la encoge.
      constraints: const BoxConstraints(minWidth: 312, minHeight: 300),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 12,
            top: 18,
            child: _Shape(
              color: p.tint10,
              width: 288,
              height: 264,
              radius: 44,
              degrees: 5,
            ),
          ),
          Container(
            width: 272,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: TutorialPalette.panel,
              borderRadius: BorderRadius.circular(16),
              boxShadow: TutorialPalette.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Impuesto de Industria y Comercio',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: TutorialPalette.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(alcaldia, style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 10),
                          const _IconText(Icons.person_outline, 'María Pérez'),
                          const SizedBox(height: 4),
                          const _IconText(Icons.payments_outlined, '\$58.000'),
                          const SizedBox(height: 4),
                          const _IconText(
                            Icons.calendar_today_outlined,
                            '21/10/2026',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const _Status.approved(iconSize: 42, fontSize: 12),
                  ],
                ),
                const SizedBox(height: 12),
                // Separador gris suave, como el del Historial tras el arreglo.
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: TutorialPalette.dotOff,
                ),
                const SizedBox(height: 6),
                _HighlightedReminder(
                  p,
                  'Recordarme el próximo pago',
                  center: false,
                ),
              ],
            ),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: _Satellite(Icons.history, p.primary),
          ),
        ],
      ),
    );
  }
}

/// Estado de un pago del Historial (ícono + texto en la variante oscura).
class _Status extends StatelessWidget {
  const _Status.approved({required this.iconSize, required this.fontSize})
    : icon = Icons.check_circle,
      iconColor = TutorialPalette.successIcon,
      label = 'APROBADA',
      textColor = TutorialPalette.successText;

  const _Status.started({required this.iconSize, required this.fontSize})
    : icon = Icons.hourglass_empty,
      iconColor = TutorialPalette.pendingIcon,
      label = 'COMENZADA',
      textColor = TutorialPalette.pendingText;

  final IconData icon;
  final Color iconColor;
  final String label;
  final Color textColor;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: iconSize, color: iconColor),
      const SizedBox(height: 2),
      Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: .3,
          color: textColor,
        ),
      ),
    ],
  );
}

// =============================================================================
// 6B · Historial (solo portal)
// =============================================================================
class _HistoryPortal extends StatelessWidget {
  const _HistoryPortal(this.p, this.alcaldia);

  final TutorialPalette p;
  final String alcaldia;

  @override
  Widget build(BuildContext context) {
    Widget payment(String tax, String amount, _Status status) => Container(
      width: 268,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: TutorialPalette.panel,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 8),
            blurRadius: 22,
            color: Color(0x24001E32),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tax,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: TutorialPalette.onSurface,
                  ),
                ),
                Text(alcaldia, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                _IconText(
                  Icons.payments_outlined,
                  amount,
                  iconSize: 15,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          status,
        ],
      ),
    );

    return ConstrainedBox(
      // Mínimo del diseño; si el recorte crece (letras largas), crece la
      // composición y el `FittedBox` de la tarjeta la encoge.
      constraints: const BoxConstraints(minWidth: 312, minHeight: 300),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 12,
            top: 18,
            child: _Shape(
              color: p.tint10,
              width: 288,
              height: 264,
              radius: 44,
              degrees: -5,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              payment(
                'Impuesto Predial Unificado',
                '\$245.000',
                const _Status.approved(iconSize: 34, fontSize: 11),
              ),
              const SizedBox(height: 10),
              payment(
                'Impuesto de Industria y Comercio',
                '\$58.000',
                const _Status.started(iconSize: 34, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 7 · Cuenta
// =============================================================================
class _Account extends StatelessWidget {
  const _Account(this.p);

  final TutorialPalette p;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      // Mínimo del diseño; si el recorte crece (letras largas), crece la
      // composición y el `FittedBox` de la tarjeta la encoge.
      constraints: const BoxConstraints(minWidth: 280, minHeight: 260),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(color: p.tint10, shape: BoxShape.circle),
          ),
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: TutorialPalette.cardShadow,
            ),
            child: Icon(
              Icons.account_circle_outlined,
              size: 76,
              color: p.primary,
            ),
          ),
          Positioned(
            left: 14,
            top: 40,
            child: _Satellite(
              Icons.notifications_outlined,
              p.primary,
              size: 58,
            ),
          ),
          Positioned(
            right: 14,
            bottom: 36,
            child: _Satellite(Icons.history, p.primary, size: 58),
          ),
          Positioned(
            right: 30,
            top: 22,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock, size: 22, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
