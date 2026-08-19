import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Adorno de círculos de la esquina superior derecha. Port de la `Image` con
/// `R.drawable.circles` que el original repite en Home, Historial de pagos,
/// Cursos y Escenarios deportivos.
///
/// Se coloca dentro de un [Stack] y **no** intercepta toques. Cada preset
/// reproduce el `Modifier` del original: `align(TopEnd).size(...).rotate(...)
/// .offset(x, y)` con el `ColorFilter.tint(...)` correspondiente. En Compose el
/// tinte solo reemplaza el RGB, así que la opacidad final es la del asset
/// (0.145) multiplicada por la del color; el `ColorFilter.mode` de Flutter se
/// comporta igual, por eso los valores de alpha son los mismos del Kotlin.
class CirclesDecoration extends StatelessWidget {
  const CirclesDecoration._({
    required this.size,
    required this.color,
    required this.top,
    required this.right,
    required this.quarterTurns,
  });

  /// Variante de la Home (`MainScreen.kt`): 110 dp, sin rotar, desbordando por
  /// la derecha, tintada de blanco al 20 %.
  const CirclesDecoration.home()
    : this._(
        size: 110,
        color: const Color(0x33FFFFFF), // White.copy(alpha = 0.2f)
        top: -30,
        right: -35, // offset(x = 35.dp) sobre align(TopEnd)
        quarterTurns: 0,
      );

  /// Variante de Historial / Cursos / Escenarios: 120 dp, rotada 90°, metida
  /// 25 dp desde el borde derecho y tintada con el color del municipio al 70 %.
  /// El color se resuelve en [build] porque depende del tema.
  const CirclesDecoration.branded()
    : this._(
        size: 120,
        color: null,
        top: -30,
        right: 25, // offset(x = -25.dp) sobre align(TopEnd)
        quarterTurns: 1,
      );

  final double size;

  /// `null` = usar `colorScheme.primary` al 70 % (variante *branded*).
  final Color? color;
  final double top;
  final double right;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    final tint =
        color ?? Theme.of(context).colorScheme.primary.withValues(alpha: 0.7);

    return Positioned(
      top: top,
      right: right,
      child: IgnorePointer(
        child: RotatedBox(
          quarterTurns: quarterTurns,
          child: SvgPicture.asset(
            'assets/images/circles.svg',
            width: size,
            height: size,
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
