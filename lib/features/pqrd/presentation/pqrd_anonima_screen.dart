import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tramiapp_flutter/core/municipality/municipality_repository.dart';
import 'package:tramiapp_flutter/core/theme/app_colors.dart';
import 'package:tramiapp_flutter/core/widgets/pqrd_dropdown.dart';
import 'package:tramiapp_flutter/core/widgets/pqrd_scaffold.dart';
import '../application/pqrd_notifier.dart';
import '../domain/pqrd_state.dart';
import 'pqrd_result_dialogs.dart';

/// PQRSD anónima — formulario de una sola página. Port fiel de
/// `PqrdAnonimaScreen.kt`: `TopbarNavigation`, "Información General",
/// Secretaría/Asunto/Clasificación, descripción, adjunto y botones
/// Cancelar/Finalizar (radica directamente, sin bottom sheet de políticas).
class PqrdAnonimaScreen extends ConsumerStatefulWidget {
  const PqrdAnonimaScreen({required this.municipalityId, super.key});

  final int municipalityId;

  @override
  ConsumerState<PqrdAnonimaScreen> createState() => _PqrdAnonimaScreenState();
}

class _PqrdAnonimaScreenState extends ConsumerState<PqrdAnonimaScreen> {
  bool _catalogRequested = false;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();

  PqrdFormStateNotifier get _form => ref.read(pqrdFormStateProvider.notifier);
  void _update(PqrdFormState Function(PqrdFormState) u) => _form.updateField(u);

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'xls', 'xlsx', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'pdf', 'rar', 'zip',
        ],
      );
      if (result != null && result.files.single.path != null) {
        final bytes = await File(result.files.single.path!).readAsBytes();
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

  void _removeFile() => _update((s) => s.copyWith(
        nombreArchivo: null,
        tipoArchivo: null,
        contenidoArchivoBase64: null,
      ));

  Future<void> _submit(String entityCode) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final res = await _form.submitAnonima(entityCode);
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

    return PqrdScaffold(
      iconAsset: 'assets/images/ico_pqrd_anonima.svg',
      title: 'PQRSD ANÓNIMA',
      description: 'Peticiones, quejas, reclamos y sugerencias',
      onBack: () => context.pop(),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Información General',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildForm(dropdowns),
                    const SizedBox(height: 30),
                    _buttons(munDto.entityCode),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(PqrdDropdownOptionsState d) {
    final form = ref.watch(pqrdFormStateProvider);
    final scheme = Theme.of(context).colorScheme;
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c, width: w),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PqrdDropdown(
          label: '*Secretaría',
          hint: 'Seleccione una secretaría',
          value: form.secretaria,
          items: d.secretarias,
          itemLabel: (s) => s.secretaria,
          onChanged: (v) => _update((s) => s.copyWith(secretaria: v)),
          validator: (v) => v == null ? 'Debe seleccionar una secretaría' : null,
        ),
        PqrdDropdown(
          label: '*Asunto de interés',
          hint: 'Seleccione un asunto de interés',
          value: form.asuntoInteres,
          items: d.asuntosInteres,
          itemLabel: (s) => s.descripcion,
          onChanged: (v) => _update((s) => s.copyWith(asuntoInteres: v)),
          validator: (v) =>
              v == null ? 'Debe seleccionar un asunto de interés' : null,
        ),
        PqrdDropdown(
          label: '*Clasificación solicitud',
          hint: 'Seleccione una clasificación',
          value: form.clasificacionSolicitud,
          items: d.clasificacionesSolicitud,
          itemLabel: (s) => s.descripcion,
          onChanged: (v) => _update((s) => s.copyWith(clasificacionSolicitud: v)),
          validator: (v) => v == null ? 'Debe seleccionar una clasificación' : null,
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: form.descripcion,
          maxLines: 6,
          onChanged: (v) => _update((s) => s.copyWith(descripcion: v)),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'La descripción no puede estar vacía.'
              : null,
          decoration: InputDecoration(
            labelText: 'Descripción *',
            alignLabelWithHint: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: b(AppColors.gray400),
            enabledBorder: b(AppColors.gray400),
            focusedBorder: b(scheme.primary, 2),
            errorBorder: b(scheme.error),
            focusedErrorBorder: b(scheme.error, 2),
          ),
        ),
        const SizedBox(height: 16),
        _fileAttach(form),
      ],
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
            child: Text(form.nombreArchivo!,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          IconButton(
            onPressed: _removeFile,
            icon: const Icon(Icons.cancel_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buttons(String entityCode) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 150,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : () => context.pop(),
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
            onPressed: _isSubmitting ? null : () => _submit(entityCode),
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
                : const Text('Finalizar'),
          ),
        ),
      ],
    );
  }
}
