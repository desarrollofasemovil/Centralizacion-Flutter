import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tramiapp_flutter/core/models/document_type_dto.dart';
import 'package:tramiapp_flutter/core/models/user_dto.dart';
import 'package:tramiapp_flutter/core/review/review_prompt_service.dart';
import 'package:tramiapp_flutter/core/router/app_routes.dart';
import 'package:tramiapp_flutter/core/widgets/important_alert_dialog.dart';
import 'package:tramiapp_flutter/features/auth/application/auth_providers.dart';
import 'package:tramiapp_flutter/features/auth/application/login_options_controller.dart';
import 'package:tramiapp_flutter/features/auth/data/auth_repository.dart';
import 'package:tramiapp_flutter/features/auth/data/google_auth_service.dart';
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

/// Qué devuelve el login nativo falso.
enum _Login { succeeds, backendError, invalidInput }

class _FakeSession extends SessionNotifier {
  _FakeSession(this.mode);

  final _Login mode;

  @override
  UserDTO? build() => null;

  @override
  Future<LoginResult> login(String email, String password) async {
    switch (mode) {
      case _Login.backendError:
        return const LoginResult.failure('Usuario no encontrado');
      case _Login.invalidInput:
        return const LoginResult.invalidInput('Correo electrónico inválido.');
      case _Login.succeeds:
        state = _user;
        return LoginResult.success(_user);
    }
  }
}

class _FakeLoginOptions extends LoginOptionsController {
  _FakeLoginOptions(super.ref, this.status);

  final GoogleAuthStatus status;

  @override
  Future<GoogleAuthOutcome> signInWithGoogle() async =>
      GoogleAuthOutcome(status);
}

/// `GoogleAuthService()` toca `FirebaseAuth.instance`: no se puede construir
/// en tests. Solo se usa su `signOut` (respaldo al registro).
class _FakeGoogleAuth implements GoogleAuthService {
  int signOuts = 0;

  @override
  Future<void> signOut() async => signOuts++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<SpyReviewPromptService> _pumpHost(
  WidgetTester tester, {
  _Login login = _Login.succeeds,
  GoogleAuthStatus google = GoogleAuthStatus.loggedIn,
  _FakeGoogleAuth? googleAuth,
}) async {
  final spy = SpyReviewPromptService();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showLoginBottomSheet(context),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const Scaffold(body: Text('pantalla de registro')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(() => _FakeSession(login)),
        loginOptionsControllerProvider
            .overrideWith((ref) => _FakeLoginOptions(ref, google)),
        googleAuthServiceProvider
            .overrideWithValue(googleAuth ?? _FakeGoogleAuth()),
        reviewPromptServiceProvider.overrideWithValue(spy),
      ],
      child: MaterialApp.router(routerConfig: router),
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
  testWidgets('login exitoso: el diálogo se cierra solo a los 2 s y luego '
      'llama onSuccessfulLogin una vez', (tester) async {
    final spy = await _pumpHost(tester);

    await _loginWithEmail(tester);
    expect(find.text('Inicio de sesión exitoso'), findsOneWidget);
    expect(find.text('Has iniciado sesión correctamente'), findsOneWidget);
    // Como el original: sin botones.
    expect(find.text('Aceptar'), findsNothing);
    expect(spy.loginCalls, 0, reason: 'se pide tras cerrar el diálogo');

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Inicio de sesión exitoso'), findsNothing);
    expect(spy.loginCalls, 1);
  });

  testWidgets('login exitoso: también se cierra tocando fuera', (tester) async {
    final spy = await _pumpHost(tester);

    await _loginWithEmail(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.text('Inicio de sesión exitoso'), findsNothing);
    expect(spy.loginCalls, 1);
    // El timer del diálogo ya cerrado no hace nada.
    await tester.pump(const Duration(seconds: 3));
    expect(spy.loginCalls, 1);
  });

  testWidgets('login fallido en backend: "No se pudo iniciar sesión" en '
      'diálogo, se borra a los 2 s y no llama onSuccessfulLogin',
      (tester) async {
    final spy = await _pumpHost(tester, login: _Login.backendError);

    await _loginWithEmail(tester);

    expect(find.byType(ImportantAlertDialog), findsOneWidget);
    expect(find.text('No se pudo iniciar sesión'), findsOneWidget);
    expect(find.text('Usuario no encontrado'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(ImportantAlertDialog), findsNothing);
    // Sigue en el formulario para reintentar.
    expect(find.widgetWithText(ElevatedButton, 'Iniciar sesión'), findsOneWidget);
    expect(spy.loginCalls, 0);
  });

  testWidgets('dato mal formado: el error va bajo el campo, sin diálogo',
      (tester) async {
    await _pumpHost(tester, login: _Login.invalidInput);

    await _loginWithEmail(tester);

    expect(find.byType(ImportantAlertDialog), findsNothing);
    expect(find.text('Correo electrónico inválido.'), findsOneWidget);
  });

  testWidgets('error con Google: aviso 3,2 s, cierra Google y va al registro',
      (tester) async {
    final googleAuth = _FakeGoogleAuth();
    await _pumpHost(
      tester,
      google: GoogleAuthStatus.error,
      googleAuth: googleAuth,
    );

    await tester.tap(find.text('Continuar con Google'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Aviso Importante'), findsOneWidget);
    expect(find.text('redirigiendo...'), findsOneWidget);
    expect(googleAuth.signOuts, 1);

    // El aviso cuenta desde que se pinta (hace ~300 ms): a los ~3,1 s sigue.
    await tester.pump(const Duration(milliseconds: 2800));
    expect(find.text('Aviso Importante'), findsOneWidget);
    expect(find.text('pantalla de registro'), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Aviso Importante'), findsNothing);
    expect(find.text('pantalla de registro'), findsOneWidget);
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
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Inicio de sesión exitoso'), findsNothing);
    expect(spy.loginCalls, 0);
  });
}
