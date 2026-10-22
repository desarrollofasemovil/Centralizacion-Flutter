import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../domain/tutorial_videos.dart';
import 'video_tutorial_screen.dart';

/// Abre [video] dentro de la app. Con [municipalityId] la pantalla va dentro
/// de la alcaldía (conserva su tema); sin él, es la de Bienvenida.
Future<void> openTutorialVideo(
  BuildContext context, {
  required TutorialVideo video,
  required VideoPlace origin,
  int? municipalityId,
}) => context.push(
  municipalityId == null
      ? AppRoutes.videoTutorial
      : AppRoutes.municipalityVideoTutorialPath(municipalityId),
  extra: VideoTutorialArgs(
    video: video,
    origin: origin,
    municipalityId: municipalityId,
  ),
);
