# Trami App — Estrategia de FLAVORS en Flutter (apps individuales por municipio)

> **Propósito.** Definir cómo, desde un **único proyecto Flutter**, generar múltiples apps independientes (Trami App Municipios + una Trami App Individual por municipio, empezando por **Manizales**) sin duplicar código y de forma **fácil de mantener**. Objetivo central: que agregar un municipio nuevo sea una receta mecánica de pocos pasos, sin tocar la lógica de negocio.
>
> Documentos hermanos: `MIGRACION_FLUTTER_BACKEND.md` (servicios) y `MIGRACION_FLUTTER_FRONTEND.md` (comportamiento).
>
> **Regla de oro de todo este documento:** un flavor define **solo identidad de build** (nombre, bundle id, ícono, proyecto Firebase, municipioId fijo). Los **colores, escudo y módulos los sigue definiendo el backend** vía `GET /api/Municipality/GetInfoBy{id}` (ver BACKEND §4.1 y §7). No metas colores/módulos en el flavor.

---

## 1. Qué es y qué NO es un flavor

| Lo define el FLAVOR (build-time, fijo en el binario) | NO lo define el flavor |
|---|---|
| Nombre visible de la app (label) | Colores de la UI → backend (`theme`) |
| `applicationId` (Android) / `bundleId` (iOS) | Escudo/logo dentro de la app → backend (`idShield.url`) |
| Ícono de launcher (no se cambia en runtime) | Módulos activos (Cursos, Escenarios, etc.) → backend (`MunicipalityDTO`) |
| Cuál `google-services.json` / `GoogleService-Info.plist` se empaqueta | Textos, anuncios, estado de la app → backend / Remote Config |
| `municipioId` fijo (o `null` para el modo selector) | Trámites, PQRD, pagos → backend por `entityCode`/`id` |
| Mostrar u ocultar el selector de municipio | — |

**Consecuencia para mantenimiento:**
- Cambio en el **backend** (color, módulo, anuncio) → se propaga **instantáneo** a todas las apps, sin recompilar.
- Cambio en **código Flutter** (pantalla, fix) → aplica a todos los flavors al **recompilar y republicar cada uno**. Con N municipios, un fix = N builds + N releases. → Por eso todo lo que pueda vivir en backend, debe vivir en backend.

---

## 2. Modelo de flavors recomendado

Empezamos con **2 flavors** y la estructura queda lista para N:

| Flavor | App | municipioId | Selector | Firebase | applicationId / bundleId |
|---|---|---|---|---|---|
| `municipios` | Trami App Municipios | `null` (dinámico) | Sí | Proyecto actual (el del `google-services.json` existente) | `com.tramites1cero1.centralizacion` (igual al actual, para conservar la app de Play Store) |
| `manizales` | Trami App Manizales | fijo (id de Manizales) | No | Proyecto nuevo de Manizales | `com.tramitesapp.manizales` (sugerido — confirmar) |

> **Importante para no romper la app en producción:** el flavor `municipios` debe conservar **exactamente** el `applicationId` actual `com.tramites1cero1.centralizacion` (versionCode actual = 48, versionName = 1.4.6) si en algún momento esa app Flutter reemplaza a la Android nativa en la misma ficha de Play Store. Si no, sería una app distinta.

---

## 3. Fuente única de verdad: el `FlavorConfig`

Toda la diferencia entre apps se concentra en **un solo objeto Dart**. Nada de `if (flavor == 'manizales')` desperdigados por el código — eso es lo que genera problemas a futuro.

```dart
// lib/core/flavor/flavor_config.dart
enum Flavor { municipios, manizales }

class FlavorConfig {
  final Flavor flavor;
  final String appName;            // label visible
  final int? fixedMunicipalityId;  // null => modo selector (Municipios)
  final bool showMunicipalitySelector;
  final String fcmTopicPrefix;     // "theme_" (igual que hoy)
  // NADA de colores/módulos aquí: eso viene del backend.

  const FlavorConfig({
    required this.flavor,
    required this.appName,
    required this.fixedMunicipalityId,
    required this.showMunicipalitySelector,
    this.fcmTopicPrefix = 'theme_',
  });

  bool get isIndividual => fixedMunicipalityId != null;

  static late FlavorConfig instance;   // se setea en el entrypoint
}
```

Regla de uso en el código:
- ¿La app entra directo a un municipio? → `FlavorConfig.instance.isIndividual`.
- ¿Muestro el selector / Welcome? → `FlavorConfig.instance.showMunicipalitySelector`.
- ¿Qué id pido al backend al arrancar? → `FlavorConfig.instance.fixedMunicipalityId ?? <id guardado por el usuario>`.

