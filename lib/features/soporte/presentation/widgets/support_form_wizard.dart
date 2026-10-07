import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/slide_switcher.dart';

import '../../application/help_notifier.dart';
import '../../domain/help_state.dart';
import '../../domain/support_enums.dart';
import 'support_form_inputs.dart';

/// Wizard del formulario de soporte técnico. Port de `SupportFormWizard.kt`.
/// Router entre el paso de selección de categoría y el de detalles, con una
/// transición horizontal (memoria espacial del flujo adelante/atrás).
class SupportFormWizard extends ConsumerWidget {
  const SupportFormWizard({super.key, required this.municipality});

  final String municipality;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(
      helpNotifierProvider(municipality).select((s) => s.formState),
    );
    final notifier = ref.read(helpNotifierProvider(municipality).notifier);

    // AnimatedContent: slideIn/Out horizontal + fade según la dirección.
    return SlideSwitcher(
      index: form.step == FormStep.fillDetails ? 1 : 0,
      child: form.step == FormStep.selectCategory
          ? _CategorySelectionStep(onCategorySelected: notifier.selectCategory)
          : _DetailsStep(form: form, notifier: notifier),
    );
  }
}

// =============================================================================
// PASO 1: Selección de categoría
// =============================================================================
class _CategorySelectionStep extends StatelessWidget {
  const _CategorySelectionStep({required this.onCategorySelected});

  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿En qué podemos ayudarte?',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Selecciona el tipo de solicitud para que podamos atenderte más rápido.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        _CategoryOptionCard(
          icon: Icons.payment,
          title: 'Problema con un pago realizado',
          subtitle: 'Mi pago no se ha visto reflejado, me cobraron mal, etc.',
          onTap: () => onCategorySelected('PAYMENT_ISSUE'),
        ),
        const SizedBox(height: 12),
        _CategoryOptionCard(
          icon: Icons.question_mark,
          title: 'Duda sobre un valor a pagar',
          subtitle: 'No entiendo el cobro, el valor parece incorrecto, etc.',
          onTap: () => onCategorySelected('PAYMENT_INQUIRY'),
        ),
        const SizedBox(height: 12),
        _CategoryOptionCard(
          icon: Icons.bug_report,
          title: 'Error técnico en la aplicación',
          subtitle: 'La app se cierra, una pantalla no carga, etc.',
          onTap: () => onCategorySelected('TECHNICAL_ERROR'),
        ),
        const SizedBox(height: 12),
        _CategoryOptionCard(
          icon: Icons.description,
          title: 'Solicitud de información o trámite',
          subtitle: 'Certificados, paz y salvo, cambio de propietario, etc.',
          onTap: () => onCategorySelected('INFORMATION_REQUEST'),
        ),
        const SizedBox(height: 12),
        _CategoryOptionCard(
          icon: Icons.help_outline,
          title: 'Otro',
          subtitle: 'Mi solicitud no encaja en las opciones anteriores.',
          onTap: () => onCategorySelected('OTHER'),
        ),
      ],
    );
  }
}

class _CategoryOptionCard extends StatelessWidget {
  const _CategoryOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PASO 2: Detalles del problema (varía según categoría)
// =============================================================================
class _DetailsStep extends StatelessWidget {
  const _DetailsStep({required this.form, required this.notifier});

  final SupportFormState form;
  final HelpNotifier notifier;

  static String _categoryTitle(String? code) => switch (code) {
    'PAYMENT_ISSUE' => 'Problema con un pago',
    'PAYMENT_INQUIRY' => 'Duda sobre un valor',
    'TECHNICAL_ERROR' => 'Error técnico',
    'INFORMATION_REQUEST' => 'Solicitud de información',
    'OTHER' => 'Otra solicitud',
    _ => 'Solicitud de soporte',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overLimit = form.freeText.length > 1000;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con botón de "volver".
        Row(
          children: [
            IconButton(
              onPressed: notifier.goBackToCategorySelection,
              icon: const Icon(Icons.arrow_back_ios_new),
              tooltip: 'Cambiar categoría',
            ),
            Expanded(
              child: Text(
                _categoryTitle(form.selectedCategoryCode),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Campos específicos por categoría.
        _CategoryFields(data: form.categoryData, notifier: notifier),

        const SizedBox(height: 12),

        // Descripción libre (al final).
        _SupportTextField(
          key: const ValueKey('free_text'),
          initialValue: form.freeText,
          label: 'Descripción adicional (opcional)',
          hint: 'Cuéntanos cualquier detalle adicional que creas relevante...',
          errorText: form.freeTextError,
          minLines: 4,
          maxLines: 6,
          onChanged: notifier.onFreeTextChanged,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${form.freeText.length}/1000',
              style: theme.textTheme.bodySmall?.copyWith(
                color: overLimit
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: form.isSubmitting ? null : notifier.submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: form.isSubmitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Enviando...'),
                    ],
                  )
                : const Text('Enviar solicitud'),
          ),
        ),
      ],
    );
  }
}

class _CategoryFields extends StatelessWidget {
  const _CategoryFields({required this.data, required this.notifier});

