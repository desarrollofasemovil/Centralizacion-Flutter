import 'package:intl/intl.dart';

/// Puerto de `utils/Formatters.kt` — moneda colombiana sin decimales
/// (`NumberFormat.getCurrencyInstance(Locale("es", "CO"))` con 0 fracciones).
String formatCurrency(num value) {
  final format = NumberFormat.currency(
    locale: 'es_CO',
    symbol: r'$',
    decimalDigits: 0,
  );
  return format.format(value);
}
