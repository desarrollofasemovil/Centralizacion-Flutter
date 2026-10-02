/// Enums del formulario de soporte. Port de `domain/model/SupportEnums.kt`.
///
/// `code` conserva el nombre de la constante Kotlin (`enum.name`) para que los
/// tags del asunto del correo se generen idénticos al original.
library;

enum TaxConcept {
  predial('PREDIAL', 'Impuesto Predial', 'Referencia Catastral'),
  ica('ICA', 'Industria y Comercio (ICA)', 'NIT o RIT'),
  avisosTableros('AVISOS_TABLEROS', 'Avisos y Tableros', 'NIT del establecimiento'),
  otro('OTRO', 'Otro impuesto', 'Identificador del trámite');

  const TaxConcept(this.code, this.displayName, this.identifierLabel);

  final String code;
  final String displayName;
  final String identifierLabel;
}

/// Métodos de pago soportados.
enum PaymentMethod {
  pse('PSE', 'PSE (Pago Electrónico)'),
  gatewayCard('GATEWAY_CARD', 'Pasarela de pago (tarjeta)'),
  unknown('UNKNOWN', 'No estoy seguro');

  const PaymentMethod(this.code, this.displayName);

  final String code;
  final String displayName;
}

enum PaymentIssueType {
  notReflected('NOT_REFLECTED', 'El pago no se ha visto reflejado'),
  incorrectAmount('INCORRECT_AMOUNT', 'El monto cobrado fue incorrecto'),
  noReceipt('NO_RECEIPT', 'No recibí mi comprobante de pago');

  const PaymentIssueType(this.code, this.displayName);

  final String code;
  final String displayName;
}

/// Tipos de dudas sobre el valor a pagar.
enum InquiryType {
  amountUnclear('AMOUNT_UNCLEAR', 'No entiendo el valor que se me está cobrando'),
  amountTooHigh('AMOUNT_TOO_HIGH', 'El valor me parece muy alto'),
  entityNotFound('ENTITY_NOT_FOUND', 'No encuentro mi predio/establecimiento en la app'),
  inconsistentData(
      'INCONSISTENT_DATA', 'Los datos del predio/establecimiento están incorrectos');

  const InquiryType(this.code, this.displayName);

  final String code;
  final String displayName;
}

/// Frecuencia con la que ocurre un error técnico.
enum ErrorFrequency {
  firstTime('FIRST_TIME', 'Es la primera vez que me pasa'),
  sometimes('SOMETIMES', 'Me ha pasado varias veces'),
  always('ALWAYS', 'Me pasa siempre que intento esta acción'),
  blocking('BLOCKING', 'No me deja avanzar para nada');

  const ErrorFrequency(this.code, this.displayName);

  final String code;
  final String displayName;
}

/// Tipos de solicitud de información.
enum InformationType {
  certificate('CERTIFICATE', 'Solicitar certificado o paz y salvo'),
  generalInfo('GENERAL_INFO', 'Información general del trámite');

  const InformationType(this.code, this.displayName);

  final String code;
  final String displayName;
}
