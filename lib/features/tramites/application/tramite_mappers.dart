import 'package:flutter/material.dart';
import '../../../core/models/municipality_dto.dart';
import '../../../core/models/municipality.dart';
import '../../../core/models/procedures.dart';
import '../../../core/models/municipality_procedure.dart';
import '../../../core/models/municipality_social_media.dart';
import '../../../core/theme/design.dart';
import '../../../core/router/app_routes.dart';
import '../../municipality/domain/municipality_model.dart';
import '../domain/info_tramite.dart';
import '../domain/integration_type_model.dart';

// New Color Palettes for Procedures from Color.kt
const List<Color> kMainProcedureColors = [
  Color(0xFFFFC3B8), // 1. Whiteish Blue
  Color(0xFFADD8E6), // 2. Light Blue
  Color(0xFFB8FFFF), // 3. Light Salmon
  Color(0xFFFFD6B0), // 4. Light Orange
  Color(0xFFFFFAB0), // 5. Light Yellow
  Color(0xFFDBFFB0), // 6. Light Lime Green
  Color(0xFFB0FFB4), // 7. Light Green
  Color(0xFFB0FFD6)  // 8. Light Mint
];

const List<Color> kOtherProcedureColors = [
  Color(0xFFC2FFF1), // 9. Light Cyan
  Color(0xFFB0E7FF), // 10. Light Sky Blue
  Color(0xFFB0BEFF), // 11. Light Purple Blue
  Color(0xFFB8B0FF), // 12. Light Purple
  Color(0xFFD8B0FF), // 13. Light Magenta
  Color(0xFFF7B0FF), // 14. Light Pink
  Color(0xFFFFB0D8), // 15. Pink
  Color(0xFFFFB0B0)  // 16. Light Red
];

const Color kPanicButtonColor = Color(0xFFFF4440);
const Color kSocialMediaColor = Color(0xFFFFFFFF);

// Mapping of icons based on procedure ID (from tramiteConfigMap in DataMappers.kt)
IconData? _getProcedureIcon(int id) {
  switch (id) {
    case 1:
      return Icons.home; // Predial
    case 2:
      return Icons.business; // ICA
    case 3:
      return Icons.article; // Declaración
    case 5:
      return Icons.water_drop; // Servicios
    case 6:
      return Icons.directions_car; // Vehículos
    case 7:
      return Icons.percent; // Retención ICA
    case 4:
      return Icons.question_answer; // PQRSDF
    case 10:
      return Icons.emergency; // Botón de pánico
    case 11:
      return Icons.card_membership; // Certificado Residencia
    case 12:
      return Icons.description; // Certificado Paz y Salvo
    case 13:
      return Icons.flight; // Aporte a Turismo
    case 14:
      return Icons.map; // Concepto Uso del Suelo
    case 8:
      return Icons.school; // Cursos
    case 9:
      return Icons.sports_soccer; // Reservas (Escenarios)
    default:
      return null;
  }
}

TramiteCategory? _getProcedureCategory(int id) {
  switch (id) {
    case 1:
    case 2:
    case 3:
    case 5:
    case 6:
    case 7:
      return TramiteCategory.main;
    case 4:
    case 8:
    case 9:
    case 10:
    case 11:
    case 12:
    case 13:
    case 14:
      return TramiteCategory.other;
    default:
      return null;
  }
}

