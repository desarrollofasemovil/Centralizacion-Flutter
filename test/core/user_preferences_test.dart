import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tramiapp_flutter/core/storage/user_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<UserPreferences> build([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);
    return UserPreferences(await SharedPreferences.getInstance());
  }

  test('ubicación por defecto está vacía', () async {
    final prefs = await build();
    final loc = prefs.getSavedLocation();
    expect(loc.guardado, isFalse);
    expect(loc.municipalityId, 0);
    expect(loc.municipio, '');
  });

  test('saveLocation persiste y getSavedLocation lo recupera', () async {
    final prefs = await build();
    await prefs.saveLocation(
      departmentId: 5,
      municipalityId: 12,
      municipio: 'Manizales',
      guardar: true,
    );
    final loc = prefs.getSavedLocation();
    expect(loc.departmentId, 5);
    expect(loc.municipalityId, 12);
    expect(loc.municipio, 'Manizales');
    expect(loc.guardado, isTrue);
  });

  test('clearCurrentMunicipality conserva municipalityId (fiel al original)',
      () async {
    final prefs = await build();
    await prefs.saveLocation(
      departmentId: 5,
      municipalityId: 12,
      municipio: 'Manizales',
      guardar: true,
    );
    await prefs.clearCurrentMunicipality();
    final loc = prefs.getSavedLocation();
    expect(loc.departmentId, 0);
    expect(loc.municipio, '');
    expect(loc.guardado, isFalse);
    expect(loc.municipalityId, 12); // NO se borra
  });

  test('toggleTheme alterna is_dark_theme', () async {
    final prefs = await build();
    expect(prefs.isDarkTheme(), isFalse);
    await prefs.toggleTheme();
    expect(prefs.isDarkTheme(), isTrue);
  });

  test('remindersIsVisible por defecto true; send por defecto false', () async {
    final prefs = await build();
    expect(prefs.remindersIsVisible(), isTrue);
    expect(prefs.remindersSendIsVisible(), isFalse);
  });

  test('authToken vacío por defecto (no la cadena "null")', () async {
    final prefs = await build();
    expect(prefs.getAuthToken(), '');
    await prefs.saveAuthToken('abc123');
    expect(prefs.getAuthToken(), 'abc123');
  });
}
