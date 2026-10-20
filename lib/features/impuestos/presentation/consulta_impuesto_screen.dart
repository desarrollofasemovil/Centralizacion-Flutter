import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/query_field.dart';
import '../../../core/municipality/municipality_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/dialog_typography.dart';
import '../../../core/widgets/important_alert_dialog.dart';
import '../../auth/application/auth_providers.dart';
import '../../../core/widgets/outlined_form_field.dart';
import '../../../core/widgets/policy_checkboxes.dart';
import '../../../core/widgets/pqrd_dropdown.dart';
import '../../tramites/application/tramite_mappers.dart';
import '../application/tax_notifier.dart';
import '../../../core/widgets/app_top_bar.dart';

/// Textos de bienvenida de la consulta. Se alternan en cada entrada a la
/// pantalla ([TaxIntroRotation]) para que la vista se sienta cercana.
const taxIntroTexts = [
  'Consulta tus facturas de forma rápida y segura. Revisa lo que debes y '
      'paga en línea, sin filas ni desplazamientos.',
  'Consulta aquí tu factura directamente desde tu alcaldía. Tus datos están '
      'protegidos y tu pago se realiza por canales seguros.',
  'Ten tus impuestos al día en pocos pasos. Consulta tu factura, revisa el '
      'valor y paga desde donde estés.',
];

/// Elige el texto de bienvenida: avanza uno en cada entrada, así nunca se
/// repite el mismo dos veces seguidas. Vive en memoria: al reabrir la app
/// arranca en una posición al azar.
abstract final class TaxIntroRotation {
  static int? _next;

  static String next() {
    final index = _next ?? Random().nextInt(taxIntroTexts.length);
    _next = (index + 1) % taxIntroTexts.length;
    return taxIntroTexts[index];
  }

  @visibleForTesting
  static void resetTo(int? index) => _next = index;
}

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
  /// Se elige una vez por entrada a la pantalla (no en cada `build`).
  final String _introText = TaxIntroRotation.next();

  @override
  void initState() {
    super.initState();
    // Mejora sobre el original: precarga documento, correo y celular del
    // usuario logueado para no re-digitarlos.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // El municipio puede tardar en llegar: se preselecciona el tipo de
      // documento ahora o cuando carguen sus datos.
      ref.listenManual(municipalityProvider(widget.municipalityId), (_, next) {
        final queryFields = next.value?.queryFields;
        if (queryFields != null) {
          ref
              .read(taxQueryNotifierProvider.notifier)
              .preselectQueryField(queryFields);
        }
      }, fireImmediately: true);
      final user = ref.read(sessionProvider);
      if (user != null) {
        ref
            .read(taxQueryNotifierProvider.notifier)
            .prefill(
              documentNumber: user.nationalId,
              email: user.email,
              phone: user.phoneNumber,
            );
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
          extra: {
            'taxes': taxes,
            'email': next.email.trim(),
            'phone': next.phone.trim(),
          },
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
      appBar: AppTopBar(
        backgroundColor: Colors.transparent,
        onBack: () => context.pop(),
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
                    style: DialogTypography.titleMedium.copyWith(
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
                          _introText,
                          textAlign: TextAlign.justify,
                          // `bodyMedium` trae interlineado 1.0 (pensado para
                          // una sola línea): en un párrafo se vería apretado.
                          style: DialogTypography.bodyMedium.copyWith(
                            height: 1.3,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  PqrdDropdown<QueryField>(
                    // El dropdown toma el valor inicial: se recrea si cambia
                    // la selección.
                    key: ValueKey(state.selectedQueryField?.id),
                    filled: true,
                    label: 'Tipo de documento*',
                    hint: '*Tipo de documento',
                    value: state.selectedQueryField,
                    items: munDto.queryFields,
                    itemLabel: (qf) => qf.queryFieldType,
                    onChanged: (qf) {
                      if (qf != null) notifier.onDocumentTypeChanged(qf);
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedFormField(
                    value: state.documentNumber,
                    onChanged: notifier.onDocumentNumberChanged,
                    label: 'Número de documento*',
                    textInputAction: TextInputAction.next,
                  ),
                  OutlinedFormField(
                    value: state.email,
                    onChanged: notifier.onEmailChanged,
                    label: 'Correo electrónico*',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    error: state.email.isNotEmpty && !isValidEmail(state.email)
                        ? 'Ingrese un correo electrónico válido.'
                        : null,
                  ),
                  OutlinedFormField(
                    value: state.phone,
                    onChanged: notifier.onPhoneChanged,
                    label: 'Teléfono celular',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    error: state.isPhoneValid
                        ? null
                        : 'Ingrese un número de 10 dígitos.',
                  ),
                  const Text(
                    'Los campos con * son obligatorios',
                    style: DialogTypography.bodySmall,
                  ),
                  const SizedBox(height: 12),
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
                child: _filledButton(
                  label: 'Cancelar',
                  background: AppColors.gray600,
                  foreground: scheme.onPrimary,
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: asyncMun.maybeWhen(
                  data: (munDto) => _filledButton(
                    label: 'Consultar',
                    background: scheme.primary,
                    foreground: scheme.onPrimary,
                    onPressed: state.isQueryButtonEnabled && !state.isLoading
                        ? () => notifier.onQueryClicked(
                            municipalityId: widget.municipalityId,
                            entityCode: munDto.entityCode,
                            taxId: widget.taxId,
                          )
                        : null,
                    child: state.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Botón de los formularios de Certificados: relleno, sin elevación, padding
  /// 12/18 y texto `headlineMedium`.
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
}
