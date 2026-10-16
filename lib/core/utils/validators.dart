/// Equivalente a `Patterns.EMAIL_ADDRESS` del original (lo usan la consulta de
/// impuestos y los certificados).
final RegExp emailAddressPattern = RegExp(r"^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$");

bool isValidEmail(String email) => emailAddressPattern.hasMatch(email.trim());

/// Para comparar textos de catálogos: sin espacios a los lados, minúsculas y
/// sin tildes ("Cédula de Ciudadanía" == "cedula de ciudadania").
String normalizeForMatch(String input) {
  const withAccents = 'áàäâãéèëêíìïîóòöôõúùüûñ';
  const without = 'aaaaaeeeeiiiiooooouuuun';
  var s = input.trim().toLowerCase();
  for (var i = 0; i < withAccents.length; i++) {
    s = s.replaceAll(withAccents[i], without[i]);
  }
  return s;
}
