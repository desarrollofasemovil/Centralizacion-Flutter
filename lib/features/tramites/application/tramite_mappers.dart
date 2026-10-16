import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/models/municipality_dto.dart';
import '../../../core/models/municipality_procedure.dart';
import '../../../core/models/municipality_social_media.dart';
import '../../../core/theme/design.dart';
import '../../../core/router/app_routes.dart';
import '../../certificados/domain/certificate_procedure.dart';
import '../../municipality/domain/municipality_model.dart';
import '../domain/info_tramite.dart';
import '../domain/integration_type_model.dart';
import '../domain/procedure_identity.dart';

// New Color Palettes for Procedures from Color.kt
const List<Color> kMainProcedureColors = [
  Color(0xFFFFC3B8), // 1. Whiteish Blue
  Color(0xFFADD8E6), // 2. Light Blue
  Color(0xFFB8FFFF), // 3. Light Salmon
  Color(0xFFFFD6B0), // 4. Light Orange
  Color(0xFFFFFAB0), // 5. Light Yellow
  Color(0xFFDBFFB0), // 6. Light Lime Green
  Color(0xFFB0FFB4), // 7. Light Green
  Color(0xFFB0FFD6), // 8. Light Mint
];

const List<Color> kOtherProcedureColors = [
  Color(0xFFC2FFF1), // 9. Light Cyan
  Color(0xFFB0E7FF), // 10. Light Sky Blue
  Color(0xFFB0BEFF), // 11. Light Purple Blue
  Color(0xFFB8B0FF), // 12. Light Purple
  Color(0xFFD8B0FF), // 13. Light Magenta
  Color(0xFFF7B0FF), // 14. Light Pink
  Color(0xFFFFB0D8), // 15. Pink
  Color(0xFFFFB0B0), // 16. Light Red
];

const Color kPanicButtonColor = Color(0xFFFF4440);
const Color kSocialMediaColor = Color(0xFFFFFFFF);

// Ícono por `code` (mismo SVG que el `R.drawable.*` de DataMappers.kt); un
// código que la app no conoce usa el ícono genérico de su tipo.
String _getProcedureIcon(ProcedureIdentity identity) {
  switch (identity.code) {
    case ProcedureCodes.predial:
      return 'assets/images/icopredial.svg';
    case ProcedureCodes.ica:
      return 'assets/images/icoica.svg';
    case ProcedureCodes.declaracion:
      return 'assets/images/icodecla.svg';
    case ProcedureCodes.serviciosPublicos:
      return 'assets/images/icoservici.svg';
    case ProcedureCodes.vehiculos:
      return 'assets/images/icovehi.svg';
    case ProcedureCodes.reteIca:
      return 'assets/images/icorete.svg';
    case ProcedureCodes.pqrsdf:
      return 'assets/images/icopqrsdf.svg';
    case ProcedureCodes.botonPanico:
      return 'assets/images/icoataquepanico.svg';
    case ProcedureCodes.certResidencia:
      return 'assets/images/icocertresidencia.svg';
    case ProcedureCodes.certPazSalvo:
      return 'assets/images/icocertpazysalvo.svg';
    case ProcedureCodes.certTurismo:
      return 'assets/images/icocertourism.svg';
    case ProcedureCodes.certUsoSuelo:
      return 'assets/images/icoconceptusodelsuelo.svg';
    case ProcedureCodes.cursos:
      return 'assets/images/icocursos.svg';
    case ProcedureCodes.reservaEspacios:
      return 'assets/images/icoreservas.svg';
  }
  return switch (identity.kind) {
    ProcedureKind.tax => 'assets/images/icopredial.svg',
    ProcedureKind.certificate => kGenericCertificateIcon,
    ProcedureKind.pqrsdf => 'assets/images/icopqrsdf.svg',
    ProcedureKind.publicServices => 'assets/images/icoservici.svg',
    ProcedureKind.courses => 'assets/images/icocursos.svg',
    ProcedureKind.venues => 'assets/images/icoreservas.svg',
    ProcedureKind.panicButton => 'assets/images/icoataquepanico.svg',
    ProcedureKind.other => 'assets/images/icoportal.svg',
  };
}

// Impuestos y servicios públicos van en "Trámites"; el resto en "Otros
// trámites" (misma partición que los ids 1–14 del original).
TramiteCategory _getProcedureCategory(ProcedureKind kind) => switch (kind) {
  ProcedureKind.tax || ProcedureKind.publicServices => TramiteCategory.main,
  _ => TramiteCategory.other,
};

