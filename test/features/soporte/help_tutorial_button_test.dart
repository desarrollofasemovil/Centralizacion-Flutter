import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tramiapp_flutter/core/analytics/analytics_service.dart';
import 'package:tramiapp_flutter/core/router/app_routes.dart';
import 'package:tramiapp_flutter/features/auth/application/auth_providers.dart';
import 'package:tramiapp_flutter/core/models/bank_dto.dart';
import 'package:tramiapp_flutter/core/models/course_x.dart';
import 'package:tramiapp_flutter/core/models/department.dart';
import 'package:tramiapp_flutter/core/models/municipality_dto.dart';
import 'package:tramiapp_flutter/core/models/shield_dto.dart';
import 'package:tramiapp_flutter/core/models/theme.dart' as model_theme;
import 'package:tramiapp_flutter/core/models/user_dto.dart';
import 'package:tramiapp_flutter/core/municipality/municipality_repository.dart';
import 'package:tramiapp_flutter/features/soporte/presentation/help_screen.dart';
import 'package:tramiapp_flutter/features/tutorial/application/tutorial_providers.dart';
import 'package:tramiapp_flutter/features/tutorial/domain/tutorial_config.dart';
import 'package:tramiapp_flutter/features/tutorial/domain/tutorial_videos.dart';
import 'package:tramiapp_flutter/features/tutorial/presentation/video_tutorial_screen.dart';

class _NoSession extends SessionNotifier {
  @override
  UserDTO? build() => null;
}

/// Municipio 81, con o sin cursos.
MunicipalityDTO _municipality({bool withCourses = false}) => MunicipalityDTO(
  id: 81,
  name: 'Rionegro',
  entityCode: '',
  domain: 'rionegro.gov.co',
  isActive: true,
  department: Department(id: 1, name: 'Antioquia'),
  bank: BankDTO(nameBank: 'Banco'),
  idShield: ShieldDTO(municipalityName: 'Rionegro', url: ''),
  theme: model_theme.Theme(
    primaryColor: '0xFF005B8C',
    secondaryColor: '0xFF4364CD',
    secondaryColorBlack: '0xFFFFFFFF',
    onPrimaryColorLight: '0xFF000000',
    onPrimaryColorDark: '0xFFFFFFFF',
    backGroundColor: '0xFFF3F4F6',
  ),
  municipalityProcedures: const [],
  municipalitySocialMedia: const [],
  courses: [
    if (withCourses)
      CourseX(get: '', id: 1, name: 'Cursos', post: '', isActive: true),
  ],
  sportsFacilities: const [],
  newsByMunicipalities: const [],
  queryFields: const [],
  passwordFintech: '',
  userFintech: '',
);

Future<void> _pump(
  WidgetTester tester, {
  TutorialConfig? config,
  TutorialVideosConfig? videos,
  bool withCourses = false,
}) async {
  final router = GoRouter(
    initialLocation: '/help',
    routes: [
      GoRoute(
        path: '/help',
        builder: (_, _) => const HelpScreen(
          municipalityId: 81,
          municipality: 'Alcaldía de Rionegro',
          portal: 'https://rionegro.gov.co',
        ),
      ),
      GoRoute(
        path: AppRoutes.tutorial,
        builder: (_, state) => Text(
          'tutorial ${state.pathParameters['id']} '
          '${(state.extra! as TutorialOrigin).value}',
        ),
      ),
      GoRoute(
        path: AppRoutes.municipalityVideoTutorial,
        builder: (_, state) {
          final args = state.extra! as VideoTutorialArgs;
          return Text(
            'video ${args.video.id} ${args.origin.value} '
            '${args.municipalityId}',
          );
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(_NoSession.new),
        if (config != null) tutorialConfigProvider.overrideWithValue(config),
        if (videos != null)
          tutorialVideosConfigProvider.overrideWithValue(videos),
        municipalityProvider.overrideWith(
          (ref, id) async => _municipality(withCourses: withCourses),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('«Ver tutorial de la app» abre el tutorial de esta alcaldía', (
    tester,
  ) async {
    await _pump(tester, config: const TutorialConfig());
    expect(find.text('NUEVO'), findsOneWidget);

    await tester.tap(find.text('Ver tutorial de la app'));
    await tester.pumpAndSettle();
    expect(find.text('tutorial 81 ayuda'), findsOneWidget);
  });

  testWidgets('con el interruptor apagado no aparece', (tester) async {
    await _pump(tester, config: const TutorialConfig(enabled: false));
    expect(find.text('Ver tutorial de la app'), findsNothing);
  });

  testWidgets('sin Remote Config (Firebase sin iniciar) tampoco', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Ver tutorial de la app'), findsNothing);
  });

  group('videos', () {
    testWidgets('el de pagos abre el reproductor dentro de la app', (
      tester,
    ) async {
      await _pump(tester, videos: const TutorialVideosConfig());
      expect(find.text('Video: Cursos y reserva de espacios'), findsNothing);

      await tester.tap(find.text('Video: Cómo pagar tus impuestos'));
      await tester.pumpAndSettle();
      expect(find.text('video pagos ayuda 81'), findsOneWidget);
    });

    testWidgets('el de cursos y reservas sale si la alcaldía los tiene', (
      tester,
    ) async {
      await _pump(
        tester,
        videos: const TutorialVideosConfig(),
        withCourses: true,
      );
      expect(find.text('Video: Cómo pagar tus impuestos'), findsOneWidget);
      expect(find.text('Video: Cursos y reserva de espacios'), findsOneWidget);
    });

    testWidgets('apagados en Remote Config no aparecen', (tester) async {
      await _pump(
        tester,
        videos: const TutorialVideosConfig(enabled: false),
        withCourses: true,
      );
      expect(find.textContaining('Video:'), findsNothing);
    });
  });
}
