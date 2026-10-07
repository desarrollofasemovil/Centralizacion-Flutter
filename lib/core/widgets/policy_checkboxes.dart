import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../utils/url_opener.dart';

class PolicyCheckboxes extends StatelessWidget {
  final bool dataPolicyChecked;
  final ValueChanged<bool> onDataPolicyChange;
  final bool privacyPolicyChecked;
  final ValueChanged<bool> onPrivacyPolicyChange;
  final String dataPolicyUrl;
  final String privacyPolicyUrl;

  const PolicyCheckboxes({
    super.key,
    required this.dataPolicyChecked,
    required this.onDataPolicyChange,
    required this.privacyPolicyChecked,
    required this.onPrivacyPolicyChange,
    required this.dataPolicyUrl,
    required this.privacyPolicyUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PolicyCheckboxRow(
          text:
              "Acepto y autorizo la política de tratamiento de datos personales",
          linkText: "tratamiento de datos personales",
          url: dataPolicyUrl,
          checked: dataPolicyChecked,
          onChanged: onDataPolicyChange,
        ),
        const SizedBox(height: 8),
        PolicyCheckboxRow(
          text: "Acepto las condiciones de uso y las políticas de privacidad",
          linkText: "políticas de privacidad",
          url: privacyPolicyUrl,
          checked: privacyPolicyChecked,
          onChanged: onPrivacyPolicyChange,
        ),
      ],
    );
  }
}

class PolicyCheckboxRow extends StatelessWidget {
  final String text;
  final String linkText;
  final String url;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const PolicyCheckboxRow({
    super.key,
    required this.text,
    required this.linkText,
    required this.url,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkIndex = text.indexOf(linkText);

    final TextSpan span;
    if (linkIndex != -1) {
      final before = text.substring(0, linkIndex);
      final after = text.substring(linkIndex + linkText.length);
      span = TextSpan(
        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: linkText,
            style: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => abrirUrl(
                url,
                toolbarColor: theme.colorScheme.primary,
              ),
          ),
          TextSpan(text: after),
        ],
      );
    } else {
      span = TextSpan(
        text: text,
        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: checked,
          onChanged: (val) => onChanged(val ?? false),
          activeColor: theme.colorScheme.primary,
        ),
        Expanded(child: RichText(text: span)),
      ],
    );
  }
}
