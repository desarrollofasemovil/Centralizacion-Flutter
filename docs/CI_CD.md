# CI/CD — GitHub Actions

Dos workflows en `.github/workflows/` (más tres scripts en `.github/scripts/`):

| Workflow | Cuándo corre | Qué hace |
|---|---|---|
| `ci.yml` | PR hacia `develop` o `main` (y como puerta dentro de `release-internal.yml`) | `flutter pub get` → `flutter analyze` → `flutter test` (Flutter 3.44.0 stable) |
| `release-internal.yml` | Cada **push a `main`** (la fusión de `develop` → `main`), o a mano | Compila el **App Bundle** firmado del flavor `municipios` y lo publica en la **pista de pruebas internas** de Google Play |

El pipeline es un port del de 101Fintech (`desarrollofasemovil/101Fintech`), que ya publica así.

## Flujo de una publicación interna

1. **Subir la versión** en `pubspec.yaml` (`version: X.Y.Z+N`, una sola fuente: Gradle usa `flutter.versionCode`).
   El `N` (versionCode) tiene que ser **mayor que cualquiera ya usado en Play**: un número usado queda gastado para
   siempre, aunque esa versión se borre o nunca llegue a producción.
2. PR a `develop` → PR `develop` → `main`. Al fusionar, `release-internal.yml` corre solo.
3. **Guarda de versión (~1 min):** lee la versión y pregunta a la API de Play si el `versionCode` está libre. Si ya
   está usado, falla aquí, antes de compilar, diciendo cuál es el siguiente libre.
4. **Calidad:** reutiliza `ci.yml` (analyze + test).
5. **Compilar y publicar (~20-25 min):** firma, compila el AAB, lo guarda como artefacto (90 días), genera las notas
   de la versión desde los commits (`feat`/`fix`, máx. 480 caracteres por idioma) y lo publica en la pista interna
   con estado *completed*. Crea el tag `vX.Y.Z+N` (las notas de la siguiente versión se calculan desde él).

**Producción no se automatiza a propósito.** La cuenta de servicio solo tiene permiso sobre los canales de prueba;
promover a producción se hace a mano en Play Console.

### Modo "solo compilar"

Actions → *Publicar en pruebas internas* → *Run workflow* → marcar `solo_compilar`. Compila y firma el AAB sin hablar
con Play (útil si los permisos de la cuenta de servicio aún se están propagando o Play está caído). El resumen del run
explica cómo subirlo a mano. Solo se puede lanzar sobre `main`.

## Secretos requeridos (Settings → Secrets and variables → Actions)

| Secreto | Contenido |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | El keystore de subida (`keystorepach.jks`, la misma clave con la que se firmaba la app Kotlin) en base64 |
| `ANDROID_KEYSTORE_PASSWORD` | `storePassword` |
| `ANDROID_KEY_PASSWORD` | `keyPassword` |
| `ANDROID_KEY_ALIAS` | `keyAlias` |
| `GOOGLE_SERVICES_MUNICIPIOS_JSON_B64` | `android/app/src/municipios/google-services.json` en base64 |
| `GCP_WIF_PROVIDER` | Proveedor de Workload Identity Federation (ver [`release/CONFIGURAR_PLAY_CI.md`](release/CONFIGURAR_PLAY_CI.md)) |
| `GCP_SERVICE_ACCOUNT` | `play-ci-centralizacion@betaappcentralizate.iam.gserviceaccount.com` |

**No hay ninguna clave JSON de Google guardada.** GitHub presenta un token efímero y Google lo canjea; el proveedor
solo acepta tokens de este repositorio (`assertion.repository == 'desarrollofasemovil/Centralizacion-Flutter'`).

El workflow falla de forma explícita si falta un secreto de firma, y comprueba con `keytool` que el keystore abre
con el alias indicado (si no, Gradle daría un error críptico 20 minutos después).

Generar el base64 en PowerShell (copia el resultado al portapapeles):

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\ruta\keystorepach.jks")) | Set-Clipboard
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\app\src\municipios\google-services.json")) | Set-Clipboard
```

Ni el keystore ni `google-services.json` entran al repo (`.gitignore`). El workflow los escribe en el runner y los borra al terminar.

## Errores frecuentes

| Síntoma | Causa |
|---|---|
| 403 con `ACCESS_TOKEN_SCOPE_INSUFFICIENT` | Falta `access_token_scopes: …/androidpublisher` en el paso de autenticación (no es Play Console) |
| 403 sin esa frase | Permisos de la cuenta de servicio en Play Console ausentes o aún propagándose: usar `solo_compilar` |
| "El versionCode N ya está usado" | Subir `version:` en `pubspec.yaml` al número que indica el error |
| Notas rechazadas por longitud | No debería pasar: el script corta en 480 caracteres contando UTF-8 (`LC_ALL=C.UTF-8`) |

## Alcance y avisos

- **Solo Android, solo flavor `municipios`.** El flavor `manizales` no se compila (sigue en
  `MultiplatformCentralizacion`).
- **iOS:** irá por **Codemagic, lanzado a mano** (sin Mac no hay alternativa barata; los runners macOS de GitHub cuestan
  10× minutos). Checklist de rechazos de Apple en las memorias del proyecto 101Fintech.
- **El repositorio es público:** los artefactos (el AAB) los puede descargar cualquier usuario con sesión en GitHub, y
  la retención máxima es de 90 días. No es un secreto (es lo que distribuye Play), pero conviene saberlo.
- **ABIs:** pese al `abiFilters arm64-v8a` de `android/app/build.gradle.kts`, el AAB lleva `arm64-v8a`,
  `armeabi-v7a` y `x86_64` (verificado el 2026-10-05: Flutter pasa sus propias plataformas destino), así que Play
  sigue sirviendo la app a dispositivos de 32 bits, como la app Kotlin.
- **`flutter build appbundle` en local (Windows) puede terminar con "failed to strip debug symbols"** aunque el AAB
  se genere bien: esa verificación usa `apkanalyzer`, que rechaza el JDK 23 configurado en esta máquina. En el CI
  (JDK 17) no pasa. El AAB queda en `build/app/outputs/bundle/municipiosRelease/` gracias a la tarea
  `copy…FlutterBundle` de `build.gradle.kts` (Gradle lo deja en `android/app/build/outputs/bundle/`).
- **Sin ofuscación de Dart** (igual que antes): no hay símbolos que archivar. Si se activa `--obfuscate`, hay que
  archivar los símbolos de cada versión (ver el pipeline de 101Fintech).
- **Un test golpea la API real** (`GET /api/Department` devuelve 400 en la suite). Debe reemplazarse por un mock.
- Proteger `develop` y `main` con el check requerido **Analyze & test** y restringir quién fusiona a `main`: esa
  fusión publica en la pista interna.
