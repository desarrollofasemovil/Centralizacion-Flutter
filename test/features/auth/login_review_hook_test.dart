import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/models/document_type_dto.dart';
import 'package:tramiapp_flutter/core/models/user_dto.dart';
import 'package:tramiapp_flutter/core/review/review_prompt_service.dart';
import 'package:tramiapp_flutter/features/auth/application/auth_providers.dart';
import 'package:tramiapp_flutter/features/auth/application/login_options_controller.dart';
import 'package:tramiapp_flutter/features/auth/data/auth_repository.dart';
import 'package:tramiapp_flutter/features/auth/presentation/login_bottom_sheet.dart';

import '../../support/spy_review_prompt_service.dart';

final _user = UserDTO(
  id: 1,
  address: 'Calle 1',
  documentType: DocumentTypeDTO(id: 1, name: 'Cédula de Ciudadanía'),
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

class _FakeSession extends SessionNotifier {
  _FakeSession({required this.succeeds});

  final bool succeeds;

  @override
  UserDTO? build() => null;

  @override
  Future<LoginResult> login(String email, String password) async {
    if (!succeeds) return const LoginResult.failure('Usuario no encontrado');
    state = _user;
    return LoginResult.success(_user);
  }
}

class _FakeLoginOptions extends LoginOptionsController {
  _FakeLoginOptions(super.ref);

  @override
  Future<GoogleAuthOutcome> signInWithGoogle() async =>
      const GoogleAuthOutcome(GoogleAuthStatus.loggedIn);
}

Future<SpyReviewPromptService> _pumpHost(
  WidgetTester tester, {
  bool loginSucceeds = true,
}) async {
  final spy = SpyReviewPromptService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider
            .overrideWith(() => _FakeSession(succeeds: loginSucceeds)),
        loginOptionsControllerProvider
            .overrideWith((ref) => _FakeLoginOptions(ref)),
        reviewPromptServiceProvider.overrideWithValue(spy),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showLoginBottomSheet(context),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return spy;
}

Future<void> _loginWithEmail(WidgetTester tester) async {
  await tester.tap(find.text('Iniciar sesión').first);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).at(0), 'ana@correo.co');
  await tester.enterText(find.byType(TextField).at(1), 'clave');
  await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('login exitoso y diálogo aceptado: llama onSuccessfulLogin una vez',
      (tester) async {
    final spy = await _pumpHost(tester);

    await _loginWithEmail(tester);
    expect(find.text('Inicio de sesión exitoso'), findsOneWidget);
    expect(spy.loginCalls, 0, reason: 'se pide tras cerrar el diálogo');

    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();

    expect(spy.loginCalls, 1);
  });

  testWidgets('login fallido: no llama onSuccessfulLogin', (tester) async {
    final spy = await _pumpHost(tester, loginSucceeds: false);

    await _loginWithEmail(tester);

    expect(find.text('Usuario no encontrado'), findsOneWidget);
    expect(spy.loginCalls, 0);
  });

  testWidgets('cerrar el sheet sin iniciar sesión: no llama onSuccessfulLogin',
      (tester) async {
    final spy = await _pumpHost(tester);

    await tester.tap(find.text('Continuar sin una cuenta'));
    await tester.pumpAndSettle();

    expect(spy.loginCalls, 0);
  });

  testWidgets('login con Google: no cuenta para la reseña (igual que Kotlin)',
      (tester) async {
    final spy = await _pumpHost(tester);

    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    expect(find.text('Inicio de sesión exitoso'), findsOneWidget);
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();

    expect(spy.loginCalls, 0);
  });
}
