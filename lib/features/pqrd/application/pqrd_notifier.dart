import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/services/api_providers.dart';
import '../../../core/models/user_dto.dart';
import '../../../core/models/pqrd_anonima_post.dart';
import '../../../core/models/pqrd_identificacion_post.dart';
import '../../../core/models/response_pqrd.dart';
import '../../../core/models/ciudadano.dart';
import '../../../core/models/documentos.dart';
import '../../../core/models/tipo_documento.dart';
import '../../../core/models/secretaria.dart';
import '../../../core/models/asunto_interes.dart';
import '../../../core/models/clasificacion_solicitud.dart';
import '../../../core/models/tipo_solicitante.dart';
import '../../../core/models/atencion_preferencial.dart';
import '../../../core/models/medio_respuesta.dart';
import '../../../core/models/grupo_interes_pqrd.dart';
import '../../../core/models/discapacidad_pqrd.dart';
import '../../../core/models/grupo_etnico_pqrd.dart';
import '../../../core/models/genero_pqrd.dart';
import '../../../core/models/rango_edad_pqrd.dart';
import '../../../core/models/actividad_economica_pqrd.dart';
import '../../../core/models/nivel_estrato_pqrd.dart';
import '../../../core/models/nivel_sisben_pqrd.dart';
import '../../../core/models/escolaridad_pqrd.dart';
import '../../../core/models/vulnerabilidad_pqrd.dart';
import '../../../core/models/departamento.dart';
import '../../auth/application/auth_providers.dart';
import '../data/pqrd_repository.dart';
import '../domain/pqrd_state.dart';

final pqrdRepositoryProvider = Provider<PqrdRepository>((ref) {
  return PqrdRepository(
    ref.watch(pqrdApiServiceProvider),
    ref.watch(generalesApiServiceProvider),
  );
});

class PqrdDropdownOptionsNotifier extends Notifier<PqrdDropdownOptionsState> {
  @override
  PqrdDropdownOptionsState build() {
    return const PqrdDropdownOptionsState();
  }

  PqrdRepository get _repository => ref.read(pqrdRepositoryProvider);

  Future<void> loadCatalogData(String codigoEntidad) async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        _repository.listSecretariaEntidad(codigoEntidad),
        _repository.listAsuntoInteres(codigoEntidad),
        _repository.listClasificacionSolicitud(codigoEntidad),
        _repository.listTipoSolicitante(codigoEntidad),
        _repository.listAtencionPreferencial(codigoEntidad),
        _repository.listMedioRespuesta(codigoEntidad),
        _repository.listTipoDocumento(codigoEntidad),
        _repository.getListGrupoInteresPQRD(codigoEntidad),
        _repository.listDiscapacidadPQRD(codigoEntidad),
        _repository.getListGrupoEtnicoPQRD(codigoEntidad),
        _repository.listGeneroPQRD(codigoEntidad),
        _repository.listRangoEdadPQRD(codigoEntidad),
        _repository.listActividadEconomicaPQRD(codigoEntidad),
        _repository.listNivelEstratoPQRD(codigoEntidad),
        _repository.listNivelSisbenPQRD(codigoEntidad),
        _repository.listEscolaridadPQRD(codigoEntidad),
        _repository.listVulnerabilidadPQRD(codigoEntidad),
        _repository.getDepartamentos(),
      ]);

      state = PqrdDropdownOptionsState(
        secretarias: (results[0] as List).cast<Secretaria>(),
        asuntosInteres: (results[1] as List).cast<AsuntoInteres>(),
        clasificacionesSolicitud: (results[2] as List).cast<ClasificacionSolicitud>(),
        tiposSolicitante: (results[3] as List).cast<TipoSolicitante>(),
        atencionesPreferenciales: (results[4] as List).cast<AtencionPreferencial>(),
        mediosRespuesta: (results[5] as List).cast<MedioRespuesta>(),
        tiposDocumento: (results[6] as List).cast<TipoDocumento>(),
        gruposInteres: (results[7] as List).cast<GrupoInteresPQRD>(),
        discapacidades: (results[8] as List).cast<DiscapacidadPQRD>(),
        gruposEtnicos: (results[9] as List).cast<GrupoEtnicoPQRD>(),
        generos: (results[10] as List).cast<GeneroPQRD>(),
        rangosEdad: (results[11] as List).cast<RangoEdadPQRD>(),
        actividadesEconomicas: (results[12] as List).cast<ActividadEconomicaPQRD>(),
        nivelesEstrato: (results[13] as List).cast<NivelEstratoPQRD>(),
        nivelesSisben: (results[14] as List).cast<NivelSisbenPQRD>(),
        escolaridades: (results[15] as List).cast<EscolaridadPQRD>(),
        vulnerabilidades: (results[16] as List).cast<VulnerabilidadPQRD>(),
        departamentos: (results[17] as List).cast<Departamento>(),
        isLoading: false,
      );

      final user = ref.read(sessionProvider);
      if (user != null) {
        ref.read(pqrdFormStateProvider.notifier).autofill(user, state);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadCiudades(int departamentoId) async {
    state = state.copyWith(isLoadingCiudades: true);
    try {
      final list = await _repository.getCiudadesPorDepartamento(departamentoId.toString());
      state = state.copyWith(ciudades: list, isLoadingCiudades: false);
    } catch (e) {
      state = state.copyWith(isLoadingCiudades: false);
    }
  }
}

