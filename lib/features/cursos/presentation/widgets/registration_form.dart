import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/courses_notifier.dart';

/// Hoja de inscripción a un curso. Port de `RegistrationForm.kt`.
class RegistrationForm extends ConsumerStatefulWidget {
  const RegistrationForm({super.key, required this.param});

  final CoursesParam param;

  @override
  ConsumerState<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends ConsumerState<RegistrationForm> {
  late final TextEditingController _document;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _age;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    final form = ref.read(coursesNotifierProvider(widget.param)).formState;
    _document = TextEditingController(text: form.documentNumber);
    _firstName = TextEditingController(text: form.firstName);
    _lastName = TextEditingController(text: form.lastName);
    _age = TextEditingController(text: form.age);
    _email = TextEditingController(text: form.email);
  }

  @override
  void dispose() {
    _document.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _age.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.read(coursesNotifierProvider(widget.param).notifier);
    final state = ref.watch(coursesNotifierProvider(widget.param));
    final form = state.formState;
    final title = state.selectedCourse?.title ?? '';

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Inscripción a: $title',
              textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _field(
              controller: _document,
              label: 'Documento',
              keyboardType: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: notifier.onDocumentNumberChanged,
              error: form.documentNumberError,
            ),
            _field(
              controller: _firstName,
              label: 'Nombre',
              formatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ ]'),
                ),
              ],
              onChanged: notifier.onFirstNameChanged,
              error: form.firstNameError,
            ),
            _field(
              controller: _lastName,
              label: 'Apellido',
              formatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ ]'),
                ),
              ],
              onChanged: notifier.onLastNameChanged,
              error: form.lastNameError,
            ),
            _field(
              controller: _age,
              label: 'Edad',
              keyboardType: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: notifier.onAgeChanged,
              error: form.ageError,
            ),
            _field(
              controller: _email,
              label: 'Correo electrónico',
              keyboardType: TextInputType.emailAddress,
              onChanged: notifier.onEmailChanged,
              error: form.emailError,
            ),
            if (form.phoneError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  form.phoneError!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: state.isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: state.isLoading
                      ? null
                      : () => notifier.submitRegistration(),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Enviar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
    String? error,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
