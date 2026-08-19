import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tramiapp_flutter/core/municipality/municipality_repository.dart';
import 'package:tramiapp_flutter/core/theme/app_colors.dart';
import 'package:tramiapp_flutter/core/widgets/confirmation_policies_dialog.dart';
import 'package:tramiapp_flutter/core/widgets/pqrd_dropdown.dart';
import 'package:tramiapp_flutter/core/widgets/top_bar_navigation.dart';
import 'package:tramiapp_flutter/core/widgets/step_indicator.dart';
import '../application/pqrd_notifier.dart';
import '../domain/pqrd_state.dart';
import 'pqrd_result_dialogs.dart';

/// PQRSDF con identificación — wizard de 3 pasos. Port fiel de
/// `PqrdsIdentificationStep1/2/3Screen.kt` (+ `PqrdsIdentificationNavScreen`):
/// `TopbarNavigation` con ícono, `StepIndicator`, `CustomDropdownPqrds` y el
/// bottom sheet de políticas antes de radicar.
class PqrdIdentificacionScreen extends ConsumerStatefulWidget {
  const PqrdIdentificacionScreen({required this.municipalityId, super.key});

  final int municipalityId;

  @override
  ConsumerState<PqrdIdentificacionScreen> createState() =>
      _PqrdIdentificacionScreenState();
}

