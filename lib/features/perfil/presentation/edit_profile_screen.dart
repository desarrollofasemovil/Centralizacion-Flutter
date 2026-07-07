import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/edit_profile_notifier.dart';

/// Pantalla Editar Perfil. Port de `EditProfileScreen.kt`.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _firstName;
  late final TextEditingController _middleName;
  late final TextEditingController _lastName;
  late final TextEditingController _secondLastName;
  late final TextEditingController _phone;
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();
    final s = ref.read(editProfileNotifierProvider);
    _firstName = TextEditingController(text: s.firstName);
    _middleName = TextEditingController(text: s.middleName);
    _lastName = TextEditingController(text: s.lastName);
    _secondLastName = TextEditingController(text: s.secondLastName);
    _phone = TextEditingController(text: s.phoneNumber);
    _address = TextEditingController(text: s.address);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _secondLastName.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.read(editProfileNotifierProvider.notifier);
    final state = ref.watch(editProfileNotifierProvider);

    ref.listen<bool?>(
      editProfileNotifierProvider.select((s) => s.updateResult),
      (prev, next) {
        if (next == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado correctamente')),
          );
          context.pop();
        } else if (next == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(state.errorMessage ?? 'Error al actualizar perfil')),
          );
          notifier.resetUpdateStatus();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: _CircleBackButton(onTap: () => context.pop()),
        ),
        title: Text('Editar Perfil',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.onSurface)),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Datos Personales',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.onSurface)),
              const SizedBox(height: 12),
              _field(
                controller: _firstName,
                label: 'Primer Nombre',
                onChanged: (v) => notifier.onFieldChange('firstName', v),
              ),
              const SizedBox(height: 12),
              _field(
                controller: _middleName,
                label: 'Segundo Nombre',
                onChanged: (v) => notifier.onFieldChange('middleName', v),
              ),
              const SizedBox(height: 12),
              _field(
                controller: _lastName,
                label: 'Primer Apellido',
                onChanged: (v) => notifier.onFieldChange('lastName', v),
              ),
              const SizedBox(height: 12),
              _field(
                controller: _secondLastName,
                label: 'Segundo Apellido',
                onChanged: (v) => notifier.onFieldChange('secondLastName', v),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text('Contacto y Ubicación',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.onSurface)),
              const SizedBox(height: 12),
              _field(
                controller: _phone,
                label: 'Teléfono',
                keyboardType: TextInputType.phone,
                onChanged: (v) => notifier.onFieldChange('phoneNumber', v),
              ),
              const SizedBox(height: 12),
              _field(
                controller: _address,
                label: 'Dirección',
                onChanged: (v) => notifier.onFieldChange('address', v),
              ),
              const SizedBox(height: 12),
              // Email y documento: solo lectura (por seguridad, igual al original).
              _readOnlyField(label: 'Correo Electrónico', value: state.email),
              const SizedBox(height: 12),
              _readOnlyField(label: 'Documento', value: state.nationalId),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: state.isLoading ? null : notifier.updateProfile,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: state.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                                theme.colorScheme.onPrimary),
                          ),
                        )
                      : Text('Guardar', style: theme.textTheme.titleMedium),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _readOnlyField({required String label, required String value}) {
    return TextField(
      controller: TextEditingController(text: value),
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap,
        child: SizedBox(
          width: 35,
          height: 35,
          child: Icon(Icons.arrow_back_ios_new,
              size: 18, color: theme.colorScheme.onPrimary),
        ),
      ),
    );
  }
}
