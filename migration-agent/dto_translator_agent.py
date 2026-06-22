"""
Agente traductor de DTOs: Kotlin -> Dart.

Qué hace: toma una data class de Kotlin y la convierte en su equivalente Dart
usando json_serializable, y entra en un bucle "traducir -> verificar -> corregir"
hasta que el archivo Dart compile sin errores.

Esto es un AGENTE (no un simple script) porque el modelo decide solo cuándo leer,
escribir y volver a corregir, usando las tres herramientas que le damos abajo.

Requisitos:
  pip install anthropic
  variable de entorno ANTHROPIC_API_KEY con tu clave de la API.

Uso:
  python dto_translator_agent.py UserDTO.kt
  python dto_translator_agent.py            # traduce TODOS los DTOs (modo lote)
"""

import os
import sys
import subprocess
from pathlib import Path

import anthropic
from anthropic import beta_tool

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN  (ajusta estas rutas a tu entorno)
# ─────────────────────────────────────────────────────────────────────────────

# Modelo. Por defecto el más capaz. Para abaratar el consumo del crédito puedes
# cambiarlo a "claude-sonnet-4-6" (más barato) o "claude-haiku-4-5" (el más barato).
MODEL = "claude-opus-4-8"

# Raíz del proyecto Kotlin actual (de donde leemos los DTOs).
KOTLIN_ROOT = Path(
    r"D:\AndroidStudioProjects\Centralizacion"
    r"\app\src\main\java\com\tramites1cero1\centralizacion\data\model"
)

# Raíz del proyecto Flutter nuevo (donde escribimos los .dart y donde corremos
# `dart analyze`). Ajusta cuando Claude Code haya creado el proyecto Flutter.
FLUTTER_ROOT = Path(r"D:\AndroidStudioProjects\trami_flutter")

# Carpeta destino de los modelos Dart, relativa a FLUTTER_ROOT.
DART_MODELS_SUBDIR = Path("lib/core/models")

# Documento de referencia con las convenciones (contrato de datos).
REPO_ROOT = Path(__file__).resolve().parent.parent
BACKEND_DOC = REPO_ROOT / "MIGRACION_FLUTTER_BACKEND.md"

client = anthropic.Anthropic()  # lee ANTHROPIC_API_KEY del entorno


# ─────────────────────────────────────────────────────────────────────────────
# HERRAMIENTAS QUE EL AGENTE PUEDE USAR
# El modelo solo "pide" estas acciones; este código las ejecuta.
# ─────────────────────────────────────────────────────────────────────────────

@beta_tool
def leer_kotlin(nombre_archivo: str) -> str:
    """Lee el contenido de un archivo .kt de DTO del proyecto Kotlin.

    Args:
        nombre_archivo: nombre del archivo, p.ej. "UserDTO.kt". Puede incluir
            subcarpeta, p.ej. "pqrddto/Secretaria.kt".
    """
    ruta = KOTLIN_ROOT / nombre_archivo
    if not ruta.exists():
        return f"ERROR: no existe {ruta}"
    print(f"  [leer]    {nombre_archivo}")
    return ruta.read_text(encoding="utf-8")


@beta_tool
def escribir_dart(nombre_archivo: str, contenido: str) -> str:
    """Escribe un archivo .dart en la carpeta de modelos del proyecto Flutter.

    Args:
        nombre_archivo: nombre destino en snake_case, p.ej. "user_dto.dart".
        contenido: el código Dart completo del archivo.
    """
    destino = FLUTTER_ROOT / DART_MODELS_SUBDIR / nombre_archivo
    destino.parent.mkdir(parents=True, exist_ok=True)
    destino.write_text(contenido, encoding="utf-8")
    print(f"  [escribir] {nombre_archivo} ({len(contenido)} chars)")
    return f"Escrito {destino}"


