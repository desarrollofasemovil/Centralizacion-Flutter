import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/user_settings_notifier.dart';

/// Formulario de cambio de contraseña (autenticado). Port de
/// `ChangePasswordContent` en `UserSettingsScreen.kt`.
class ChangePasswordSheet extends ConsumerStatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  ConsumerState<ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<ChangePasswordSheet> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.read(userSettingsNotifierProvider.notifier);
    final form = ref.watch(
      userSettingsNotifierProvider.select((s) => s.passwordForm),
    );

    // Cierra la hoja al confirmarse el cambio de contraseña.
    ref.listen<bool>(
      userSettingsNotifierProvider.select((s) => s.passwordChanged),
      (prev, next) {
        if (next) {
          notifier.consumePasswordChanged();
          Navigator.of(context).pop();
        }
      },
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cambiar Contraseña',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _PasswordField(
            controller: _current,
            label: 'Contraseña actual',
            obscure: !_showCurrent,
            errorText: form.currentError,
            onToggle: () => setState(() => _showCurrent = !_showCurrent),
            onChanged: (v) => notifier.onPasswordInput('current', v),
          ),
          const SizedBox(height: 12),
          _PasswordField(
            controller: _new,
            label: 'Nueva contraseña',
            obscure: !_showNew,
            errorText: form.newError,
            onToggle: () => setState(() => _showNew = !_showNew),
            onChanged: (v) => notifier.onPasswordInput('new', v),
          ),
          const SizedBox(height: 12),
          _PasswordField(
            controller: _confirm,
            label: 'Confirmar contraseña',
            obscure: !_showConfirm,
            errorText: form.confirmError,
            onToggle: () => setState(() => _showConfirm = !_showConfirm),
            onChanged: (v) => notifier.onPasswordInput('confirm', v),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: form.isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: (form.isValid && !form.isSaving)
                      ? notifier.submitChangePassword
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: form.isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : const Text('Actualizar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    required this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          tooltip: obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
        ),
      ),
    );
  }
}