  final CategoryFormData data;
  final HelpNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return switch (data) {
      final PaymentIssueData d => _PaymentIssueFields(
        data: d,
        notifier: notifier,
      ),
      final PaymentInquiryData d => _PaymentInquiryFields(
        data: d,
        notifier: notifier,
      ),
      final TechnicalErrorData d => _TechnicalErrorFields(
        data: d,
        notifier: notifier,
      ),
      final InformationRequestData d => _InformationRequestFields(
        data: d,
        notifier: notifier,
      ),
      OtherCategory() => const SizedBox.shrink(),
      EmptyCategory() => const SizedBox.shrink(),
    };
  }
}

// ── Payment issue ────────────────────────────────────────────────────────────
class _PaymentIssueFields extends StatelessWidget {
  const _PaymentIssueFields({required this.data, required this.notifier});
  final PaymentIssueData data;
  final HelpNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EnumDropdown<TaxConcept>(
          label: 'Impuesto con el que pagaste *',
          options: TaxConcept.values,
          selected: data.taxConcept,
          displayName: (t) => t.displayName,
          errorText: data.taxConceptError,
          onSelected: notifier.setPaymentIssueTaxConcept,
        ),
        const SizedBox(height: 10),
        EnumDropdown<PaymentIssueType>(
          label: 'Tipo de problema *',
          options: PaymentIssueType.values,
          selected: data.issueType,
          displayName: (t) => t.displayName,
          errorText: data.issueTypeError,
          onSelected: notifier.setPaymentIssueType,
        ),
        const SizedBox(height: 10),
        EnumDropdown<PaymentMethod>(
          label: '¿Cómo realizaste el pago? *',
          options: PaymentMethod.values,
          selected: data.paymentMethod,
          displayName: (t) => t.displayName,
          errorText: data.paymentMethodError,
          onSelected: notifier.setPaymentIssueMethod,
        ),
        const SizedBox(height: 10),
        DatePickerField(
          value: data.paymentDate,
          label: 'Fecha del pago *',
          placeholder: 'Toca para seleccionar la fecha',
          errorText: data.paymentDateError,
          onDateSelected: notifier.setPaymentIssueDate,
        ),
        const SizedBox(height: 10),
        MoneyTextField(
          value: data.amountPaid,
          label: 'Monto pagado *',
          placeholder: '250.000',
          errorText: data.amountPaidError,
          onValueChanged: notifier.setPaymentIssueAmount,
        ),
        const SizedBox(height: 10),
        _SupportTextField(
          key: const ValueKey('voucher'),
          initialValue: data.voucherReference,
          label: 'Número de comprobante o referencia *',
          hint: 'Número de autorización, CUS, o referencia bancaria',
          errorText: data.voucherReferenceError,
          onChanged: notifier.setPaymentIssueVoucher,
        ),
      ],
    );
  }
}

