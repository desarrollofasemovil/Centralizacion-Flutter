/// Resuelve el correo de soporte destino según el municipio. Port de
/// `data/provider/SupportEmailProvider.kt`.
class SupportEmailProvider {
  const SupportEmailProvider();

  static const String _defaultSupportEmail = 'fasemovilfirebase@gmail.com';

  String getSupportEmailFor(String municipality) {
    // TODO: cuando exista el mapeo real, reemplazar este switch.
    switch (municipality.toLowerCase()) {
      // case 'granada': return 'soporte.granada@tramitesxxx.com';
      // case 'itagui':  return 'soporte.itagui@tramitesxxx.com';
      default:
        return _defaultSupportEmail;
    }
  }
}
