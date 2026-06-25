"""
Compresión de contexto para el agente de migración.

Implementa compresión por reglas para tool outputs (código fuente Kotlin/Dart,
resultados de dart analyze) antes de que lleguen al LLM. Reduce tokens sin
perder información esencial.

Uso:
    from headroom_config import compress_tool_output, get_stats

    resultado = compress_tool_output(kotlin_source, content_type="code")
    print(get_stats())
"""

import re
import hashlib
from typing import Optional

# ─────────────────────────────────────────────────────────────────────────────
# ESTADÍSTICAS DE LA SESIÓN
# ─────────────────────────────────────────────────────────────────────────────

_stats = {
    "total_before": 0,
    "total_after": 0,
    "total_saved": 0,
    "compressions": 0,
}


def _estimate_tokens(text: str) -> int:
    """Estimación rápida de tokens (~4 chars por token en promedio)."""
    return max(1, len(text) // 4)


def _compress_code(content: str) -> str:
    """Comprime código fuente eliminando ruido sin perder semántica.

    Estrategia:
    - Eliminar comentarios de una línea (// ...)
    - Colapsar espacios múltiples
    - Eliminar líneas en blanco consecutivas (dejar máximo 1)
    - Eliminar espacios trailing
    - Colapsar bloques de propiedades repetitivos
    - Preservar firmas de función y anotaciones
    """
    lines = content.split("\n")
    result = []
    prev_blank = False

    for line in lines:
        stripped = line.strip()

        # Saltar líneas vacías consecutivas
        if not stripped:
            if not prev_blank:
                result.append("")
            prev_blank = True
            continue
        prev_blank = False

        # Eliminar comentarios de línea completa (preservando docstrings)
        if stripped.startswith("//") and not stripped.startswith("///"):
            continue

        # Elimstrar bloques Javadoc/KDoc completos
        if stripped.startswith("/**") or stripped.startswith("* ") or stripped.startswith("*/"):
            continue

        # Eliminar comentarios inline al final de la línea
        if "//" in stripped:
            parts = stripped.split('"')
            in_string = False
            cleaned_parts = []
            for i, part in enumerate(parts):
                if i % 2 == 0:
                    if "//" in part:
                        comment_idx = part.index("//")
                        cleaned_parts.append(part[:comment_idx].rstrip())
                        break
                cleaned_parts.append(part)
            stripped = '"'.join(cleaned_parts) if cleaned_parts else stripped.split("//")[0].rstrip()

        # Colapsar espacios múltiples (preservando indentación inicial)
        indent = len(line) - len(line.lstrip())
        stripped = re.sub(r"\s+", " ", stripped)

        # Eliminar whitespace trailing
        stripped = stripped.rstrip()

        if stripped:
            result.append(" " * indent + stripped)

    compressed = "\n".join(result)
    return compressed.strip()


def _compress_log(content: str) -> str:
    """Comprime logs/salida de comandos manteniendo errores y advertencias.

    Estrategia:
    - Mantener líneas con error/warning/AVISO
    - Colapsar líneas informativas repetitivas
    - Eliminar líneas de progreso vacías
    - Preservar números de línea y archivos
    - Eliminar líneas info redundantes (max 3)
    """
    lines = content.split("\n")
    result = []
    seen_patterns = set()
    info_count = 0
    MAX_INFO_LINES = 3

    for line in lines:
        stripped = line.strip()

        # Siempre mantener errores, warnings, avisos
        if any(kw in stripped.lower() for kw in ["error", "warning", "aviso", "fatal"]):
            result.append(stripped)
            continue

        # Siempre mantener líneas OK/exitosas
        if stripped.startswith("OK:"):
            result.append(stripped)
            continue

        # Eliminar líneas vacías o solo espacios
        if not stripped:
            continue

        # Contar y limitar líneas info
        if stripped.lower().startswith("info") or "info -" in stripped.lower():
            info_count += 1
            if info_count > MAX_INFO_LINES:
                continue
            result.append(stripped)
            continue

        # Colapsar líneas repetitivas (mismo patrón)
        normalized = re.sub(r"\d+", "N", stripped)
        normalized = re.sub(r"[A-Z]:\\[^:]+", "PATH", normalized)
        normalized = re.sub(r"lib/[^:]+:\d+:\d+", "FILE:N:N", normalized)

        if normalized in seen_patterns:
            continue
        seen_patterns.add(normalized)

        result.append(stripped)

    # Agregar resumen de líneas info colapsadas
    if info_count > MAX_INFO_LINES:
        result.append(f"[{info_count - MAX_INFO_LINES} líneas info omitidas]")

    return "\n".join(result)


def compress_tool_output(
    content: str,
    content_type: str = "code",
    model: Optional[str] = None,
) -> str:
    """Comprime un tool output antes de devolverlo al LLM.

    Args:
        content: Texto a comprimir (código, logs, resultado de comando).
        content_type: Tipo de contenido ("code", "log", "text").
        model: Ignorado (compatibilidad con interfaz Headroom).

    Returns:
        Texto comprimido, o el original si la compresión no es beneficiosa.
    """
    if not content or len(content) < 100:
        return content

    before_tokens = _estimate_tokens(content)

    if content_type == "code":
        compressed = _compress_code(content)
    elif content_type == "log":
        compressed = _compress_log(content)
    else:
        compressed = content

    after_tokens = _estimate_tokens(compressed)

    # Actualizar estadísticas
    saved = before_tokens - after_tokens
    _stats["total_before"] += before_tokens
    _stats["total_after"] += after_tokens
    _stats["total_saved"] += max(0, saved)
    _stats["compressions"] += 1

    # Si la compresión no es beneficiosa (<10%), devolver original
    if saved < before_tokens * 0.1:
        return content

    return compressed


def get_stats() -> dict:
    """Devuelve estadísticas acumuladas de compresión de la sesión."""
    total = _stats["total_before"]
    if total == 0:
        return {**_stats, "savings_pct": 0.0}
    return {
        **_stats,
        "savings_pct": round(_stats["total_saved"] / total * 100, 1),
    }


def reset_stats() -> None:
    """Reinicia las estadísticas de compresión."""
    _stats.update({
        "total_before": 0,
        "total_after": 0,
        "total_saved": 0,
        "compressions": 0,
    })
