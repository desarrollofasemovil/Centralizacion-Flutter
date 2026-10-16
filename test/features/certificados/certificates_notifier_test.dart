import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/api/services/api_providers.dart';
import 'package:tramiapp_flutter/core/api/services/payment_history_api_service.dart';
import 'package:tramiapp_flutter/core/api/services/pqrd_api_service.dart';
import 'package:tramiapp_flutter/core/api/services/tax_api_service.dart';
import 'package:tramiapp_flutter/core/models/document_type_dto.dart';
import 'package:tramiapp_flutter/core/models/procedure_application_request.dart';
import 'package:tramiapp_flutter/core/models/procedure_application_response.dart';
import 'package:tramiapp_flutter/core/models/tax_dto.dart';
import 'package:tramiapp_flutter/core/models/tipo_documento.dart';
import 'package:tramiapp_flutter/core/models/tourism_contribution_dto.dart';
import 'package:tramiapp_flutter/core/models/user_dto.dart';
import 'package:tramiapp_flutter/core/models/validation_response_dto.dart';
import 'package:tramiapp_flutter/core/remote_config/remote_config_service.dart';
import 'package:tramiapp_flutter/core/telemetry/non_fatal_reporter.dart';
import 'package:tramiapp_flutter/features/auth/application/auth_providers.dart';
import 'package:tramiapp_flutter/features/certificados/application/certificates_notifier.dart';
import 'package:tramiapp_flutter/features/certificados/domain/certificate_attachment.dart';
import 'package:tramiapp_flutter/features/certificados/domain/certificate_procedure.dart';
import 'package:tramiapp_flutter/features/certificados/domain/certificates_state.dart';

final _cc = TipoDocumento(descripcion: 'Cédula de Ciudadanía', id: 1);
final _pasaporte = TipoDocumento(descripcion: 'Pasaporte', id: 2);

/// Orden real de las llamadas del envío.
final _calls = <String>[];

