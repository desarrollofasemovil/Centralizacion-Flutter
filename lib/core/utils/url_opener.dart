import 'dart:ui' show Color;

import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as custom_tabs;
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Puerto de `utils/ChromeTabs.kt` (`abrirURL`).
///
/// Abre la URL en un navegador in-app del sistema: Chrome Custom Tabs en
/// Android (igual que el original) y SFSafariViewController en iOS. Este es el
/// canal indicado para la pasarela PSE: barra de URL/candado visibles, sesión y
/// autofill del navegador real, y los redirects a apps bancarias funcionan
/// (un WebView embebido suele ser bloqueado por los bancos).
///
/// [toolbarColor] tiñe el header de la Custom Tab / barra del Safari VC,
/// equivalente al `builder.setToolbarColor(toolbarColor)` del original
/// (los llamadores pasan el color primario del municipio).
///
/// Si no hay navegador in-app disponible cae al navegador externo.
Future<bool> abrirUrl(String? url, {Color? toolbarColor}) async {
  if (url == null || url.trim().isEmpty) return false;

  final normalized = url.trim();
  final parsed = Uri.tryParse(normalized);
  if (parsed == null) return false;
  // Igual que el original: si no trae esquema, se antepone https://
  final uri = parsed.hasScheme ? parsed : Uri.parse('https://$normalized');

  // Custom Tabs / Safari VC solo aplican a http(s).
  if (uri.scheme == 'http' || uri.scheme == 'https') {
    try {
      await custom_tabs.launchUrl(
        uri,
        customTabsOptions: custom_tabs.CustomTabsOptions(
          colorSchemes: custom_tabs.CustomTabsColorSchemes.defaults(
            toolbarColor: toolbarColor,
          ),
          urlBarHidingEnabled: true,
          showTitle: true,
        ),
        safariVCOptions: custom_tabs.SafariViewControllerOptions(
          preferredBarTintColor: toolbarColor,
          barCollapsingEnabled: true,
        ),
      );
      return true;
    } catch (_) {
      // Sin navegador compatible con Custom Tabs: probamos el externo.
    }
  }

  try {
    return await url_launcher.launchUrl(
      uri,
      mode: url_launcher.LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}