final pqrdDropdownOptionsProvider =
    NotifierProvider<PqrdDropdownOptionsNotifier, PqrdDropdownOptionsState>(PqrdDropdownOptionsNotifier.new);

class PqrdFormStateNotifier extends Notifier<PqrdFormState> {
  @override
  PqrdFormState build() {
    return const PqrdFormState();
  }

  PqrdRepository get _repository => ref.read(pqrdRepositoryProvider);

  void updateField(PqrdFormState Function(PqrdFormState) updater) {
    state = updater(state);
  }

  void autofill(UserDTO user, PqrdDropdownOptionsState dropdowns) {
    final typeDocs = dropdowns.tiposDocumento;
    TipoDocumento? typeDoc;
    for (final d in typeDocs) {
      if (d.descripcion.toLowerCase() == user.documentType.name.toLowerCase()) {
        typeDoc = d;
        break;
      }
    }
    if (typeDoc == null && typeDocs.isNotEmpty) {
      typeDoc = typeDocs.first;
    }

    state = state.copyWith(
      identificacion: user.nationalId,
      primerNombre: user.firstName,
      segundoNombre: user.middleName ?? '',
      primerApellido: user.lastName,
      segundoApellido: user.secondLastName ?? '',
      correoElectronico: user.email,
      direccion: user.address,
      telefonoCelular: user.phoneNumber,
      tipoDocumento: typeDoc,
    );
  }

  Future<ResponsePQRD> submitAnonima(String entityCode) async {
    final docObj = Documentos(
      contentType: state.tipoArchivo ?? '',
      documentos: state.contenidoArchivoBase64 ?? '',
      nombreArchivo: state.nombreArchivo ?? '',
    );
    final body = PqrdAnonimaPost(
      codigoEntidad: entityCode,
      descripcion: state.descripcion,
      documentos: docObj,
      idAsuntoInteres: state.asuntoInteres?.id ?? 0,
      idcLasificacion: state.clasificacionSolicitud?.id ?? 0,
      idSecretaria: state.secretaria?.idSecretaria ?? 0,
    );
    return _repository.insertPQRDAnonima(body);
  }

  Future<ResponsePQRD> submitIdentificada(String entityCode) async {
    final docObj = Documentos(
      contentType: state.tipoArchivo ?? '',
      documentos: state.contenidoArchivoBase64 ?? '',
      nombreArchivo: state.nombreArchivo ?? '',
    );
    final ciudadanoObj = Ciudadano(
      direccion: state.direccion,
      email: state.correoElectronico,
      identificacion: state.identificacion,
      primerApellido: state.primerApellido,
      primerNombre: state.primerNombre,
      segundoApellido: state.segundoApellido,
      segundoNombre: state.segundoNombre,
      telefono: state.telefonoCelular.isNotEmpty ? state.telefonoCelular : state.telefonoFijo,
      tipoDocumento: state.tipoDocumento?.id ?? 0,
    );
    final body = PqrdIdentificacionPost(
      atencionEspecial: state.atencionPreferencial != null,
      ciudad: state.ciudad?.id.toString() ?? '',
      ciudadano: ciudadanoObj,
      codigoEntidad: entityCode,
      departamento: state.departamento?.id.toString() ?? '',
      descripcion: state.descripcion,
      documentos: docObj,
      iDActividadEconomica: state.actividadEconomica?.id ?? 0,
      iDAsunto: state.asuntoInteres?.id ?? 0,
      iDAtencionEspecial: state.atencionPreferencial?.id ?? 0,
      iDAtencionPreferencial: state.atencionPreferencial?.id ?? 0,
      iDClasificacion: state.clasificacionSolicitud?.id ?? 0,
      iDDiscapacidad: state.discapacidad?.id ?? 0,
      iDEscolaridad: state.escolaridad?.id ?? 0,
      iDGenero: state.genero?.id ?? 0,
      iDGrupoEtnico: state.grupoEtnico?.id ?? 0,
      iDGrupoInteres: state.grupoInteres?.id ?? 0,
      iDMedioRespuesta: state.medioRespuesta?.id ?? 0,
      iDNivelExtrato: state.nivelEstrato?.id ?? 0,
      iDNivelSisben: state.nivelSisben?.id ?? 0,
      iDRangoEdad: state.rangoEdad?.id ?? 0,
      iDSecretaria: state.secretaria?.idSecretaria ?? 0,
      iDTipoSolicitante: state.tipoSolicitante?.id ?? 0,
      iDVulnerabilidad: state.vulnerabilidad?.id ?? 0,
      pais: state.pais.isNotEmpty ? state.pais : 'Colombia',
      razonSocial: state.razonSocial,
      recepcion: state.medioRespuesta?.descripcion ?? 'Correo Electronico',
    );
    return _repository.insertPQRDIdentificacion(body);
  }
}

final pqrdFormStateProvider = NotifierProvider<PqrdFormStateNotifier, PqrdFormState>(PqrdFormStateNotifier.new);
