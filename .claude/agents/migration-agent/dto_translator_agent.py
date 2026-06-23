"""
DTO Translator Agent: Kotlin -> Dart.

What it does: takes a Kotlin data class and converts it to its Dart equivalent
using json_serializable, entering a "translate -> verify -> fix" loop until
the Dart file compiles without errors.

This is an AGENT (not a simple script) because the model decides on its own
when to read, write, and correct, using the three tools defined below.

Requirements:
  pip install anthropic
  ANTHROPIC_API_KEY environment variable set with your API key.

Usage:
  python dto_translator_agent.py UserDTO.kt
  python dto_translator_agent.py            # translates ALL DTOs (batch mode)

Configuration via environment variables (or edit the CONFIG section below):
  KOTLIN_ROOT   - absolute path to Kotlin model directory
  FLUTTER_ROOT  - absolute path to Flutter project root
"""

import os
import sys
import json
import time
import subprocess
from pathlib import Path
from dotenv import load_dotenv


import anthropic

# La consola de Windows usa cp1252 por defecto y revienta (UnicodeEncodeError)
# al imprimir emojis/flechas que el modelo incluye en sus respuestas. Forzamos
# UTF-8 en stdout/stderr para que esos prints no tumben el proceso.
for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION  (edit these or set the equivalent environment variables)
# ─────────────────────────────────────────────────────────────────────────────

# El script vive en:
#   tramiapp_flutter/.claude/agents/migration-agent/dto_translator_agent.py
_SCRIPT_DIR = Path(__file__).resolve().parent

# Carga las variables de entorno desde environmentkeys.env (junto al script).
# Como respaldo, también intenta un .env estándar.
load_dotenv(_SCRIPT_DIR / "environmentkeys.env")
load_dotenv()

MODEL = os.getenv("DTO_MODEL", "claude-haiku-4-5")

# Rutas derivadas de la ubicación del script para que funcione sin importar
# dónde esté clonado el repo. El proyecto Flutter es el ancestro a 3 niveles.
_FLUTTER_DEFAULT = _SCRIPT_DIR.parents[2]
_KOTLIN_DEFAULT = (
    _FLUTTER_DEFAULT
    / "codebase/app/src/main/java/com/tramites1cero1/centralizacion/data/model"
)

FLUTTER_ROOT = Path(os.getenv("FLUTTER_ROOT", str(_FLUTTER_DEFAULT)))
KOTLIN_ROOT = Path(os.getenv("KOTLIN_ROOT", str(_KOTLIN_DEFAULT)))

DART_MODELS_SUBDIR = Path("lib/core/models")

client = anthropic.Anthropic(max_retries=5)  # reads ANTHROPIC_API_KEY from environment

# Errores transitorios de la API que conviene reintentar (529 overloaded, 429
# rate limit, 5xx, problemas de conexión/timeout).
_TRANSIENT_ERRORS = (
    anthropic.OverloadedError,
    anthropic.RateLimitError,
    anthropic.InternalServerError,
    anthropic.APIConnectionError,
    anthropic.APITimeoutError,
)


def crear_mensaje_con_reintento(messages, max_intentos: int = 6):
    """Llama a la API con backoff exponencial ante errores transitorios.

    El SDK ya reintenta internamente (max_retries=5); esta capa adicional evita
    que un pico de sobrecarga (529) tumbe una corrida en lote larga.
    """
    espera = 2.0
    for intento in range(max_intentos):
        try:
            return client.messages.create(
                model=MODEL,
                max_tokens=8096,
                system=SYSTEM_PROMPT,
                tools=TOOLS,
                messages=messages,
            )
        except _TRANSIENT_ERRORS as e:
            if intento == max_intentos - 1:
                raise
            print(
                f"  [retry]   {type(e).__name__} de la API; "
                f"reintento {intento + 1}/{max_intentos - 1} en {espera:.0f}s..."
            )
            time.sleep(espera)
            espera = min(espera * 2, 60)


# ─────────────────────────────────────────────────────────────────────────────
# TOOL IMPLEMENTATIONS
# The model requests these actions; this code executes them.
# ─────────────────────────────────────────────────────────────────────────────

def leer_kotlin(nombre_archivo: str) -> str:
    """Reads the content of a Kotlin DTO file from the Kotlin project.

    Tolerante a rutas parciales: si `KOTLIN_ROOT / nombre_archivo` no existe,
    busca por nombre de archivo de forma recursiva bajo KOTLIN_ROOT. Así el
    agente puede pasar la ruta completa, parcial o solo el nombre.
    """
    ruta = KOTLIN_ROOT / nombre_archivo
    if not ruta.exists():
        base = Path(nombre_archivo).name
        matches = list(KOTLIN_ROOT.rglob(base))
        if len(matches) == 1:
            ruta = matches[0]
        elif len(matches) > 1:
            rel = ", ".join(str(m.relative_to(KOTLIN_ROOT)).replace("\\", "/") for m in matches)
            return f"ERROR: multiple files named '{base}' found: {rel}. Pass the full relative path."
        else:
            return f"ERROR: file not found at {ruta} (and no '{base}' under {KOTLIN_ROOT})."
    rel = str(ruta.relative_to(KOTLIN_ROOT)).replace("\\", "/")
    print(f"  [read]    {rel}")
    return ruta.read_text(encoding="utf-8")


