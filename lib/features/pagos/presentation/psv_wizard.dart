import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:tramiapp_flutter/core/municipality/municipality_repository.dart';
import 'package:tramiapp_flutter/core/utils/formatters.dart';
import 'package:tramiapp_flutter/core/widgets/app_back_button.dart';
import 'package:tramiapp_flutter/core/widgets/policy_checkboxes.dart';
import 'package:tramiapp_flutter/core/widgets/step_indicator.dart';
import 'package:tramiapp_flutter/core/widgets/validation_error_dialog.dart';
import 'package:tramiapp_flutter/features/auth/application/auth_providers.dart';
import 'package:tramiapp_flutter/features/auth/application/signup_providers.dart';
import '../application/psv_notifier.dart';

/// Puerto fiel de `PsvScreen.kt` (+ `Step1Form`, `Step2Form`, `Step3Summary` y
/// `FormButtons`). Asistente de 3 pasos para el Pago Sin Validación (PSV).
///
/// El diseño (cabecera `primary` con badge circular, hoja redondeada,
/// [StepIndicator] con checks, campos con borde y tarjeta roja "Importante")
/// replica el original de Compose. Al pagar se registra el historial y se crea
/// la transacción, igual que `onPayClicked` del `PsvPaymentViewModel`.
class PsvWizard extends ConsumerStatefulWidget {
  const PsvWizard({
    required this.municipalityId,
    required this.taxId,
    required this.taxName,
    required this.entityCode,
    required this.dataPolicyUrl,
    required this.privacyPolicyUrl,
    super.key,
  });

  final int municipalityId;
  final int taxId;
  final String taxName;
  final String entityCode;
  final String dataPolicyUrl;
  final String privacyPolicyUrl;

  @override
  ConsumerState<PsvWizard> createState() => _PsvWizardState();
}

class _PsvWizardState extends ConsumerState<PsvWizard> {
  int _currentStep = 1;
  bool _isSubmitting = false;
  // Dirección de la transición entre pasos: true = avanzar, false = retroceder.
  bool _isForward = true;

  // --- Paso 1: datos del ciudadano ---
  int? _documentTypeId;
  String? _pendingDocTypeName; // tipo de doc del usuario, pendiente de resolver
  final _documentCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _secondNameCtrl = TextEditingController();
  final _firstLastNameCtrl = TextEditingController();
  final _secondLastNameCtrl = TextEditingController();

  // --- Paso 2: datos de pago ---
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _invoiceCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  late final TextEditingController _taxNameCtrl;
  bool _acceptsDataPolicy = false;
  bool _acceptsTerms = false;

  late final String _paymentDateTime;

  @override
  void initState() {
    super.initState();
    _paymentDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    _taxNameCtrl = TextEditingController(text: widget.taxName);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(psvFormNotifierProvider.notifier);
      notifier.reset();

      // Banco del municipio (para enrutar la pasarela), igual que loadInitialData.
      ref.read(municipalityProvider(widget.municipalityId)).whenData((mun) {
        notifier.updateField(
          (s) => s.copyWith(selectedBank: mun.bank.nameBank),
        );
      });

      // Autorrelleno con el usuario logueado (autofillUserData del original).
      final user = ref.read(sessionProvider);
      if (user != null) {
        _documentCtrl.text = user.nationalId;
        _firstNameCtrl.text = user.firstName;
        _secondNameCtrl.text = user.middleName ?? '';
        _firstLastNameCtrl.text = user.lastName;
        _secondLastNameCtrl.text = user.secondLastName ?? '';
        _emailCtrl.text = user.email;
        _phoneCtrl.text = user.phoneNumber;
        _pendingDocTypeName = user.documentType.name;
      }
      _resolvePendingDocType();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _documentCtrl.dispose();
    _firstNameCtrl.dispose();
    _secondNameCtrl.dispose();
    _firstLastNameCtrl.dispose();
    _secondLastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _invoiceCtrl.dispose();
    _amountCtrl.dispose();
    _taxNameCtrl.dispose();
    super.dispose();
  }

