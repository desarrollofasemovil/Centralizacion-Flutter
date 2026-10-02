import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/services/api_providers.dart';
import '../../../../core/models/user_dto.dart';
import '../../../../core/models/document_type_dto.dart';
import '../../../../core/models/people_invitated.dart';
import '../../../../core/storage/user_preferences.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/main_viewmodel.dart';
import '../../../../core/widgets/policy_checkboxes.dart';

class ModalForm extends ConsumerStatefulWidget {
  final ModalFormMode mode;
  final String dataPolicyUrl;
  final String privacyPolicyUrl;
  final VoidCallback onDismiss;
  final ValueChanged<UserDTO> onConfirm;

  const ModalForm({
    super.key,
    required this.mode,
    required this.dataPolicyUrl,
    required this.privacyPolicyUrl,
    required this.onDismiss,
    required this.onConfirm,
  });

  @override
  ConsumerState<ModalForm> createState() => _ModalFormState();
}

class _ModalFormState extends ConsumerState<ModalForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _identificacionController;
  late final TextEditingController _nombresApellidosController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _correoController;

  bool _aceptaPoliticas = false;
  bool _aceptaCondiciones = false;
  bool _isLoading = false;
  bool _isEditable = true;

  @override
  void initState() {
    super.initState();
    _identificacionController = TextEditingController();
    _nombresApellidosController = TextEditingController();
    _telefonoController = TextEditingController();
    _correoController = TextEditingController();

    _initForm();
  }

  void _initForm() {
    final loggedInUser = ref.read(sessionProvider);
    final prefs = ref.read(userPreferencesProvider);
    final guestJson = prefs.getGuestUserDataJson();

    UserDTO? guestUser;
    if (guestJson != null) {
      try {
        guestUser = UserDTO.fromJson(
          Map<String, dynamic>.from(
            Uri.splitQueryString(
              guestJson,
            ), // O JSON decode normal si es JSON string
          ),
        );
      } catch (_) {
        // En caso de parse error, fallback
      }
    }

    final user = loggedInUser ?? guestUser;
    if (user != null) {
      _identificacionController.text = user.nationalId;
      _nombresApellidosController.text = "${user.firstName} ${user.lastName}"
          .trim();
      _telefonoController.text = user.phoneNumber;
      _correoController.text = user.email;
    }

    setState(() {
      _isEditable = loggedInUser == null;
    });
  }

  @override
  void dispose() {
    _identificacionController.dispose();
    _nombresApellidosController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_aceptaPoliticas || !_aceptaCondiciones) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar las políticas y condiciones'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final body = PeopleInvitated(
        documentationDni: _identificacionController.text.trim(),
        completeName: _nombresApellidosController.text.trim(),
        phoneNumber: _telefonoController.text.trim(),
        email: _correoController.text.trim(),
      );

      final api = ref.read(peopleInvitatedApiServiceProvider);
      final response = await api.createPeopleInvitated(body);

      if (response.booleanStatus) {
        // Crear un DTO guest dummy para pasar a la confirmación
        final nameParts = _nombresApellidosController.text.trim().split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts.first : '';
        final lastName = nameParts.length > 1
            ? nameParts.skip(1).join(' ')
            : '';

        final guestUser = UserDTO(
          id: 0,
          address: "",
          documentType: DocumentTypeDTO(id: 0, name: ""),
          documentTypeId: 0,
          email: _correoController.text.trim(),
          firstName: firstName,
          lastName: lastName,
          loginStatus: false,
          nationalId: _identificacionController.text.trim(),
          password: "",
          phoneNumber: _telefonoController.text.trim(),
          birthDate: "",
        );

        widget.onConfirm(guestUser);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              response.sentencesError.isNotEmpty
                  ? response.sentencesError
                  : 'Error al registrar información.',
            ),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  "Por favor, ingrese los siguientes datos y presione el botón continuar.",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _identificacionController,
                  readOnly: !_isEditable,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: "Número de Identificación",
                    labelStyle: theme.textTheme.bodySmall,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty ||
                        value.trim().length < 4) {
                      return "Ingrese una identificación válida (mínimo 4 caracteres)";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nombresApellidosController,
                  readOnly: !_isEditable,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: "Nombres y apellidos",
                    labelStyle: theme.textTheme.bodySmall,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Ingrese su nombre";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefonoController,
                  readOnly: !_isEditable,
                  style: theme.textTheme.bodyMedium,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Número de teléfono",
                    labelStyle: theme.textTheme.bodySmall,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty ||
                        value.trim().length < 10) {
                      return "El teléfono debe tener al menos 10 caracteres";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _correoController,
                  readOnly: !_isEditable,
                  style: theme.textTheme.bodyMedium,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Correo electrónico",
                    labelStyle: theme.textTheme.bodySmall,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Ingrese su correo electrónico";
                    }
                    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return "El correo no es válido";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PolicyCheckboxes(
                  dataPolicyChecked: _aceptaPoliticas,
                  onDataPolicyChange: (val) =>
                      setState(() => _aceptaPoliticas = val),
                  privacyPolicyChecked: _aceptaCondiciones,
                  onPrivacyPolicyChange: (val) =>
                      setState(() => _aceptaCondiciones = val),
                  dataPolicyUrl: widget.dataPolicyUrl,
                  privacyPolicyUrl: widget.privacyPolicyUrl,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Continuar",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
