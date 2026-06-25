import 'dart:async';
import 'package:flutter/material.dart';

class PanicCountdownDialog extends StatefulWidget {
  final VoidCallback onDismiss;
  final VoidCallback onConfirm;
  final int initialCountdown;

  const PanicCountdownDialog({
    super.key,
    required this.onDismiss,
    required this.onConfirm,
    this.initialCountdown = 6,
  });

  @override
  State<PanicCountdownDialog> createState() => _PanicCountdownDialogState();
}

class _PanicCountdownDialogState extends State<PanicCountdownDialog> {
  late int _countdown;
  Timer? _timer;
  final Color _redColor = const Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _countdown = widget.initialCountdown;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 0) {
          _countdown--;
          if (_countdown == 0) {
            _timer?.cancel();
            widget.onConfirm();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Text(
              "Esta alerta se comunica con la estación de policía más cercana.",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _redColor, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                "$_countdown",
                style: TextStyle(
                  fontSize: 31,
                  color: _redColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "El uso indebido de este servicio puede acarrear sanciones \n (Ley 1801 de 2016) .",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: widget.onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _redColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: const Text(
                  "CANCELAR ALERTA",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