  /// Resuelve el id del tipo de documento del usuario contra la lista del
  /// backend cuando ésta ya está disponible.
  void _resolvePendingDocType() {
    if (_documentTypeId != null || _pendingDocTypeName == null) return;
    final list = ref.read(documentTypesProvider).value;
    if (list == null) return;
    for (final d in list) {
      if (d.name == _pendingDocTypeName) {
        _documentTypeId = d.id;
        break;
      }
    }
  }

  // --- Íconos por impuesto: 1 → predial, 2/3 → ica (when(taxId) del original) ---
  String get _taxIconAsset => switch (widget.taxId) {
    2 || 3 => 'assets/images/icoica.svg',
    _ => 'assets/images/icopredial.svg',
  };

  String get _rawAmount => _amountCtrl.text.replaceAll(RegExp(r'\D'), '');
  int get _amountValue => int.tryParse(_rawAmount) ?? 0;

  bool _emailValid(String v) =>
      RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim());

  // Validación por paso (validateForm del original).
  bool get _step1Valid =>
      _documentTypeId != null &&
      _documentCtrl.text.trim().isNotEmpty &&
      _firstNameCtrl.text.trim().isNotEmpty &&
      _firstLastNameCtrl.text.trim().isNotEmpty;

  bool get _step2Valid =>
      _emailValid(_emailCtrl.text) &&
      _phoneCtrl.text.trim().isNotEmpty &&
      _invoiceCtrl.text.trim().isNotEmpty &&
      _rawAmount.isNotEmpty &&
      _acceptsDataPolicy &&
      _acceptsTerms;

  bool get _allValid => _step1Valid && _step2Valid;

  void _onNextStep() {
    if (_currentStep < 3) {
      setState(() {
        _isForward = true;
        _currentStep++;
      });
    }
  }

  void _onPreviousStep() {
    if (_currentStep > 1) {
      setState(() {
        _isForward = false;
        _currentStep--;
      });
    }
  }

  void _onBackPressed() {
    if (_currentStep == 1) {
      context.pop();
    } else {
      _onPreviousStep();
    }
  }

  Future<void> _onPayClicked() async {
    if (!_allValid) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => ValidationErrorDialog(
          onDismiss: () => Navigator.of(dialogContext).pop(),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Datos del municipio: banco (enruta la pasarela) y procedimiento del
    // impuesto (integrationType + id para el historial).
    final mun = ref.read(municipalityProvider(widget.municipalityId)).value;
    final matches = (mun?.municipalityProcedures ?? const []).where(
      (p) => p.procedures.id == widget.taxId,
    );
    final matched = matches.isNotEmpty ? matches.first : null;
    final integrationType = matched?.integrationType ?? 'psv';
    final procedureId = matched?.id ?? 0;
    final bankName = mun?.bank.nameBank ?? '';

    final notifier = ref.read(psvFormNotifierProvider.notifier);
    final fullName =
        '${_firstNameCtrl.text.trim()} ${_firstLastNameCtrl.text.trim()}'
            .trim();
    notifier.updateField(
      (s) => s.copyWith(
        documentNumber: _documentCtrl.text.trim(),
        fullName: fullName,
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        invoiceNumber: _invoiceCtrl.text.trim(),
        amount: _amountValue,
        selectedBank: bankName.isNotEmpty ? bankName : null,
      ),
    );

    try {
      // 1. Historial de pago (createHistoryPay del original).
      await notifier.createHistoryPay(
        amount: _amountValue,
        idImpuesto: widget.taxId.toString(),
        factura: _invoiceCtrl.text.trim(),
        codigoEntidad: widget.entityCode,
        municipalityProceduresId: procedureId,
      );

      // 2. Creación de la transacción (createTransactionUseCase del original).
      final gatewayInfo = await notifier.submitPsv(
        municipalityId: widget.municipalityId,
        entityCode: widget.entityCode,
        taxId: widget.taxId,
        taxName: widget.taxName,
        integrationType: integrationType,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      context.push(
        '/municipality/${widget.municipalityId}/pagos/processing',
        extra: {'paymentUrl': gatewayInfo.url},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ocurrió un error al procesar el pago: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Mantiene vivo el notifier (autoDispose) mientras esta pantalla está
    // montada. Sin esto, al no observar su estado, el provider se desecha entre
    // pasos y las llamadas de red del paso 3 (createHistoryPay/submitPsv) lo
    // encuentran ya desechado y lanzan excepción → el pago fallaba. Observamos
    // `.notifier` (referencia estable) para no reconstruir en cada cambio.
    ref.watch(psvFormNotifierProvider.notifier);

    // Resuelve el tipo de documento del usuario en cuanto carguen los tipos.
    ref.listen(documentTypesProvider, (previous, next) {
      next.whenData((_) {
        if (_documentTypeId == null && _pendingDocTypeName != null) {
          _resolvePendingDocType();
          if (mounted) setState(() {});
        }
      });
    });

    return PopScope(
      canPop: _currentStep == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onPreviousStep();
      },
      child: Scaffold(
        backgroundColor: scheme.primary,
        body: SafeArea(
          bottom: false,
          child: NestedScrollView(
            // El topbar `primary` se colapsa al hacer scroll hacia arriba y
            // vuelve a expandirse al bajar (enterAlwaysScrollBehavior del
            // `LargeTopAppBar` original).
            floatHeaderSlivers: true,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                pinned: true,
                floating: true,
                snap: false,
                automaticallyImplyLeading: false,
                backgroundColor: scheme.primary,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                collapsedHeight: 64,
                expandedHeight: 128,
                flexibleSpace: _PsvCollapsingHeader(
                  title: 'Pago Seguros en Línea',
                  subtitle: widget.taxName,
                  iconAsset: _taxIconAsset,
                  onBack: _onBackPressed,
                ),
              ),
            ],
            body: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                color: scheme.surface,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: StepIndicator(currentStep: _currentStep),
                        ),
                        const SizedBox(height: 32),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          // Desliza el paso entrante desde la derecha al avanzar
                          // y desde la izquierda al retroceder (el saliente sale
                          // hacia el lado opuesto), dando la ilusión de avanzar/
                          // retroceder en el formulario.
                          transitionBuilder: (child, animation) {
                            final isIncoming =
                                child.key == ValueKey<int>(_currentStep);
                            final beginX = isIncoming
                                ? (_isForward ? 1.0 : -1.0)
                                : (_isForward ? -1.0 : 1.0);
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset(beginX, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          layoutBuilder: (currentChild, previousChildren) =>
                              Stack(
                                alignment: Alignment.topCenter,
                                children: [...previousChildren, ?currentChild],
                              ),
                          child: KeyedSubtree(
                            key: ValueKey<int>(_currentStep),
                            child: _buildStep(theme, scheme),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(ThemeData theme, ColorScheme scheme) {
    switch (_currentStep) {
      case 1:
        return _buildStep1(theme, scheme);
      case 2:
        return _buildStep2(theme, scheme);
      default:
        return _buildStep3(theme, scheme);
    }
  }

  // ------------------------------------------------------------------ Paso 1
  Widget _buildStep1(ThemeData theme, ColorScheme scheme) {
    final docTypes = ref.watch(documentTypesProvider).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle('Datos del ciudadano o contribuyente'),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          key: ValueKey<int?>(_documentTypeId),
          initialValue: _documentTypeId,
          isExpanded: true,
          decoration: _fieldDecoration(theme, scheme, '*Tipo de documento'),
          items: [
            for (final d in docTypes)
              DropdownMenuItem(value: d.id, child: Text(d.name)),
          ],
          onChanged: (val) => setState(() => _documentTypeId = val),
        ),
        const SizedBox(height: 12),
        _PsvTextField(
          controller: _documentCtrl,
          label: '*Número identificación',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _PsvTextField(
          controller: _firstNameCtrl,
          label: '*Primer nombre',
          inputFormatters: [_lettersOnly],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _PsvTextField(
          controller: _secondNameCtrl,
          label: 'Segundo nombre',
          inputFormatters: [_lettersOnly],
        ),
        const SizedBox(height: 12),
        _PsvTextField(
          controller: _firstLastNameCtrl,
          label: '*Primer apellido',
          inputFormatters: [_lettersOnly],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _PsvTextField(
          controller: _secondLastNameCtrl,
          label: 'Segundo apellido',
          inputFormatters: [_lettersOnly],
        ),
        const SizedBox(height: 8),
        _FormButtons(
          onCancel: () => context.pop(),
          onNext: _onNextStep,
          isNextEnabled: _step1Valid,
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ Paso 2
  Widget _buildStep2(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle('Datos de pago'),
        const SizedBox(height: 12),
        _PsvTextField(
          controller: _taxNameCtrl,
          label: '*Tipo de Impuesto',
          enabled: false,
        ),
        const SizedBox(height: 12),
        _PsvTextField(
          controller: _emailCtrl,
          label: '*Correo electrónico',
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _PsvTextField(
          controller: _phoneCtrl,
          label: '*Teléfono',
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _PsvTextField(
          controller: _invoiceCtrl,
          label: '*Número de Factura',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _PsvTextField(
          controller: _amountCtrl,
          label: '*Valor a pagar',
          keyboardType: TextInputType.number,
          prefixText: '\$ ',
          inputFormatters: [_ThousandsInputFormatter()],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        PolicyCheckboxes(
          dataPolicyChecked: _acceptsDataPolicy,
          onDataPolicyChange: (v) => setState(() => _acceptsDataPolicy = v),
          privacyPolicyChecked: _acceptsTerms,
          onPrivacyPolicyChange: (v) => setState(() => _acceptsTerms = v),
          dataPolicyUrl: widget.dataPolicyUrl,
          privacyPolicyUrl: widget.privacyPolicyUrl,
        ),
        const SizedBox(height: 8),
        _FormButtons(
          backText: 'Atras',
          onCancel: _onPreviousStep,
          onNext: _onNextStep,
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ Paso 3
  Widget _buildStep3(ThemeData theme, ColorScheme scheme) {
    final usuario =
        '${_firstNameCtrl.text.trim()} ${_firstLastNameCtrl.text.trim()}'
            .trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle('Resumen de pago'),
        const SizedBox(height: 16),
        // Tarjeta gris con el resumen.
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: const Color(0xFFF5F5F5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _SummaryRow(label: 'Trámite:', value: widget.taxName),
                const SizedBox(height: 8),
                _SummaryRow(label: 'Usuario:', value: usuario),
                const SizedBox(height: 8),
                _SummaryRow(label: 'Fecha y hora:', value: _paymentDateTime),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'No. de factura:',
                  value: _invoiceCtrl.text.trim(),
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Valor a pagar:',
                  value: formatCurrency(_amountValue),
                  isBold: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Tarjeta roja "Importante".
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFFEF5350),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Importante',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Al seleccionar "Pagar", será llevado a la pasarela de pagos '
                  'donde podrá finalizar la transacción de forma segura. '
                  'Asegúrese de revisar que los datos y el valor a pagar sean '
                  'correctos antes de continuar.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_isSubmitting)
          const Padding(
            padding: EdgeInsets.only(bottom: 50, top: 8),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          _FormButtons(
            backText: 'Atrás',
            nextText: 'Pagar',
            onCancel: _onPreviousStep,
            onNext: _onPayClicked,
          ),
      ],
    );
  }

  // -------------------------------------------------------------- decoración
  InputDecoration _fieldDecoration(
    ThemeData theme,
    ColorScheme scheme,
    String label,
  ) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );
    return InputDecoration(
      labelText: label,
      labelStyle: theme.textTheme.bodySmall,
      isDense: true,
      filled: false,
      border: border(scheme.outline),
      enabledBorder: border(scheme.outline),
      focusedBorder: border(scheme.primary),
    );
  }
}

// Solo letras y espacios (mismos filtros que onFirstNameChange del original).
final _lettersOnly = FilteringTextInputFormatter.allow(
  RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]'),
);

/// Formatea el valor con separadores de miles (punto), igual que la
/// `CurrencyVisualTransformation` del original (locale con agrupación por
/// punto). El texto crudo se recupera quitando los no-dígitos.
class _ThousandsInputFormatter extends TextInputFormatter {
  final NumberFormat _fmt = NumberFormat.decimalPattern('es_CO');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formatted = _fmt.format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Cabecera `primary` colapsable (flexibleSpace del `SliverAppBar`): botón de
/// atrás circular, badge blanco con el ícono del impuesto, título y subtítulo.
/// Al colapsar se reduce el tamaño del badge/ícono/título y se desvanece el
/// subtítulo, igual que el `LargeTopAppBar` (`scrollBehavior.collapsedFraction`)
/// del original.
class _PsvCollapsingHeader extends StatelessWidget {
  const _PsvCollapsingHeader({
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final String iconAsset;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // t: 1 = expandido, 0 = colapsado (leído del propio SliverAppBar).
    final settings = context
        .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    double t = 1;
    if (settings != null) {
      final delta = settings.maxExtent - settings.minExtent;
      if (delta > 0) {
        t = ((settings.currentExtent - settings.minExtent) / delta).clamp(
          0.0,
          1.0,
        );
      }
    }

    final badgeSize = lerpDouble(38, 52, t)!;
    final iconSize = lerpDouble(24, 32, t)!;
    final titleSize = lerpDouble(16, 20, t)!;

    // El botón de atrás queda fijo arriba (mismo sitio que `AppTopBar` y
    // `TopBarNavigationScaffold`); la fila del badge y el título se desliza
    // con el colapso a su derecha.
    return Container(
      color: scheme.primary,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppBackButton.edgeInset + AppBackButton.size + 8,
                4,
                16,
                // Colapsada (64 px, badge de 38) la fila queda centrada a la
                // altura del botón.
                13,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        iconAsset,
                        width: iconSize,
                        height: iconSize,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: titleSize,
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (t > 0.05)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Opacity(
                                opacity: t,
                                child: Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onPrimary.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: AppBackButton.edgeInset,
            top: (AppBackButton.barHeight - AppBackButton.size) / 2,
            child: AppBackButton(
              onPressed: onBack,
              style: AppBackButtonStyle.light,
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de sección centrado, en negrita y color `primary` (igual que el
/// encabezado de cada paso del original).
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

/// Campo de texto con borde redondeado (10) y relleno transparente, réplica de
/// `transparentTextFieldColors` del original.
class _PsvTextField extends StatelessWidget {
  const _PsvTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.inputFormatters,
    this.prefixText,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefixText;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.bodySmall,
        prefixText: prefixText,
        isDense: true,
        filled: false,
        border: border(scheme.outline),
        enabledBorder: border(scheme.outline),
        disabledBorder: border(scheme.outline.withValues(alpha: 0.5)),
        focusedBorder: border(scheme.primary),
      ),
    );
  }
}

/// Fila etiqueta/valor del resumen (SummaryRow del original).
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.black),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.black,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

/// Fila de dos botones (secundario + primario), réplica de `FormButtons` del
/// original: alto 50, separación 12 y padding inferior 50.
class _FormButtons extends StatelessWidget {
  const _FormButtons({
    required this.onCancel,
    required this.onNext,
    this.backText = 'Cancelar',
    this.nextText = 'Siguiente',
    this.isNextEnabled = true,
  });

  final VoidCallback onCancel;
  final VoidCallback onNext;
  final String backText;
  final String nextText;
  final bool isNextEnabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 50),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: onCancel,
                // Cancelar/Atrás: tono suave del color del municipio (versión de
                // baja emphasis del `primary`) — claramente la acción secundaria
                // frente al botón sólido de Siguiente/Pagar, sin fondo oscuro.
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  foregroundColor: scheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: scheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                child: Text(backText),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isNextEnabled ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  disabledBackgroundColor: scheme.primary.withValues(
                    alpha: 0.4,
                  ),
                  disabledForegroundColor: scheme.onPrimary.withValues(
                    alpha: 0.7,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(nextText),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
