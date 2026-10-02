import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/venues_notifier.dart';

/// Hoja de reserva de un escenario. Port de `ReservationForm.kt`.
class ReservationForm extends ConsumerStatefulWidget {
  const ReservationForm({super.key, required this.param});

  final VenuesParam param;

  @override
  ConsumerState<ReservationForm> createState() => _ReservationFormState();
}

class _ReservationFormState extends ConsumerState<ReservationForm> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _document;
  late final TextEditingController _email;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final f = ref.read(venuesNotifierProvider(widget.param)).formState;
    _firstName = TextEditingController(text: f.firstName);
    _lastName = TextEditingController(text: f.lastName);
    _document = TextEditingController(text: f.documentNumber);
    _email = TextEditingController(text: f.email);
    _phone = TextEditingController(text: f.phone);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _document.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickDate(VenuesNotifier notifier) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      String two(int n) => n.toString().padLeft(2, '0');
      notifier.onDateChange(
        '${picked.year}-${two(picked.month)}-${two(picked.day)}',
      );
    }
  }

  Future<void> _pickTime(VenuesNotifier notifier) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      String two(int n) => n.toString().padLeft(2, '0');
      notifier.onTimeChange('${two(picked.hour)}:${two(picked.minute)}:00');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.read(venuesNotifierProvider(widget.param).notifier);
    final state = ref.watch(venuesNotifierProvider(widget.param));
    final form = state.formState;
    final title = state.selectedVenue?.title ?? '';
    final dateTimeError = form.dateError ?? form.timeError;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 8),
            _field(
              controller: _firstName,
              label: 'Nombre',
              formatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ ]'),
                ),
              ],
              onChanged: notifier.onFirstNameChange,
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
              onChanged: notifier.onLastNameChange,
              error: form.lastNameError,
            ),
            _field(
              controller: _document,
              label: 'Número de Documento',
              readOnly: true,
              onChanged: (_) {},
              error: form.documentNumberError,
            ),
            _field(
              controller: _email,
              label: 'Correo Electrónico',
              keyboardType: TextInputType.emailAddress,
              onChanged: notifier.onEmailChange,
              error: form.emailError,
            ),
            _field(
              controller: _phone,
              label: 'Número de Contacto',
              keyboardType: TextInputType.phone,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: notifier.onPhoneChange,
              error: form.phoneError,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(notifier),
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: Text(form.date.isEmpty ? 'Fecha' : form.date),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(notifier),
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(form.time.isEmpty ? 'Hora' : form.time),
                  ),
                ),
              ],
            ),
            if (dateTimeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 16),
                child: Text(
                  dateTimeError,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () => notifier.submitReservation(),
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Reservar'),
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
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        readOnly: readOnly,
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