// ── Payment inquiry ──────────────────────────────────────────────────────────
class _PaymentInquiryFields extends StatelessWidget {
  const _PaymentInquiryFields({required this.data, required this.notifier});
  final PaymentInquiryData data;
  final HelpNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final idLabel = data.taxConcept?.identifierLabel ?? 'Identificador';
    return Column(
      children: [
        EnumDropdown<TaxConcept>(
          label: 'Impuesto sobre el que consultas *',
          options: TaxConcept.values,
          selected: data.taxConcept,
          displayName: (t) => t.displayName,
          errorText: data.taxConceptError,
          onSelected: notifier.setPaymentInquiryTaxConcept,
        ),
        const SizedBox(height: 10),
        _SupportTextField(
          // Se recrea al cambiar el impuesto para refrescar la etiqueta dinámica.
          key: ValueKey('entity_${data.taxConcept?.code ?? 'none'}'),
          initialValue: data.taxableEntityId,
          label: '$idLabel *',
          hint: 'Ingresa el identificador',
          errorText: data.taxableEntityIdError,
          enabled: data.taxConcept != null,
          onChanged: notifier.setPaymentInquiryEntityId,
        ),
        const SizedBox(height: 10),
        FiscalYearDropdown(
          value: data.fiscalYear,
          label: 'Vigencia (año) *',
          errorText: data.fiscalYearError,
          onValueChanged: notifier.setPaymentInquiryFiscalYear,
        ),
        const SizedBox(height: 10),
        EnumDropdown<InquiryType>(
          label: '¿Qué duda tienes específicamente? *',
          options: InquiryType.values,
          selected: data.inquiryType,
          displayName: (t) => t.displayName,
          errorText: data.inquiryTypeError,
          onSelected: notifier.setPaymentInquiryType,
        ),
      ],
    );
  }
}

// ── Technical error ──────────────────────────────────────────────────────────
class _TechnicalErrorFields extends StatelessWidget {
  const _TechnicalErrorFields({required this.data, required this.notifier});
  final TechnicalErrorData data;
  final HelpNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SupportTextField(
          key: const ValueKey('screen_name'),
          initialValue: data.screenName,
          label: '¿En qué pantalla ocurrió? *',
          hint: 'Ej. Pago de Predial, Login, Inicio',
          errorText: data.screenNameError,
          onChanged: notifier.setTechnicalScreenName,
        ),
        const SizedBox(height: 10),
        _SupportTextField(
          key: const ValueKey('attempted_action'),
          initialValue: data.attemptedAction,
          label: '¿Qué intentabas hacer? *',
          hint: 'Ej. Consultar el valor del predial 2026',
          errorText: data.attemptedActionError,
          minLines: 2,
          maxLines: 4,
          onChanged: notifier.setTechnicalAttemptedAction,
        ),
        const SizedBox(height: 10),
        EnumDropdown<ErrorFrequency>(
          label: '¿Con qué frecuencia ocurre? *',
          options: ErrorFrequency.values,
          selected: data.frequency,
          displayName: (t) => t.displayName,
          errorText: data.frequencyError,
          onSelected: notifier.setTechnicalFrequency,
        ),
        const SizedBox(height: 10),
        _SupportTextField(
          key: const ValueKey('error_message'),
          initialValue: data.errorMessage,
          label: 'Mensaje de error (si lo recuerdas)',
          hint: 'Copia textual del mensaje, si lo viste',
          minLines: 1,
          maxLines: 3,
          onChanged: notifier.setTechnicalErrorMessage,
        ),
      ],
    );
  }
}

// ── Information request ──────────────────────────────────────────────────────
class _InformationRequestFields extends StatelessWidget {
  const _InformationRequestFields({required this.data, required this.notifier});
  final InformationRequestData data;
  final HelpNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EnumDropdown<InformationType>(
          label: 'Tipo de solicitud *',
          options: InformationType.values,
          selected: data.requestType,
          displayName: (t) => t.displayName,
          errorText: data.requestTypeError,
          onSelected: notifier.setInformationRequestType,
        ),
        const SizedBox(height: 10),
        EnumDropdown<TaxConcept>(
          label: 'Impuesto relacionado (opcional)',
          options: TaxConcept.values,
          selected: data.taxConcept,
          displayName: (t) => t.displayName,
          onSelected: notifier.setInformationTaxConcept,
        ),
      ],
    );
  }
}

// ── Campo de texto reutilizable con controller local ─────────────────────────
class _SupportTextField extends StatefulWidget {
  const _SupportTextField({
    super.key,
    required this.initialValue,
    required this.label,
    required this.onChanged,
    this.hint,
    this.errorText,
    this.minLines = 1,
    this.maxLines = 1,
    this.enabled = true,
  });

  final String initialValue;
  final String label;
  final ValueChanged<String> onChanged;
  final String? hint;
  final String? errorText;
  final int minLines;
  final int maxLines;
  final bool enabled;

  @override
  State<_SupportTextField> createState() => _SupportTextFieldState();
}

class _SupportTextFieldState extends State<_SupportTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      textInputAction: widget.maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      style: theme.textTheme.bodyMedium,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        alignLabelWithHint: widget.maxLines > 1,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
