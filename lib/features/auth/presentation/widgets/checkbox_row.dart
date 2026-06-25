import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Checkbox con texto y enlace — puerto de `CheckboxRow`: checkbox + texto donde
/// [linkText] es un enlace subrayado que abre [url] en el navegador. Toda la fila
/// es clickable para alternar el check.
class CheckboxRow extends StatelessWidget {
  const CheckboxRow({
    super.key,
    required this.text,
    required this.linkText,
    required this.url,
    required this.checked,
    required this.onChanged,
  });

  final String text;
  final String linkText;
  final String url;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final contentColor = scheme.onSurface.withValues(alpha: 0.8);
    final linkColor = scheme.primary;
    final baseStyle = Theme.of(context)
        .textTheme
        .labelMedium
        ?.copyWith(color: contentColor);

    final start = text.indexOf(linkText);
    final spans = <InlineSpan>[];
    if (start == -1) {
      spans.add(TextSpan(text: text));
    } else {
      spans.add(TextSpan(text: text.substring(0, start)));
      spans.add(
        TextSpan(
          text: linkText,
          style: TextStyle(
            color: linkColor,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final uri = Uri.tryParse(url);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
        ),
      );
      spans.add(TextSpan(text: text.substring(start + linkText.length)));
    }

    return InkWell(
      onTap: () => onChanged(!checked),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: checked,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: scheme.primary,
            checkColor: scheme.onPrimary,
          ),
          Expanded(
            child: Text.rich(TextSpan(style: baseStyle, children: spans)),
          ),
        ],
      ),
    );
  }
}
