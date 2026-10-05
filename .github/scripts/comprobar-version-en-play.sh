#!/usr/bin/env bash
#
# Falla ANTES de compilar si el versionCode ya se usó en Google Play.
#
# La regla de Play es dura y no tiene vuelta atrás: «no podés subir un APK con
# un versionCode que ya usaste para una versión anterior». No es "mayor que el
# publicado" — es que ese número queda quemado para siempre, aunque la versión
# se borre o nunca se publique.
#
# Sin esta comprobación, olvidarse de subir el versionCode se descubre después
# de ~25 minutos de compilación y una subida completa, con un error de la API
# que no dice claramente qué pasó. Acá cuesta ~30 segundos.
#
# ⚠️ Esto NO calcula el número, solo lo valida. El versionCode se sube a mano en
# la línea `version:` de `pubspec.yaml` (`X.Y.Z+N`) y viaja en el commit, porque
# es lo que identifica un artefacto publicado (dos subidas pueden compartir
# versionName).
#
# Variables: ACCESS_TOKEN, PACKAGE_NAME, VERSION_CODE

set -euo pipefail

: "${ACCESS_TOKEN:?falta ACCESS_TOKEN}"
: "${PACKAGE_NAME:?falta PACKAGE_NAME}"
: "${VERSION_CODE:?falta VERSION_CODE}"

API="https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE_NAME}"
EDIT_ID=""

# Un edit abierto bloquea los siguientes, así que se cierra pase lo que pase.
limpiar() {
  if [[ -n "$EDIT_ID" ]]; then
    curl -s -o /dev/null -X DELETE \
      -H "Authorization: Bearer ${ACCESS_TOKEN}" \
      "${API}/edits/${EDIT_ID}" || true
  fi
}
trap limpiar EXIT

llamar() {
  # Devuelve "cuerpo<TAB>código_http" para poder diagnosticar sin perder el cuerpo.
  curl -s -w '\t%{http_code}' "$@"
}

publicar_locales() {
  # Los idiomas de la ficha, para saber en cuáles se pueden escribir las notas.
  # Se aprovecha el mismo edit ya abierto: una llamada más, cero coste.
  #
  # No se suponen. Play rechaza unas notas en un idioma que la ficha no declara,
  # y ese rechazo llegaría tras compilar el bundle entero.
  local respuesta cuerpo codigo locales
  respuesta=$(llamar -H "Authorization: Bearer ${ACCESS_TOKEN}" "${API}/edits/${EDIT_ID}/listings")
  cuerpo="${respuesta%$'\t'*}"
  codigo="${respuesta##*$'\t'}"

  if [[ "$codigo" != "200" ]]; then
    echo "Aviso: no se pudieron leer los idiomas de la ficha (HTTP $codigo). Se publicará sin notas." >&2
    return 0
  fi

  locales=$(echo "$cuerpo" | jq -r '[.listings[]?.language] | join(",")')
  echo "Idiomas de la ficha: ${locales:-(ninguno)}"

  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "locales=$locales" >> "$GITHUB_OUTPUT"
  fi
}

respuesta=$(llamar -X POST \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Length: 0" \
  "${API}/edits")
cuerpo="${respuesta%$'\t'*}"
codigo="${respuesta##*$'\t'}"

if [[ "$codigo" != "200" ]]; then
  echo "::error::La API de Play rechazó la apertura de un edit (HTTP $codigo)." >&2
  case "$codigo" in
    401) echo "El token no es válido. Revisá la federación de identidades (docs/release/CONFIGURAR_PLAY_CI.md)." >&2 ;;
    403)
      # Dos causas MUY distintas devuelven 403, y confundirlas manda a revisar
      # Play Console cuando el problema está en el YAML (o al revés).
      if echo "$cuerpo" | grep -q 'ACCESS_TOKEN_SCOPE_INSUFFICIENT'; then
        echo "El problema NO son los permisos de Play Console: es el SCOPE del token." >&2
        echo "El paso 'Autenticarse en Google' necesita:" >&2
        echo "  access_token_scopes: https://www.googleapis.com/auth/androidpublisher" >&2
        echo "Sin eso la action acuña el token con 'cloud-platform', que Play rechaza." >&2
      else
        echo "La cuenta de servicio no tiene permiso sobre esta app." >&2
        echo "En Play Console → Usuarios y permisos necesita, sobre ${PACKAGE_NAME}:" >&2
        echo "(Si se acaba de invitar, los permisos pueden tardar horas en propagarse:" >&2
        echo " mientras tanto, lanzá el workflow a mano con 'solo_compilar'.)" >&2
        echo "  · Ver información de la aplicación" >&2
        echo "  · Publicar aplicaciones en los canales de prueba" >&2
      fi
      ;;
    404) echo "Play no reconoce el paquete '${PACKAGE_NAME}'." >&2 ;;
  esac
  echo "$cuerpo" >&2
  exit 1
fi

EDIT_ID=$(echo "$cuerpo" | jq -r '.id')

respuesta=$(llamar -H "Authorization: Bearer ${ACCESS_TOKEN}" "${API}/edits/${EDIT_ID}/bundles")
cuerpo="${respuesta%$'\t'*}"
codigo="${respuesta##*$'\t'}"

if [[ "$codigo" != "200" ]]; then
  echo "::error::No se pudo listar los bundles ya subidos (HTTP $codigo)." >&2
  echo "$cuerpo" >&2
  exit 1
fi

# `.bundles` no viene si la app todavía no tiene ninguno.
usados=$(echo "$cuerpo" | jq -r '.bundles[]?.versionCode' | sort -n)

if [[ -z "$usados" ]]; then
  echo "Play no reporta bundles previos. Se publica el ${VERSION_CODE}."
  publicar_locales
  exit 0
fi

echo "versionCode ya subidos a Play: $(echo "$usados" | tr '\n' ' ')"

publicar_locales

if echo "$usados" | grep -qx "$VERSION_CODE"; then
  mayor=$(echo "$usados" | tail -1)
  echo "::error file=pubspec.yaml::El versionCode ${VERSION_CODE} ya está usado en Play." >&2
  cat >&2 <<MSG

  Google Play no acepta dos veces el mismo versionCode, ni aunque se borre la
  versión. El más alto que Play ya conoce es el ${mayor}.

  Qué hacer:
    1. En pubspec.yaml subí la versión a  X.Y.Z+$((mayor + 1))
    2. PR a develop y luego develop → main

  No se compiló ni se subió nada.

MSG
  exit 1
fi

echo "El versionCode ${VERSION_CODE} está libre."
