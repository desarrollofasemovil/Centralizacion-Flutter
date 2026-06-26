import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/municipality/municipality_repository.dart';
import '../application/pqrd_notifier.dart';

class PqrdsChoiceScreen extends ConsumerWidget {
  const PqrdsChoiceScreen({required this.municipalityId, super.key});
  final int municipalityId;

  void _showHabeasDataDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Mensaje del sistema de información',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ciudadano/a tenga en cuenta que la información a registrar en el siguiente formulario se encuentra protegida bajo la ley del Habeas data - Ley 1581 de 2012, Decreto 1377 de 2013- si quiere conocer más sobre esta ley dé clic aquí:',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                // Abre el PDF de Habeas Data
              },
              child: const Text(
                'http://www.mintic.gov.co/portal/604/articles-4274_documento.pdf',
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Aceptar y Continuar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final asyncMun = ref.watch(municipalityProvider(municipalityId));

    return asyncMun.maybeWhen(
      data: (munDto) {
        final entityCode = munDto.entityCode;
        return Scaffold(
          appBar: AppBar(
            title: const Text('PQRSDF'),
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Seleccione el tipo de PQRSDF',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Puedes registrar una solicitud identificada para realizar seguimiento, o una anónima.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 32),
                  // Tarjeta PQRSDF Identificada
                  _ChoiceCard(
                    title: 'P.Q.R.S.D Identificada',
                    description: 'Podrá recibir un radicado y hacer seguimiento de su trámite',
                    icon: Icons.person,
                    imagePath: 'assets/images/fondopqrdidentifi.png',
                    onTap: () {
                      _showHabeasDataDialog(context, () {
                        // Carga los catálogos y navega
                        ref.read(pqrdDropdownOptionsProvider.notifier).loadCatalogData(entityCode);
                        context.push('/municipality/$municipalityId/pqrd/identificada');
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  // Tarjeta PQRSDF Anónima
                  _ChoiceCard(
                    title: 'P.Q.R.S.D Anónima',
                    description: 'No se guardan sus datos de contacto ni podrá consultar la respuesta',
                    icon: Icons.lock_person,
                    imagePath: 'assets/images/fondopqrds.png',
                    onTap: () {
                      _showHabeasDataDialog(context, () {
                        // Carga los catálogos y navega
                        ref.read(pqrdDropdownOptionsProvider.notifier).loadCatalogData(entityCode);
                        context.push('/municipality/$municipalityId/pqrd/anonima');
                      });
                    },
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      orElse: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.imagePath,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final String imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primary,
                  foregroundColor: Colors.white,
                  radius: 24,
                  child: Icon(icon, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
