# Convenciones del proyecto Flutter

> Reglas de arquitectura y código para que **cada módulo migrado se vea igual**. Si dudas entre dos formas de hacer algo, la que esté aquí gana. Estas convenciones traducen la arquitectura Clean + Hilt + Compose del proyecto Kotlin a su equivalente Flutter.

---

## 1. Estructura de carpetas

```
lib/
├── core/                       # Compartido por toda la app
│   ├── api/                    # Dio, interceptores, factory de servicios por base URL
│   ├── models/                 # DTOs (json_serializable) — salida del agente traductor
│   ├── auth/                   # Sesión, login nativo + Google
│   ├── theme/                  # ThemeData dinámico desde el backend
│   ├── router/                 # go_router
│   ├── storage/                # shared_preferences / Hive
│   └── flavor/                 # FlavorConfig + flavors.dart
├── features/                   # Un directorio por módulo
│   └── <feature>/
│       ├── data/               # repositorios (implementación)
│       ├── domain/             # modelos de dominio + interfaces
│       ├── application/        # providers/notifiers (estado)
│       └── presentation/       # pantallas + widgets
├── main_municipios.dart        # entrypoint flavor municipios
└── main_manizales.dart         # entrypoint flavor manizales
```

Un *feature* = un módulo del catálogo de `FRONTEND.md §5` (tramites, pqrd, impuestos, certificados, servicios_publicos, pagos, cursos, escenarios, noticias, recordatorios, soporte, auth, perfil).

---

## 2. Equivalencias de stack (Kotlin → Dart)

| Concepto | Android actual | Flutter |
|---|---|---|
| UI | Jetpack Compose | Widgets |
| Estado / ViewModel | ViewModel + StateFlow | **Riverpod** (`AsyncNotifier` / `Notifier`) |
| Inyección de dependencias | Hilt | Riverpod providers (+ get_it si hace falta) |
| HTTP | Retrofit + OkHttp | **dio + retrofit** |
| Serialización | Gson (`@SerializedName`) | **json_serializable** (`@JsonKey(name:)`) |
| Navegación | Navigation Component | **go_router** |
| Imágenes | Coil | cached_network_image |
| Cámara/QR | ML Kit + CameraX | mobile_scanner |
| Local | DataStore | shared_preferences / Hive |
| WebView/Tabs | WebKit + Custom Tabs | flutter_inappwebview / url_launcher |
| Push | FCM | firebase_messaging |

---

## 3. Estado con Riverpod

- Cada `*ViewModel` de Kotlin se convierte en un `Notifier`/`AsyncNotifier`.
- El estado de pantalla se modela con una clase (sello/`sealed`-like) equivalente a los `UiState`:
  `Loading` / `Success(data)` / `Error(message)` / `Empty`.
- El `MunicipalityViewModel` (config del municipio) se expone como un provider de alcance superior y se consume en todo el subárbol del flujo de alcaldías — equivalente al ViewModel compartido a nivel de grafo (`FRONTEND.md §2.1`).

```dart
@riverpod
class MunicipalityNotifier extends _$MunicipalityNotifier {
  @override
  Future<MunicipalityModel> build(int municipalityId) =>
      ref.read(municipalityRepositoryProvider).getMunicipalityData(municipalityId);
}
```

---

## 4. Capa de red

- Un único `Dio` configurado en `core/api/` con timeouts de 40s y un **interceptor global** equivalente a `GlobalErrorInterceptor` (`BACKEND.md §1.1`): publica estado en el provider de estado global y relanza el error.
- Servicios `retrofit` por microservicio, cada uno con su base URL (`BACKEND.md §2`).
- **Convención crítica de respuesta:** el éxito se evalúa por `booleanStatus`, no por el HTTP code. En login, el token viaja en `sentencesError`. No trates `sentencesError` siempre como error. Ver `BACKEND.md §4.2`.

---

## 5. Modelos / DTOs

- Generados con el agente traductor (`migration-agent/`), uno por archivo, en `core/models/`.
- **Conservar los nombres JSON exactos** con `@JsonKey(name: '...')` donde el Kotlin use `@SerializedName`.
- Nombres de archivo en snake_case: `UserDTO.kt` → `user_dto.dart`.
- Nullables de Kotlin (`String?`) → nullables en Dart (`String?`).

---

## 6. Theming dinámico

- Los colores llegan en `MunicipalityDTO.theme` como hex (`"0xFFRRGGBB"`); el escudo en `idShield.url`.
- Parsear los hex con la misma defensa que `parseColor` (quita `0x`, espera 8 chars ARGB, fallback). Construir `ColorScheme` con `.copyWith(primary:…, secondary:…)`.
- El escudo se carga con `cached_network_image`.
- Mantener un tema neutro (`InicialTheme`) para Welcome/Selector y el tema propio de Servicios Públicos como subárbol aparte (`FRONTEND.md §4`).

---

## 7. Navegación

- go_router con rutas anidadas; usar `ShellRoute` para el flujo de alcaldías (donde se comparte la config del municipio).
- **No pasar datos largos por la ruta** (URLs de políticas, JSON de queryFields). Pasarlos por `extra`/estado. (En Kotlin viajaban por path params; no replicar eso.)

---

## 8. White-label / flavors

- Toda diferencia entre apps vive en `core/flavor/FlavorConfig` (ver `FLAVORS.md §3`).
- Nada de `if (flavor == 'manizales')` regado por el código. Comportamiento nuevo = campo nuevo en `FlavorConfig`.
- El flavor solo fija identidad de build (nombre, bundle id, ícono, Firebase, `municipioId`). Colores/módulos los sigue dando el backend.

---

## 9. Nombres y estilo

- Archivos y carpetas: `snake_case`.
- Clases: `PascalCase`. Providers: `camelCase` terminando en `Provider`.
- Un widget público por archivo de pantalla; widgets privados auxiliares en el mismo archivo o en `presentation/widgets/`.
- Strings de UI en español (como la app actual).

---

## 10. Cómo estructurar un feature nuevo (receta)

1. Crear `features/<feature>/` con las 4 subcarpetas (`data`, `domain`, `application`, `presentation`).
2. `domain/`: modelo(s) de dominio + interfaz del repositorio.
3. `data/`: implementación del repositorio usando el/los servicio(s) retrofit y los DTOs de `core/models/`.
4. `application/`: provider(s) Riverpod con el `UiState`.
5. `presentation/`: pantalla(s) que consumen el provider.
6. Registrar la(s) ruta(s) en `core/router/`.
7. Verificar (`flutter analyze`) y marcar la casilla en el roadmap.