> Así, si mañana una app individual necesita comportamiento distinto, se agrega **un campo al `FlavorConfig`**, no condicionales por todo el árbol.

---

## 4. Entrypoints por flavor (un `main_*.dart` por app)

Un archivo de arranque mínimo por flavor; todos delegan en un `bootstrap()` común.

```
lib/
├── main_municipios.dart      // entrypoint flavor municipios
├── main_manizales.dart       // entrypoint flavor manizales
├── bootstrap.dart            // init común (Firebase, RC, runApp)
└── core/flavor/
    ├── flavor_config.dart
    └── flavors.dart          // tabla con la config de cada flavor (ver §8)
```

```dart
// lib/main_manizales.dart
import 'core/flavor/flavors.dart';
import 'bootstrap.dart';

Future<void> main() async {
  await bootstrap(flavorManizales);   // flavorManizales viene de flavors.dart
}
```

```dart
// lib/bootstrap.dart
Future<void> bootstrap(FlavorConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.instance = config;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // init Remote Config, Crashlytics, etc.
  runApp(const TramiApp());
}
```

Ejecutar en desarrollo:
```bash
flutter run --flavor manizales -t lib/main_manizales.dart
flutter run --flavor municipios -t lib/main_municipios.dart
```

---

## 5. Configuración Android (productFlavors)

En `android/app/build.gradle` (o `.kts`):

```kotlin
android {
    // ...
    flavorDimensions += "app"
    productFlavors {
        create("municipios") {
            dimension = "app"
            applicationId = "com.tramites1cero1.centralizacion"   // conserva la app actual
            resValue("string", "app_name", "Trami App Municipios")
        }
        create("manizales") {
            dimension = "app"
            applicationId = "com.tramitesapp.manizales"
            resValue("string", "app_name", "Trami App Manizales")
        }
    }
}
```

**`google-services.json` por flavor** (cada uno con su proyecto Firebase):
```
android/app/src/municipios/google-services.json   ← el actual
android/app/src/manizales/google-services.json    ← nuevo, proyecto Manizales
```
El plugin `com.google.gms.google-services` toma automáticamente el archivo de la carpeta del flavor en build.

**Ícono por flavor:** carpeta `android/app/src/<flavor>/res/mipmap-*/` con su `ic_launcher`. (Recomendado generar con `flutter_launcher_icons` por flavor — ver §9.)

**Firma:** ya existe `keystorepach.jks` en la raíz. Definir `signingConfigs` y aplicarlo en `buildTypes.release`. Mismo keystore puede firmar todos los flavors; solo el `applicationId` cambia. (Mantener credenciales del keystore fuera del repo, en `key.properties` / `local.properties`.)

---

## 6. Configuración iOS (schemes + configs)

iOS no tiene "product flavors"; se usan **Build Configurations + Schemes + Targets/xcconfig**. Pasos (en Xcode, sobre `ios/Runner.xcworkspace`):

1. Crear un **Scheme** por flavor: `municipios`, `manizales`.
2. Duplicar las Build Configurations (`Debug-manizales`, `Release-manizales`, etc.) o usar `xcconfig` por flavor con:
   - `PRODUCT_BUNDLE_IDENTIFIER` = bundle del flavor.
   - `PRODUCT_NAME` / `DISPLAY_NAME` = nombre de la app.
3. **`GoogleService-Info.plist` por flavor**: agregar un Run Script (Build Phase) que copie el `.plist` correcto según la configuración, o usar carpetas por configuración:
   ```
   ios/config/municipios/GoogleService-Info.plist
   ios/config/manizales/GoogleService-Info.plist
   ```
4. Ícono por flavor: asset catalog por configuración (o `flutter_launcher_icons`).
5. **Google Sign-In:** cada flavor necesita su `REVERSED_CLIENT_ID` en `Info.plist` (URL Types), tomado del `GoogleService-Info.plist` de su proyecto Firebase.
6. **APNs:** subir la APNs Auth Key (.p8) en cada proyecto Firebase para que FCM funcione en iOS.

Ejecutar:
```bash
flutter run --flavor manizales -t lib/main_manizales.dart
flutter build ipa --flavor manizales -t lib/main_manizales.dart
```

