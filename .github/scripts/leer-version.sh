#!/usr/bin/env bash
#
# Lee la versión del artefacto desde `pubspec.yaml`.
#
# En este repo la versión tiene UNA sola fuente: `android/app/build.gradle.kts`
# usa `flutter.versionCode` / `flutter.versionName`, que salen de la línea
# `version:` del pubspec (`2.0.0+53` → versionName 2.0.0, versionCode 53).
#
# Escribe `version_code`, `version_name` y `version_full` en GITHUB_OUTPUT.

set -euo pipefail

PUBSPEC="pubspec.yaml"

# `sed` y no `grep -P`: la sintaxis Perl de grep depende del locale.
version=$(sed -n 's/^version:[[:space:]]*\([^ #]*\).*/\1/p' "$PUBSPEC" | head -1)

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]]; then
  echo "::error file=$PUBSPEC::La línea 'version:' debe tener la forma X.Y.Z+N (encontrado: '${version}')." >&2
  exit 1
fi

version_name="${version%%+*}"
version_code="${version##*+}"

echo "Versión: $version_name ($version_code)"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "version_code=$version_code"
    echo "version_name=$version_name"
    echo "version_full=${version_name}+${version_code}"
  } >> "$GITHUB_OUTPUT"
fi
