import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/models/query_field.dart';
import 'package:tramiapp_flutter/features/impuestos/application/tax_notifier.dart';

QueryField _field(int id, String type) =>
    QueryField(id: id, queryFieldType: type, fieldName: 'campo$id');

ProviderContainer _setUp() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.listen(taxQueryNotifierProvider, (_, _) {});
  return container;
}

void main() {
  test('con un solo tipo de documento queda seleccionado', () {
    final container = _setUp();
    final only = _field(1, 'Cédula');

    container.read(taxQueryNotifierProvider.notifier).preselectQueryField([
      only,
    ]);

    expect(container.read(taxQueryNotifierProvider).selectedQueryField, only);
  });

  test('con varios queda seleccionado el primero', () {
    final container = _setUp();
    final first = _field(1, 'Cédula');

    container.read(taxQueryNotifierProvider.notifier).preselectQueryField([
      first,
      _field(2, 'NIT'),
    ]);

    expect(container.read(taxQueryNotifierProvider).selectedQueryField, first);
  });

  test('no pisa lo que el usuario ya eligió', () {
    final container = _setUp();
    final notifier = container.read(taxQueryNotifierProvider.notifier);
    final chosen = _field(2, 'NIT');

    notifier.onDocumentTypeChanged(chosen);
    notifier.preselectQueryField([_field(1, 'Cédula'), chosen]);

    expect(container.read(taxQueryNotifierProvider).selectedQueryField, chosen);
  });

  test('sin opciones no selecciona nada', () {
    final container = _setUp();

    container.read(taxQueryNotifierProvider.notifier).preselectQueryField([]);

    expect(container.read(taxQueryNotifierProvider).selectedQueryField, isNull);
  });
}
