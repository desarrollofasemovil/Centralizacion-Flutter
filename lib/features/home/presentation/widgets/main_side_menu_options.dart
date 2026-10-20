import 'package:flutter/material.dart';
import '../../../../core/models/user_dto.dart';

class MainSideMenuOptions extends StatelessWidget {
  final UserDTO? user;
  final VoidCallback onLoginSuccess;
  final VoidCallback goToSettingsUser;
  final VoidCallback goToReminders;
  final VoidCallback onTermsClick;
  final VoidCallback goToHelp;
  final VoidCallback onLogoutSuccess;

  const MainSideMenuOptions({
    super.key,
    required this.user,
    required this.onLoginSuccess,
    required this.goToSettingsUser,
    required this.goToReminders,
    required this.onTermsClick,
    required this.goToHelp,
    required this.onLogoutSuccess,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF181E31); // Navy brand primary
    const onColor = Colors.white;

    final isLoggedIn = user != null && user!.loginStatus;

    return Container(
      color: primaryColor,
      child: Column(
        children: [
          const SizedBox(height: 50),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                if (isLoggedIn)
                  _MenuItem(
                    text: "Hola, ${user!.firstName} ${user!.lastName}",
                    icon: Icons.person_outline,
                    color: onColor,
                    onTap: () {},
                  )
                else
                  _MenuItem(
                    text: "Iniciar sesión",
                    icon: Icons.login,
                    color: onColor,
                    onTap: onLoginSuccess,
                  ),
                const SizedBox(height: 10),
                _MenuItem(
                  text: "Mis recordatorios",
                  icon: Icons.notifications_active_outlined,
                  color: onColor,
                  onTap: goToReminders,
                ),
                const SizedBox(height: 10),
                _MenuItem(
                  text: "Configuraciones",
                  icon: Icons.settings_outlined,
                  color: onColor,
                  onTap: goToSettingsUser,
                ),
                const SizedBox(height: 10),
                _MenuItem(
                  text: "Términos y condiciones",
                  icon: Icons.content_paste,
                  color: onColor,
                  onTap: onTermsClick,
                ),
                const SizedBox(height: 10),
                _MenuItem(
                  text: "Ayuda y Soporte",
                  icon: Icons.help_outline,
                  color: onColor,
                  onTap: goToHelp,
                ),
              ],
            ),
          ),
          if (isLoggedIn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              child: _MenuItem(
                text: "Cerrar sesión",
                icon: Icons.logout,
                color: onColor,
                onTap: onLogoutSuccess,
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.text,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