@beta_tool
def verificar_dart(nombre_archivo: str) -> str:
    """Corre `dart analyze` sobre un archivo .dart y devuelve los errores/avisos.

    Si Dart/Flutter aún no está instalado o el proyecto no existe, lo informa
    para que el agente entregue igual su mejor traducción.

    Args:
        nombre_archivo: el .dart a analizar, p.ej. "user_dto.dart".
    """
    archivo = FLUTTER_ROOT / DART_MODELS_SUBDIR / nombre_archivo
    if not FLUTTER_ROOT.exists():
        return ("AVISO: el proyecto Flutter aún no existe en "
                f"{FLUTTER_ROOT}. No se pudo verificar; entrega tu mejor "
                "traducción y la verificaremos luego.")
    try:
        print(f"  [verificar] dart analyze {nombre_archivo}")
        res = subprocess.run(
            ["dart", "analyze", str(archivo)],
            cwd=str(FLUTTER_ROOT),
            capture_output=True, text=True, timeout=180,
        )
        salida = (res.stdout + res.stderr).strip()
        if res.returncode == 0:
            return "OK: dart analyze no encontró errores."
        return f"ERRORES de dart analyze:\n{salida}"
    except FileNotFoundError:
        return ("AVISO: el comando `dart` no está disponible. Entrega tu mejor "
                "traducción; la verificaremos manualmente.")
    except subprocess.TimeoutExpired:
        return "AVISO: dart analyze tardó demasiado (timeout)."


# ─────────────────────────────────────────────────────────────────────────────
# INSTRUCCIONES DEL AGENTE (system prompt)
# ─────────────────────────────────────────────────────────────────────────────

CONVENCIONES = """\
Eres un agente que migra modelos de datos de Kotlin (Android) a Dart (Flutter).

Reglas de traducción:
- Usa `json_serializable` con `@JsonSerializable()` y `part 'archivo.g.dart';`.
- Conserva EXACTAMENTE los nombres de campo JSON. Si el Kotlin usa
  `@SerializedName("xxx")`, en Dart usa `@JsonKey(name: 'xxx')`.
- Tipos: String->String, Int->int, Boolean->bool, Double->double,
  List<T>->List<T>, tipos anidados -> su clase Dart equivalente.
- Campos nullables de Kotlin (`String?`) -> nullables en Dart (`String?`).
- Nombre de archivo destino en snake_case (UserDTO.kt -> user_dto.dart).
- Incluye `factory X.fromJson(...)` y `toJson()` generados por json_serializable.
- NO inventes campos. Traduce solo lo que existe en el Kotlin.

Flujo OBLIGATORIO por cada DTO:
1. Lee el archivo Kotlin con la herramienta `leer_kotlin`.
2. Escribe el .dart con `escribir_dart`.
3. Verifica con `verificar_dart`.
4. Si hay errores, corrígelos y vuelve a escribir + verificar hasta que pase
   (o hasta que el aviso indique que no se puede verificar todavía).
5. Termina con un resumen de una línea de lo que hiciste.
"""


def traducir(nombre_archivo: str) -> None:
    print(f"\n=== Traduciendo {nombre_archivo} ===")
    runner = client.beta.messages.tool_runner(
        model=MODEL,
        max_tokens=16000,
        thinking={"type": "adaptive"},   # el modelo decide cuánto razonar
        system=[{
            "type": "text",
            "text": CONVENCIONES,
            # Cachea el system prompt: se reutiliza en cada DTO -> ~90% más barato.
            "cache_control": {"type": "ephemeral"},
        }],
        tools=[leer_kotlin, escribir_dart, verificar_dart],
        messages=[{
            "role": "user",
            "content": f"Migra el DTO de Kotlin a Dart: {nombre_archivo}",
        }],
    )
    # El tool runner ejecuta el bucle solo; aquí solo mostramos el texto final.
    for message in runner:
        for block in message.content:
            if block.type == "text" and block.text.strip():
                print(f"  > {block.text.strip()}")


def listar_dtos() -> list[str]:
    """Devuelve todos los .kt bajo KOTLIN_ROOT (incluye subcarpeta pqrddto/)."""
    return sorted(
        str(p.relative_to(KOTLIN_ROOT)).replace("\\", "/")
        for p in KOTLIN_ROOT.rglob("*.kt")
    )


if __name__ == "__main__":
    if len(sys.argv) > 1:
        traducir(sys.argv[1])
    else:
        archivos = listar_dtos()
        print(f"Modo lote: {len(archivos)} DTOs encontrados.")
        for arch in archivos:
            traducir(arch)
    print("\nListo.")
