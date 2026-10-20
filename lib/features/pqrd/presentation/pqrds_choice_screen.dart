import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/municipality/municipality_repository.dart';
import '../../../core/utils/url_opener.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/dialog_typography.dart';
import '../application/pqrd_notifier.dart';

class PqrdsChoiceScreen extends ConsumerWidget {
  const PqrdsChoiceScreen({required this.municipalityId, super.key});
  final int municipalityId;

  /// Ley de Habeas Data (Ley 1581 de 2012) en el gestor normativo de Función
  /// Pública. Es HTTPS: se puede abrir en el navegador in-app, también en iOS.
  static const _habeasDataUrl =
      'https://www.funcionpublica.gov.co/eva/gestornormativo/norma_pdf.php?i=49981';

  /// Aviso de Habeas Data antes de entrar a una PQRSDF. Lo muestra el toque en
  /// cualquiera de las dos tarjetas: "Continuar" sigue al formulario de esa
  /// tarjeta y "Cancelar" (o la X) se queda en esta pantalla.
  ///
  /// Parte del `InformationDialog` de `PqrdsChoiceScreen.kt` (X arriba, título y
  /// texto), que en el Kotlin de producción está definido pero no se llama. A
  /// diferencia de ese original, el enlace se puede tocar y los botones son
  /// Cancelar / Continuar en vez de volver a elegir el tipo de PQRSDF.
  void _showHabeasDataDialog(
    BuildContext context, {
    required VoidCallback onContinue,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          icon: Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () => Navigator.of(ctx).pop(),
              icon: const Icon(Icons.close),
              tooltip: 'Cerrar',
            ),
          ),
          iconColor: scheme.onSurfaceVariant,
          title: const Text(
            'Mensaje del sistema de información',
            textAlign: TextAlign.center,
          ),
          // Título por defecto de un AlertDialog de Compose (headlineSmall del
          // `Type.kt`) con `fontWeight = Bold`.
          titleTextStyle: DialogTypography.headlineSmall.copyWith(
            color: scheme.onSurface,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                // Copy del original; solo se corrige la tilde de "dé" y el
                // espacio de "Decreto 1377".
                'Ciudadano/a tenga en cuenta que la información a registrar en el siguiente formulario se encuentra protegida bajo la ley del Habeas data - Ley 1581 de 2012, Decreto 1377 de 2013- si quiere conocer más sobre esta ley dé click:',
                textAlign: TextAlign.justify,
                style: DialogTypography.withFontSize(
                  DialogTypography.bodyMedium,
                  14,
                ).copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () =>
                    abrirUrl(_habeasDataUrl, toolbarColor: scheme.primary),
                child: Text(
                  _habeasDataUrl,
                  textAlign: TextAlign.center,
                  style: DialogTypography.withFontSize(
                    DialogTypography.bodyMedium,
                    12,
                  ).copyWith(
                    color: const Color(0xFF0000FF),
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFF0000FF),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Uno al lado del otro, a todo el ancho y separados 5 px.
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onContinue();
                      },
                      child: const Text('Continuar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final asyncMun = ref.watch(municipalityProvider(municipalityId));

    return asyncMun.maybeWhen(
      data: (munDto) {
        final entityCode = munDto.entityCode;
        // Carga los catálogos y navega al formulario del tipo elegido.
        void goToForm(String kind) {
          ref
              .read(pqrdDropdownOptionsProvider.notifier)
              .loadCatalogData(entityCode);
          context.push('/municipality/$municipalityId/pqrd/$kind');
        }

        void showNotice(String kind) => _showHabeasDataDialog(
          context,
          onContinue: () => goToForm(kind),
        );

        return Scaffold(
          appBar: AppTopBar(title: 'PQRSDF', onBack: () => context.pop()),
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
                  Text(
                    'Puedes registrar una solicitud identificada para realizar seguimiento, o una anónima.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Tarjeta PQRSDF Identificada
                  _ChoiceCard(
                    title: 'P.Q.R.S.D Identificada',
                    description: 'Podrá recibir un radicado y hacer seguimiento de su trámite',
                    icon: Icons.person,
                    imagePath: 'assets/images/fondopqrdidentifi.png',
                    onTap: () => showNotice('identificada'),
                  ),
                  const SizedBox(height: 24),
                  // Tarjeta PQRSDF Anónima
                  _ChoiceCard(
                    title: 'P.Q.R.S.D Anónima',
                    description: 'No se guardan sus datos de contacto ni podrá consultar la respuesta',
                    icon: Icons.lock_person,
                    imagePath: 'assets/images/fondopqrds.png',
                    onTap: () => showNotice('anonima'),
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
      orElse: () => Scaffold(
        appBar: AppTopBar(title: 'PQRSDF', onBack: () => context.pop()),
        body: const Center(child: CircularProgressIndicator()),
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
