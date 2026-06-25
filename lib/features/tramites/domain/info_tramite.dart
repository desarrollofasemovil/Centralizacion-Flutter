import 'package:flutter/material.dart';
import '../../../core/models/query_field.dart';

enum TramiteCategory { main, other, social }

sealed class TramiteAccion {
  const TramiteAccion();
}

class ShowPqrds extends TramiteAccion {
  const ShowPqrds();
}

class AbrirUrl extends TramiteAccion {
  final String url;
  const AbrirUrl(this.url);
}

class NavegarANativo extends TramiteAccion {
  final String ruta;
  const NavegarANativo(this.ruta);
}

class AbrirUrlDirecto extends TramiteAccion {
  final String url;
  const AbrirUrlDirecto(this.url);
}

class AbrirBotonPanico extends TramiteAccion {
  final String baseWhatsappUrl;
  final String emailPanic;
  const AbrirBotonPanico(this.baseWhatsappUrl, this.emailPanic);
}

class NavegarAConsultaImpuesto extends TramiteAccion {
  final String entityCode;
  final List<QueryField> queryFields;
  final int taxId;
  final String dataPolicyUrl;
  final String privacyPolicyUrl;

  const NavegarAConsultaImpuesto({
    required this.entityCode,
    required this.queryFields,
    required this.taxId,
    required this.dataPolicyUrl,
    required this.privacyPolicyUrl,
  });
}

class NavegarACursos extends TramiteAccion {
  final int municipalityId;
  final int courseId;
  final String dataPolicyUrl;
  final String privacyPolicyUrl;
  final String emailMunicipalities;

  const NavegarACursos({
    required this.municipalityId,
    required this.courseId,
    required this.dataPolicyUrl,
    required this.privacyPolicyUrl,
    required this.emailMunicipalities,
  });
}

class NavegarAvenues extends TramiteAccion {
  final int municipalityId;
  final int venueId;
  final String dataPolicyUrl;
  final String privacyPolicyUrl;
  final String emailMunicipalities;

  const NavegarAvenues({
    required this.municipalityId,
    required this.venueId,
    required this.dataPolicyUrl,
    required this.privacyPolicyUrl,
    required this.emailMunicipalities,
  });
}

class NavegarAPagoSinValidacion extends TramiteAccion {
  final int taxId;
  final String taxName;
  final String entityCode;
  final String dataPolicyUrl;
  final String privacyPolicyUrl;

  const NavegarAPagoSinValidacion({
    required this.taxId,
    required this.taxName,
    required this.entityCode,
    required this.dataPolicyUrl,
    required this.privacyPolicyUrl,
  });
}

class InfoTramite {
  final String nombre;
  final IconData icono;
  final Color color;
  final TramiteAccion accion;
  final int idtramite;
  final bool isActive;
  final TramiteCategory category;

  const InfoTramite({
    required this.nombre,
    required this.icono,
    required this.color,
    required this.accion,
    required this.idtramite,
    required this.isActive,
    required this.category,
  });

  InfoTramite copyWith({
    String? nombre,
    IconData? icono,
    Color? color,
    TramiteAccion? accion,
    int? idtramite,
    bool? isActive,
    TramiteCategory? category,
  }) {
    return InfoTramite(
      nombre: nombre ?? this.nombre,
      icono: icono ?? this.icono,
      color: color ?? this.color,
      accion: accion ?? this.accion,
      idtramite: idtramite ?? this.idtramite,
      isActive: isActive ?? this.isActive,
      category: category ?? this.category,
    );
  }
}
