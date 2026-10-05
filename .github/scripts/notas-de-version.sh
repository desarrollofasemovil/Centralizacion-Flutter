#!/usr/bin/env bash
#
# Compone las notas de la versión para la PISTA INTERNA, a partir de los commits
# desde el último tag de publicación.
#
# ⚠️ Solo para pruebas internas. Quien lee estas notas es el equipo, y lo que
# necesita es "qué toca probar": un resumen de commits es exactamente eso.
# **Las notas de PRODUCCIÓN se escriben a mano** — ahí quien lee es el
# ciudadano, y un volcado de mensajes de commit no es copy de producto.
#
# Se escribe un fichero por idioma que la ficha de Play declare de verdad
# (`LOCALES`, que consulta la guarda). Escribir en un idioma que la ficha no
# tiene hace que Play rechace la subida.
#
# Variables: DESTINO, LOCALES (separados por coma). Opcional: VERSION_FULL.

set -euo pipefail

: "${DESTINO:?falta DESTINO}"

# Play RECHAZA la versión entera (no la recorta) si las notas de un idioma
# pasan de 500 caracteres. Se apunta a 480 para dejar margen: en 101Fintech una
# versión se cayó con 501, porque el recorte daba 500 justos y `printf '%s\n'`
# le sumaba el salto de línea final.
readonly LIMITE_PLAY=500
readonly LIMITE=480

# `${#var}` cuenta en el locale activo: en `C` cuenta BYTES, y una tilde vale
# dos. Con UTF-8 cuenta caracteres, que es lo que mide Play.
export LC_ALL=C.UTF-8

mkdir -p "$DESTINO"

if [[ -z "${LOCALES:-}" ]]; then
  echo "Sin idiomas conocidos de la ficha: se publica sin notas."
  exit 0
fi

ultimo_tag=$(git describe --tags --abbrev=0 2>/dev/null || true)

if [[ -n "$ultimo_tag" ]]; then
  rango="${ultimo_tag}..HEAD"
  echo "Commits desde $ultimo_tag"
else
  # Primera publicación con tags: no hay desde dónde medir, así que se toma un
  # puñado reciente en vez de volcar la historia entera del repositorio.
  rango="HEAD~15..HEAD"
  echo "Sin tags previos: se toman los últimos 15 commits"
fi

# `--no-merges`: un "Merge pull request #60" no le dice nada a quien va a probar.
# Tampoco los commits de mantenimiento (chore/ci/docs/test/...): no hay nada
# que probar en ellos, y son justo los que llenaban el cupo de 500.
mapfile -t asuntos < <(
  git log --no-merges --pretty=format:'%s' "$rango" 2>/dev/null |
    grep -Ev '^(chore|ci|docs|test|style|build|refactor)(\(|:|!)' || true
)

# Sin el prefijo convencional: "feat(pqrd): pedir reseña..." → "Pedir reseña...".
lineas=()
for asunto in "${asuntos[@]}"; do
  texto=$(printf '%s' "$asunto" | sed -E 's/^[a-z]+(\([^)]*\))?!?:[[:space:]]*//')
  [[ -z "$texto" ]] && continue
  lineas+=("- ${texto^}")
done

# Líneas ENTERAS mientras quepan, nunca un corte a mitad de frase. Se reserva
# sitio para la línea de cierre por si algo no entra.
cuerpo=""
incluidas=0
for linea in "${lineas[@]}"; do
  candidato="${cuerpo:+$cuerpo$'\n'}$linea"
  if (( ${#candidato} > LIMITE - 30 )); then
    break
  fi
  cuerpo="$candidato"
  incluidas=$((incluidas + 1))
done

restantes=$(( ${#lineas[@]} - incluidas ))
if (( restantes > 0 )); then
  cierre="- Y ${restantes} cambio$([[ $restantes -eq 1 ]] || echo s) más."
  cuerpo="${cuerpo:+$cuerpo$'\n'}$cierre"
fi

if [[ -z "$cuerpo" ]]; then
  cuerpo="- Correcciones internas."
fi

# Red de seguridad: si una sola línea ya fuera enorme, se corta igual. Nunca
# debe llegar a Play algo que Play vaya a rechazar después de 20 min de build.
if (( ${#cuerpo} > LIMITE )); then
  cuerpo="${cuerpo:0:$((LIMITE - 3))}..."
fi

IFS=',' read -ra idiomas <<< "$LOCALES"
for idioma in "${idiomas[@]}"; do
  [[ -z "$idioma" ]] && continue
  # `%s` SIN salto de línea: el `\n` final contaba como carácter para Play.
  printf '%s' "$cuerpo" > "${DESTINO}/whatsnew-${idioma}"
  echo "  · whatsnew-${idioma} (${#cuerpo} caracteres, máximo ${LIMITE_PLAY})"
done

echo "--- notas ---"
printf '%s\n' "$cuerpo"
