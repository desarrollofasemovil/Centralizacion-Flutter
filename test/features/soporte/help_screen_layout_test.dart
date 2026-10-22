import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/models/document_type_dto.dart';
import 'package:tramiapp_flutter/core/models/user_dto.dart';
import 'package:tramiapp_flutter/features/auth/application/auth_providers.dart';
import 'package:tramiapp_flutter/features/soporte/application/help_notifier.dart';
import 'package:tramiapp_flutter/features/soporte/presentation/help_screen.dart';

const _municipality = 'Test';

final _user = UserDTO(
  id: 7,
  address: 'Calle 1',
  documentType: DocumentTypeDTO(id: 1, name: 'CC'),
  documentTypeId: 1,
  email: 'u7@correo.co',
  firstName: 'Usuario',
  lastName: '7',
  loginStatus: true,
  nationalId: '7',
  password: '',
  phoneNumber: '300',
  birthDate: '1990-01-01',
);

class _Session extends SessionNotifier {
  @override
  UserDTO? build() => _user;
}

Future<ProviderContainer> _pumpHelp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sessionProvider.overrideWith(_Session.new)],
      child: const MaterialApp(
        home: HelpScreen(
          municipalityId: 1,
          municipality: _municipality,
          portal: 'https://x.co',
        ),
      ),
    ),
  );
  await tester.pump();
  return ProviderScope.containerOf(tester.element(find.byType(HelpScreen)));
}

void main() {
  testWidgets('el contenido de Ayuda y Soporte va 2 sp más grande', (
    tester,
  ) async {
    await _pumpHelp(tester);
    final base = Theme.of(tester.element(find.byType(Scaffold))).textTheme;

    final title = tester.widget<Text>(find.text('Sobre mis Impuestos'));
    final style = DefaultTextStyle.of(
      tester.element(find.text('Sobre mis Impuestos')),
    ).style.merge(title.style);
    expect(style.fontSize, base.titleMedium!.fontSize! + 2);
  });

  testWidgets('los campos de la solicitud no quedan pegados', (tester) async {
    final container = await _pumpHelp(tester);
    container
        .read(helpNotifierProvider(_municipality).notifier)
        .selectCategory('PAYMENT_ISSUE');
    await tester.pumpAndSettle();

    final fields = find.byType(InputDecorator);
    final rects = [
      for (var i = 0; i < fields.evaluate().length; i++)
        tester.getRect(fields.at(i)),
    ]..sort((a, b) => a.top.compareTo(b.top));
    // 6 campos + la descripción libre.
    expect(rects.length, 7);
    for (var i = 1; i < rects.length; i++) {
      expect(
        rects[i].top - rects[i - 1].bottom,
        greaterThanOrEqualTo(16),
        reason: 'campo $i pegado al anterior',
      );
    }
  });
}
