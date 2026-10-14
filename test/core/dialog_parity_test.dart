import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Los diálogos de las features usan los ports de marca de `core/widgets/`
/// (`ConfirmationDialog`, `ImportantAlertDialog`, …) igual que el Kotlin. Este
/// test falla si una feature vuelve a construir un `AlertDialog(` de Material
/// a mano —así se coló el "Cambio de municipio" con el ícono azul—.
///
/// Excepciones: pantallas cuyo original Kotlin TAMBIÉN usa el `AlertDialog` de
/// Material 3. Cada entrada nombra el archivo Kotlin que lo justifica; si ese
/// original cambia a un diálogo de marca, quítala de aquí.
const _allowlist = <String, String>{
  // Módulo deshabilitado y mockeado (hub F-02, F-23): no se toca hasta que
  // se reactive.
  'lib/features/servicios_publicos/presentation/barcode_instructions_screen.dart':
      'F-23',
  'lib/features/pqrd/presentation/pqrd_result_dialogs.dart':
      'pqrds/components/SuccessPqrdDialog.kt, ErrorPqrdDialog.kt',
  'lib/features/pqrd/presentation/pqrds_choice_screen.dart':
      'pqrds/PqrdsChoiceScreen.kt (InformationDialog)',
  'lib/features/auth/presentation/signup_wizard.dart':
      'signup/components/SignUpDialogs.kt (RegistrationErrorDialog)',
  'lib/features/soporte/presentation/help_screen.dart':
      'help/HelpScreen.kt (HandleUiStateDialogs)',
};

/// `AlertDialog(` que no sea parte de otro identificador
/// (`ImportantAlertDialog(`, `CupertinoAlertDialog(`).
final _rawAlertDialog = RegExp(r'(?<![A-Za-z0-9_])AlertDialog\(');

void main() {
  test('ninguna feature construye un AlertDialog de Material a mano', () {
    final offenders = <String>[];
    final files = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      final path = file.path.replaceAll(r'\', '/');
      if (_allowlist.containsKey(path)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (_rawAlertDialog.hasMatch(lines[i])) {
          offenders.add('$path:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Usa ConfirmationDialog / ImportantAlertDialog (core/widgets/) como '
          'el Kotlin. Si el original de esa pantalla usa de verdad el '
          'AlertDialog de Material, agrégala a _allowlist con su archivo .kt.',
    );
  });

  test('las excepciones siguen existiendo (no quedan entradas muertas)', () {
    for (final path in _allowlist.keys) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}