> **Recomendación fuerte para no sufrir el setup manual de iOS+Android:** usar el paquete **`flutter_flavorizr`**, que genera automáticamente productFlavors de Android, schemes/configs de iOS, los `main_*.dart` y la estructura de assets a partir de un bloque en `pubspec.yaml`. Configurarlo una vez y dejar documentado el bloque (ver §9).

---

## 7. Firebase por flavor (con FlutterFire CLI)

Cada app individual usa **su propio proyecto Firebase** (analytics/push/crashlytics separados por municipio). Generar la config con:

```bash
# Proyecto Manizales
flutterfire configure \
  --project=trami-manizales \
  --out=lib/firebase/firebase_options_manizales.dart \
  --ios-bundle-id=com.tramitesapp.manizales \
  --android-package-name=com.tramitesapp.manizales

# Proyecto Municipios (el existente)
flutterfire configure \
  --project=<proyecto-actual> \
  --out=lib/firebase/firebase_options_municipios.dart \
  --ios-bundle-id=com.tramites1cero1.centralizacion \
  --android-package-name=com.tramites1cero1.centralizacion
```

Luego cada `bootstrap` inicializa con su `firebase_options_*.dart`. Las **mismas keys de Remote Config** (`welcome_carousel_images`, `app_status_config`, `send_to_welcome`, `tourism_tax_rates`) deben existir en **cada** proyecto Firebase (ver BACKEND §6.1).

> ⚠️ Checklist Firebase por nuevo municipio: (1) crear proyecto, (2) registrar apps iOS+Android con el bundle/package del flavor, (3) descargar `google-services.json` y `GoogleService-Info.plist`, (4) subir APNs key, (5) crear las 4 keys de Remote Config, (6) habilitar Google como proveedor de Auth.

---

## 8. Tabla central de flavors (un solo lugar para editarlos)

Para que agregar municipios sea trivial, centralizar las definiciones:

```dart
// lib/core/flavor/flavors.dart
const flavorMunicipios = FlavorConfig(
  flavor: Flavor.municipios,
  appName: 'Trami App Municipios',
  fixedMunicipalityId: null,
  showMunicipalitySelector: true,
);

const flavorManizales = FlavorConfig(
  flavor: Flavor.manizales,
  appName: 'Trami App Manizales',
  fixedMunicipalityId: 12,            // ⚠️ reemplazar por el id real de Manizales en el backend
  showMunicipalitySelector: false,
);
```

> **Dato pendiente crítico:** confirmar el `id` (Int) de Manizales que espera `GET /api/Municipality/GetInfoBy{id}`. Ese número es lo único "de negocio" que hace que la app sea de Manizales. Anótalo aquí cuando se confirme.

---

## 9. Bloque `flutter_flavorizr` sugerido (automatiza el setup)

Para no configurar iOS/Android a mano cada vez:

```yaml
# pubspec.yaml
flavorizr:
  app:
    android:
      flavorDimensions: "app"
    ios: {}
  flavors:
    municipios:
      app:
        name: "Trami App Municipios"
      android:
        applicationId: "com.tramites1cero1.centralizacion"
      ios:
        bundleId: "com.tramites1cero1.centralizacion"
    manizales:
      app:
        name: "Trami App Manizales"
      android:
        applicationId: "com.tramitesapp.manizales"
      ios:
        bundleId: "com.tramitesapp.manizales"
```

Íconos por flavor con `flutter_launcher_icons` (un config por flavor) o `icons_launcher`.

---

## 10. CI/CD — un job por flavor

Pipeline (GitHub Actions, mac-runner para iOS). Matriz por flavor:

```yaml
strategy:
  matrix:
    flavor: [municipios, manizales]
steps:
  - run: flutter build apk    --flavor ${{ matrix.flavor }} -t lib/main_${{ matrix.flavor }}.dart --release
  - run: flutter build appbundle --flavor ${{ matrix.flavor }} -t lib/main_${{ matrix.flavor }}.dart --release
  - run: flutter build ipa    --flavor ${{ matrix.flavor }} -t lib/main_${{ matrix.flavor }}.dart --release
```

- Publicación: `fastlane` con un `lane` por flavor/tienda (cada flavor a su ficha de Play Store / App Store, todas bajo la **cuenta de la empresa** — `Store ownership: ustedes`).
- Versionado: `versionCode`/`versionName` pueden compartirse o gestionarse por flavor; mantener un esquema único evita confusiones (ej. todos parten de versionCode 48 / 1.4.6, el actual).

---

## 11. Playbook: agregar un municipio nuevo (receta de N pasos)

