import 'package:flutter/material.dart';

class MainTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuClicked;
  final VoidCallback onBackClicked;

  const MainTopBar({
    super.key,
    required this.onMenuClicked,
    required this.onBackClicked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      color: primaryColor,
      padding: const EdgeInsets.only(
        top: 35,
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
              child: GestureDetector(
                onTap: onBackClicked,
                child: Container(
                  width: 35,
                  height: 35,
                  margin: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: primaryColor,
                    size: 18, // 23dp in Compose ~ 18 in Flutter is equivalent
                  ),
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
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(90);
}
