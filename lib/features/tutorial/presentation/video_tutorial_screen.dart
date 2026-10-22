import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../domain/tutorial_videos.dart';

/// Lo que viaja como `extra` a la ruta del video.
class VideoTutorialArgs {
  const VideoTutorialArgs({
    required this.video,
    required this.origin,
    this.municipalityId,
  });

  final TutorialVideo video;
  final VideoPlace origin;

  /// `null` desde Welcome (todavía no hay alcaldía).
  final int? municipalityId;
}

/// Un video tutorial de YouTube reproducido dentro de la app (reproductor
/// oficial de YouTube en un WebView): la persona no sale a la app de YouTube.
///
/// Pensada para adultos mayores: no arranca sola (nada de sonido de golpe),
/// el video va grande arriba, los subtítulos en español se muestran solos en
/// cuanto el canal los publique, y girar el celular lo pone en pantalla
/// completa.
class VideoTutorialScreen extends ConsumerStatefulWidget {
  const VideoTutorialScreen({super.key, required this.args});

  final VideoTutorialArgs args;

  @override
  ConsumerState<VideoTutorialScreen> createState() =>
      _VideoTutorialScreenState();
}

class _VideoTutorialScreenState extends ConsumerState<VideoTutorialScreen> {
  late final YoutubePlayerController _controller;
  late final AnalyticsService _analytics;
  StreamSubscription<YoutubePlayerValue>? _valueSub;
  StreamSubscription<YoutubeVideoState>? _positionSub;

  Duration _maxPosition = Duration.zero;
  Duration _duration = Duration.zero;
  bool _ended = false;

  TutorialVideo get _video => widget.args.video;

  @override
  void initState() {
    super.initState();
    _analytics = ref.read(analyticsServiceProvider);
    _controller = YoutubePlayerController.fromVideoId(
      videoId: _video.youtubeId,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        // Subtítulos e interfaz en español; los subtítulos salen activados
        // si el video los tiene.
        captionLanguage: 'es',
        enableCaption: true,
        interfaceLanguage: 'es',
        // Al terminar, solo videos del mismo canal; sin anotaciones encima.
        strictRelatedVideos: true,
        showVideoAnnotations: false,
      ),
    );
    _valueSub = _controller.stream.listen((value) {
      final duration = value.metaData.duration;
      if (duration > Duration.zero) _duration = duration;
      if (value.playerState == PlayerState.ended) _ended = true;
    });
    _positionSub = _controller.videoStateStream.listen((state) {
      if (state.position > _maxPosition) _maxPosition = state.position;
    });

    // La app es vertical; mientras se ve el video se puede girar para verlo
    // en grande (el reproductor entra solo a pantalla completa). En iOS el
    // Info.plist solo permite vertical, así que allá no gira.
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);

    _analytics.logTutorialVideoOpened(
      video: _video.id,
      origin: widget.args.origin.value,
      municipalityId: widget.args.municipalityId,
    );
  }

  @override
  void dispose() {
    // Lista explícita: una vacía en Android quitaría también el bloqueo
    // vertical del manifiesto.
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    _analytics.logTutorialVideoClosed(
      video: _video.id,
      origin: widget.args.origin.value,
      municipalityId: widget.args.municipalityId,
      percentWatched: _percentWatched,
      completed: _ended,
    );
    _valueSub?.cancel();
    _positionSub?.cancel();
    _controller.close();
    super.dispose();
  }

  int get _percentWatched {
    if (_ended) return 100;
    if (_duration == Duration.zero) return 0;
    final ratio = _maxPosition.inMilliseconds / _duration.inMilliseconds;
    return math.min(100, (ratio * 100).round());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppTopBar(
        title: 'Video tutorial',
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: YoutubePlayer(
                controller: _controller,
                aspectRatio: 16 / 9,
                backgroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _video.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            const _Hint(
              icon: Icons.play_circle_outline,
              text: 'Toca el video para reproducirlo o pausarlo.',
            ),
            const SizedBox(height: 12),
            const _Hint(
              icon: Icons.screen_rotation_outlined,
              text: 'Gira el celular para verlo en pantalla completa.',
            ),
            const SizedBox(height: 28),
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: BorderSide(color: scheme.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 26, color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