Para "Trami App Pereira" (ejemplo):

1. **Backend:** confirmar que el municipio existe y obtener su `id` y `entityCode` (el backend ya entrega su config por `GetInfoBy{id}`). **Cero cambios de backend.**
2. **Firebase:** crear proyecto, registrar apps iOS+Android con el bundle/package nuevo, descargar configs, subir APNs key, crear las 4 keys de Remote Config, habilitar Google Auth (§7).
3. **`flavors.dart`:** agregar `flavorPereira` con `appName`, `fixedMunicipalityId`, `showMunicipalitySelector: false`.
4. **Entrypoint:** crear `lib/main_pereira.dart` (3 líneas).
5. **`pubspec.yaml` flavorizr:** agregar el flavor `pereira` y correr `flutter pub run flutter_flavorizr` (genera productFlavor Android + scheme iOS).
6. **Configs Firebase a su sitio:** `android/app/src/pereira/google-services.json` e `ios/config/pereira/GoogleService-Info.plist`.
7. **Ícono:** generar con `flutter_launcher_icons` para el flavor.
8. **iOS signing:** crear bundle id + Provisioning Profile en Apple Developer.
9. **CI:** agregar `pereira` a la matriz y un lane de fastlane.
10. **Build + publicar:** `flutter build appbundle/ipa --flavor pereira -t lib/main_pereira.dart`.

> Si todo lo anterior está bien centralizado (§3, §8), los pasos de **código** son 3, 4 y 5. El resto es configuración de plataforma/tienda, inevitable por las reglas de Apple/Google.

---

## 12. Errores comunes a evitar (para no sufrir después)

1. **Meter colores/módulos en el flavor.** No. Eso es del backend; si lo duplicas, tendrás que recompilar por cada cambio de marca. (El backend ya lo resuelve por `id`.)
2. **Condicionales `if (flavor == X)` regados.** Centraliza todo en `FlavorConfig`. Un comportamiento nuevo = un campo nuevo.
3. **Olvidar el `-t lib/main_<flavor>.dart`.** El `--flavor` solo no basta; sin el entrypoint correcto se inicializa el Firebase equivocado.
4. **Mezclar `google-services.json`.** Cada flavor en su carpeta `src/<flavor>/`. Un archivo mal ubicado hace que el push/analytics vaya al proyecto equivocado.
5. **iOS sin `REVERSED_CLIENT_ID` por flavor.** Google Sign-In falla silenciosamente.
6. **iOS sin APNs key por proyecto.** Las notificaciones no llegan en iPhone.
7. **Reusar el `applicationId` para una app que debe ser distinta** (o cambiarlo en el flavor que debía conservar la app de Play Store). Decide desde el día 1 cuál flavor hereda la app actual de Municipios.
8. **Remote Config sin las keys en el proyecto nuevo.** La app del municipio nuevo no sabrá su estado/anuncios. Crear las 4 keys siempre.
9. **No fijar/confirmar el `municipioId`.** Sin el `id` correcto en `flavors.dart`, la app individual pedirá la config equivocada al backend.
10. **Suscripción FCM acumulativa en app individual.** En Municipios la suscripción a tópicos es acumulativa; una app individual debe suscribirse **solo** a su `theme_<municipio>`.

---

## 13. Checklist de "app individual lista"

- [ ] `id` y `entityCode` del municipio confirmados con el backend.
- [ ] Proyecto Firebase creado (iOS+Android registrados, APNs, 4 keys de Remote Config, Google Auth).
- [ ] `flavors.dart` + `main_<flavor>.dart` agregados.
- [ ] productFlavor Android + scheme iOS generados (flavorizr).
- [ ] `google-services.json` / `GoogleService-Info.plist` en sus carpetas.
- [ ] `REVERSED_CLIENT_ID` en `Info.plist` (iOS).
- [ ] Ícono y `app_name` por flavor.
- [ ] Bundle id + Provisioning Profile en Apple Developer.
- [ ] Firma Android configurada (keystore).
- [ ] App arranca directo al municipio (sin Welcome/selector) y carga colores/escudo/módulos del backend.
- [ ] Push de prueba recibido en iOS y Android.
- [ ] Job de CI + lane de publicación agregados.

---

*Generado a partir del estado real del proyecto Android (`com.tramites1cero1.centralizacion`, versionCode 48, versionName 1.4.6, keystore `keystorepach.jks`, `google-services.json` único actual). Estrategia para el proyecto Flutter nuevo. Prioridad: Trami App Manizales.*
