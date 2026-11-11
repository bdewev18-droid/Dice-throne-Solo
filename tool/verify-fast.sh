#!/usr/bin/env bash
set -euo pipefail

TARGET="web"
TIMEOUT_SECONDS=180
WITH_ANALYZE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target|-t)
      TARGET="${2:-}"
      shift 2
      ;;
    --timeout|--timeout-seconds)
      TIMEOUT_SECONDS="${2:-}"
      shift 2
      ;;
    --with-analyze)
      WITH_ANALYZE=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [--target web|apk|analyze] [--timeout 180] [--with-analyze]"
      exit 0
      ;;
    *)
      echo "Argument inconnu: $1" >&2
      exit 1
      ;;
  esac
done

case "$TARGET" in
  web|apk|analyze) ;;
  *)
    echo "Target invalide '$TARGET'. Valeurs autorisees: web, apk, analyze." >&2
    exit 1
    ;;
esac

if [[ ! "$TIMEOUT_SECONDS" =~ ^[0-9]+$ ]] || (( TIMEOUT_SECONDS < 30 || TIMEOUT_SECONDS > 1800 )); then
  echo "Timeout invalide '$TIMEOUT_SECONDS'. Attendu: entier entre 30 et 1800." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

FLUTTER_CMD="${FLUTTER_BIN:-}"
if [[ -z "$FLUTTER_CMD" ]] && command -v flutter >/dev/null 2>&1; then
  FLUTTER_CMD="$(command -v flutter)"
fi
if [[ -z "$FLUTTER_CMD" ]]; then
  for candidate in \
    "/home/deck/dev/flutter/bin/flutter" \
    "$HOME/dev/flutter/bin/flutter" \
    "$HOME/flutter/bin/flutter"
  do
    if [[ -x "$candidate" ]]; then
      FLUTTER_CMD="$candidate"
      break
    fi
  done
fi

if [[ -z "$FLUTTER_CMD" ]] || [[ ! -x "$FLUTTER_CMD" ]]; then
  echo "Flutter introuvable. Definir FLUTTER_BIN ou ajouter flutter au PATH (ex: /home/deck/dev/flutter/bin)." >&2
  exit 1
fi

run_bounded_flutter() {
  echo "> $FLUTTER_CMD $*"
  if ! timeout "$TIMEOUT_SECONDS" "$FLUTTER_CMD" "$@"; then
    local rc=$?
    if [[ $rc -eq 124 ]]; then
      echo "Commande Flutter interrompue apres ${TIMEOUT_SECONDS}s." >&2
      echo "Si le script tourne dans un bac a sable restreint, relance-le avec acces complet a \$HOME et au SDK Flutter." >&2
    fi
    return "$rc"
  fi
}

if [[ "$WITH_ANALYZE" -eq 1 ]]; then
  run_bounded_flutter analyze --no-pub
fi

case "$TARGET" in
  web)
    run_bounded_flutter build web --release --base-href '/Dice-throne-Solo/' --no-pub
    ;;
  apk)
    run_bounded_flutter build apk --release --no-pub
    ;;
  analyze)
    if [[ "$WITH_ANALYZE" -eq 0 ]]; then
      run_bounded_flutter analyze --no-pub
    fi
    ;;
esac

echo "Verification $TARGET terminee."
