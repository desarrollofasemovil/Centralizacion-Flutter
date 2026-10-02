# Centralizacion-Flutter

Migración de **Trami App Municipios** (Kotlin/Jetpack Compose) a **Flutter**, con flavors por municipio (`municipios`, `manizales`).

- Empieza por [`CLAUDE.md`](CLAUDE.md): reglas de oro, mapa de documentos y flujo de trabajo.
- Documentación de la migración en [`docs/`](docs/) (`MIGRACION_FLUTTER_*.md`).
- El código Kotlin original (fuente de verdad del diseño) se espeja localmente en `codebase/` (no versionado); ver instrucciones en `CLAUDE.md`.
- Traductor de DTOs Kotlin → Dart en [`migration-agent/`](migration-agent/).

```bash
flutter pub get
flutter run --flavor municipios -t lib/main_municipios.dart
```

> El nombre del paquete Dart sigue siendo `tramiapp_flutter` (ver `pubspec.yaml`); no se renombra para no romper los imports.
