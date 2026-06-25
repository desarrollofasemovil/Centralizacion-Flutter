import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Overlay de éxito de registro — puerto de `RegistrationSuccessOverlay`: scrim
/// semitransparente, círculo verde con check, título y subtítulo; aparece,
/// sostiene [holdDuration] y llama [onFinished] (para navegar).
class RegistrationSuccessOverlay extends StatefulWidget {
  const RegistrationSuccessOverlay({
    super.key,
    required this.visible,
    required this.onFinished,
    this.title = '¡Registro exitoso!',
    this.subtitle = 'Redirigiendo al inicio de sesión...',
    this.holdDuration = const Duration(milliseconds: 2200),
  });

  final bool visible;
  final VoidCallback onFinished;
  final String title;
  final String subtitle;
  final Duration holdDuration;

  @override
  State<RegistrationSuccessOverlay> createState() =>
      _RegistrationSuccessOverlayState();
}

class _RegistrationSuccessOverlayState
    extends State<RegistrationSuccessOverlay> {
  bool _contentVisible = false;

  @override
  void didUpdateWidget(RegistrationSuccessOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _runSequence();
    } else if (!widget.visible) {
      _contentVisible = false;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.visible) _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    setState(() => _contentVisible = true);
    await Future.delayed(widget.holdDuration);
    if (!mounted) return;
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          color: Colors.black.withValues(alpha: 0.72),
          alignment: Alignment.center,
          child: AnimatedScale(
            scale: _contentVisible ? 1 : 0.8,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: AnimatedOpacity(
              opacity: _contentVisible ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: AppColors.successGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          size: 52, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
