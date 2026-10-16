import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:tramiapp_flutter/core/router/app_routes.dart';
import 'package:tramiapp_flutter/core/router/safe_pop.dart';
import 'package:tramiapp_flutter/core/theme/app_colors.dart';
import 'package:tramiapp_flutter/core/widgets/dialog_typography.dart';
import 'package:tramiapp_flutter/core/widgets/pqrd_dropdown.dart';
import 'package:tramiapp_flutter/core/widgets/slide_switcher.dart';
import 'package:tramiapp_flutter/core/widgets/step_indicator.dart';
import 'package:tramiapp_flutter/core/widgets/top_bar_navigation.dart';
import '../application/certificates_notifier.dart';
import '../domain/certificate_procedure.dart';
import '../domain/certificates_state.dart';

/// Asistente de certificados en 3 pasos. Port de `CertificatesNavScreen.kt` +
/// `CertificateStep1/2/3Screen.kt`.
class CertificatesWizard extends ConsumerStatefulWidget {
  const CertificatesWizard({
    required this.municipalityId,
    required this.certificate,
    super.key,
  });

  final int municipalityId;

  /// Certificado ya resuelto por código (título, ícono, `IDTramite`,
  /// `IDImpuesto` y valor).
  final CertificateProcedure certificate;

  @override
  ConsumerState<CertificatesWizard> createState() => _CertificatesWizardState();
}

class _CertificatesWizardState extends ConsumerState<CertificatesWizard> {
  final _identificacionCtrl = TextEditingController();
  final _primerNombreCtrl = TextEditingController();
  final _segundoNombreCtrl = TextEditingController();
  final _primerApellidoCtrl = TextEditingController();
  final _segundoApellidoCtrl = TextEditingController();

  final _correoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _celularCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  late final CertificatesFamilyParam _param;

