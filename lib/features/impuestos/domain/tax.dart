import 'package:intl/intl.dart';

class Tax {
  final String entity;
  final String entityCode;
  final String document;
  final String name;
  final String taxName;
  final int taxId;
  final int value;
  final String invoice;
  final String reference;
  final String dueDate;
  final String? pdfUrltoApi;
  final String? portalUrl;
  final String queryField;

  const Tax({
    required this.entity,
    required this.entityCode,
    required this.document,
    required this.name,
    required this.taxName,
    required this.taxId,
    required this.value,
    required this.invoice,
    required this.reference,
    required this.dueDate,
    this.pdfUrltoApi,
    this.portalUrl,
    required this.queryField,
  });

  bool get isExpired {
    final parsedDate = _parseDueDate(dueDate);
    if (parsedDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return parsedDate.isBefore(today);
  }

  DateTime? _parseDueDate(String dateString) {
    final formats = [
      'yyyy/dd/MM',
      'dd/MM/yyyy',
      'MM/yyyy/dd',
      'dd/yyyy/MM',
      'yyyy/MM/dd',
    ];

    for (final fmt in formats) {
      try {
        return DateFormat(fmt).parse(dateString);
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