class _PqrdApi implements PqrdApiService {
  @override
  Future<List<TipoDocumento>> listTipoDocumento(String codigoEntidad) async => [
    _cc,
    _pasaporte,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ProcedureApi implements ProcedureApplicationApiService {
  _ProcedureApi({this.estado = true, this.mensaje});

  /// Tal como llega del servicio: `tramitesservices` manda un booleano.
  final Object estado;
  final String? mensaje;
  ProcedureApplicationRequest? lastRequest;

  @override
  Future<ProcedureApplicationResponse> insertSolicitudProcedure(
    ProcedureApplicationRequest request,
  ) async {
    lastRequest = request;
    _calls.add('solicitud');
    // Por `fromJson`, para probar el parseo real de la respuesta.
    return ProcedureApplicationResponse.fromJson({
      'Estado': estado,
      'Ticket': 'TCK-00123',
      'Mensaje': ?mensaje,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PaymentApi implements PaymentApiService {
  BancolombiaGatewayRequestDTO? lastRequest;

  @override
  Future<BancolombiaGatewayResponseDTO> createTransaction(
    BancolombiaGatewayRequestDTO request,
  ) async {
    lastRequest = request;
    _calls.add('transaccion');
    return const BancolombiaGatewayResponseDTO(url: 'https://pse.test/pago');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _HistoryApi implements PaymentHistoryApiService {
  _HistoryApi({this.fail = false});

  final bool fail;
  Map<String, dynamic>? lastBody;

  @override
  Future<ValidationResponseDTO> createPaymentHistory(
    Map<String, dynamic> body,
  ) async {
    lastBody = body;
    // Deja pasar un ciclo: si el flujo no esperara, la transacción se colaría.
    await Future<void>.delayed(Duration.zero);
    _calls.add('historial');
    if (fail) throw StateError('POST api/PaymentHistory falló');
    return ValidationResponseDTO(codeStatus: 200, booleanStatus: true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RemoteConfig implements RemoteConfigService {
  @override
  TourismTaxConfigDTO getTourismTaxRates() => TourismTaxConfigDTO(
    national: TaxAgePriceRatesDTO(adult: 100, child_7_14: 50, teen_15_17: 75),
    foreign: TaxAgePriceRatesDTO(adult: 200, child_7_14: 110, teen_15_17: 150),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reporter implements NonFatalReporter {
  final reports = <String>[];

  @override
  void report(
    String reason, {
    Map<String, Object?> context = const {},
    Object? error,
    StackTrace? stackTrace,
  }) => reports.add(reason);
}

class _Session extends SessionNotifier {
  _Session(this.user);
  final UserDTO? user;

  @override
  UserDTO? build() => user;
}

UserDTO _user({String documentType = 'cedula de ciudadania'}) => UserDTO(
  id: 7,
  address: 'Calle 1',
  documentType: DocumentTypeDTO(id: 1, name: documentType),
  documentTypeId: 1,
  email: 'ana@correo.co',
  firstName: 'Ana',
  lastName: 'Pérez',
  loginStatus: true,
  nationalId: '123456',
  password: '',
  phoneNumber: '3001234567',
  birthDate: '1990-01-01',
);

CertificateProcedure _certificate({
  String code = 'CERT_RESIDENCIA',
  int gatewayTaxId = 43,
  String value = '9000',
}) => CertificateProcedure(
  municipalityProcedureId: 501,
  entityCode: '05030',
  name: 'Certificado',
  code: code,
  externalId: 11,
  gatewayTaxId: gatewayTaxId,
  value: value,
);

class _Harness {
  _Harness({
    UserDTO? user,
    _ProcedureApi? procedureApi,
    _HistoryApi? historyApi,
    CertificateProcedure? certificate,
  }) : procedureApi = procedureApi ?? _ProcedureApi(),
       historyApi = historyApi ?? _HistoryApi(),
       param = CertificatesFamilyParam(
         certificate: certificate ?? _certificate(),
       ) {
    _calls.clear();
    container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(() => _Session(user)),
        pqrdApiServiceProvider.overrideWithValue(_PqrdApi()),
        procedureApplicationApiServiceProvider.overrideWithValue(
          this.procedureApi,
        ),
        paymentApiServiceProvider.overrideWithValue(paymentApi),
        paymentHistoryApiServiceProvider.overrideWithValue(this.historyApi),
        remoteConfigServiceProvider.overrideWithValue(_RemoteConfig()),
        nonFatalReporterProvider.overrideWithValue(reporter),
      ],
    );
    addTearDown(container.dispose);
    // autoDispose: mantenerlo vivo durante el test.
    container.listen(certificatesNotifierProvider(param), (_, _) {});
  }

  final _ProcedureApi procedureApi;
  final _HistoryApi historyApi;
  final paymentApi = _PaymentApi();
  final reporter = _Reporter();
  final CertificatesFamilyParam param;
  late final ProviderContainer container;

  CertificatesUiState get state =>
      container.read(certificatesNotifierProvider(param));
  CertificatesNotifier get notifier =>
      container.read(certificatesNotifierProvider(param).notifier);

  /// Espera a que carguen los tipos de documento (microtask del `build`).
  Future<void> loaded() async {
    state;
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  void fillValidForm() {
    notifier
      ..onTipoDocumentoChange(_cc)
      ..onIdentificacionChange('123456')
      ..onPrimerNombreChange('Ana')
      ..onPrimerApellidoChange('Pérez')
      ..correoElectronicoChange('ana@correo.co')
      ..onTelefonoCelularChange('3001234567')
      ..onDescripcionChange('Necesito el certificado')
      ..onTratamientoDatosAcepted(true)
      ..onCondicionesUsoAcepted(true);
  }
}

void main() {
  group('copyWith (A2)', () {
    test('las banderas clearX devuelven los opcionales a null', () {
      const s = CertificatesUiState(
        gatewayTaxId: 43,
        identificacionError: 'x',
        ageError: 'y',
        fileError: 'z',
        nombreArchivo: 'a.pdf',
        tipoArchivo: 'application/pdf',
        contenidoArchivoBase64: 'AAAA',
        urlTransaction: 'https://pse',
      );
      final cleared = s.copyWith(
        clearIdentificacionError: true,
        clearAgeError: true,
        clearFileError: true,
        clearFile: true,
        clearUrlTransaction: true,
      );
      expect(cleared.identificacionError, isNull);
      expect(cleared.ageError, isNull);
      expect(cleared.fileError, isNull);
      expect(cleared.nombreArchivo, isNull);
      expect(cleared.tipoArchivo, isNull);
      expect(cleared.contenidoArchivoBase64, isNull);
      expect(cleared.urlTransaction, isNull);
      // Sin bandera, `null` conserva el valor.
      expect(s.copyWith().identificacionError, 'x');
    });

    test('el error de identificación se va al corregirla', () async {
      final h = _Harness();
      await h.loaded();
      h.notifier.onIdentificacionChange('12');
      expect(
        h.state.identificacionError,
        'La identificación debe tener al menos 4 caracteres.',
      );
      h.notifier.onIdentificacionChange('123456');
      expect(h.state.identificacionError, isNull);
    });

    test('"Quitar archivo" borra el adjunto', () async {
      final h = _Harness();
      await h.loaded();
      await h.notifier.attachFile(
        fileName: 'soporte.pdf',
        sizeBytes: 1024,
        readBase64: () async => 'JVBERi0=',
      );
      expect(h.state.hasFile, isTrue);
      h.notifier.clearFile();
      expect(h.state.hasFile, isFalse);
      expect(h.state.contenidoArchivoBase64, isNull);
    });
  });

  group('autollenado (A3)', () {
    test(
      'elige el tipo por descripción normalizada (tildes, mayúsculas)',
      () async {
        final h = _Harness(user: _user(documentType: ' CEDULA DE CIUDADANIA '));
        await h.loaded();
        expect(h.state.tipoDocumento, same(_cc));
        expect(h.state.primerNombre, 'Ana');
      },
    );

    test('sin coincidencia deja el tipo sin elegir', () async {
      final h = _Harness(user: _user(documentType: 'Registro civil'));
      await h.loaded();
      expect(h.state.tipoDocumento, isNull);
      expect(h.state.identificacion, '123456');
    });
  });

  group('valor de Contribución al turismo', () {
    Future<_Harness> tourism() async {
      final h = _Harness(
        certificate: _certificate(
          code: 'CERT_TURISMO',
          gatewayTaxId: 269,
          value: '',
        ),
      );
      await h.loaded();
      return h;
    }

    test('por rango de edad, nacional', () async {
      final h = await tourism();
      h.notifier.onTipoDocumentoChange(_cc);
      const expected = {
        '3': '0',
        '6': '0',
        '7': '50',
        '14': '50',
        '15': '75',
        '17': '75',
        '18': '100',
        '90': '100',
      };
      expected.forEach((age, value) {
        h.notifier.onAgeChange(age);
        expect(h.state.certificateValue, value, reason: 'edad $age');
      });
    });

    test('documento extranjero usa la tabla extranjera', () async {
      final h = await tourism();
      h.notifier
        ..onTipoDocumentoChange(_pasaporte)
        ..onAgeChange('10');
      expect(h.state.certificateValue, '110');
      h.notifier.onAgeChange('30');
      expect(h.state.certificateValue, '200');
    });

    test('la edad se filtra a dígitos y es obligatoria', () async {
      final h = await tourism();
      h.notifier.onAgeChange('2a5');
      expect(h.state.age, '25');
      h.notifier.onAgeChange('');
      h.notifier.validateStep1();
      expect(h.state.ageError, 'La edad es requerida.');
      h.notifier.onAgeChange('130');
      h.notifier.validateStep1();
      expect(h.state.ageError, 'Por favor, introduce una edad válida (0-120).');
      h.notifier.onAgeChange('30');
      expect(h.state.ageError, isNull);
    });

    test('otro certificado: el paso 1 limpia edad y su error', () async {
      final h = _Harness();
      await h.loaded();
      h.notifier.onAgeChange('20');
      h.notifier.validateStep1();
      expect(h.state.age, '');
      expect(h.state.ageError, isNull);
    });
  });

  group('validación por campo', () {
    test('paso 1 marca los obligatorios y avanza cuando están', () async {
      final h = _Harness();
      await h.loaded();
      h.notifier.onNextStep();
      final e = h.state.errors;
      expect(e.tipoDocumentoError, isTrue);
      expect(e.primerNombreError, isTrue);
      expect(e.primerApellidoError, isTrue);
      expect(h.state.identificacionError, 'Por favor, introduce un documento.');
      expect(h.state.currentStep, 1);

      // Cada error se limpia al cambiar su campo.
      h.notifier.onPrimerNombreChange('Ana');
      expect(h.state.errors.primerNombreError, isFalse);

      h.fillValidForm();
      h.notifier.onNextStep();
      expect(h.state.currentStep, 2);
    });

    test('identificación de más de 20 caracteres', () async {
      final h = _Harness();
      await h.loaded();
      h.notifier.onIdentificacionChange('1' * 21);
      expect(
        h.state.identificacionError,
        'La identificación no puede exceder los 20 caracteres.',
      );
    });

    test(
      'paso 2: correo (patrón de EMAIL_ADDRESS), teléfono de 10, descripción',
      () async {
        final h = _Harness();
        await h.loaded();
        h.fillValidForm();
        h.notifier.onNextStep();
        h.notifier
          ..correoElectronicoChange('ana@correo')
          ..onTelefonoCelularChange('300')
          ..onDescripcionChange('  ');
        h.notifier.onNextStep();
        expect(h.state.errors.correoElectronicoError, isTrue);
        expect(h.state.errors.telefonoCelularError, isTrue);
        expect(h.state.errors.descripcionError, isTrue);
        expect(h.state.currentStep, 2);

        // TLD largo: el regex anterior (`{2,4}`) lo rechazaba.
        h.notifier
          ..correoElectronicoChange('ana@alcaldia.gov.co.museum')
          ..onTelefonoCelularChange('3001234567')
          ..onDescripcionChange('Texto');
        expect(h.state.errors.correoElectronicoError, isFalse);
        h.notifier.onNextStep();
        expect(h.state.currentStep, 3);
      },
    );
  });

  group('adjunto', () {
    test('rechaza más de 5 MB sin leer el archivo', () async {
      final h = _Harness();
      await h.loaded();
      var read = false;
      await h.notifier.attachFile(
        fileName: 'grande.pdf',
        sizeBytes: kMaxCertificateAttachmentBytes + 1,
        readBase64: () async {
          read = true;
          return '';
        },
      );
      expect(read, isFalse);
      expect(h.state.fileError, kAttachmentSizeError);
      expect(h.state.hasFile, isFalse);
    });

    test('rechaza tipos no permitidos', () async {
      final h = _Harness();
      await h.loaded();
      await h.notifier.attachFile(
        fileName: 'notas.docx',
        sizeBytes: 10,
        readBase64: () async => '',
      );
      expect(h.state.fileError, kAttachmentTypeError);
    });

    test('acepta pdf/png/jpg con su MIME y el base64 real', () async {
      expect(
        (checkCertificateAttachment(fileName: 'a.PDF', sizeBytes: 1)
                as AttachmentAccepted)
            .mimeType,
        'application/pdf',
      );
      expect(
        (checkCertificateAttachment(fileName: 'b.jpeg', sizeBytes: 1)
                as AttachmentAccepted)
            .mimeType,
        'image/jpeg',
      );
      expect(
        checkCertificateAttachment(
          fileName: 'c.png',
          sizeBytes: kMaxCertificateAttachmentBytes,
        ),
        isA<AttachmentAccepted>(),
      );

      final h = _Harness();
      await h.loaded();
      await h.notifier.attachFile(
        fileName: 'foto.jpg',
        sizeBytes: 2048,
        readBase64: () async => '/9j/4AAQ',
      );
      expect(h.state.tipoArchivo, 'image/jpeg');
      expect(h.state.contenidoArchivoBase64, '/9j/4AAQ');
    });

    test(
      'si falla la lectura muestra "Error al procesar el archivo."',
      () async {
        final h = _Harness();
        await h.loaded();
        await h.notifier.attachFile(
          fileName: 'a.pdf',
          sizeBytes: 10,
          readBase64: () async => throw Exception('io'),
        );
        expect(h.state.fileError, kAttachmentProcessError);
      },
    );
  });

  group('envío', () {
    Future<_Harness> readyToSubmit({
      UserDTO? user,
      _HistoryApi? historyApi,
      _ProcedureApi? procedureApi,
    }) async {
      final h = _Harness(
        user: user,
        historyApi: historyApi,
        procedureApi: procedureApi,
      );
      await h.loaded();
      h.fillValidForm();
      return h;
    }

    test(
      'orden: solicitud → historial → transacción, con los datos del resolver',
      () async {
        final h = await readyToSubmit(user: _user());
        await h.notifier.submitSolicitudTramite();

        expect(_calls, ['solicitud', 'historial', 'transaccion']);
        final request = h.procedureApi.lastRequest!;
        expect(request.idTramite, 11); // externalId
        expect(request.recepcion, 'Correo Electronico');
        // Sin archivo: textos vacíos, no "null".
        expect(request.documentos.documentos, '');
        expect(request.documentos.nombreArchivo, '');

        final body = h.historyApi.lastBody!;
        expect(body['userId'], 7);
        expect(body['amount'], 9000);
        expect(body['status'], false);
        expect(body['statusType'], 2);
        expect(body['municipalityProceduresId'], 501);
        expect(body['codigoEntidad'], '05030');
        expect(body['factura'], '00123');
        expect(body['idimpuesto'], '43');

        final tx = h.paymentApi.lastRequest!;
        expect(tx.reference, '00123');
        expect(tx.invoice, '00123');
        expect(tx.taxId, 43); // gatewayTaxId
        expect(tx.documentType, 'CC');
        expect(tx.paymentSource, 2);
        expect(tx.implementationType, 3);
        expect(tx.total, 9000);

        final submission = h.state.submission as CertificatesResponseSuccess;
        expect(submission.urlTransaction, 'https://pse.test/pago');
        expect(submission.reference, '00123');
      },
    );

    test('con adjunto manda el base64 real', () async {
      final h = await readyToSubmit();
      await h.notifier.attachFile(
        fileName: 'soporte.pdf',
        sizeBytes: 3,
        readBase64: () async => 'JVBERi0=',
      );
      await h.notifier.submitSolicitudTramite();
      final documentos = h.procedureApi.lastRequest!.documentos;
      expect(documentos.documentos, 'JVBERi0=');
      expect(documentos.contentType, 'application/pdf');
      expect(documentos.nombreArchivo, 'soporte.pdf');
    });

    test('si el historial falla igual se paga y queda el no fatal', () async {
      final h = await readyToSubmit(
        user: _user(),
        historyApi: _HistoryApi(fail: true),
      );
      await h.notifier.submitSolicitudTramite();
      expect(_calls, ['solicitud', 'historial', 'transaccion']);
      expect(h.state.submission, isA<CertificatesResponseSuccess>());
      expect(h.reporter.reports, hasLength(1));
    });

    test('sin sesión no registra historial', () async {
      final h = await readyToSubmit();
      await h.notifier.submitSolicitudTramite();
      expect(_calls, ['solicitud', 'transaccion']);
      expect(h.historyApi.lastBody, isNull);
    });

    test(
      'solicitud rechazada: el Mensaje del servicio o el texto fijo',
      () async {
        final h = await readyToSubmit(
          procedureApi: _ProcedureApi(estado: false, mensaje: 'Sin cupo'),
        );
        await h.notifier.submitSolicitudTramite();
        expect(
          (h.state.submission as CertificatesResponseError).message,
          'Sin cupo',
        );
        expect(_calls, ['solicitud']);

        final h2 = await readyToSubmit(
          procedureApi: _ProcedureApi(estado: false),
        );
        await h2.notifier.submitSolicitudTramite();
        expect(
          (h2.state.submission as CertificatesResponseError).message,
          'Error al crear la solicitud.',
        );
      },
    );

    test('sin doble envío mientras está en curso', () async {
      final h = await readyToSubmit();
      final first = h.notifier.submitSolicitudTramite();
      final second = h.notifier.submitSolicitudTramite();
      await Future.wait([first, second]);
      expect(_calls.where((c) => c == 'solicitud'), hasLength(1));
    });

    test(
      'el estado del envío no se comparte entre certificados (A4)',
      () async {
        final h = await readyToSubmit();
        await h.notifier.submitSolicitudTramite();
        expect(h.state.submission, isA<CertificatesResponseSuccess>());

        final other = CertificatesFamilyParam(
          certificate: _certificate(code: 'CERT_PAZ_SALVO', gatewayTaxId: 26),
        );
        h.container.listen(certificatesNotifierProvider(other), (_, _) {});
        expect(
          h.container.read(certificatesNotifierProvider(other)).submission,
          isA<CertificatesResponseEmpty>(),
        );
      },
    );
  });
}
