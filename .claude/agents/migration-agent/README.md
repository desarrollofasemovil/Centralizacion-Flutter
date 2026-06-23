# Agente traductor de DTOs (Kotlin → Dart)

Primer experimento de automatización con la API de Claude. Convierte las `data class`
de Kotlin en clases Dart con `json_serializable`, compilando y auto-corrigiendo en bucle.

## Qué es (y por qué es un "agente")

No es un find-replace ni un script lineal. Le damos al modelo **tres herramientas**
(`leer_kotlin`, `escribir_dart`, `verificar_dart`) y él **decide solo** el orden:
lee el `.kt`, escribe el `.dart`, corre `dart analyze`, y si hay errores los corrige y
vuelve a verificar — hasta que compile. Ese bucle "intentar → verificar → corregir" es
lo que lo hace un agente.

## Requisitos

```bash
pip install anthropic
```

Y tu clave de la API en el entorno:

```powershell
# PowerShell (Windows)
$env:ANTHROPIC_API_KEY = "sk-ant-..."
```
```bash
# bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

Python 3.10 o superior.

## Configuración

Abre `dto_translator_agent.py` y ajusta arriba:

- `MODEL` — por defecto `claude-opus-4-8` (el más capaz). Para gastar menos crédito:
  `claude-sonnet-4-6` (más barato) o `claude-haiku-4-5` (el más barato). Para traducir
  DTOs, Sonnet o Haiku suelen rendir de sobra.
- `KOTLIN_ROOT` — ya apunta a la carpeta de DTOs de Centralización.
- `FLUTTER_ROOT` — ruta del proyecto Flutter nuevo. Ajústala cuando Claude Code lo cree.
- `DART_MODELS_SUBDIR` — dónde se guardan los `.dart` (por defecto `lib/core/models`).

## Uso

```bash
# Un solo DTO:
python dto_translator_agent.py UserDTO.kt

# Un DTO en subcarpeta:
python dto_translator_agent.py pqrddto/Secretaria.kt

# TODOS los DTOs (modo lote):
python dto_translator_agent.py
```

## Notas de costo

- Un agente que itera **consume bastantes tokens** (reenvía el contexto en cada paso).
  Empieza traduciendo **un solo DTO** para medir antes de lanzar el modo lote.
- El `system` prompt va **cacheado** (`cache_control`), así que su costo se reduce ~90%
  en cada DTO siguiente.
- Si el proyecto Flutter aún no existe, `verificar_dart` lo avisa y el agente entrega
  igual su mejor traducción (la verificas después).

## Recomendación de arranque

1. Que **Claude Code** cree primero la estructura del proyecto Flutter y deje listo
   `json_serializable` + `build_runner` en `pubspec.yaml`.
2. Ajusta `FLUTTER_ROOT`.
3. Corre el agente con **un DTO** y revisa el resultado.
4. Si te convence, lánzalo en modo lote.
