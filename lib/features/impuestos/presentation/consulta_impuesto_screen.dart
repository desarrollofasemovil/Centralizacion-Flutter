import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/municipality/municipality_repository.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/important_alert_dialog.dart';
import '../../auth/application/auth_providers.dart';
import '../../../core/widgets/policy_checkboxes.dart';
import '../../tramites/application/tramite_mappers.dart';
import '../application/tax_notifier.dart';
import 'widgets/styled_dropdown_menu.dart';

/// Puerto de `TaxQueryScreen` (ConsultaImpuestoScreen.kt): formulario de
/// consulta de impuestos. Toda la lógica vive en [TaxQueryNotifier].
class ConsultaImpuestoScreen extends ConsumerStatefulWidget {
  const ConsultaImpuestoScreen({
    required this.municipalityId,
    required this.taxId,
    required this.title,
    this.dataPolicyUrl = '',
    this.privacyPolicyUrl = '',
    super.key,
  });

  final int municipalityId;
  final int taxId;
  final String title;
  final String dataPolicyUrl;
  final String privacyPolicyUrl;

  @override
  ConsumerState<ConsultaImpuestoScreen> createState() =>
      _ConsultaImpuestoScreenState();
}

class _ConsultaImpuestoScreenState
    extends ConsumerState<ConsultaImpuestoScreen> {
  @override
  void initState() {
    super.initState();
    // Mejora sobre el original: precarga documento y correo del usuario
    // logueado para no re-digitarlos.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(sessionProvider);
      if (user != null) {
        ref
            .read(taxQueryNotifierProvider.notifier)
            .prefill(documentNumber: user.nationalId, email: user.email);
      }
    });
  }

  // Ícono según taxId, como el `when (taxId)` del original.
  String get _taxIconAsset => switch (widget.taxId) {
    2 => 'assets/images/icoica.svg',
    _ => 'assets/images/icopredial.svg',
  };

  void _showNoResultsDialog() {
    final notifier = ref.read(taxQueryNotifierProvider.notifier);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => ImportantAlertDialog(
        onDismissRequest: () => Navigator.of(dialogContext).pop(),
        title: 'Consulta sin resultados',
        message: 'No se encontrarón facturas para este documento.',
        confirmButtonText: 'Aceptar',
      ),
    ).whenComplete(notifier.onNoResultsDialogDismissed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(taxQueryNotifierProvider);
    final notifier = ref.read(taxQueryNotifierProvider.notifier);
    final asyncMun = ref.watch(municipalityProvider(widget.municipalityId));

    // Eventos de un solo disparo (equivalentes a los LaunchedEffect del
    // original): éxito → pantalla de resultados; sin resultados → diálogo.
    ref.listen(taxQueryNotifierProvider, (previous, next) {
      final taxes = next.querySuccess;
      if (taxes != null && taxes.isNotEmpty) {
        notifier.onQueryHandled();
        context.push(
          '/municipality/${widget.municipalityId}/taxes/results',
          extra: {'taxes': taxes, 'email': next.email.trim()},
        );
      }
      if (next.showNoResultsDialog && previous?.showNoResultsDialog != true) {
        _showNoResultsDialog();
      }
      final error = next.queryError;
      if (error != null && previous?.queryError != error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al consultar facturas: $error')),
        );
      }
    });

    return Scaffold(
      backgroundColor: scheme.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Center(child: AppBackButton(onPressed: () => context.pop())),
        ),
      ),
      body: asyncMun.maybeWhen(
        data: (munDto) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: kMainProcedureColors[0],
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          _taxIconAsset,
                          width: 36,
                          height: 36,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Consulta tus facturas y haz el pago de tus impuestos de manera rápida y segura.',
                          textAlign: TextAlign.justify,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  StyledDropdownMenu(
                    selectedValue:
                        state.selectedQueryField?.queryFieldType ?? '',
                    placeholderText: 'Selecciona tipo de documento',
                    isExpanded: state.isDropdownVisible,
                    onExpandedChange: notifier.onDropdownVisibilityChanged,
                    options: munDto.queryFields,
                    onOptionSelected: notifier.onDocumentTypeChanged,
                    itemToString: (qf) => qf.queryFieldType,
                  ),
                  const SizedBox(height: 20),
                  _CustomTextField(
                    value: state.documentNumber,
                    onChanged: notifier.onDocumentNumberChanged,
                    label: 'Número de documento',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  _CustomTextField(
                    value: state.email,
                    onChanged: notifier.onEmailChanged,
                    label: 'Correo electrónico',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 20),
                  PolicyCheckboxes(
                    dataPolicyChecked: state.acceptsPolicies,
                    onDataPolicyChange: notifier.onAcceptsPoliciesChanged,
                    privacyPolicyChecked: state.acceptsConditions,
                    onPrivacyPolicyChange: notifier.onAcceptsConditionsChanged,
                    dataPolicyUrl: widget.dataPolicyUrl,
                    privacyPolicyUrl: widget.privacyPolicyUrl,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        orElse: () => const Center(child: CircularProgressIndicator.adaptive()),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: 50,
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F4F4F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: asyncMun.maybeWhen(
                    data: (munDto) => ElevatedButton(
                      onPressed: state.isQueryButtonEnabled && !state.isLoading
                          ? () => notifier.onQueryClicked(
                              entityCode: munDto.entityCode,
                              taxId: widget.taxId,
                            )
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Consultar',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: scheme.onPrimary,
                              ),
                            ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Puerto del `CustomTextField` del original: relleno `surfaceContainer`,
/// radio 16 y sin línea indicadora.
class _CustomTextField extends StatefulWidget {
  const _CustomTextField({
    required this.value,
    required this.onChanged,
    required this.label,
    this.keyboardType,
    this.textInputAction,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String label;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  State<_CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<_CustomTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant _CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = _controller.value.copyWith(text: widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    );
    // Tipografía por defecto de Material (no el bodySmall del original de
    // Compose): en Flutter ese estilo se veía demasiado pequeño; prima la
    // legibilidad sobre la equivalencia 1:1.
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLines: 1,
      decoration: InputDecoration(
        labelText: widget.label,
        // La etiqueta flotante (igual que el `label` del `TextField` filled del
        // original) necesita espacio arriba al subir; con padding simétrico se
        // encimaba con el texto. Reservamos top para que no se solape.
        alignLabelWithHint: true,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: scheme.surfaceContainer,
        border: border,
        enabledBorder: border,
        focusedBorder: border,
        contentPadding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      ),
    );
  }
}
