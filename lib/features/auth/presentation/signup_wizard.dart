import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/services/api_providers.dart';
import '../../../core/models/create_user_dto.dart';
import '../../../core/models/document_type_dto.dart';
import '../../../core/models/municipalities_dto.dart';
import '../../../core/theme/app_colors.dart';
import '../application/auth_providers.dart';
import '../application/registration_draft.dart';
import '../application/signup_providers.dart';
import '../data/google_auth_service.dart';
import 'widgets/checkbox_row.dart';
import 'widgets/date_picker_field.dart';
import 'widgets/register_password_field.dart';
import 'widgets/register_text_field.dart';
import 'widgets/registration_success_overlay.dart';
import 'widgets/searchable_dropdown.dart';
import 'widgets/signup_step_row.dart';

/// Wizard de registro de 3 pasos — puerto de `SignUpStep1/2/3Screen.kt`.
/// Soporta prellenado desde un borrador de Google ([RegistrationDraft]) y,
/// para ese caso, crea el usuario de Firebase **solo** al finalizar el registro
/// en backend (fix de usuarios fantasma).
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  int _currentStep = 0;

  final _formStep1 = GlobalKey<FormState>();
  final _formStep2 = GlobalKey<FormState>();
  final _formStep3 = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _secondLastName = TextEditingController();
  final _docTypeQuery = TextEditingController();
  final _nationalId = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _phone = TextEditingController();
  final _municipalityQuery = TextEditingController();
  final _address = TextEditingController();

  DocumentTypeDTO? _selectedDocType;
  MunicipalitiesDTO? _selectedMunicipality;
  DateTime? _birthDate;
  bool _acceptedPrivacy = false;
  bool _acceptedTerms = false;

  String? _docTypeError;
  String? _municipalityError;
  String? _termsError;

  bool _isLoading = false;
  bool _showSuccessOverlay = false;
  bool _fromGoogle = false;
  bool _registrationHadSession = false;
  RegistrationDraft? _draft;

  @override
  void initState() {
    super.initState();
    // Prellenado desde Google (si hay borrador).
    _draft = ref.read(registrationDraftProvider);
    if (_draft != null) {
      _fromGoogle = _draft!.isFromGoogle;
      _firstName.text = _draft!.firstName;
      _lastName.text = _draft!.lastName;
      _email.text = _draft!.email;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _middleName,
      _lastName,
      _secondLastName,
      _docTypeQuery,
      _nationalId,
      _email,
      _password,
      _confirmPassword,
      _phone,
      _municipalityQuery,
      _address,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Formato que espera el backend para `DateOnly`: YYYY-MM-DD.
  String _apiDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      ref.read(registrationDraftProvider.notifier).state = null;
      if (context.canPop()) {
        context.pop();
      }
    }
  }

  void _next() {
    if (_currentStep == 0) {
      if (_formStep1.currentState!.validate()) {
        setState(() => _currentStep = 1);
      }
    } else if (_currentStep == 1) {
      setState(() {
        _docTypeError = _selectedDocType == null ? 'Selecciona un tipo' : null;
      });
      final ok = _formStep2.currentState!.validate() & (_docTypeError == null);
      if (ok) setState(() => _currentStep = 2);
    }
  }

  Future<void> _finish() async {
    setState(() {
      _termsError = (!_acceptedPrivacy || !_acceptedTerms)
          ? 'Debes aceptar las políticas y condiciones.'
          : null;
    });
    final formOk = _formStep3.currentState!.validate();
    if (!formOk || _termsError != null) return;

    setState(() => _isLoading = true);

    final payload = CreateUserDTO(
      firstName: _firstName.text.trim(),
      middleName:
          _middleName.text.trim().isNotEmpty ? _middleName.text.trim() : null,
      lastName: _lastName.text.trim(),
      secondLastName: _secondLastName.text.trim().isNotEmpty
          ? _secondLastName.text.trim()
          : null,
      documentTypeId: _selectedDocType?.id ?? 0,
      nationalId: _nationalId.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      address: _address.text.trim(),
      phoneNumber: _phone.text.trim(),
      // El backend espera DateOnly (YYYY-MM-DD), no un datetime ISO.
      birthDate: _birthDate == null ? null : _apiDate(_birthDate!),
      // loginStatus es Int32 no-nullable en el backend (no acepta null).
      loginStatus: 0,
      fixedMunicipality: _selectedMunicipality?.id ?? 0,
      lastMunicipality: _selectedMunicipality?.id ?? 0,
    );

    try {
      final api = ref.read(authApiServiceProvider);
      final res = await api.createUser(payload);
      if (!res.booleanStatus) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showError(res.sentencesError.isNotEmpty
            ? res.sentencesError
            : 'No se pudo completar el registro.');
        return;
      }

      // Registro OK en backend → el usuario queda logueado (igual que el base).
      _registrationHadSession = false;
      if (_fromGoogle && _draft != null) {
        // Google: recién ahora creamos el usuario Firebase (fix de fantasmas)
        // e iniciamos sesión con sus datos del backend.
        await ref.read(googleAuthServiceProvider).completeFirebaseSignIn(
              idToken: _draft!.googleIdToken,
              accessToken: _draft!.googleAccessToken,
            );
        final user = await api.getUserByEmail(_email.text.trim());
        if (user != null) {
          await ref.read(sessionProvider.notifier).setSession(user);
          _registrationHadSession = true;
        }
      } else {
        // Email/clave: auto-login con las credenciales recién registradas.
        final loginRes = await ref
            .read(sessionProvider.notifier)
            .login(_email.text.trim(), _password.text);
        _registrationHadSession = loginRes.success;
      }
      ref.read(registrationDraftProvider.notifier).state = null;

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _showSuccessOverlay = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('No se pudo establecer conexión con el servidor.');
    }
  }

  void _onOverlayFinished() {
    if (!_registrationHadSession) {
      // Sin sesión → volver al home y reabrir el sheet de login (flag del base).
      ref.read(registrationSuccessProvider.notifier).state = true;
    }
    if (context.canPop()) {
      context.pop();
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aviso'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final scheme = base.colorScheme;
    final title = _fromGoogle ? 'Completar registro' : 'Registrarse';

    // El registro usa un acento fijo (#5856D6) en TODA la vista —números de
    // paso, bordes de campos, back button, etc.— igual que el proyecto base, no
    // el primarycolor. Se inyecta sobreescribiendo `primary` para este subárbol.
    return Theme(
      data: base.copyWith(
        colorScheme: scheme.copyWith(
          primary: AppColors.registerAccent,
          onPrimary: Colors.white,
        ),
      ),
      child: Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // TopBar (back + título)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 30, 10, 10),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SignUpBackButton(onPressed: _back),
                      ),
                      Text(title,
                          style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        SignUpStepRow(activeStep: _currentStep + 1),
                        const SizedBox(height: 12),
                        Text(
                          'Los campos con (*) son obligatorios.',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: AppColors.registerAccent
                                    .withValues(alpha: 0.8),
                              ),
                        ),
                        const SizedBox(height: 8),
                        IndexedStack(
                          index: _currentStep,
                          children: [
                            _buildStep1(),
                            _buildStep2(),
                            _buildStep3(),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildButtons(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            RegistrationSuccessOverlay(
              visible: _showSuccessOverlay,
              title: '¡Registro exitoso!',
              subtitle: _registrationHadSession
                  ? 'Bienvenido. Preparando tu sesión...'
                  : 'Tu cuenta fue creada. Redirigiendo...',
              onFinished: _onOverlayFinished,
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RegisterTextField(
            controller: _firstName,
            label: 'Primer Nombre*',
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          RegisterTextField(
            controller: _middleName,
            label: 'Segundo Nombre',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          RegisterTextField(
            controller: _lastName,
            label: 'Primer Apellido*',
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          RegisterTextField(
            controller: _secondLastName,
            label: 'Segundo Apellido',
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    final docTypesAsync = ref.watch(documentTypesProvider);
    final docTypes = docTypesAsync.maybeWhen(
      data: (d) => d,
      orElse: () => const <DocumentTypeDTO>[],
    );
    final isPassport = _selectedDocType?.name == 'Pasaporte';

    return Form(
      key: _formStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchableDropdown<DocumentTypeDTO>(
            controller: _docTypeQuery,
            items: docTypes,
            itemLabel: (d) => d.name,
            label: 'Tipo de documento*',
            errorText: _docTypeError,
            onSelected: (d) => setState(() {
              _selectedDocType = d;
              _docTypeError = null;
            }),
          ),
          const SizedBox(height: 12),
          RegisterTextField(
            controller: _nationalId,
            label: 'Número de documento*',
            keyboardType:
                isPassport ? TextInputType.text : TextInputType.number,
            inputFormatters:
                isPassport ? null : [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          RegisterTextField(
            controller: _email,
            label: 'Correo electrónico*',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Requerido';
              final re = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
              return re.hasMatch(v.trim()) ? null : 'Correo inválido';
            },
          ),
          const SizedBox(height: 12),
          RegisterPasswordField(
            controller: _password,
            label: 'Contraseña*',
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
          ),
          const SizedBox(height: 12),
          RegisterPasswordField(
            controller: _confirmPassword,
            label: 'Repetir contraseña*',
            textInputAction: TextInputAction.done,
            validator: (v) =>
                v != _password.text ? 'Las contraseñas no coinciden' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final municipalitiesAsync = ref.watch(allMunicipalitiesProvider);
    final municipalities = municipalitiesAsync.maybeWhen(
      data: (m) => m,
      orElse: () => const <MunicipalitiesDTO>[],
    );

    return Form(
      key: _formStep3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RegisterTextField(
            controller: _phone,
            label: 'Teléfono*',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          DatePickerField(
            value: _birthDate == null ? '' : _formatDate(_birthDate!),
            label: 'Fecha de nacimiento (DD/MM/AAAA)',
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _birthDate = picked);
            },
          ),
          const SizedBox(height: 12),
          SearchableDropdown<MunicipalitiesDTO>(
            controller: _municipalityQuery,
            items: municipalities,
            itemLabel: (m) => m.name,
            label: 'Municipio de residencia',
            errorText: _municipalityError,
            showLeadingSearch: true,
            onSelected: (m) => setState(() {
              _selectedMunicipality = m;
              _municipalityError = null;
            }),
          ),
          const SizedBox(height: 12),
          RegisterTextField(
            controller: _address,
            label: 'Dirección',
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 8),
          CheckboxRow(
            text: 'Acepto las políticas de tratamiento de datos',
            linkText: 'políticas de tratamiento de datos',
            url: 'https://www.1cero1.com/tratamientos.html',
            checked: _acceptedPrivacy,
            onChanged: (v) => setState(() => _acceptedPrivacy = v),
          ),
          CheckboxRow(
            text: 'Acepto las condiciones de uso',
            linkText: 'condiciones de uso',
            url: 'https://www.1cero1.com/tratamientos.html',
            checked: _acceptedTerms,
            onChanged: (v) => setState(() => _acceptedTerms = v),
          ),
          if (_termsError != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(
                _termsError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: IndexedStack(
                  index: _currentStep,
                  children: [
                    // Step 1: Personal Info
                    Form(
                      key: _formKeyStep1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Datos Personales',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'Primer Nombre',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _middleNameController,
                            decoration: const InputDecoration(
                              labelText: 'Segundo Nombre (Opcional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Primer Apellido',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _secondLastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Segundo Apellido (Opcional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<DocumentTypeDTO>(
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Documento',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: _selectedDocType,
                            items: _docTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedDocType = val;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nationalIdController,
                            decoration: const InputDecoration(
                              labelText: 'Número de Documento',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: const Icon(Icons.calendar_month),
                            label: Text(
                              _birthDate == null
                                  ? 'Fecha de Nacimiento'
                                  : 'F. Nac: ${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime(2000),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _birthDate = picked;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    // Step 2: Contact Info
                    Form(
                      key: _formKeyStep2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Datos de Contacto',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo Electrónico',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Celular / Teléfono',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Dirección de Residencia',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                        ],
                      ),
                    ),
                    // Step 3: Password setup
                    Form(
                      key: _formKeyStep3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Seguridad',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña (mínimo 8 caracteres)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v!.length < 8 ? 'Mínimo 8 caracteres' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirmar Contraseña',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v != _passwordController.text
                                ? 'Las contraseñas no coinciden'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            child: Text(
              isLast ? (_isLoading ? 'Registrando...' : 'Finalizar') : 'Siguiente',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 54,
          child: OutlinedButton(
            onPressed: _back,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.registerAccent,
              side: const BorderSide(color: AppColors.registerAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(_currentStep == 0 ? 'Cancelar' : 'Volver'),
          ),
        ),
      ],
    );
  }
}
