import 'package:flutter/material.dart';

import '../../../../core/widgets/app_back_button.dart';

/// Barra superior de la Home. Va dentro del `body` (no como `appBar`) para que el
/// área de color primario llegue al borde superior y `SafeArea` inserte el
/// contenido bajo la barra de estado en Android y bajo el notch / Dynamic Island
/// en iPhone (el original fijaba `top = 35.dp`, válido solo en Android).
class MainTopBar extends StatelessWidget {
  final VoidCallback onMenuClicked;
  final VoidCallback onBackClicked;

  const MainTopBar({
    super.key,
    required this.onMenuClicked,
    required this.onBackClicked,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: AppBackButton(
                      onPressed: onBackClicked,
                      style: AppBackButtonStyle.light,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: onMenuClicked,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
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