def escribir_dart(nombre_archivo: str, contenido: str) -> str:
    """Writes a .dart file to the Flutter models directory."""
    destino = FLUTTER_ROOT / DART_MODELS_SUBDIR / nombre_archivo
    destino.parent.mkdir(parents=True, exist_ok=True)
    destino.write_text(contenido, encoding="utf-8")
    print(f"  [write]   {nombre_archivo} ({len(contenido)} chars)")
    return f"Written: {destino}"


def verificar_dart(nombre_archivo: str) -> str:
    """Runs `dart analyze` on a .dart file and returns any errors/warnings."""
    archivo = FLUTTER_ROOT / DART_MODELS_SUBDIR / nombre_archivo
    if not FLUTTER_ROOT.exists():
        return (
            f"WARNING: Flutter project not found at {FLUTTER_ROOT}. "
            "Cannot verify yet; deliver your best translation and we'll check later."
        )
    try:
        print(f"  [verify]  dart analyze {nombre_archivo}")
        res = subprocess.run(
            ["dart", "analyze", str(archivo)],
            cwd=str(FLUTTER_ROOT),
            capture_output=True,
            text=True,
            timeout=180,
        )
        output = (res.stdout + res.stderr).strip()
        if res.returncode == 0:
            return "OK: dart analyze found no errors."

        # Filtra los errores que SOLO se resuelven al correr build_runner: el
        # archivo `.g.dart` (part) aún no existe y por eso `_$XFromJson` /
        # `_$XToJson` aparecen indefinidos. Si esos son los únicos errores, la
        # traducción es correcta y NO hay que reintentar.
        g_part = nombre_archivo.replace(".dart", ".g.dart")
        errores_reales = []
        for linea in output.splitlines():
            txt = linea.strip()
            if not txt:
                continue
            low = txt.lower()
            if g_part.lower() in low:      # "Target of URI doesn't exist: 'x.g.dart'"
                continue
            if "_$" in txt:                # _$XFromJson / _$XToJson indefinidos
                continue
            if low.startswith("analyzing") or ("issue" in low and "found" in low):
                continue                   # encabezado / resumen, no es un error
            errores_reales.append(txt)

        if not errores_reales:
            return (
                "OK (pendiente codegen): los únicos avisos son por el archivo "
                f"'{g_part}' que genera build_runner. La traducción es correcta; "
                "NO reintentes por esto, finaliza con tu resumen."
            )
        return "dart analyze ERRORS:\n" + "\n".join(errores_reales)
    except FileNotFoundError:
        return (
            "WARNING: `dart` command not available. "
            "Deliver your best translation; we'll verify manually."
        )
    except subprocess.TimeoutExpired:
        return "WARNING: dart analyze timed out."


# ─────────────────────────────────────────────────────────────────────────────
# TOOL DISPATCHER
# Maps tool names (strings from the model) to their Python functions.
# ─────────────────────────────────────────────────────────────────────────────

TOOL_MAP = {
    "leer_kotlin": leer_kotlin,
    "escribir_dart": escribir_dart,
    "verificar_dart": verificar_dart,
}

def execute_tool(name: str, input_args: dict) -> str:
    fn = TOOL_MAP.get(name)
    if fn is None:
        return f"ERROR: unknown tool '{name}'"
    return fn(**input_args)


# ─────────────────────────────────────────────────────────────────────────────
# TOOL SCHEMAS (what the model sees)
# ─────────────────────────────────────────────────────────────────────────────

TOOLS = [
    {
        "name": "leer_kotlin",
        "description": (
            "Reads the content of a Kotlin DTO file from the Kotlin project. "
            "Use this as the first step before translating."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "nombre_archivo": {
                    "type": "string",
                    "description": (
                        "File name, e.g. 'UserDTO.kt'. "
                        "Can include a subfolder, e.g. 'pqrddto/Secretaria.kt'."
                    ),
                }
            },
            "required": ["nombre_archivo"],
        },
    },
    {
        "name": "escribir_dart",
        "description": (
            "Writes a .dart file to the Flutter models directory. "
            "Use after generating the Dart translation."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "nombre_archivo": {
                    "type": "string",
                    "description": "Destination filename in snake_case, e.g. 'user_dto.dart'.",
                },
                "contenido": {
                    "type": "string",
                    "description": "Complete Dart code for the file.",
                },
            },
            "required": ["nombre_archivo", "contenido"],
        },
    },
    {
        "name": "verificar_dart",
        "description": (
            "Runs `dart analyze` on a .dart file and returns errors/warnings. "
            "Always call this after writing; fix any errors and repeat until clean."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "nombre_archivo": {
                    "type": "string",
                    "description": "The .dart file to analyze, e.g. 'user_dto.dart'.",
                }
            },
            "required": ["nombre_archivo"],
        },
    },
]


