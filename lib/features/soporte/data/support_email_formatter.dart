import '../domain/support_request.dart';

/// Construye el asunto y el cuerpo HTML del correo de soporte. Port de
/// `data/formatter/SupportEmailFormatter.kt`.
class SupportEmailFormatter {
  const SupportEmailFormatter();

  // ---------------------------------------------------------------------------
  // Subject — texto plano (los asuntos no soportan HTML).
  // ---------------------------------------------------------------------------
  String buildSubject(SupportRequest request) {
    final categoryTag = _buildCategoryTag(request.category);
    final municipalityTag = '[${request.userContext.municipality}]';
    final contextTag = _buildContextTag(request.category);
    final shortDescription = _extractShortDescription(request.category);
    return '$categoryTag$municipalityTag$contextTag $shortDescription';
  }

  // ---------------------------------------------------------------------------
  // Body — HTML con estilos inline.
  // ---------------------------------------------------------------------------
  String buildBody(SupportRequest request) {
    final b = StringBuffer();
    b.writeln('<!DOCTYPE html>');
    b.writeln('<html lang="es">');
    b.writeln('<head>');
    b.writeln('  <meta charset="UTF-8">');
    b.writeln(
        '  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    b.writeln('  <title>Solicitud de Soporte</title>');
    b.writeln('</head>');
    b.writeln('<body style="$_styleBody">');
    b.writeln('  <div style="$_styleContainer">');

    // Header principal
    b.writeln('    <div style="$_styleHeader">');
    b.writeln('      <div style="$_styleHeaderLabel">SOLICITUD DE SOPORTE</div>');
    b.writeln(
        '      <div style="$_styleHeaderTitle">${_escape(request.category.displayName)}</div>');
    b.writeln('    </div>');

    // Sección 1: Detalles del problema
    _appendSection(b, '🔍', 'Detalles del problema', _colorAccentPrimary, () {
      _appendCategoryDetailsHtml(b, request.category);
    });

    // Sección 2: Descripción adicional del usuario
    _appendSection(b, '💬', 'Descripción adicional del usuario',
        _colorAccentSecondary, () {
      final freeText = request.freeText.trim().isEmpty
          ? '<em style="color: $_colorTextMuted;">(El usuario no proporcionó descripción adicional)</em>'
          : _escapePreservingLineBreaks(request.freeText);
      b.writeln('      <div style="$_styleFreeText">$freeText</div>');
    });

    // Sección 3: Datos de contacto
    _appendSection(b, '👤', 'Datos de contacto', _colorAccentTertiary, () {
      b.writeln('      <table style="$_styleTable">');
      _appendRow(b, 'Nombre', request.userContext.fullName);
      _appendRow(b, request.userContext.documentTypeName,
          request.userContext.nationalId);
      _appendRow(b, 'Email', request.userContext.email);
      _appendRow(b, 'Teléfono', request.userContext.phoneNumber ?? '');
      _appendRow(b, 'Dirección', request.userContext.address);
      _appendRow(b, 'Municipio', request.userContext.municipality);
      final fixed = request.userContext.fixedMunicipalityId;
      if (fixed != null && fixed != 0) {
        _appendRow(b, 'Municipio fijo (ID)', fixed.toString());
      }
      final last = request.userContext.lastMunicipalityId;
      if (last != null && last != 0) {
        _appendRow(b, 'Último municipio (ID)', last.toString());
      }
      b.writeln('      </table>');
    });

    // Sección 4: Información técnica
    _appendSection(b, '⚙️', 'Información técnica', _colorAccentMuted, () {
      b.writeln('      <table style="$_styleTable">');
      _appendRow(b, 'Versión app', request.userContext.appVersion);
      _appendRow(b, 'Dispositivo', request.userContext.deviceModel);
      _appendRow(b, 'Sistema', request.userContext.platformVersion);
      _appendRow(b, 'Timestamp', _formatTimestamp(request.userContext.timestamp));
      _appendRow(b, 'Código interno', request.category.code, monospace: true);
      b.writeln('      </table>');
    });

    // Footer
    b.writeln('    <div style="$_styleFooter">');
    b.writeln('      Correo generado automáticamente por el módulo de soporte.');
    b.writeln('    </div>');

    b.writeln('  </div>');
    b.writeln('</body>');
    b.writeln('</html>');
    return b.toString();
  }

  // ---------------------------------------------------------------------------
  // Helpers de construcción HTML
  // ---------------------------------------------------------------------------
  void _appendSection(
    StringBuffer b,
    String icon,
    String title,
    String accentColor,
    void Function() content,
  ) {
    b.writeln('    <div style="$_styleSection">');
    b.writeln('      <div style="${_styleSectionHeader(accentColor)}">');
    b.writeln('        <span style="$_styleSectionIcon">$icon</span>');
    b.writeln(
        '        <span style="$_styleSectionTitle">${_escape(title)}</span>');
    b.writeln('      </div>');
    b.writeln('      <div style="$_styleSectionBody">');
    content();
    b.writeln('      </div>');
    b.writeln('    </div>');
  }

  void _appendRow(StringBuffer b, String label, String value,
      {bool monospace = false}) {
    final valueStyle = monospace ? _styleTdValueMono : _styleTdValue;
    b.writeln('        <tr>');
    b.writeln('          <td style="$_styleTdLabel">${_escape(label)}</td>');
    b.writeln('          <td style="$valueStyle">${_escape(value)}</td>');
    b.writeln('        </tr>');
  }

  void _appendCategoryDetailsHtml(StringBuffer b, SupportCategory category) {
    b.writeln('      <table style="$_styleTable">');
    switch (category) {
      case SupportPaymentIssue():
        _appendRow(b, 'Tipo de problema', category.issueType.displayName);
        _appendRow(b, 'Impuesto', category.taxConcept.displayName);
        _appendRow(b, 'Método de pago', category.paymentMethod.displayName);
        _appendRow(b, 'Fecha del pago', category.paymentDate);
        _appendRow(b, 'Monto pagado', category.amountPaid);
        _appendRow(b, 'Comprobante / Ref.', category.voucherReference,
            monospace: true);
      case SupportPaymentInquiry():
        _appendRow(b, 'Tipo de duda', category.inquiryType.displayName);
        _appendRow(b, 'Impuesto', category.taxConcept.displayName);
        _appendRow(b, category.taxConcept.identifierLabel,
            category.taxableEntityId,
            monospace: true);
        _appendRow(b, 'Vigencia', category.fiscalYear);
      case SupportTechnicalError():
        _appendRow(b, 'Pantalla', category.screenName);
        _appendRow(b, 'Acción intentada', category.attemptedAction);
        _appendRow(b, 'Frecuencia', category.frequency.displayName);
        _appendRow(b, 'Mensaje de error',
            category.errorMessage ?? '(No reportado por el usuario)');
      case SupportInformationRequest():
        _appendRow(b, 'Tipo de solicitud', category.requestType.displayName);
        final tax = category.taxConcept;
        if (tax != null) _appendRow(b, 'Impuesto', tax.displayName);
      case SupportOther():
        b.writeln('        <tr><td colspan="2" style="$_styleTdValue">');
        b.writeln('          <em style="color: $_colorTextMuted;">');
        b.writeln(
            '            (Solicitud sin categorización estructurada. Ver descripción del usuario.)');
        b.writeln('          </em>');
        b.writeln('        </td></tr>');
    }
    b.writeln('      </table>');
  }

  // ---------------------------------------------------------------------------
  // Helpers para el subject
  // ---------------------------------------------------------------------------
  String _buildCategoryTag(SupportCategory category) => switch (category) {
        SupportPaymentIssue() => '[${category.issueType.code}]',
        SupportPaymentInquiry() => '[${category.inquiryType.code}]',
        SupportTechnicalError() => '[TECH-ERROR]',
        SupportInformationRequest() => '[INFO-${category.requestType.code}]',
        SupportOther() => '[OTHER]',
      };

  String _buildContextTag(SupportCategory category) => switch (category) {
        SupportPaymentIssue() => '[${category.taxConcept.code}]',
        SupportPaymentInquiry() =>
          '[${category.taxConcept.code}-${category.fiscalYear}]',
        SupportTechnicalError() => '[${category.screenName}]',
        SupportInformationRequest() =>
          category.taxConcept != null ? '[${category.taxConcept!.code}]' : '',
        SupportOther() => '',
      };

  String _extractShortDescription(SupportCategory category) => switch (category) {
        SupportPaymentIssue() => category.issueType.displayName,
        SupportPaymentInquiry() => category.inquiryType.displayName,
        SupportTechnicalError() => 'Error: ${category.attemptedAction}',
        SupportInformationRequest() => category.requestType.displayName,
        SupportOther() => 'Solicitud general',
      };

  String _formatTimestamp(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  // ---------------------------------------------------------------------------
  // HTML escaping — evita XSS con el texto del usuario.
  // ---------------------------------------------------------------------------
  String _escape(String text) => text
      .replaceAll('&', '&amp;') // debe ser el primero
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');

  String _escapePreservingLineBreaks(String text) =>
      _escape(text).replaceAll('\n', '<br>');

  // =========================================================================
  // Paleta y estilos
  // =========================================================================
  static const _colorBg = '#f4f6f8';
  static const _colorCardBg = '#ffffff';
  static const _colorBorder = '#e1e5ea';
  static const _colorTextPrimary = '#1a1d21';
  static const _colorTextSecondary = '#5a6470';
  static const _colorTextMuted = '#9aa3ad';
  static const _colorAccentPrimary = '#2563eb';
  static const _colorAccentSecondary = '#7c3aed';
  static const _colorAccentTertiary = '#0891b2';
  static const _colorAccentMuted = '#64748b';
  static const _colorHeaderBg = '#1e293b';
  static const _colorHeaderText = '#ffffff';
  static const _colorHeaderLabel = '#94a3b8';

  static const _fontFamily =
      "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif";
  static const _fontMono = "'Courier New', Consolas, Monaco, monospace";

  static const _styleBody = 'margin: 0; padding: 20px 0; '
      'background-color: $_colorBg; font-family: $_fontFamily; '
      'color: $_colorTextPrimary; -webkit-text-size-adjust: 100%;';

  static const _styleContainer = 'max-width: 600px; margin: 0 auto; '
      'background-color: $_colorCardBg; border-radius: 12px; overflow: hidden; '
      'box-shadow: 0 1px 3px rgba(0,0,0,0.08);';

  static const _styleHeader =
      'background-color: $_colorHeaderBg; color: $_colorHeaderText; padding: 24px 28px;';

  static const _styleHeaderLabel = 'font-size: 11px; font-weight: 600; '
      'letter-spacing: 1.5px; color: $_colorHeaderLabel; '
      'text-transform: uppercase; margin-bottom: 6px;';

  static const _styleHeaderTitle =
      'font-size: 22px; font-weight: 700; line-height: 1.3;';

  static const _styleSection = 'padding: 0; margin: 0;';

  static String _styleSectionHeader(String accent) =>
      'display: block; padding: 16px 28px 12px 28px; '
      'border-top: 1px solid $_colorBorder; border-left: 4px solid $accent; '
      'background-color: #fafbfc;';

  static const _styleSectionIcon = 'font-size: 16px; margin-right: 8px;';

  static const _styleSectionTitle = 'font-size: 13px; font-weight: 700; '
      'text-transform: uppercase; letter-spacing: 0.5px; color: $_colorTextPrimary;';

  static const _styleSectionBody = 'padding: 8px 28px 20px 28px;';

  static const _styleTable =
      'width: 100%; border-collapse: collapse; margin: 0;';

  static const _styleTdLabel = 'padding: 8px 16px 8px 0; font-size: 13px; '
      'color: $_colorTextSecondary; font-weight: 500; vertical-align: top; '
      'white-space: nowrap; border-bottom: 1px solid #f1f3f5;';

  static const _styleTdValue = 'padding: 8px 0; font-size: 14px; '
      'color: $_colorTextPrimary; font-weight: 500; vertical-align: top; '
      'word-break: break-word; border-bottom: 1px solid #f1f3f5;';

  static const _styleTdValueMono = 'padding: 8px 0; font-size: 13px; '
      'color: $_colorTextPrimary; font-family: $_fontMono; vertical-align: top; '
      'word-break: break-all; border-bottom: 1px solid #f1f3f5;';

  static const _styleFreeText = 'padding: 14px 16px; background-color: #fafbfc; '
      'border-radius: 8px; font-size: 14px; line-height: 1.6; '
      'color: $_colorTextPrimary; white-space: pre-wrap;';

  static const _styleFooter =
      'padding: 16px 28px 20px 28px; border-top: 1px solid $_colorBorder; '
      'font-size: 11px; color: $_colorTextMuted; text-align: center;';
}
