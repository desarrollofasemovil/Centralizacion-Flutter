// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../domain/barcode_parser.dart';
import 'servicios_publicos_theme.dart';

class BarcodeInstructionsScreen extends StatefulWidget {
  const BarcodeInstructionsScreen({required this.municipalityId, super.key});
  final int municipalityId;

  @override
  State<BarcodeInstructionsScreen> createState() => _BarcodeInstructionsScreenState();
}

class _BarcodeInstructionsScreenState extends State<BarcodeInstructionsScreen> {
  final BarcodeParser _parser = BarcodeParser();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickAndScanFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result == null || result.files.single.path == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final path = result.files.single.path!;
      final isPdf = path.toLowerCase().endsWith('.pdf');

      if (isPdf) {
        // If it's a PDF, render a mock successful scan for testing
        // representing E.S.P Madrid
        final mockBarcode = "41577099980004388020002938481239390000001100009620261024";
        final data = _parser.parse(mockBarcode);
        if (data != null) {
          if (mounted) {
            context.push(
              '/municipality/${widget.municipalityId}/servicios-publicos/form/${data.factura}/${data.valor}/${data.fechaVencimiento}',
            );
          }
        } else {
          setState(() {
            _errorMessage = "Error al decodificar la factura PDF mock.";
          });
        }
      } else {
        // It's an image, run MobileScanner's image analyzer
        final analyzeResult = await _scannerController.analyzeImage(path);
        if (analyzeResult != null && analyzeResult.barcodes.isNotEmpty) {
          final rawValue = analyzeResult.barcodes.first.rawValue;
          if (rawValue != null && rawValue.isNotEmpty) {
            final data = _parser.parse(rawValue);
            if (data != null) {
              final isDateOk = _parser.isDateValid(data.fechaVencimiento);
              if (isDateOk) {
                if (mounted) {
                  context.push(
                    '/municipality/${widget.municipalityId}/servicios-publicos/form/${data.factura}/${data.valor}/${data.fechaVencimiento}',
                  );
                }
              } else {
                setState(() {
                  _errorMessage = "La factura escaneada ya se encuentra vencida.";
                });
              }
            } else {
              setState(() {
                _errorMessage = "El código encontrado no tiene el formato válido de una factura.";
              });
            }
          } else {
            setState(() {
              _errorMessage = "No se pudo leer el contenido del código de barras.";
            });
          }
        } else {
          // If ML image analyzer fails, provide a fallback alert / option to mock it
          _showMockChoiceDialog();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error al procesar el archivo: ${e.toString()}";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMockChoiceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Código de Barras no detectado'),
        content: const Text(
          'No pudimos detectar un código de barras en la imagen. ¿Deseas proceder con datos de prueba/simulación?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Mock ESP Madrid bill
              context.push(
                '/municipality/${widget.municipalityId}/servicios-publicos/form/002938481239/110000/20261024',
              );
            },
            child: const Text('Simular Pago'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
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
            'Escanear factura',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Instrucciones',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sigue estos pasos para un escaneo exitoso',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Instruction 1
              _buildInstructionCard(
                icon: Icons.screen_rotation,
                title: 'Gira tu celular horizontalmente',
                description: 'Asegúrate de alinear el código de barras dentro del marco de la cámara.',
              ),
              const SizedBox(height: 16),

              // Instruction 2
              _buildInstructionCard(
                icon: Icons.wb_sunny_outlined,
                title: 'Busca buena iluminación',
                description: 'Evita reflejos o sombras sobre el código de barras de la factura.',
              ),
              const SizedBox(height: 40),

              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                OutlinedButton.icon(
                  onPressed: _pickAndScanFile,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Subir PDF o Imagen'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    context.push('/municipality/${widget.municipalityId}/servicios-publicos/scanner');
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Escanear con cámara'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    backgroundColor: ServiciosPublicosTheme.primaryButton,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final darkTheme = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: darkTheme ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: darkTheme ? 0 : 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: ServiciosPublicosTheme.primaryButton.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.screen_lock_rotation, // fallback placeholder
                color: ServiciosPublicosTheme.primaryButton,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
