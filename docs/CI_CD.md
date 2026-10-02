# CI/CD — GitHub Actions

Dos workflows en `.github/workflows/`:

| Workflow | Cuándo corre | Qué hace |
|---|---|---|
| `ci.yml` | PR hacia `develop` o `main` | `flutter pub get` → `flutter analyze` → `flutter test` (Flutter 3.44.0 stable) |
| `release-apk.yml` | **Solo** cuando se **fusiona** un PR `develop` → `main` | Compila el APK release firmado por flavor y lo sube como artefacto (30 días) |

`release-apk.yml` no corre en pushes directos a `main`, en PRs sin fusionar, ni en PRs que vengan de otra rama o de un fork
(la condición exige `merged == true`, `head.ref == 'develop'` y mismo repositorio). Compila el commit de fusión
(`merge_commit_sha`), no el HEAD del PR.

## Alcance actual

- **Solo Android, solo flavor `municipios`.** El flavor `manizales` no se compila: en este repo sigue con
  `fixedMunicipalityId: 0` y sin `android/app/src/manizales/` (el trabajo vive en `MultiplatformCentralizacion`).
  Para sumarlo: agregar `manizales` a la matriz de `release-apk.yml` y un secreto `google-services.json` propio.
- **iOS queda fuera** (falta cuenta de Apple Developer, bundle id, `GoogleService-Info.plist`, APNs y un runner macOS).
- **No se publica en Play Store**: solo se genera el APK como artefacto del run.

## Secretos requeridos (Settings → Secrets and variables → Actions)

| Secreto | Contenido |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | El keystore (`keystorepach.jks`) en base64 |
| `ANDROID_KEYSTORE_PASSWORD` | `storePassword` |
| `ANDROID_KEY_PASSWORD` | `keyPassword` |
| `ANDROID_KEY_ALIAS` | `keyAlias` |
| `GOOGLE_SERVICES_MUNICIPIOS_JSON_B64` | `android/app/src/municipios/google-services.json` en base64 |

El workflow falla de forma explícita si falta alguno. Es intencional: sin `key.properties`, Gradle firmaría el
"release" con la debug key.

Generar el base64 en PowerShell (copia el resultado al portapapeles):

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\ruta\keystorepach.jks")) | Set-Clipboard
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\app\src\municipios\google-services.json")) | Set-Clipboard
```

Ni el keystore ni `google-services.json` entran al repo (`.gitignore`). El workflow los escribe en el runner y los borra al terminar.

## Recomendaciones de repositorio

- Proteger `develop` y `main` con el check requerido **Analyze & test** (Settings → Branches).
- Restringir quién puede fusionar a `main`: esa fusión dispara un build firmado.

## Pendientes y avisos

- **`versionCode`.** El `pubspec.yaml` está en `1.0.0+1`. La ficha de Play Store de la app Android nativa va en
  `versionCode 48` (versionName 1.4.6): antes de subir un APK/AAB de este repo hay que subir `version:` por encima.
  El workflow no toca el número de build.
- **Un test golpea la API real** (`GET /api/Department` devuelve 400 en la suite; pasa, pero depende de red).
  Debe reemplazarse por un mock.
- **Cobertura baja** (6 archivos de test); `dart format` no se verifica todavía.
- Compila APK (`--release`, `arm64-v8a` según `abiFilters`), no AAB: Play Store pedirá AAB.
