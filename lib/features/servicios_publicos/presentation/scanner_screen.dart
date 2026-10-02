// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../domain/barcode_parser.dart';
import 'servicios_publicos_theme.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({required this.municipalityId, super.key});
  final int municipalityId;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final BarcodeParser _parser = BarcodeParser();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final rawValue = barcodes.first.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        final data = _parser.parse(rawValue);
        if (data != null) {
          final isDateOk = _parser.isDateValid(data.fechaVencimiento);
          if (isDateOk) {
            setState(() {
              _isProcessing = true;
              _errorMessage = null;
            });

            HapticFeedback.heavyImpact();

            // Navigate to form screen
            if (mounted) {
              context.pushReplacement(
                '/municipality/${widget.municipalityId}/servicios-publicos/form/${data.factura}/${data.valor}/${data.fechaVencimiento}',
              );
            }
          } else {
            setState(() {
              _errorMessage = "La factura escaneada ya se encuentra vencida.";
            });
          }
        } else {
          // Show invalid code warning
          setState(() {
            _errorMessage = "Alinee el código de barras dentro del recuadro.";
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = Theme.of(context).brightness == Brightness.dark;
    final activeTheme = darkTheme ? ServiciosPublicosTheme.darkTheme : ServiciosPublicosTheme.lightTheme;

    return Theme(
      data: activeTheme,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Escanear con cámara',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Stack(
          children: [
            // Mobile Scanner Camera View
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),

            // Scanning Overlay
            _buildOverlay(context),

            // Warning Messages (if any)
            if (_errorMessage != null)
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Loader when processing
            if (_isProcessing)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boxWidth = size.width * 0.8;
    final boxHeight = 150.0;

    return Stack(
      children: [
        // Semi-transparent background
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                color: Colors.transparent,
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: boxWidth,
                  height: boxHeight,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Framing border
        Align(
          alignment: Alignment.center,
          child: Container(
            width: boxWidth,
            height: boxHeight,
            decoration: BoxDecoration(
              border: Border.all(
                color: _errorMessage != null ? Colors.red : ServiciosPublicosTheme.primaryButton,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Corner marks decoration or target line
                Center(
                  child: Container(
                    width: boxWidth - 20,
                    height: 2,
                    color: Colors.red.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Helpful hint label
        Positioned(
          top: size.height * 0.25,
          left: 20,
          right: 20,
          child: const Text(
            'Ubica el código de barras de tu factura en el recuadro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
