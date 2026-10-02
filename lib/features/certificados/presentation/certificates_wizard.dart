import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:tramiapp_flutter/core/router/app_routes.dart';
import 'package:tramiapp_flutter/core/municipality/municipality_repository.dart';
import 'package:tramiapp_flutter/core/models/tipo_documento.dart';
import 'package:tramiapp_flutter/core/widgets/step_indicator.dart';
import 'package:tramiapp_flutter/core/widgets/top_bar_navigation.dart';
import '../application/certificates_notifier.dart';
import '../domain/certificates_state.dart';

class CertificatesWizard extends ConsumerStatefulWidget {
  const CertificatesWizard({
    required this.municipalityId,
    required this.entityCode,
    required this.procedureId,
    required this.integrationType,
    super.key,
  });

  final int municipalityId;
  final String entityCode;
  final int procedureId;
  final String integrationType; // corresponds to payValue (cost)

  @override
  ConsumerState<CertificatesWizard> createState() => _CertificatesWizardState();
}

class _CertificatesWizardState extends ConsumerState<CertificatesWizard> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

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

  late CertificatesFamilyParam _param;

  @override
  void initState() {
    super.initState();
    _param = CertificatesFamilyParam(
      taxId: widget.procedureId,
      entityCode: widget.entityCode,
      payValue: widget.integrationType,
    );

    // Initial pre-population
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(certificatesNotifierProvider(_param));
      _updateControllers(state);
    });
  }

  void _updateControllers(CertificatesUiState state) {
    _identificacionCtrl.text = state.identificacion;
    _primerNombreCtrl.text = state.primerNombre;
    _segundoNombreCtrl.text = state.segundoNombre;
    _primerApellidoCtrl.text = state.primerApellido;
    _segundoApellidoCtrl.text = state.segundoApellido;
    _correoCtrl.text = state.correoElectronico;
    _direccionCtrl.text = state.direccion;
    _celularCtrl.text = state.telefonoCelular;
    _ageCtrl.text = state.age;
    _descripcionCtrl.text = state.descripcion;
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
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);
        final sizeBytes = await file.length();

        // 10 MB Limit
        if (sizeBytes > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('El archivo excede el tamaño máximo de 10 MB.'),
              ),
            );
          }
          return;
        }

        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        final name = result.files.single.name;
        final extension = result.files.single.extension;
        final mimeType = _getMimeType(extension);

        notifier.onFileSelected(
          name: name,
          mimeType: mimeType,
          base64Content: base64String,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar archivo: $e')),
        );
      }
    }
  }

  String? _getMimeType(String? extension) {
    if (extension == null) return null;
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncMun = ref.watch(municipalityProvider(widget.municipalityId));
    final state = ref.watch(certificatesNotifierProvider(_param));
    final notifier = ref.read(certificatesNotifierProvider(_param).notifier);
    final responseState = ref.watch(certificatesResponseStateProvider);

    // Sync input text controllers with notifier state updates (e.g. from autofill)
    ref.listen<CertificatesUiState>(certificatesNotifierProvider(_param), (
      previous,
      next,
    ) {
      if (previous == null || previous.identificacion != next.identificacion) {
        if (_identificacionCtrl.text != next.identificacion) {
          _identificacionCtrl.text = next.identificacion;
        }
      }
      if (previous == null || previous.primerNombre != next.primerNombre) {
        if (_primerNombreCtrl.text != next.primerNombre) {
          _primerNombreCtrl.text = next.primerNombre;
        }
      }
      if (previous == null || previous.segundoNombre != next.segundoNombre) {
        if (_segundoNombreCtrl.text != next.segundoNombre) {
          _segundoNombreCtrl.text = next.segundoNombre;
        }
      }
      if (previous == null || previous.primerApellido != next.primerApellido) {
        if (_primerApellidoCtrl.text != next.primerApellido) {
          _primerApellidoCtrl.text = next.primerApellido;
        }
      }
      if (previous == null ||
          previous.segundoApellido != next.segundoApellido) {
        if (_segundoApellidoCtrl.text != next.segundoApellido) {
          _segundoApellidoCtrl.text = next.segundoApellido;
        }
      }
      if (previous == null ||
          previous.correoElectronico != next.correoElectronico) {
        if (_correoCtrl.text != next.correoElectronico) {
          _correoCtrl.text = next.correoElectronico;
        }
      }
      if (previous == null || previous.direccion != next.direccion) {
        if (_direccionCtrl.text != next.direccion) {
          _direccionCtrl.text = next.direccion;
        }
      }
      if (previous == null ||
          previous.telefonoCelular != next.telefonoCelular) {
        if (_celularCtrl.text != next.telefonoCelular) {
          _celularCtrl.text = next.telefonoCelular;
        }
      }
      if (previous == null || previous.age != next.age) {
        if (_ageCtrl.text != next.age) {
          _ageCtrl.text = next.age;
        }
      }
      if (previous == null || previous.descripcion != next.descripcion) {
        if (_descripcionCtrl.text != next.descripcion) {
          _descripcionCtrl.text = next.descripcion;
        }
      }
    });

    // Listen for submission responses
    ref.listen<CertificatesResponseState>(certificatesResponseStateProvider, (
      prev,
      next,
    ) {
      if (next is CertificatesResponseSuccess) {
        ref.read(certificatesResponseStateProvider.notifier).reset();
        // Redirect to WebView processing screen
        context.push(
          AppRoutes.pagosProcessingPath(widget.municipalityId),
          extra: {
            'url': next.urlTransaction,
            'reference': next.reference,
            'entityCode': widget.entityCode,
            'taxId': widget.procedureId.toString(),
          },
        );
      } else if (next is CertificatesResponseError) {
        ref.read(certificatesResponseStateProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.red),
        );
      }
    });

    final title = state.titleCertificate ?? 'Certificado';
    final isReady =
        asyncMun.hasValue &&
        !state.isLoading &&
        responseState is! CertificatesResponseLoading;

    return PopScope(
      canPop: state.currentStep == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          notifier.onPreviousStep();
        }
      },
      // Cabecera compartida `TopbarNavigation` del original (franja primaria con
      // insignia del certificado, título y descripción, que colapsa al hacer
      // scroll). Antes era un `AppBar` plano con la flecha por defecto.
      child: TopBarNavigationScaffold(
        iconAsset:
            state.certificateIconPath ?? 'assets/images/icocertresidencia.svg',
        title: title,
        description: 'Pide, paga y recibe tu certificado.',
        onBack: () {
          if (state.currentStep == 1) {
            context.pop();
          } else {
            notifier.onPreviousStep();
          }
        },
        bottomBar: isReady ? _buildBottomButtons(state, notifier) : null,
        body: !isReady
            ? const SizedBox(
                height: 280,
                child: Center(child: CircularProgressIndicator()),
              )
            : GestureDetector(
                // Toque fuera de los campos = cerrar teclado, igual que el
                // `clickable { focusManager.clearFocus() }` del original.
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).unfocus(),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StepIndicator(currentStep: state.currentStep),
                      const SizedBox(height: 24),
                      if (state.currentStep == 1) _buildStep1(state, notifier),
                      if (state.currentStep == 2) _buildStep2(state, notifier),
                      if (state.currentStep == 3) _buildStep3(state, notifier),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStep1(CertificatesUiState state, CertificatesNotifier notifier) {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Datos Básicos de la Solicitud',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TipoDocumento>(
            decoration: const InputDecoration(
              labelText: 'Tipo de documento*',
              border: OutlineInputBorder(),
            ),
            initialValue: state.tipoDocumento,
            items: state.listTipoDocumento
                .map(
                  (t) => DropdownMenuItem<TipoDocumento>(
                    value: t,
                    child: Text(t.descripcion),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                notifier.onTipoDocumentoChange(val);
              }
            },
            validator: (v) => v == null ? 'Seleccione tipo de documento' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _identificacionCtrl,
            decoration: const InputDecoration(
              labelText: 'Identificación*',
              border: OutlineInputBorder(),
            ),
            keyboardType: _getKeyboardType(state.tipoDocumento?.descripcion),
            onChanged: notifier.onIdentificacionChange,
            validator: (v) => notifier.validateIdentificacion(v ?? ''),
          ),
          if (state.procedureId == 269) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageCtrl,
              decoration: InputDecoration(
                labelText: 'Edad*',
                border: const OutlineInputBorder(),
                errorText: state.ageError,
              ),
              keyboardType: TextInputType.number,
              onChanged: notifier.onAgeChange,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'La edad es requerida';
                }
                final ageInt = int.tryParse(v);
                if (ageInt == null || ageInt < 0 || ageInt > 120) {
                  return 'Introduzca una edad válida (0-120)';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _primerNombreCtrl,
            decoration: const InputDecoration(
              labelText: 'Primer nombre*',
              border: OutlineInputBorder(),
            ),
            onChanged: notifier.onPrimerNombreChange,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'El primer nombre es requerido'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _segundoNombreCtrl,
            decoration: const InputDecoration(
              labelText: 'Segundo nombre',
              border: OutlineInputBorder(),
            ),
            onChanged: notifier.onSegundoNombreChange,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _primerApellidoCtrl,
            decoration: const InputDecoration(
              labelText: 'Primer apellido*',
              border: OutlineInputBorder(),
            ),
            onChanged: notifier.onPrimerApellidoChange,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'El primer apellido es requerido'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _segundoApellidoCtrl,
            decoration: const InputDecoration(
              labelText: 'Segundo apellido',
              border: OutlineInputBorder(),
            ),
            onChanged: notifier.onSegundoApellidoChange,
          ),
          const SizedBox(height: 8),
          const Text(
            'Los campos con * son obligatorios',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  TextInputType _getKeyboardType(String? docType) {
    if (docType == null) return TextInputType.number;
    final lower = docType.toLowerCase();
    if (lower.contains('pasaporte') ||
        lower.contains('nit') ||
        lower.contains('visa')) {
      return TextInputType.text;
    }
    return TextInputType.number;
  }

  Widget _buildStep2(CertificatesUiState state, CertificatesNotifier notifier) {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Información de Contacto y Soporte',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _correoCtrl,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico*',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: notifier.correoElectronicoChange,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'El correo electrónico es requerido';
              }
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(v)) {
                return 'Ingrese un correo electrónico válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _direccionCtrl,
            decoration: const InputDecoration(
              labelText: 'Dirección',
              border: OutlineInputBorder(),
            ),
            onChanged: notifier.onDireccionChange,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _celularCtrl,
            decoration: const InputDecoration(
              labelText: 'Teléfono celular*',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            onChanged: notifier.onTelefonoCelularChange,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'El teléfono celular es requerido';
              }
              if (v.trim().length != 10) {
                return 'Ingrese un número válido de 10 dígitos';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descripcionCtrl,
            decoration: const InputDecoration(
              labelText: 'Descripción*',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            onChanged: notifier.onDescripcionChange,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'La descripción no puede estar vacía'
                : null,
          ),
          const SizedBox(height: 20),
          const Text(
            'Documento de soporte (Opcional - Máx. 10 MB, solo PDF o imágenes)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (state.nombreArchivo == null)
            OutlinedButton.icon(
              onPressed: () => _pickFile(notifier),
              icon: const Icon(Icons.attach_file),
              label: const Text('Adjuntar documentos'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.nombreArchivo!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: notifier.clearFile,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Los campos con * son obligatorios',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(CertificatesUiState state, CertificatesNotifier notifier) {
    final valueText =
        (state.certificateValue != null && state.certificateValue!.isNotEmpty)
        ? '\$${state.certificateValue} COP'
        : '\$0 COP';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Resumen de solicitud',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryRow('Trámite:', state.titleCertificate ?? ''),
                const Divider(),
                _buildSummaryRow(
                  'Nombre:',
                  '${state.primerNombre} ${state.primerApellido}',
                ),
                const Divider(),
                _buildSummaryRow('Correo:', state.correoElectronico),
                const Divider(),
                _buildSummaryRow('Identificación:', state.identificacion),
                const Divider(),
                _buildSummaryRow('Valor a Pagar:', valueText, isBold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: state.aceptaTratamientoDatos,
              onChanged: (val) =>
                  notifier.onTratamientoDatosAcepted(val ?? false),
            ),
            const Expanded(
              child: Text(
                'Acepto la política de tratamiento de datos personales.',
                style: TextStyle(fontSize: 13, color: Colors.blue),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: state.aceptaCondicionesUso,
              onChanged: (val) =>
                  notifier.onCondicionesUsoAcepted(val ?? false),
            ),
            const Expanded(
              child: Text(
                'Acepto las Condiciones de Uso y las políticas de privacidad.',
                style: TextStyle(fontSize: 13, color: Colors.blue),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.red[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info, color: Colors.white, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Importante',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Al seleccionar "Finalizar", será llevado a la pasarela de pagos donde podrá finalizar la transacción de forma segura. Asegúrese de revisar que los datos y el valor a pagar sean correctos.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? Colors.black : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(
    CertificatesUiState state,
    CertificatesNotifier notifier,
  ) {
    final showBack = state.currentStep > 1;
    final isSubmit = state.currentStep == 3;
    final isSubmitEnabled =
        state.aceptaTratamientoDatos && state.aceptaCondicionesUso;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          if (showBack) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: notifier.onPreviousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Atrás'),
              ),
            ),
            const SizedBox(width: 16),
          ] else ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[350]!),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (state.currentStep == 1) {
                  if (_formKey1.currentState!.validate()) {
                    notifier.onNextStep();
                  }
                } else if (state.currentStep == 2) {
                  if (_formKey2.currentState!.validate()) {
                    notifier.onNextStep();
                  }
                } else {
                  if (isSubmitEnabled) {
                    notifier.submitSolicitudTramite();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: isSubmit
                    ? (isSubmitEnabled ? Colors.green[600] : Colors.grey[300])
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(isSubmit ? 'Finalizar' : 'Siguiente'),
            ),
          ),
        ],
      ),
    );
  }
}
