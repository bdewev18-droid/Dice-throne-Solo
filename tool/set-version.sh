#!/usr/bin/env bash
set -euo pipefail

VERSION=""
BUILD_NUMBER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version|-v)
      VERSION="${2:-}"
      shift 2
      ;;
    --build-number|-b)
      BUILD_NUMBER="${2:-}"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 --version X.Y.Z --build-number N"
      exit 0
      ;;
    *)
      if [[ -z "$VERSION" ]]; then
        VERSION="$1"
        shift
      elif [[ -z "$BUILD_NUMBER" ]]; then
        BUILD_NUMBER="$1"
        shift
      else
        echo "Argument inconnu: $1" >&2
        exit 1
      fi
      ;;
  esac
done

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version invalide '$VERSION'. Format attendu: X.Y.Z (ex: 1.5.25)" >&2
  exit 1
fi

if [[ ! "$BUILD_NUMBER" =~ ^[0-9]+$ ]] || (( BUILD_NUMBER < 1 || BUILD_NUMBER > 999999 )); then
  echo "BuildNumber invalide '$BUILD_NUMBER'. Attendu: entier entre 1 et 999999." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

NODE_BIN="${NODE_BIN:-}"
if [[ -z "$NODE_BIN" ]]; then
  if command -v node >/dev/null 2>&1; then
    NODE_BIN="$(command -v node)"
  elif [[ -x "/home/deck/dev/node/bin/node" ]]; then
    NODE_BIN="/home/deck/dev/node/bin/node"
  else
    echo "Node.js introuvable pour synchroniser la version." >&2
    exit 1
  fi
fi

"$NODE_BIN" - "$ROOT_DIR" "$VERSION" "$BUILD_NUMBER" <<'EOF'
const fs = require('fs');
const path = require('path');

const [rootDir, version, buildStr] = process.argv.slice(2);
const buildNumber = Number(buildStr);

const pubspecPath = path.join(rootDir, 'pubspec.yaml');
const mainPath = path.join(rootDir, 'lib', 'main.dart');
const versionJsonPath = path.join(rootDir, 'web', 'version.json');

let pubspec = fs.readFileSync(pubspecPath, 'utf8');
pubspec = pubspec.replace(/^version:\s*\S+\r?$/m, `version: ${version}+${buildNumber}`);
fs.writeFileSync(pubspecPath, pubspec, 'utf8');

let mainDart = fs.readFileSync(mainPath, 'utf8');
mainDart = mainDart.replace(
  /const String appVersionLabel = 'Version [^']+';/,
  `const String appVersionLabel = 'Version ${version}';`
);
if (/const int appBuildNumber = \d+;/.test(mainDart)) {
  mainDart = mainDart.replace(
    /const int appBuildNumber = \d+;/,
    `const int appBuildNumber = ${buildNumber};`
  );
}
fs.writeFileSync(mainPath, mainDart, 'utf8');

if (fs.existsSync(versionJsonPath)) {
  try {
    const vJson = JSON.parse(fs.readFileSync(versionJsonPath, 'utf8'));
    vJson.version = version;
    vJson.buildNumber = buildNumber;
    fs.writeFileSync(versionJsonPath, JSON.stringify(vJson, null, 4) + '\n', 'utf8');
  } catch (err) {
    console.warn(`Impossible de mettre a jour web/version.json: ${err.message}`);
  }
}

console.log(`Version synchronisee: ${version}+${buildNumber}`);
EOF
