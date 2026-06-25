import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/models/municipality_dto.dart';
import 'package:tramiapp_flutter/core/models/municipality_procedure.dart';
import 'package:tramiapp_flutter/core/models/municipality_social_media.dart';
import 'package:tramiapp_flutter/core/models/municipality.dart';
import 'package:tramiapp_flutter/core/models/department.dart';
import 'package:tramiapp_flutter/core/models/bank_dto.dart';
import 'package:tramiapp_flutter/core/models/shield_dto.dart';
import 'package:tramiapp_flutter/core/models/theme.dart' as model_theme;
import 'package:tramiapp_flutter/core/models/procedures.dart';
import 'package:tramiapp_flutter/core/models/social_media_type.dart';
import 'package:tramiapp_flutter/features/tramites/domain/info_tramite.dart';
import 'package:tramiapp_flutter/features/tramites/domain/integration_type_model.dart';
import 'package:tramiapp_flutter/features/tramites/application/tramite_mappers.dart';

void main() {
  group('Tramite Mappers Test', () {
    late MunicipalityDTO testDto;
    late Municipality dummyMunicipality;

    setUp(() {
      dummyMunicipality = Municipality(
        domain: 'test.gov.co',
        id: 1,
        name: 'Test Municipality',
        isActive: true,
      );

      testDto = MunicipalityDTO(
        id: 1,
        name: 'Test Municipality',
        entityCode: 'ENT-001',
        domain: 'test.gov.co',
        isActive: true,
        department: Department(id: 1, name: 'Test Dept'),
        bank: BankDTO(nameBank: 'Test Bank'),
        idShield: ShieldDTO(municipalityName: 'Test Mun', url: 'https://test.gov.co/shield.png'),
        theme: model_theme.Theme(
          primaryColor: '0xFF181E31',
          secondaryColor: '0xFF4364CD',
          secondaryColorBlack: '0xFFFFFFFF',
          onPrimaryColorLight: '0xFF000000',
          onPrimaryColorDark: '0xFFFFFFFF',
          backGroundColor: '0xFFF3F4F6',
        ),
        municipalityProcedures: [
          MunicipalityProcedure(
            id: 1,
            integrationType: '',
            isActive: true,
            municipality: dummyMunicipality,
            procedures: Procedures(id: 4, name: 'PQRSDF'), // Native PQRSDF
          ),
          MunicipalityProcedure(
            id: 2,
            integrationType: 'psv',
            isActive: true,
            municipality: dummyMunicipality,
            procedures: Procedures(id: 1, name: 'Predial'), // PSV Predial
          ),
          MunicipalityProcedure(
            id: 3,
            integrationType: 'http://test.gov.co/ica',
            isActive: true,
            municipality: dummyMunicipality,
            procedures: Procedures(id: 2, name: 'Industria y Comercio'), // External URL
          ),
        ],
        municipalitySocialMedia: [
          MunicipalitySocialMedia(
            id: 1,
            url: 'https://facebook.com/test',
            isActive: true,
            municipality: dummyMunicipality,
            socialMediaType: SocialMediaType(id: 1, name: 'Facebook'),
          ),
        ],
        courses: [],
        sportsFacilities: [],
        queryFields: [],
        newsByMunicipalities: [],
        dataPrivacy: 'https://test.gov.co/privacy',
        dataProcessingPrivacy: 'https://test.gov.co/data-policy',
        emailMunicipalities: 'info@test.gov.co',
        emailPanic: 'panic@test.gov.co',
        phone: 1234567,
        passwordFintech: '123456',
        userFintech: 'user',
      );
    });

    test('toIntegrationModel maps correctly with entityCode', () {
      final integration = testDto.toIntegrationModel();
      expect(integration, isA<TramitesporAPP>());
      expect((integration as TramitesporAPP).codigoEntidad, 'ENT-001');
    });

    test('toIntegrationModel maps to TramitesporURL when entityCode is empty', () {
      final dtoWithoutCode = MunicipalityDTO(
        id: testDto.id,
        name: testDto.name,
        entityCode: '',
        domain: testDto.domain,
        isActive: testDto.isActive,
        department: testDto.department,
        bank: testDto.bank,
        idShield: testDto.idShield,
        theme: testDto.theme,
        municipalityProcedures: testDto.municipalityProcedures,
        municipalitySocialMedia: testDto.municipalitySocialMedia,
        courses: testDto.courses,
        sportsFacilities: testDto.sportsFacilities,
        queryFields: testDto.queryFields,
        newsByMunicipalities: testDto.newsByMunicipalities,
        dataPrivacy: testDto.dataPrivacy,
        dataProcessingPrivacy: testDto.dataProcessingPrivacy,
        emailMunicipalities: testDto.emailMunicipalities,
        emailPanic: testDto.emailPanic,
        phone: testDto.phone,
        passwordFintech: testDto.passwordFintech,
        userFintech: testDto.userFintech,
      );
      final integration = dtoWithoutCode.toIntegrationModel();
      expect(integration, isA<TramitesporURL>());
    });

    test('toInfoTramite maps PQRSDF correctly', () {
      final integration = testDto.toIntegrationModel();
      final proc = testDto.municipalityProcedures.first; // PQRSDF
      final info = proc.toInfoTramite(testDto, integration);

      expect(info, isNotNull);
      expect(info!.idtramite, 4);
      expect(info.nombre, 'PQRSDF');
      expect(info.category, TramiteCategory.other);
      expect(info.accion, isA<ShowPqrds>());
    });

    test('toInfoTramite maps PSV correctly', () {
      final integration = testDto.toIntegrationModel();
      final proc = testDto.municipalityProcedures[1]; // Predial PSV
      final info = proc.toInfoTramite(testDto, integration);

      expect(info, isNotNull);
      expect(info!.idtramite, 1);
      expect(info.category, TramiteCategory.main);
      expect(info.accion, isA<NavegarAPagoSinValidacion>());
      final psvAccion = info.accion as NavegarAPagoSinValidacion;
      expect(psvAccion.taxId, 1);
      expect(psvAccion.entityCode, 'ENT-001');
    });

    test('toInfoTramite maps external URL correctly', () {
      final integration = testDto.toIntegrationModel();
      final proc = testDto.municipalityProcedures[2]; // External ICA
      final info = proc.toInfoTramite(testDto, integration);

      expect(info, isNotNull);
      expect(info!.idtramite, 2);
      expect(info.accion, isA<AbrirUrl>());
      expect((info.accion as AbrirUrl).url, 'http://test.gov.co/ica');
    });

    test('Social media maps correctly', () {
      final social = testDto.municipalitySocialMedia.first;
      final info = social.toInfoTramite();

      expect(info, isNotNull);
      expect(info!.nombre, 'Facebook');
      expect(info.category, TramiteCategory.social);
      expect(info.accion, isA<AbrirUrlDirecto>());
      expect((info.accion as AbrirUrlDirecto).url, 'https://facebook.com/test');
    });

    test('toDomainModel builds MunicipalityModel and colors items correctly', () {
      final model = testDto.toDomainModel();

      expect(model.idMunicipio, 1);
      expect(model.codigoEntidad, 'ENT-001');
      expect(model.nombreMunicipio, 'Alcaldía de Test Municipality');
      expect(model.tramitesPrincipales, hasLength(2)); // Predial (1), ICA (2)
      expect(model.otrosTramites, hasLength(1)); // PQRSDF (4)
      expect(model.socialLinks, hasLength(1)); // Facebook

      // Colors should be assigned from lists
      expect(model.tramitesPrincipales[0].color, kMainProcedureColors[0]);
      expect(model.otrosTramites[0].color, kOtherProcedureColors[0]);
      expect(model.socialLinks[0].color, kSocialMediaColor);
    });
  });
}