bool _isHttpUrl(String value) {
  final lower = value.trim().toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

void _logHidden(String procedureName, String reason) {
  if (kDebugMode) {
    debugPrint('[tramites] "$procedureName" oculto: $reason');
  }
}

String? _getSocialMediaIcon(String name) {
  final lName = name.toLowerCase();
  if (lName.contains('facebook')) return 'assets/images/icofacebook.svg';
  if (lName.contains('instagram')) return 'assets/images/icoinstagram.svg';
  if (lName.contains('youtube')) return 'assets/images/icoyoutube.svg';
  if (lName.contains('blogger')) return 'assets/images/icoblogger.svg';
  if (lName.contains('tiktok')) return 'assets/images/tiktok.svg';
  // "X" (antes Twitter) — comprobar al final para no colisionar con otras letras.
  if (lName == 'x' || lName.contains('twitter')) {
    return 'assets/images/icotwitter.svg';
  }
  return null;
}

extension MunicipalityDTOToDomain on MunicipalityDTO {
  MunicipalityModel toDomainModel() {
    final integrationModel = toIntegrationModel();

    // 1. Mapea los trámites que vienen en la lista `municipalityProcedures`
    final tramitesDesdeApi = municipalityProcedures
        .map((p) => p.toInfoTramite(this, integrationModel))
        .whereType<InfoTramite>()
        .toList();

    // 2. Mapea módulos adicionales (si existen en el JSON). Sus tiles no son
    // trámites del catálogo: se identifican por `CURSOS` / `RESERVA_ESPACIOS`.
    InfoTramite? cursosTramite;
    final cursosAction = _cursosAction();
    if (cursosAction != null) {
      const identity = ProcedureIdentity(
        kind: ProcedureKind.courses,
        code: ProcedureCodes.cursos,
      );
      cursosTramite = InfoTramite(
        nombre: "Cursos",
        icono: _getProcedureIcon(identity),
        color: Colors.transparent, // placeholder
        accion: cursosAction,
        idtramite: 8,
        isActive: courses.first.isActive,
        category: _getProcedureCategory(identity.kind),
        key: ProcedureCodes.cursos,
        kind: identity.kind,
      );
    }

    InfoTramite? sportsTramite;
    final venuesAction = _venuesAction();
    if (venuesAction != null) {
      const identity = ProcedureIdentity(
        kind: ProcedureKind.venues,
        code: ProcedureCodes.reservaEspacios,
      );
      sportsTramite = InfoTramite(
        nombre: "Reserva de espacios",
        icono: _getProcedureIcon(identity),
        color: Colors.transparent, // placeholder
        accion: venuesAction,
        idtramite: 9,
        isActive: sportsFacilities.first.isActive,
        category: _getProcedureCategory(identity.kind),
        key: ProcedureCodes.reservaEspacios,
        kind: identity.kind,
      );
    }

    // 3. Mapea las redes sociales
    final socialTramites = municipalitySocialMedia
        .map((s) => s.toInfoTramite())
        .whereType<InfoTramite>()
        .toList();

    // 4. Une todas las fuentes en una sola lista distinta por `key` (no por
    // `idtramite`: los tiles sintéticos 8/9 chocaban con trámites del catálogo
    // recreados con esos ids, p. ej. el certificado de turismo en desarrollo).
    final combinedList = <InfoTramite>[
      ...tramitesDesdeApi,
      ...socialTramites,
      // ignore: use_null_aware_elements
      if (cursosTramite != null) cursosTramite,
      // ignore: use_null_aware_elements
      if (sportsTramite != null) sportsTramite,
    ];

    final uniqueTramites = <String, InfoTramite>{};
    for (final item in combinedList) {
      uniqueTramites.putIfAbsent(item.key, () => item);
    }
    final allTramitesWithPlaceholderColor = uniqueTramites.values.toList();

    // 5. Separate by category for color assignment
    final mainTramites = allTramitesWithPlaceholderColor
        .where((t) => t.category == TramiteCategory.main)
        .toList();
    final otherTramites = allTramitesWithPlaceholderColor
        .where((t) => t.category == TramiteCategory.other)
        .toList();
    final socialTramitesFinal = allTramitesWithPlaceholderColor
        .where((t) => t.category == TramiteCategory.social)
        .toList();

    // 6. Apply dynamic color to MAIN and OTHER
    final mainTramitesColored = mainTramites.asMap().entries.map((entry) {
      final index = entry.key;
      final tramite = entry.value;
      final colorIndex = (index ~/ 3) % kMainProcedureColors.length;
      return tramite.copyWith(color: kMainProcedureColors[colorIndex]);
    }).toList();

    final otherTramitesColored = otherTramites.asMap().entries.map((entry) {
      final index = entry.key;
      final tramite = entry.value;
      if (tramite.kind == ProcedureKind.panicButton) {
        return tramite.copyWith(color: kPanicButtonColor);
      } else {
        final colorIndex = (index ~/ 3) % kOtherProcedureColors.length;
        return tramite.copyWith(color: kOtherProcedureColors[colorIndex]);
      }
    }).toList();

    // 8. Extrae la URL de noticias
    final urlNews = newsByMunicipalities.isNotEmpty
        ? newsByMunicipalities.first.url
        : "";

    // 9. Construye el modelo final
    return MunicipalityModel(
      idMunicipio: id,
      codigoEntidad: entityCode,
      nombreMunicipio: "Alcaldía de $name",
      departamento: department.name,
      design: Design.fromThemeHex(
        alcaldiaName: "Alcaldía de $name",
        shieldUrl: idShield.url,
        primaryColor: theme.primaryColor,
        secondaryColor: theme.secondaryColor,
        secondaryColorBlack: theme.secondaryColorBlack,
        onPrimaryColorLight: theme.onPrimaryColorLight,
        onPrimaryColorDark: theme.onPrimaryColorDark,
      ),
      bank: bank.nameBank,
      tipoIntegracion: integrationModel,
      newsUrl: urlNews,
      domain: domain,
      privacyPolicyUrl: dataPrivacy ?? "",
      dataPolicyUrl: dataProcessingPrivacy ?? "",
      tramitesPrincipales: mainTramitesColored,
      otrosTramites: otherTramitesColored,
      socialLinks: socialTramitesFinal,
      municipalityProcedures: municipalityProcedures,
      latitude: double.tryParse(latitude ?? ""),
      longitude: double.tryParse(longitude ?? ""),
      emailMunicipality: emailMunicipalities,
      emailPanic: emailPanic,
      phone: phone,
    );
  }

  NavegarACursos? _cursosAction() {
    if (courses.isEmpty) return null;
    return NavegarACursos(
      municipalityId: id,
      courseId: courses.first.id,
      dataPolicyUrl: dataProcessingPrivacy ?? "",
      privacyPolicyUrl: dataPrivacy ?? "",
      emailMunicipalities: emailMunicipalities ?? "",
    );
  }

  NavegarAvenues? _venuesAction() {
    if (sportsFacilities.isEmpty) return null;
    return NavegarAvenues(
      municipalityId: id,
      venueId: sportsFacilities.first.id,
      dataPolicyUrl: dataProcessingPrivacy ?? "",
      privacyPolicyUrl: dataPrivacy ?? "",
      emailMunicipalities: emailMunicipalities ?? "",
    );
  }

  IntegrationTypeModel toIntegrationModel() {
    if (entityCode.trim().isNotEmpty) {
      return TramitesporAPP(
        codigoEntidad: entityCode,
        campoConsulta: queryFields,
      );
    } else {
      final hasIdentity = responseHasProcedureIdentity(municipalityProcedures);
      String findUrl(String code) {
        for (final p in municipalityProcedures) {
          final identity = resolveProcedure(
            p.procedures,
            responseHasIdentity: hasIdentity,
          );
          if (identity?.code == code) return p.integrationType;
        }
        return "";
      }

      return TramitesporURL(
        urlPredial: findUrl(ProcedureCodes.predial),
        urlIca: findUrl(ProcedureCodes.ica),
        urlPqrds: findUrl(ProcedureCodes.pqrsdf),
        urlDeclaracion: findUrl(ProcedureCodes.declaracion),
        urlReteIca: findUrl(ProcedureCodes.reteIca),
      );
    }
  }
}

extension MunicipalityProcedureToDomain on MunicipalityProcedure {
  /// Motor de trámites (diseño de identidad §4.1). `null` = no se muestra.
  ///
  /// 1. Botón de pánico, cursos y escenarios: por su tipo, aunque el valor
  ///    empiece por `http` (es su configuración, no un enlace).
  /// 2. Valor `http(s)`: abrir el enlace, sea cual sea el tipo. Solo los
  ///    impuestos piden antes los datos del ciudadano (`AbrirUrl`); el resto
  ///    abre directo (`AbrirUrlDirecto`).
  /// 3. Si no, el módulo del tipo. Un certificado nunca cae en la consulta de
  ///    impuestos.
  InfoTramite? toInfoTramite(
    MunicipalityDTO parentDto,
    IntegrationTypeModel integracion,
  ) {
    final identity = resolveProcedure(
      procedures,
      responseHasIdentity: responseHasProcedureIdentity(
        parentDto.municipalityProcedures,
      ),
    );
    if (identity == null) return null;

    final accion = _resolveAction(identity, parentDto, integracion);
    if (accion == null) return null;

    return InfoTramite(
      nombre: procedures.name,
      icono: _getProcedureIcon(identity),
      color: Colors.transparent, // placeholder, will be colored dynamically
      accion: accion,
      idtramite: procedures.id,
      isActive: isActive,
      category: _getProcedureCategory(identity.kind),
      key: identity.code ?? 'procedure:${procedures.id}',
      kind: identity.kind,
    );
  }

  TramiteAccion? _resolveAction(
    ProcedureIdentity identity,
    MunicipalityDTO parentDto,
    IntegrationTypeModel integracion,
  ) {
    final procedureName = procedures.name;
    final value = integrationType.trim();

    // 1. Su valor es configuración, nunca un enlace.
    switch (identity.kind) {
      case ProcedureKind.panicButton:
        return AbrirBotonPanico(integrationType, parentDto.emailPanic ?? "");
      case ProcedureKind.courses:
        return parentDto._cursosAction();
      case ProcedureKind.venues:
        return parentDto._venuesAction();
      default:
        break;
    }

    // 2. Canal enlace externo.
    if (_isHttpUrl(value)) {
      return identity.kind == ProcedureKind.tax
          ? AbrirUrl(value)
          : AbrirUrlDirecto(value);
    }

    // 3. Módulo nativo del tipo.
    switch (identity.kind) {
      case ProcedureKind.pqrsdf:
        return const ShowPqrds();
      case ProcedureKind.certificate:
        return _certificateAction(identity, parentDto, value);
      case ProcedureKind.publicServices:
        return NavegarANativo(
          AppRoutes.serviciosPublicosMenuPath(parentDto.id),
        );
      case ProcedureKind.tax:
        final taxId = identity.externalId;
        if (taxId == null) {
          _logHidden(procedureName, 'impuesto sin externalId');
          return null;
        }
        if (value.toLowerCase() == "psv") {
          return NavegarAPagoSinValidacion(
            taxId: taxId,
            taxName: procedureName,
            entityCode: parentDto.entityCode,
            dataPolicyUrl: parentDto.dataProcessingPrivacy ?? "",
            privacyPolicyUrl: parentDto.dataPrivacy ?? "",
          );
        }
        if (integracion is TramitesporAPP) {
          return NavegarAConsultaImpuesto(
            entityCode: integracion.codigoEntidad,
            queryFields: integracion.campoConsulta,
            taxId: taxId,
            dataPolicyUrl: parentDto.dataProcessingPrivacy ?? "",
            privacyPolicyUrl: parentDto.dataPrivacy ?? "",
          );
        }
        return null;
      case ProcedureKind.other:
        // Sin módulo en la app: solo existe como enlace.
        return null;
      case ProcedureKind.panicButton:
      case ProcedureKind.courses:
      case ProcedureKind.venues:
        return null; // resueltos en el paso 1
    }
  }

  /// `CERT_TURISMO` siempre abre el asistente (se cobra por edad); los demás
  /// certificados solo con valor. Sin `externalId` o sin id de pasarela no se
  /// pueden pedir ni pagar, así que se ocultan.
  TramiteAccion? _certificateAction(
    ProcedureIdentity identity,
    MunicipalityDTO parentDto,
    String value,
  ) {
    final procedureName = procedures.name;
    if (!isCertificateOffered(code: identity.code, value: value)) return null;

    final externalId = identity.externalId;
    final gatewayTaxId = identity.gatewayTaxId;
    if (externalId == null) {
      _logHidden(procedureName, 'certificado sin externalId');
      return null;
    }
    if (gatewayTaxId == null) {
      _logHidden(
        procedureName,
        'certificado sin id de pasarela (code ${identity.code})',
      );
      return null;
    }

    return NavegarACertificado(
      municipalityId: parentDto.id,
      certificate: CertificateProcedure(
        municipalityProcedureId: id,
        entityCode: parentDto.entityCode,
        name: procedureName,
        code: identity.code,
        externalId: externalId,
        gatewayTaxId: gatewayTaxId,
        value: value,
      ),
    );
  }
}

extension MunicipalitySocialMediaToDomain on MunicipalitySocialMedia {
  InfoTramite? toInfoTramite() {
    final icon = _getSocialMediaIcon(socialMediaType.name);
    if (icon == null) return null;

    return InfoTramite(
      nombre: socialMediaType.name,
      icono: icon,
      color: kSocialMediaColor,
      accion: AbrirUrlDirecto(url),
      idtramite: id + 100, // Evita colisión de IDs
      isActive: isActive,
      category: TramiteCategory.social,
      key: 'social:$id',
    );
  }
}