class _PqrdIdentificacionScreenState
    extends ConsumerState<PqrdIdentificacionScreen> {
  int _currentStep = 1;
  bool _catalogRequested = false;
  bool _isSubmitting = false;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  PqrdFormStateNotifier get _form =>
      ref.read(pqrdFormStateProvider.notifier);

  void _update(PqrdFormState Function(PqrdFormState) updater) =>
      _form.updateField(updater);

  // ------------------------------------------------------------------ archivo
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'xls', 'xlsx', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'pdf', 'rar', 'zip',
        ],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        _update((s) => s.copyWith(
              nombreArchivo: result.files.single.name,
              tipoArchivo: result.files.single.extension,
              contenidoArchivoBase64: base64Encode(bytes),
            ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar archivo: $e')),
      );
    }
  }

  void _removeFile() => _update(
        (s) => s.copyWith(
          nombreArchivo: null,
          tipoArchivo: null,
          contenidoArchivoBase64: null,
        ),
      );

  // ----------------------------------------------------------------- navegación
  void _next() {
    if (_currentStep == 1 && _formKey1.currentState!.validate()) {
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2 && _formKey2.currentState!.validate()) {
      setState(() => _currentStep = 3);
    }
  }

  void _prev() {
    if (_currentStep > 1) setState(() => _currentStep -= 1);
  }

  // ------------------------------------------------------------------- radicar
  void _onFinalize(String entityCode) {
    if (!_formKey3.currentState!.validate()) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Consumer(
        builder: (ctx, ref, _) {
          final form = ref.watch(pqrdFormStateProvider);
          final notifier = ref.read(pqrdFormStateProvider.notifier);
          return ConfirmationPoliciesDialog(
            aceptaTratamientoDatos: form.aceptaTratamientoDatos,
            onAceptaTratamientoDatosChange: (v) =>
                notifier.updateField((s) => s.copyWith(aceptaTratamientoDatos: v)),
            aceptaCondicionesUso: form.aceptaCondicionesUso,
            onAceptaCondicionesUsoChange: (v) =>
                notifier.updateField((s) => s.copyWith(aceptaCondicionesUso: v)),
            onDismiss: () => Navigator.pop(ctx),
            onConfirm: () {
              Navigator.pop(ctx);
              _submit(entityCode);
            },
          );
        },
      ),
    );
  }

  Future<void> _submit(String entityCode) async {
    setState(() => _isSubmitting = true);
    try {
      final res = await _form.submitIdentificada(entityCode);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      if (res.estado) {
        await showPqrdSuccessDialog(
          context,
          res.ticket,
          onDismiss: () => context.go('/municipality/${widget.municipalityId}'),
        );
      } else {
        await showPqrdErrorDialog(
          context,
          'No fue posible radicar su solicitud. Intente nuevamente.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await showPqrdErrorDialog(context, 'Ocurrió un error en la red: $e');
    }
  }

  // --------------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final asyncMun = ref.watch(municipalityProvider(widget.municipalityId));
    final dropdowns = ref.watch(pqrdDropdownOptionsProvider);

    final mun = asyncMun.asData?.value;
    if (mun != null && !_catalogRequested) {
      _catalogRequested = true;
      Future.microtask(
        () => ref
            .read(pqrdDropdownOptionsProvider.notifier)
            .loadCatalogData(mun.entityCode),
      );
    }

    return TopBarNavigationScaffold(
      iconAsset: 'assets/images/ico_pqrd_identificacion.svg',
      title: 'PQRDS CON IDENTIFICACIÓN',
      description: 'Peticiones, quejas, reclamos y sugerencias',
      onBack: () => _currentStep == 1 ? context.pop() : _prev(),
      body: asyncMun.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (munDto) {
          if (dropdowns.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: StepIndicator(currentStep: _currentStep),
                  ),
                  const SizedBox(height: 25),
                  if (_currentStep == 1) _buildStep1(dropdowns),
                  if (_currentStep == 2) _buildStep2(dropdowns),
                  if (_currentStep == 3) _buildStep3(dropdowns),
                  const SizedBox(height: 16),
                  _buttons(munDto.entityCode),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------------- widgets
  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
        ),
      );

  InputDecoration _fieldDeco(String label) {
    final scheme = Theme.of(context).colorScheme;
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: b(AppColors.gray400),
      enabledBorder: b(AppColors.gray400),
      focusedBorder: b(scheme.primary, 2),
      errorBorder: b(scheme.error),
      focusedErrorBorder: b(scheme.error, 2),
    );
  }

  Widget _field({
    required String label,
    required String initial,
    required ValueChanged<String> onChanged,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextFormField(
          initialValue: initial,
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: _fieldDeco(label),
        ),
      );

  String? _required(String? v, String msg) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  Widget _obligatoriosHint() => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'Los campos con * son obligatorios',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );

  // --------------------------------------------------------------------- paso 1
  Widget _buildStep1(PqrdDropdownOptionsState d) {
    final form = ref.watch(pqrdFormStateProvider);
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Datos de la Secretaría'),
          PqrdDropdown(
            label: 'Secretaría*',
            value: form.secretaria,
            items: d.secretarias,
            itemLabel: (s) => s.secretaria,
            onChanged: (v) => _update((s) => s.copyWith(secretaria: v)),
            validator: (v) => v == null ? 'Debe seleccionar una secretaría' : null,
          ),
          PqrdDropdown(
            label: 'Asunto de interés*',
            value: form.asuntoInteres,
            items: d.asuntosInteres,
            itemLabel: (s) => s.descripcion,
            onChanged: (v) => _update((s) => s.copyWith(asuntoInteres: v)),
            validator: (v) =>
                v == null ? 'Debe seleccionar un asunto de interés' : null,
          ),
          PqrdDropdown(
            label: 'Clasificación solicitud*',
            value: form.clasificacionSolicitud,
            items: d.clasificacionesSolicitud,
            itemLabel: (s) => s.descripcion,
            onChanged: (v) => _update((s) => s.copyWith(clasificacionSolicitud: v)),
            validator: (v) =>
                v == null ? 'Debe seleccionar una clasificación' : null,
          ),
          PqrdDropdown(
            label: 'Tipo de solicitante*',
            value: form.tipoSolicitante,
            items: d.tiposSolicitante,
            itemLabel: (s) => s.descripcion,
            onChanged: (v) => _update((s) => s.copyWith(tipoSolicitante: v)),
            validator: (v) =>
                v == null ? 'Debe seleccionar un tipo de solicitante' : null,
          ),
          PqrdDropdown(
            label: 'Tipo atención preferencial*',
            value: form.atencionPreferencial,
            items: d.atencionesPreferenciales,
            itemLabel: (s) => s.descripcion,
            onChanged: (v) => _update((s) => s.copyWith(atencionPreferencial: v)),
            validator: (v) =>
                v == null ? 'Debe seleccionar una atención preferencial' : null,
          ),
          PqrdDropdown(
            label: 'Medio de respuesta*',
            value: form.medioRespuesta,
            items: d.mediosRespuesta,
            itemLabel: (s) => s.descripcion,
            onChanged: (v) => _update((s) => s.copyWith(medioRespuesta: v)),
            validator: (v) =>
                v == null ? 'Debe seleccionar un medio de respuesta' : null,
          ),
          _obligatoriosHint(),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------- paso 2
  Widget _buildStep2(PqrdDropdownOptionsState d) {
    final form = ref.watch(pqrdFormStateProvider);
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Datos del ciudadano o contribuyente'),
          PqrdDropdown(
            label: 'Tipo de documento*',
            value: form.tipoDocumento,
            items: d.tiposDocumento,
            itemLabel: (s) => s.descripcion,
            onChanged: (v) => _update((s) => s.copyWith(tipoDocumento: v)),
            validator: (v) => v == null ? 'Seleccione un tipo de documento' : null,
          ),
          _field(
            label: 'Identificación*',
            initial: form.identificacion,
            keyboardType: TextInputType.number,
            onChanged: (v) => _update((s) => s.copyWith(identificacion: v)),
            validator: (v) => _required(v, 'Por favor, introduce un documento.'),
          ),
          _field(
            label: 'Primer nombre*',
            initial: form.primerNombre,
            onChanged: (v) => _update((s) => s.copyWith(primerNombre: v)),
            validator: (v) => _required(v, 'El primer nombre es requerido.'),
          ),
          _field(
            label: 'Segundo nombre',
            initial: form.segundoNombre,
            onChanged: (v) => _update((s) => s.copyWith(segundoNombre: v)),
          ),
          _field(
            label: 'Primer apellido*',
            initial: form.primerApellido,
            onChanged: (v) => _update((s) => s.copyWith(primerApellido: v)),
            validator: (v) => _required(v, 'El primer apellido es requerido.'),
          ),
          _field(
            label: 'Segundo apellido',
            initial: form.segundoApellido,
            onChanged: (v) => _update((s) => s.copyWith(segundoApellido: v)),
          ),
          PqrdDropdown(
            label: '¿Pertenece a algún grupo de interés?',
            value: form.grupoInteres,
            items: d.gruposInteres,
            itemLabel: (s) => s.descripcion,
            onChanged: (v) => _update((s) => s.copyWith(grupoInteres: v)),
          ),
          PqrdDropdown(
            label: '¿Tiene condición de discapacidad?',
            value: form.discapacidad,
            items: d.discapacidades,
            itemLabel: (s) => s.descripcion,
            onChanged: (v) => _update((s) => s.copyWith(discapacidad: v)),
          ),
          PqrdDropdown(
            label: '¿Pertenece a algún grupo étnico?',
            value: form.grupoEtnico,
            items: d.gruposEtnicos,
            itemLabel: (s) => s.descripcion,
            onChanged: (v) => _update((s) => s.copyWith(grupoEtnico: v)),
          ),
          PqrdDropdown(
            label: 'Género',
            value: form.genero,
            items: d.generos,
            itemLabel: (s) => s.descripcion,
            onChanged: (v) => _update((s) => s.copyWith(genero: v)),
          ),
          PqrdDropdown(
            label: 'Rango de edad',
            value: form.rangoEdad,
            items: d.rangosEdad,
            itemLabel: (s) => s.descripcion,
            onChanged: (v) => _update((s) => s.copyWith(rangoEdad: v)),
          ),
          PqrdDropdown(
            label: 'Actividad económica',
            value: form.actividadEconomica,
            items: d.actividadesEconomicas,
            itemLabel: (s) => s.descripcion,
            onChanged: (v) => _update((s) => s.copyWith(actividadEconomica: v)),
          ),
          PqrdDropdown(
            label: 'Estrato',
            value: form.nivelEstrato,
            items: d.nivelesEstrato,
            itemLabel: (s) => s.descripcion,
            onChanged: (v) => _update((s) => s.copyWith(nivelEstrato: v)),
          ),
          PqrdDropdown(
            label: 'Nivel sisbén',
            value: form.nivelSisben,
            items: d.nivelesSisben,
            itemLabel: (s) => s.descripcion,
            onChanged: (v) => _update((s) => s.copyWith(nivelSisben: v)),
          ),
          PqrdDropdown(
            label: 'Escolaridad',
            value: form.escolaridad,
            items: d.escolaridades,
            itemLabel: (s) => s.descripcion,
            onChanged: (v) => _update((s) => s.copyWith(escolaridad: v)),
          ),
          PqrdDropdown(
            label: 'Vulnerabilidad',
            value: form.vulnerabilidad,
            items: d.vulnerabilidades,
            itemLabel: (s) => s.descripcion,
            onChanged: (v) => _update((s) => s.copyWith(vulnerabilidad: v)),
          ),
          _obligatoriosHint(),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------- paso 3
  Widget _buildStep3(PqrdDropdownOptionsState d) {
    final form = ref.watch(pqrdFormStateProvider);
    return Form(
      key: _formKey3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Datos Razón Social'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextFormField(
              initialValue: 'Colombia',
              readOnly: true,
              decoration: _fieldDeco('País'),
            ),
          ),
          PqrdDropdown(
            label: 'Departamento*',
            value: form.departamento,
            items: d.departamentos,
            itemLabel: (s) => s.nombreDepartamento,
            onChanged: (v) {
              _update((s) => s.copyWith(departamento: v, ciudad: null));
              if (v != null) {
                ref
                    .read(pqrdDropdownOptionsProvider.notifier)
                    .loadCiudades(v.id);
              }
            },
            validator: (v) => v == null ? 'Debe seleccionar un departamento.' : null,
          ),
          Stack(
            alignment: Alignment.centerRight,
            children: [
              PqrdDropdown(
                // Se reconstruye al cambiar el departamento para limpiar la ciudad.
                key: ValueKey('ciudad-${form.departamento?.id}'),
                label: 'Ciudad*',
                value: form.ciudad,
                items: d.ciudades,
                itemLabel: (s) => s.nombreCiudad,
                enabled: form.departamento != null && !d.isLoadingCiudades,
                onChanged: (v) => _update((s) => s.copyWith(ciudad: v)),
                validator: (v) => v == null ? 'Debe seleccionar una ciudad.' : null,
              ),
              if (d.isLoadingCiudades)
                const Padding(
                  padding: EdgeInsets.only(right: 44),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          _field(
            label: 'Razón social*',
            initial: form.razonSocial,
            onChanged: (v) => _update((s) => s.copyWith(razonSocial: v)),
            validator: (v) => _required(v, 'La razón social no puede estar vacía.'),
          ),
          _field(
            label: 'Correo electrónico*',
            initial: form.correoElectronico,
            keyboardType: TextInputType.emailAddress,
            onChanged: (v) => _update((s) => s.copyWith(correoElectronico: v)),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Ingrese un correo electrónico válido.';
              }
              final ok = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(v.trim());
              return ok ? null : 'Ingrese un correo electrónico válido.';
            },
          ),
          _field(
            label: 'Dirección',
            initial: form.direccion,
            onChanged: (v) => _update((s) => s.copyWith(direccion: v)),
          ),
          _field(
            label: 'Teléfono celular',
            initial: form.telefonoCelular,
            keyboardType: TextInputType.phone,
            onChanged: (v) => _update((s) => s.copyWith(telefonoCelular: v)),
          ),
          _field(
            label: 'Telefono fijo(si tiene)',
            initial: form.telefonoFijo,
            keyboardType: TextInputType.phone,
            onChanged: (v) => _update((s) => s.copyWith(telefonoFijo: v)),
          ),
          _field(
            label: 'Descripción *',
            initial: form.descripcion,
            maxLines: 5,
            onChanged: (v) => _update((s) => s.copyWith(descripcion: v)),
            validator: (v) => _required(v, 'La descripción no puede estar vacía.'),
          ),
          const SizedBox(height: 12),
          _fileAttach(form),
          _obligatoriosHint(),
        ],
      ),
    );
  }

  Widget _fileAttach(PqrdFormState form) {
    final scheme = Theme.of(context).colorScheme;
    final hasFile = (form.nombreArchivo ?? '').isNotEmpty;
    if (!hasFile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: _pickFile,
                child: const Icon(Icons.attach_file),
              ),
              const SizedBox(width: 8),
              Text('Adjuntar documentos',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Seleccionar documentos',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.successGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              form.nombreArchivo!,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          IconButton(
            onPressed: _removeFile,
            icon: const Icon(Icons.cancel_outlined),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------- botones
  Widget _buttons(String entityCode) {
    final scheme = Theme.of(context).colorScheme;
    final isLast = _currentStep == 3;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 150,
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () => _currentStep == 1 ? context.pop() : _prev(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gray600,
              foregroundColor: scheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        SizedBox(
          width: 150,
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () => isLast ? _onFinalize(entityCode) : _next(),
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isLast ? 'Finalizar' : 'Siguiente'),
          ),
        ),
      ],
    );
  }
}