IconData? _getSocialMediaIcon(String name) {
  final lName = name.toLowerCase();
  if (lName.contains('facebook')) return Icons.facebook;
  if (lName.contains('instagram')) return Icons.camera_alt;
  if (lName.contains('x')) return Icons.close; // O un ícono similar
  if (lName.contains('youtube')) return Icons.play_circle;
  if (lName.contains('blogger')) return Icons.web;
  if (lName.contains('tiktok')) return Icons.music_note;
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

    // 2. Mapea módulos adicionales (si existen en el JSON)
    InfoTramite? cursosTramite;
    if (courses.isNotEmpty) {
      final courseInfo = courses.first;
      final icon = _getProcedureIcon(8)!;
      final category = _getProcedureCategory(8)!;
      final action = NavegarACursos(
        municipalityId: id,
        courseId: courseInfo.id,
        dataPolicyUrl: dataProcessingPrivacy ?? "",
        privacyPolicyUrl: dataPrivacy ?? "",
        emailMunicipalities: emailMunicipalities ?? "",
      );
      cursosTramite = InfoTramite(
        nombre: "Cursos",
        icono: icon,
        color: Colors.transparent, // placeholder
        accion: action,
        idtramite: 8,
        isActive: courseInfo.isActive,
        category: category,
      );
    }

    InfoTramite? sportsTramite;
    if (sportsFacilities.isNotEmpty) {
      final sportsInfo = sportsFacilities.first;
      final icon = _getProcedureIcon(9)!;
      final category = _getProcedureCategory(9)!;
      final action = NavegarAvenues(
        municipalityId: id,
        venueId: sportsInfo.id,
        dataPolicyUrl: dataProcessingPrivacy ?? "",
        privacyPolicyUrl: dataPrivacy ?? "",
        emailMunicipalities: emailMunicipalities ?? "",
      );
      sportsTramite = InfoTramite(
        nombre: "Reserva de espacios",
        icono: icon,
        color: Colors.transparent, // placeholder
        accion: action,
        idtramite: 9,
        isActive: sportsInfo.isActive,
        category: category,
      );
    }

    // 3. Mapea las redes sociales
    final socialTramites = municipalitySocialMedia
        .map((s) => s.toInfoTramite())
        .whereType<InfoTramite>()
        .toList();

    // 4. Une todas las fuentes en una sola lista distinta por idtramite
    final combinedList = <InfoTramite>[
      ...tramitesDesdeApi,
      ...socialTramites,
      // ignore: use_null_aware_elements
      if (cursosTramite != null) cursosTramite,
      // ignore: use_null_aware_elements
      if (sportsTramite != null) sportsTramite,
    ];

    final uniqueTramites = <int, InfoTramite>{};
    for (final item in combinedList) {
      uniqueTramites.putIfAbsent(item.idtramite, () => item);
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
      if (tramite.idtramite == 10) {
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

  IntegrationTypeModel toIntegrationModel() {
    if (entityCode.trim().isNotEmpty) {
      return TramitesporAPP(
        codigoEntidad: entityCode,
        campoConsulta: queryFields,
      );
    } else {
      String findUrl(String name) {
        final dummyMun = Municipality(
          domain: '',
          id: 0,
          name: '',
          isActive: false,
        );
        final proc = municipalityProcedures.firstWhere(
          (p) => p.procedures.name.toLowerCase().contains(name.toLowerCase()),
          orElse: () => MunicipalityProcedure(
            id: 0,
            integrationType: "",
            isActive: false,
            municipality: dummyMun,
            procedures: Procedures(id: 0, name: ""),
          ),
        );
        return proc.integrationType;
      }

      return TramitesporURL(
        urlPredial: findUrl("Predial"),
        urlIca: findUrl("Industria"),
        urlPqrds: findUrl("PQRSDF"),
        urlDeclaracion: findUrl("Declaracion"),
        urlReteIca: findUrl("ReteIca"),
      );
    }
  }
}

extension MunicipalityProcedureToDomain on MunicipalityProcedure {
  InfoTramite? toInfoTramite(
    MunicipalityDTO parentDto,
    IntegrationTypeModel integracion,
  ) {
    final procedureId = procedures.id;
    final procedureName = procedures.name;

    final icon = _getProcedureIcon(procedureId);
    final category = _getProcedureCategory(procedureId);
    if (icon == null || category == null) return null;

    final TramiteAccion accion;

    if (procedureId == 10 || procedureName.toLowerCase().contains("pánico")) {
      accion = AbrirBotonPanico(integrationType, parentDto.emailPanic ?? "");
    } else if (integrationType.isEmpty && procedureId == 4) {
      accion = const ShowPqrds();
    } else if (integrationType.isNotEmpty &&
        (procedureId == 11 ||
            procedureId == 12 ||
            procedureId == 13 ||
            procedureId == 14)) {
      accion = NavegarANativo(
        AppRoutes.certificadosPath(
          parentDto.id,
          parentDto.entityCode,
          procedureId,
          integrationType,
        ),
      );
    } else if (integrationType.isEmpty && procedureId == 5) {
      accion = NavegarANativo(
        AppRoutes.serviciosPublicosMenuPath(parentDto.id),
      );
    } else if (integrationType.isNotEmpty &&
        integrationType.toLowerCase().startsWith("http")) {
      accion = AbrirUrl(integrationType);
    } else if (integrationType.toLowerCase() == "psv") {
      accion = NavegarAPagoSinValidacion(
        taxId: procedureId,
        taxName: procedureName,
        entityCode: parentDto.entityCode,
        dataPolicyUrl: parentDto.dataProcessingPrivacy ?? "",
        privacyPolicyUrl: parentDto.dataPrivacy ?? "",
      );
    } else {
      if (integracion is TramitesporAPP) {
        accion = NavegarAConsultaImpuesto(
          entityCode: integracion.codigoEntidad,
          queryFields: integracion.campoConsulta,
          taxId: procedureId,
          dataPolicyUrl: parentDto.dataProcessingPrivacy ?? "",
          privacyPolicyUrl: parentDto.dataPrivacy ?? "",
        );
      } else {
        return null;
      }
    }

    return InfoTramite(
      nombre: procedureName,
      icono: icon,
      color: Colors.transparent, // placeholder, will be colored dynamically
      accion: accion,
      idtramite: procedureId,
      isActive: isActive,
      category: category,
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
    );
  }
}