  @override
  void initState() {
    super.initState();
    _param = CertificatesFamilyParam(certificate: widget.certificate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncControllers(ref.read(certificatesNotifierProvider(_param)));
    });
  }

  /// Lleva al texto de los campos los valores que cambia el notifier (el
  /// autollenado de la sesión, la edad filtrada a dígitos, etc.).
  void _syncControllers(CertificatesUiState s) {
    void sync(TextEditingController c, String value) {
      if (c.text != value) c.text = value;
    }

    sync(_identificacionCtrl, s.identificacion);
    sync(_primerNombreCtrl, s.primerNombre);
    sync(_segundoNombreCtrl, s.segundoNombre);
    sync(_primerApellidoCtrl, s.primerApellido);
    sync(_segundoApellidoCtrl, s.segundoApellido);
    sync(_correoCtrl, s.correoElectronico);
    sync(_direccionCtrl, s.direccion);
    sync(_celularCtrl, s.telefonoCelular);
    sync(_ageCtrl, s.age);
    sync(_descripcionCtrl, s.descripcion);
  }

  @override
  void dispose() {
    _identificacionCtrl.dispose();
    _primerNombreCtrl.dispose();
    _segundoNombreCtrl.dispose();
    _primerApellidoCtrl.dispose();
    _segundoApellidoCtrl.dispose();
    _correoCtrl.dispose();
    _direccionCtrl.dispose();
    _celularCtrl.dispose();
    _ageCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile(CertificatesNotifier notifier) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );
      final file = result?.files.single;
      final path = file?.path;
      if (file == null || path == null) return;

      await notifier.attachFile(
        fileName: file.name,
        sizeBytes: file.size,
        // Lectura y base64 fuera del hilo de la UI (hasta 5 MB).
        readBase64: () =>
            Isolate.run(() => base64Encode(File(path).readAsBytesSync())),
      );
    } catch (_) {
      notifier.onFilePickFailed();
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _close() =>
      context.popOrGo(AppRoutes.municipalityPath(widget.municipalityId));

  @override
  Widget build(BuildContext context) {
    final provider = certificatesNotifierProvider(_param);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    ref.listen<CertificatesUiState>(provider, (_, next) {
      _syncControllers(next);
    });

    ref.listen<String?>(provider.select((s) => s.fileError), (_, next) {
      if (next == null) return;
      _showSnack(next);
      notifier.clearFileError();
    });

    ref.listen<CertificatesResponseState>(
      provider.select((s) => s.submission),
      (_, next) {
        if (next is CertificatesResponseSuccess) {
          notifier.resetSubmission();
          context.push(
            AppRoutes.pagosProcessingPath(widget.municipalityId),
            // Antes mandaba `'url'` y la ruta lee `'paymentUrl'`: la pasarela
            // nunca abría.
            extra: AppRoutes.pagosProcessingExtra(next.urlTransaction),
          );
        } else if (next is CertificatesResponseError) {
          notifier.resetSubmission();
          // En Kotlin este snackbar nunca se veía (su `ScaffoldState` no estaba
          // conectado a nada).
          _showSnack(next.message);
        }
      },
    );

    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: state.currentStep == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) notifier.onPreviousStep();
      },
      child: TopBarNavigationScaffold(
        iconAsset: state.certificateIconPath ?? kGenericCertificateIcon,
        title: state.titleCertificate ?? 'Certificado',
        description: 'Pide, paga y recibe tu certificado.',
        onBack: () {
          if (state.currentStep == 1) {
            _close();
          } else {
            notifier.onPreviousStep();
          }
        },
        body: GestureDetector(
          // Toque fuera de los campos = cerrar teclado (`clearFocus()`).
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 32, right: 32),
                  child: StepIndicator(currentStep: state.currentStep),
                ),
                const SizedBox(height: 18),
                // AnimatedContent "StepAnimation" (slide + fade).
                SlideSwitcher(
                  index: state.currentStep,
                  child: switch (state.currentStep) {
                    1 => _buildStep1(state, notifier, scheme),
                    2 => _buildStep2(state, notifier, scheme),
                    _ => _buildStep3(state, notifier, scheme),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Campos (OutlinedTextField del original)
  // ---------------------------------------------------------------------------

  /// `OutlinedTextField` con los colores de `outLineTextColor`: esquinas 10,
  /// etiqueta `bodyMedium` (Gray400 en reposo, primario al enfocar) y fondo =
  /// `background`. [hasSupportingText] reserva el renglón de `supportingText`
  /// como en Compose, que es el aire entre campos del original.
  Widget _field({
    required ColorScheme scheme,
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
    String? error,
    bool hasSupportingText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    double? height,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: width),
        );

    final field = TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: DialogTypography.bodyMedium.copyWith(color: scheme.onSurface),
      // `singleLine = true` en todos los campos del original.
      maxLines: height == null ? 1 : null,
      expands: height != null,
      textAlignVertical: height == null ? null : TextAlignVertical.center,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: DialogTypography.bodyMedium.copyWith(
          color: AppColors.gray400,
        ),
        floatingLabelStyle: DialogTypography.bodyMedium.copyWith(
          color: error != null ? scheme.error : scheme.primary,
        ),
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: border(AppColors.gray400),
        enabledBorder: border(AppColors.gray400),
        focusedBorder: border(scheme.primary, 2),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 2),
        errorText: error,
        errorStyle: DialogTypography.bodySmall.copyWith(color: scheme.error),
        helperText: hasSupportingText ? ' ' : null,
        helperStyle: DialogTypography.bodySmall,
      ),
    );

    if (height == null) return field;
    return SizedBox(height: height, child: field);
  }

  Widget _requiredFieldsNote() => const Text(
    'Los campos con  * son obligatorios',
    style: DialogTypography.bodySmall,
  );

  // ---------------------------------------------------------------------------
  // Paso 1 — CertificateStep1Screen.kt
  // ---------------------------------------------------------------------------

  /// Teclado de texto solo para estos tipos exactos; número para el resto.
  TextInputType _documentKeyboard(String? description) => switch (description) {
    'Pasaporte' ||
    'NIT' ||
    'Permiso Especial de Permanencia' ||
    'Visa' ||
    'VISA' => TextInputType.text,
    _ => TextInputType.number,
  };

  Widget _buildStep1(
    CertificatesUiState state,
    CertificatesNotifier notifier,
    ColorScheme scheme,
  ) {
    final errors = state.errors;
    return Column(
      key: const ValueKey('certificates-step-1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.isLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          PqrdDropdown(
            // El dropdown toma el valor inicial: se recrea cuando el
            // autollenado elige el tipo.
            key: ValueKey(state.tipoDocumento?.id),
            label: 'Tipo de documento*',
            hint: '*Tipo de documento',
            value: state.tipoDocumento,
            items: state.listTipoDocumento,
            itemLabel: (t) => t.descripcion,
            onChanged: (t) {
              if (t != null) notifier.onTipoDocumentoChange(t);
            },
          ),
          if (errors.tipoDocumentoError)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                'Seleccione un tipo de documento',
                style: DialogTypography.bodySmall.copyWith(color: scheme.error),
              ),
            ),
          const SizedBox(height: 8),
          _field(
            scheme: scheme,
            controller: _identificacionCtrl,
            label: 'Identificación*',
            onChanged: notifier.onIdentificacionChange,
            keyboardType: _documentKeyboard(state.tipoDocumento?.descripcion),
            error: state.identificacionError,
            hasSupportingText: true,
          ),
          if (state.isAgePriced)
            _field(
              scheme: scheme,
              controller: _ageCtrl,
              label: 'Edad*',
              onChanged: notifier.onAgeChange,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              error: state.ageError,
              hasSupportingText: true,
            ),
          _field(
            scheme: scheme,
            controller: _primerNombreCtrl,
            label: 'Primer nombre*',
            onChanged: notifier.onPrimerNombreChange,
            error: errors.primerNombreError
                ? 'El primer nombre es requerido.'
                : null,
            hasSupportingText: true,
          ),
          _field(
            scheme: scheme,
            controller: _segundoNombreCtrl,
            label: 'Segundo nombre',
            onChanged: notifier.onSegundoNombreChange,
          ),
          const SizedBox(height: 16),
          _field(
            scheme: scheme,
            controller: _primerApellidoCtrl,
            label: 'Primer apellido*',
            onChanged: notifier.onPrimerApellidoChange,
            error: errors.primerApellidoError
                ? 'El primer apellido es requerido.'
                : null,
            hasSupportingText: true,
          ),
          _field(
            scheme: scheme,
            controller: _segundoApellidoCtrl,
            label: 'Segundo apellido',
            onChanged: notifier.onSegundoApellidoChange,
          ),
          const SizedBox(height: 5),
        ],
        _requiredFieldsNote(),
        const SizedBox(height: 20),
        _stepButtons(
          scheme: scheme,
          // En el paso 1 "Cancelar" cierra el módulo.
          onCancel: _close,
          onNext: state.isNextButtonEnabled ? notifier.onNextStep : null,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Paso 2 — CertificateStep2Screen.kt
  // ---------------------------------------------------------------------------

  Widget _buildStep2(
    CertificatesUiState state,
    CertificatesNotifier notifier,
    ColorScheme scheme,
  ) {
    final errors = state.errors;
    return Column(
      key: const ValueKey('certificates-step-2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.isLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          _field(
            scheme: scheme,
            controller: _correoCtrl,
            label: 'Correo electrónico*',
            onChanged: notifier.correoElectronicoChange,
            keyboardType: TextInputType.emailAddress,
            error: errors.correoElectronicoError
                ? 'Ingrese un correo electrónico válido.'
                : null,
            hasSupportingText: true,
          ),
          _field(
            scheme: scheme,
            controller: _direccionCtrl,
            label: 'Dirección',
            onChanged: notifier.onDireccionChange,
          ),
          const SizedBox(height: 16),
          _field(
            scheme: scheme,
            controller: _celularCtrl,
            label: 'Teléfono celular*',
            onChanged: notifier.onTelefonoCelularChange,
            keyboardType: TextInputType.phone,
            error: errors.telefonoCelularError
                ? 'Ingrese un número válido.'
                : null,
            hasSupportingText: true,
          ),
          // 150 de alto como en Kotlin. Allí es `singleLine`: aquí no admite
          // saltos de línea, pero el texto se ajusta dentro del recuadro.
          _field(
            scheme: scheme,
            controller: _descripcionCtrl,
            label: 'Descripción *',
            onChanged: notifier.onDescripcionChange,
            inputFormatters: [FilteringTextInputFormatter.deny('\n')],
            error: errors.descripcionError
                ? 'La descripción no puede estar vacía.'
                : null,
            hasSupportingText: true,
            height: 150,
          ),
        ],
        _attachment(state, notifier, scheme),
        _requiredFieldsNote(),
        const SizedBox(height: 20),
        _stepButtons(
          scheme: scheme,
          // En el paso 2 "Cancelar" vuelve al paso anterior.
          onCancel: notifier.onPreviousStep,
          onNext: state.isNextButtonEnabled ? notifier.onNextStep : null,
        ),
      ],
    );
  }

  Widget _attachment(
    CertificatesUiState state,
    CertificatesNotifier notifier,
    ColorScheme scheme,
  ) {
    if (!state.hasFile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () => _pickFile(notifier),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                  ),
                  child: const Icon(Icons.attach_file),
                ),
                const SizedBox(width: 3),
                const Text(
                  'Adjuntar documentos',
                  style: DialogTypography.bodyMedium,
                ),
              ],
            ),
          ),
          Material(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _pickFile(notifier),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Seleccionar documentos',
                  style: DialogTypography.bodyMedium,
                ),
              ),
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
          const Icon(
            Icons.check_circle,
            color: AppColors.successGreen,
            semanticLabel: 'Archivo adjuntado',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                state.nombreArchivo!,
                overflow: TextOverflow.ellipsis,
                style: DialogTypography.bodyMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Quitar archivo',
            onPressed: notifier.clearFile,
            icon: const Icon(Icons.cancel),
          ),
        ],
      ),
    );
  }

  /// Botones de los pasos 1 y 2: dentro del scroll, después del formulario.
  Widget _stepButtons({
    required ColorScheme scheme,
    required VoidCallback onCancel,
    required VoidCallback? onNext,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 150,
            child: _filledButton(
              label: 'Cancelar',
              background: AppColors.gray600,
              foreground: scheme.onPrimary,
              onPressed: onCancel,
            ),
          ),
          SizedBox(
            width: 150,
            child: _filledButton(
              label: 'Siguiente',
              background: scheme.primary,
              foreground: scheme.onPrimary,
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }

  /// `Button` de Compose: relleno, sin elevación, padding 12/18, texto
  /// `headlineMedium`.
  Widget _filledButton({
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback? onPressed,
    Widget? child,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: background,
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        textStyle: DialogTypography.headlineMedium,
      ),
      child: child ?? Text(label, maxLines: 1, softWrap: false),
    );
  }

  // ---------------------------------------------------------------------------
  // Paso 3 — CertificateStep3Screen.kt
  // ---------------------------------------------------------------------------

  Widget _buildStep3(
    CertificatesUiState state,
    CertificatesNotifier notifier,
    ColorScheme scheme,
  ) {
    final isSubmitting = state.submission is CertificatesResponseLoading;
    final value = (state.certificateValue ?? '').isEmpty
        ? '0'
        : state.certificateValue!;

    return Column(
      key: const ValueKey('certificates-step-3'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.all(5),
          child: Text(
            'Resumen de solicitud',
            style: DialogTypography.titleMedium,
          ),
        ),
        const SizedBox(height: 16),
        Material(
          color: scheme.surface,
          elevation: 3,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _summaryRow('Trámite:', state.titleCertificate ?? 'Trámite'),
                const SizedBox(height: 5),
                _summaryRow(
                  'Nombre:',
                  '${state.primerNombre} ${state.primerApellido}',
                ),
                const SizedBox(height: 5),
                _summaryRow('Correo:', state.correoElectronico),
                const SizedBox(height: 5),
                _summaryRow('Identificación:', state.identificacion),
                const SizedBox(height: 5),
                // Sin separador de miles, como el original.
                _summaryRow('Valor a Pagar:', '\$$value COP', isBold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _policyRow(
          checked: state.aceptaTratamientoDatos,
          onChanged: notifier.onTratamientoDatosAcepted,
          text: 'Acepto la política de tratamiento de datos personales.',
        ),
        _policyRow(
          checked: state.aceptaCondicionesUso,
          onChanged: notifier.onCondicionesUsoAcepted,
          text: 'Acepto las Condiciones de Uso y las políticas de privacidad.',
        ),
        const SizedBox(height: 24),
        _warningBox(scheme),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _filledButton(
                label: 'Cancelar',
                background: AppColors.gray600,
                foreground: scheme.onPrimary,
                onPressed: isSubmitting ? null : notifier.onPreviousStep,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _filledButton(
                label: 'Finalizar',
                background: scheme.primary,
                foreground: scheme.onPrimary,
                onPressed:
                    state.aceptaTratamientoDatos &&
                        state.aceptaCondicionesUso &&
                        !isSubmitting
                    ? notifier.submitSolicitudTramite
                    : null,
                child: isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
        // Aire para el indicador de inicio de iOS (Kotlin no lo tiene).
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DialogTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: DialogTypography.bodyMedium.copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _policyRow({
    required bool checked,
    required ValueChanged<bool> onChanged,
    required String text,
  }) {
    return Row(
      children: [
        Checkbox(value: checked, onChanged: (v) => onChanged(v ?? false)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: DialogTypography.bodySmall.copyWith(color: AppColors.blue),
          ),
        ),
      ],
    );
  }

  Widget _warningBox(ColorScheme scheme) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: const Color(0xFFEF5350),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info, color: Colors.white, size: 36),
                const SizedBox(width: 8),
                Text(
                  'Importante',
                  style: DialogTypography.titleLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Al seleccionar "Finalizar", será llevado a la pasarela de pagos '
              'donde podrá finalizar la transacción de forma segura. Asegúrese '
              'de revisar que los datos y el valor a pagar sean correctos.',
              style: DialogTypography.bodySmall.copyWith(
                color: scheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