# ─────────────────────────────────────────────────────────────────────────────
# AGENT SYSTEM PROMPT
# ─────────────────────────────────────────────────────────────────────────────

SYSTEM_PROMPT = """\
You are an agent that migrates data models from Kotlin (Android) to Dart (Flutter).

Translation rules:
- Import EXACTLY `import 'package:json_annotation/json_annotation.dart';`
  (NOT 'package:json_serializable/...'; that is a dev-only package and does not
  export `JsonSerializable`). Then use `@JsonSerializable()` and `part 'file.g.dart';`.
- For a nested DTO of type `Foo`, add `import 'foo.dart';` (snake_case of the
  class name) so the type resolves.
- Preserve JSON field names EXACTLY. If Kotlin uses `@SerializedName("xxx")`,
  use `@JsonKey(name: 'xxx')` in Dart.
- Dart field names MUST be lowerCamelCase. If the Kotlin field name is not already
  lowerCamelCase (e.g. PascalCase like `IDTramite`, `Estado`, `ContentType`), rename
  the Dart field to lowerCamelCase AND add `@JsonKey(name: 'OriginalKotlinName')` to
  preserve the JSON key — even when there is no `@SerializedName`.
- A Dart field must NEVER have the same name as its enclosing class (that is a Dart
  compile error). Rename it to lowerCamelCase and add `@JsonKey(name: 'OriginalName')`.
- Types: String->String, Int->int, Boolean->bool, Double->double,
  List<T>->List<T>, nested types -> their Dart class equivalent.
- Nullable Kotlin fields (`String?`) -> nullable in Dart (`String?`).
- Destination filename in snake_case (UserDTO.kt -> user_dto.dart).
- Include `factory X.fromJson(...)` and `toJson()` generated by json_serializable.
- Do NOT invent fields. Only translate what exists in the Kotlin source.

MANDATORY flow for each DTO:
1. Read the Kotlin file with `leer_kotlin`.
2. Write the .dart file with `escribir_dart`.
3. Verify with `verificar_dart`.
4. If there are errors, fix them and repeat write + verify until it passes
   (or until the warning says verification isn't possible yet).
5. Finish with a one-line summary of what you did.
"""


# ─────────────────────────────────────────────────────────────────────────────
# AGENTIC LOOP
# The model runs until stop_reason == "end_turn" (no more tool calls).
# ─────────────────────────────────────────────────────────────────────────────

def traducir(nombre_archivo: str) -> None:
    print(f"\n=== Translating {nombre_archivo} ===")

    messages = [
        {"role": "user", "content": f"Migrate the Kotlin DTO to Dart: {nombre_archivo}"}
    ]

    while True:
        response = crear_mensaje_con_reintento(messages)

        # Collect text output and tool calls from this turn
        tool_calls = []
        for block in response.content:
            if block.type == "text" and block.text.strip():
                print(f"  > {block.text.strip()}")
            elif block.type == "tool_use":
                tool_calls.append(block)

        # If the model is done (no tool calls), exit the loop
        if response.stop_reason == "end_turn" or not tool_calls:
            break

        # Append assistant turn to history
        messages.append({"role": "assistant", "content": response.content})

        # Execute each tool call and collect results
        tool_results = []
        for tc in tool_calls:
            result = execute_tool(tc.name, tc.input)
            tool_results.append({
                "type": "tool_result",
                "tool_use_id": tc.id,
                "content": result,
            })

        # Append tool results as user turn and continue
        messages.append({"role": "user", "content": tool_results})


# ─────────────────────────────────────────────────────────────────────────────
# ENTRY POINT
# ─────────────────────────────────────────────────────────────────────────────

def listar_dtos() -> list[str]:
    """Returns all .kt files under KOTLIN_ROOT (includes subdirectories)."""
    return sorted(
        str(p.relative_to(KOTLIN_ROOT)).replace("\\", "/")
        for p in KOTLIN_ROOT.rglob("*.kt")
    )


if __name__ == "__main__":
    if len(sys.argv) > 1:
        traducir(sys.argv[1])
    else:
        archivos = listar_dtos()
        print(f"Batch mode: {len(archivos)} DTOs found.")
        for arch in archivos:
            traducir(arch)
    print("\nDone.")
