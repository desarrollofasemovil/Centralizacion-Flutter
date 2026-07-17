// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import 'package:tramiapp_flutter/core/municipality/municipality_repository.dart';
import '../application/pqrd_notifier.dart';
import '../domain/pqrd_state.dart';

class PqrdWizard extends ConsumerStatefulWidget {
  const PqrdWizard({required this.municipalityId, required this.isAnonymous, super.key});
  final int municipalityId;
  final bool isAnonymous;

  @override
  ConsumerState<PqrdWizard> createState() => _PqrdWizardState();
}

class _PqrdWizardState extends ConsumerState<PqrdWizard> {
  int _currentStep = 1;
  bool _isSubmitting = false;
  // Evita re-disparar la carga de catálogos en cada rebuild.
  bool _catalogRequested = false;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  // Text controllers for step 2 (Identified only)
  final _identificacionCtrl = TextEditingController();
  final _primerNombreCtrl = TextEditingController();
  final _segundoNombreCtrl = TextEditingController();
  final _primerApellidoCtrl = TextEditingController();
  final _segundoApellidoCtrl = TextEditingController();

  // Text controllers for step 3
  final _razonSocialCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _celularCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  @override
  void dispose() {
    _identificacionCtrl.dispose();
    _primerNombreCtrl.dispose();
    _segundoNombreCtrl.dispose();
    _primerApellidoCtrl.dispose();
    _segundoApellidoCtrl.dispose();
    _razonSocialCtrl.dispose();
    _correoCtrl.dispose();
    _direccionCtrl.dispose();
    _celularCtrl.dispose();
    _telefonoCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Pre-populate fields once states are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final form = ref.read(pqrdFormStateProvider);
      _identificacionCtrl.text = form.identificacion;
      _primerNombreCtrl.text = form.primerNombre;
      _segundoNombreCtrl.text = form.segundoNombre;
      _primerApellidoCtrl.text = form.primerApellido;
      _segundoApellidoCtrl.text = form.segundoApellido;
      _razonSocialCtrl.text = form.razonSocial;
      _correoCtrl.text = form.correoElectronico;
      _direccionCtrl.text = form.direccion;
      _celularCtrl.text = form.telefonoCelular;
      _telefonoCtrl.text = form.telefonoFijo;
      _descripcionCtrl.text = form.descripcion;
    });
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xls', 'xlsx', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'pdf', 'rar', 'zip'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        final fileName = result.files.single.name;
        final fileType = result.files.single.extension;

        ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(
              nombreArchivo: fileName,
              tipoArchivo: fileType,
              contenidoArchivoBase64: base64String,
            ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar archivo: $e')),
      );
    }
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_formKey1.currentState!.validate()) {
        setState(() {
          _currentStep = widget.isAnonymous ? 3 : 2;
        });
      }
    } else if (_currentStep == 2) {
      if (_formKey2.currentState!.validate()) {
        // Save fields to form state
        ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(
              identificacion: _identificacionCtrl.text.trim(),
              primerNombre: _primerNombreCtrl.text.trim(),
              segundoNombre: _segundoNombreCtrl.text.trim(),
              primerApellido: _primerApellidoCtrl.text.trim(),
              segundoApellido: _segundoApellidoCtrl.text.trim(),
            ));
        setState(() {
          _currentStep = 3;
        });
      }
    }
  }

  void _prevStep() {
    setState(() {
      _currentStep = (widget.isAnonymous && _currentStep == 3) ? 1 : _currentStep - 1;
    });
  }

  Future<void> _submitForm(String entityCode) async {
    if (!_formKey3.currentState!.validate()) return;

    final form = ref.read(pqrdFormStateProvider);
    if (!form.aceptaTratamientoDatos || !form.aceptaCondicionesUso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe aceptar las políticas y condiciones para continuar.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Save fields
    ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(
          razonSocial: _razonSocialCtrl.text.trim(),
          correoElectronico: _correoCtrl.text.trim(),
          direccion: _direccionCtrl.text.trim(),
          telefonoCelular: _celularCtrl.text.trim(),
          telefonoFijo: _telefonoCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim(),
        ));

    try {
      final res = widget.isAnonymous
          ? await ref.read(pqrdFormStateProvider.notifier).submitAnonima(entityCode)
          : await ref.read(pqrdFormStateProvider.notifier).submitIdentificada(entityCode);

      setState(() {
        _isSubmitting = false;
      });

      if (res.estado) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Registro Exitoso'),
              content: Text('Su solicitud ha sido radicada correctamente.\nTicket/Radicado: ${res.ticket}'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/municipality/${widget.municipalityId}');
                  },
                  child: const Text('Aceptar'),
                )
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al radicar solicitud.')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocurrió un error en la red: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final asyncMun = ref.watch(municipalityProvider(widget.municipalityId));
    final dropdowns = ref.watch(pqrdDropdownOptionsProvider);

    // Carga los catálogos de los selects (por CodigoEntidad, BACKEND §3.16) en
    // cuanto el municipio está disponible. Sin esto los dropdowns quedaban vacíos.
    final munForCatalog = asyncMun.asData?.value;
    if (munForCatalog != null && !_catalogRequested) {
      _catalogRequested = true;
      Future.microtask(() => ref
          .read(pqrdDropdownOptionsProvider.notifier)
          .loadCatalogData(munForCatalog.entityCode));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAnonymous ? 'PQRSDF Anónima' : 'PQRSDF Identificada'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      body: asyncMun.maybeWhen(
        data: (munDto) {
          if (dropdowns.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStepIndicator(scheme),
                const SizedBox(height: 24),
                if (_currentStep == 1) _buildStep1(dropdowns),
                if (_currentStep == 2) _buildStep2(dropdowns),
                if (_currentStep == 3) _buildStep3(dropdowns),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 1)
                      OutlinedButton(
                        onPressed: _prevStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Atrás'),
                      )
                    else
                      const SizedBox.shrink(),
                    _isSubmitting
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _currentStep == 3 ? () => _submitForm(munDto.entityCode) : _nextStep,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text(_currentStep == 3 ? 'Radicar' : 'Siguiente'),
                          ),
                  ],
                ),
              ],
            ),
          );
        },
        orElse: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildStepIndicator(ColorScheme scheme) {
    final steps = widget.isAnonymous ? 2 : 3;
    final displayStep = (widget.isAnonymous && _currentStep == 3) ? 2 : _currentStep;

    return Row(
      children: List.generate(steps * 2 - 1, (index) {
        if (index.isEven) {
          final stepNum = index ~/ 2 + 1;
          final isActive = stepNum <= displayStep;
          return CircleAvatar(
            radius: 16,
            backgroundColor: isActive ? scheme.primary : Colors.grey[300],
            foregroundColor: isActive ? scheme.onPrimary : Colors.black87,
            child: Text('$stepNum', style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        } else {
          return Expanded(
            child: Container(
              height: 2,
              color: Colors.grey[300],
            ),
          );
        }
      }),
    );
  }

  Widget _buildStep1(PqrdDropdownOptionsState dropdowns) {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Información Básica del Trámite', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Secretaría
          DropdownButtonFormField<dynamic>(
            decoration: const InputDecoration(labelText: 'Secretaría Destino', border: OutlineInputBorder()),
            value: ref.read(pqrdFormStateProvider).secretaria,
            items: dropdowns.secretarias.map((s) => DropdownMenuItem(value: s, child: Text(s.secretaria))).toList(),
            onChanged: (val) {
              ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(secretaria: val));
            },
            validator: (v) => v == null ? 'Seleccione una Secretaría' : null,
          ),
          const SizedBox(height: 16),
          // Asunto
          DropdownButtonFormField<dynamic>(
            decoration: const InputDecoration(labelText: 'Asunto de Interés', border: OutlineInputBorder()),
            value: ref.read(pqrdFormStateProvider).asuntoInteres,
            items: dropdowns.asuntosInteres.map((s) => DropdownMenuItem(value: s, child: Text(s.descripcion))).toList(),
            onChanged: (val) {
              ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(asuntoInteres: val));
            },
            validator: (v) => v == null ? 'Seleccione un Asunto' : null,
          ),
          const SizedBox(height: 16),
          // Clasificación
          DropdownButtonFormField<dynamic>(
            decoration: const InputDecoration(labelText: 'Clasificación de Solicitud', border: OutlineInputBorder()),
            value: ref.read(pqrdFormStateProvider).clasificacionSolicitud,
            items: dropdowns.clasificacionesSolicitud.map((s) => DropdownMenuItem(value: s, child: Text(s.descripcion))).toList(),
            onChanged: (val) {
              ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(clasificacionSolicitud: val));
            },
            validator: (v) => v == null ? 'Seleccione una Clasificación' : null,
          ),
          const SizedBox(height: 16),
          if (!widget.isAnonymous) ...[
            // Tipo Solicitante
            DropdownButtonFormField<dynamic>(
              decoration: const InputDecoration(labelText: 'Tipo de Solicitante', border: OutlineInputBorder()),
              value: ref.read(pqrdFormStateProvider).tipoSolicitante,
              items: dropdowns.tiposSolicitante.map((s) => DropdownMenuItem(value: s, child: Text(s.descripcion))).toList(),
              onChanged: (val) {
                ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(tipoSolicitante: val));
              },
              validator: (v) => v == null ? 'Seleccione Tipo de Solicitante' : null,
            ),
            const SizedBox(height: 16),
            // Atención Preferencial
            DropdownButtonFormField<dynamic>(
              decoration: const InputDecoration(labelText: 'Atención Preferencial', border: OutlineInputBorder()),
              value: ref.read(pqrdFormStateProvider).atencionPreferencial,
              items: dropdowns.atencionesPreferenciales.map((s) => DropdownMenuItem(value: s, child: Text(s.descripcion))).toList(),
              onChanged: (val) {
                ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(atencionPreferencial: val));
              },
              validator: (v) => v == null ? 'Seleccione Atención Preferencial' : null,
            ),
            const SizedBox(height: 16),
          ],
          // Medio de Respuesta
          DropdownButtonFormField<dynamic>(
            decoration: const InputDecoration(labelText: 'Medio de Respuesta', border: OutlineInputBorder()),
            value: ref.read(pqrdFormStateProvider).medioRespuesta,
            items: dropdowns.mediosRespuesta.map((s) => DropdownMenuItem(value: s, child: Text(s.descripcion))).toList(),
            onChanged: (val) {
              ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(medioRespuesta: val));
            },
            validator: (v) => v == null ? 'Seleccione un Medio de Respuesta' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(PqrdDropdownOptionsState dropdowns) {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Datos del Solicitante', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<dynamic>(
            decoration: const InputDecoration(labelText: 'Tipo de Documento', border: OutlineInputBorder()),
            value: ref.read(pqrdFormStateProvider).tipoDocumento,
            items: dropdowns.tiposDocumento.map((s) => DropdownMenuItem(value: s, child: Text(s.descripcion))).toList(),
            onChanged: (val) {
              ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(tipoDocumento: val));
            },
            validator: (v) => v == null ? 'Seleccione Tipo Documento' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _identificacionCtrl,
            decoration: const InputDecoration(labelText: 'Número de Identificación', border: OutlineInputBorder()),
            validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese la identificación' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _primerNombreCtrl,
            decoration: const InputDecoration(labelText: 'Primer Nombre', border: OutlineInputBorder()),
            validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese primer nombre' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _segundoNombreCtrl,
            decoration: const InputDecoration(labelText: 'Segundo Nombre (Opcional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _primerApellidoCtrl,
            decoration: const InputDecoration(labelText: 'Primer Apellido', border: OutlineInputBorder()),
            validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese primer apellido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _segundoApellidoCtrl,
            decoration: const InputDecoration(labelText: 'Segundo Apellido (Opcional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<dynamic>(
            decoration: const InputDecoration(labelText: 'Grupo de Interés', border: OutlineInputBorder()),
            value: ref.read(pqrdFormStateProvider).grupoInteres,
            items: dropdowns.gruposInteres.map((s) => DropdownMenuItem(value: s, child: Text(s.descripcion))).toList(),
            onChanged: (val) {
              ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(grupoInteres: val));
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<dynamic>(
            decoration: const InputDecoration(labelText: 'Discapacidad', border: OutlineInputBorder()),
            value: ref.read(pqrdFormStateProvider).discapacidad,
            items: dropdowns.discapacidades.map((s) => DropdownMenuItem(value: s, child: Text(s.descripcion))).toList(),
            onChanged: (val) {
              ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(discapacidad: val));
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<dynamic>(
            decoration: const InputDecoration(labelText: 'Grupo Étnico', border: OutlineInputBorder()),
            value: ref.read(pqrdFormStateProvider).grupoEtnico,
            items: dropdowns.gruposEtnicos.map((s) => DropdownMenuItem(value: s, child: Text(s.descripcion))).toList(),
            onChanged: (val) {
              ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(grupoEtnico: val));
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<dynamic>(
            decoration: const InputDecoration(labelText: 'Género', border: OutlineInputBorder()),
            value: ref.read(pqrdFormStateProvider).genero,
            items: dropdowns.generos.map((s) => DropdownMenuItem(value: s, child: Text(s.descripcion))).toList(),
            onChanged: (val) {
              ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(genero: val));
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<dynamic>(
            decoration: const InputDecoration(labelText: 'Rango de Edad', border: OutlineInputBorder()),
            value: ref.read(pqrdFormStateProvider).rangoEdad,
            items: dropdowns.rangosEdad.map((s) => DropdownMenuItem(value: s, child: Text(s.descripcion))).toList(),
            onChanged: (val) {
              ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(rangoEdad: val));
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<dynamic>(
            decoration: const InputDecoration(labelText: 'Actividad Económica', border: OutlineInputBorder()),
            value: ref.read(pqrdFormStateProvider).actividadEconomica,
            items: dropdowns.actividadesEconomicas.map((s) => DropdownMenuItem(value: s, child: Text(s.descripcion))).toList(),
            onChanged: (val) {
              ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(actividadEconomica: val));
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<dynamic>(
            decoration: const InputDecoration(labelText: 'Estrato', border: OutlineInputBorder()),
            value: ref.read(pqrdFormStateProvider).nivelEstrato,
            items: dropdowns.nivelesEstrato.map((s) => DropdownMenuItem(value: s, child: Text(s.descripcion))).toList(),
            onChanged: (val) {
              ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(nivelEstrato: val));
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<dynamic>(
            decoration: const InputDecoration(labelText: 'Sisbén', border: OutlineInputBorder()),
            value: ref.read(pqrdFormStateProvider).nivelSisben,
            items: dropdowns.nivelesSisben.map((s) => DropdownMenuItem(value: s, child: Text(s.descripcion))).toList(),
            onChanged: (val) {
              ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(nivelSisben: val));
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<dynamic>(
            decoration: const InputDecoration(labelText: 'Escolaridad', border: OutlineInputBorder()),
            value: ref.read(pqrdFormStateProvider).escolaridad,
            items: dropdowns.escolaridades.map((s) => DropdownMenuItem(value: s, child: Text(s.descripcion))).toList(),
            onChanged: (val) {
              ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(escolaridad: val));
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<dynamic>(
            decoration: const InputDecoration(labelText: 'Vulnerabilidad', border: OutlineInputBorder()),
            value: ref.read(pqrdFormStateProvider).vulnerabilidad,
            items: dropdowns.vulnerabilidades.map((s) => DropdownMenuItem(value: s, child: Text(s.descripcion))).toList(),
            onChanged: (val) {
              ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(vulnerabilidad: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(PqrdDropdownOptionsState dropdowns) {
    final form = ref.watch(pqrdFormStateProvider);

    return Form(
      key: _formKey3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Ubicación y Descripción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: 'Colombia',
            readOnly: true,
            decoration: const InputDecoration(labelText: 'País', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<dynamic>(
            decoration: const InputDecoration(labelText: 'Departamento', border: OutlineInputBorder()),
            value: form.departamento,
            items: dropdowns.departamentos.map((s) => DropdownMenuItem(value: s, child: Text(s.nombreDepartamento))).toList(),
            onChanged: (val) {
              ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(departamento: val, ciudad: null));
              if (val != null) {
                ref.read(pqrdDropdownOptionsProvider.notifier).loadCiudades(val.id);
              }
            },
            validator: (v) => v == null ? 'Seleccione un Departamento' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<dynamic>(
            decoration: const InputDecoration(
              labelText: 'Ciudad',
              border: OutlineInputBorder(),
            ),
            value: form.ciudad,
            disabledHint: const Text('Seleccione un departamento primero'),
            items: dropdowns.ciudades.map((s) => DropdownMenuItem(value: s, child: Text(s.nombreCiudad))).toList(),
            onChanged: dropdowns.isLoadingCiudades
                ? null
                : (val) {
                    ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(ciudad: val));
                  },
            validator: (v) => v == null ? 'Seleccione una Ciudad' : null,
          ),
          if (dropdowns.isLoadingCiudades) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 16),
          if (!widget.isAnonymous) ...[
            TextFormField(
              controller: _razonSocialCtrl,
              decoration: const InputDecoration(labelText: 'Razón Social (Opcional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _correoCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese un correo electrónico' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _direccionCtrl,
              decoration: const InputDecoration(labelText: 'Dirección de Correspondencia', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese su dirección' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _celularCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono Celular', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese su celular' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono Fijo (Opcional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _descripcionCtrl,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Descripción de la Solicitud', border: OutlineInputBorder()),
            validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese una descripción' : null,
          ),
          const SizedBox(height: 24),
          const Text('Adjuntar Archivo Soporte (Máx. 10MB)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: const Text('Seleccionar Archivo'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  form.nombreArchivo ?? 'Ningún archivo seleccionado',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CheckboxListTile(
            title: const Text(
              'Acepto el tratamiento de datos personales de acuerdo con la política de privacidad.',
              style: TextStyle(fontSize: 12),
            ),
            value: form.aceptaTratamientoDatos,
            onChanged: (val) {
              ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(aceptaTratamientoDatos: val ?? false));
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            title: const Text(
              'Acepto las condiciones de uso y términos del servicio.',
              style: TextStyle(fontSize: 12),
            ),
            value: form.aceptaCondicionesUso,
            onChanged: (val) {
              ref.read(pqrdFormStateProvider.notifier).updateField((s) => s.copyWith(aceptaCondicionesUso: val ?? false));
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }
}
