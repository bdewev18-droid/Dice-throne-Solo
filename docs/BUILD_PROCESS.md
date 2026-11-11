# Build and Deployment Process

## Source of truth

- Enemy profiles live in `docs/enemy_profiles.json`.
- The JSON is loaded at startup by `lib/data/enemy_profile_repository.dart`.
- `lib/data/fallback_enemy_profiles.dart` only contains generic fallback profiles and the Naxarus safety profile used if the JSON cannot be loaded.
- The data model and attack-plan types live in `lib/models/enemy_profile.dart`.
- Do not add a full enemy profile back to `lib/main.dart`.

## Dart structure

`lib/main.dart` is now the shared application library and entry point. Its UI is split into Dart parts so existing private helpers and state can be migrated safely without duplicated imports:

- `lib/parts/app_shell.dart`
- `lib/parts/history.dart`
- `lib/parts/hero_setup.dart`
- `lib/parts/map.dart`
- `lib/parts/fight.dart`
- `lib/parts/rewards_details.dart`
- `lib/parts/run_generation.dart`

New screen or combat UI code should go into the matching part file. Keep `main.dart` for shared state/models, startup, and library-wide helpers.

## Versioning

Use one command from the repository root to synchronize `pubspec.yaml`, `lib/main.dart`, and `web/version.json`:

**Windows (PowerShell):**

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\set-version.ps1 -Version 1.2.30 -BuildNumber 43
```

**Linux / SteamOS (Bash):**

```bash
./tool/set-version.sh --version 1.2.30 --build-number 43
```

## Environment Variables & Toolchain

- **GitHub Actions Flutter:** `3.44.5` (`channel: stable`)
- **Dart:** `3.12.2` (`sdk: ">=3.8.0 <4.0.0"`)
- **Node.js (local preview & tools):** `>=22.13.0` (`v22.x` LTS recommended)

### Windows

Define these environment variables (or PowerShell session variables) so `flutter`, Android builds, Chrome debugging, and `.ps1` scripts resolve cleanly:

```powershell
$env:FLUTTER_BIN       = "C:\dev\flutter\bin\flutter.bat"
$env:ANDROID_SDK_ROOT  = "C:\dev\sdk"
$env:CHROME_EXECUTABLE = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$env:Path              = "C:\dev\flutter\bin;$env:ANDROID_SDK_ROOT\platform-tools;$env:Path"
```

*(If Google Chrome is installed per-user on Windows, use `"$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"`.)*

Important for Codex/local automation on Windows: Flutter must be executed with system permissions, outside the restricted filesystem sandbox. The Flutter tool writes to `%APPDATA%\.flutter_tool_state` and reads `C:\dev\flutter`; sandboxed runs can hang or timeout before returning useful output.

### Linux / SteamOS (Recommandations & Setup)

Sur SteamOS (système `/` en lecture seule de 5 Go réinitialisé aux mises à jour, et SSD interne rapide) :

- **Installer en espace utilisateur sur le SSD interne** (`/home/deck/dev/flutter`, `/home/deck/dev/node`) et placer les dépôts actifs sur le SSD (`/home/deck/Projects`) pour garder des `pub get`, `npm ci` et compilations rapides. Ne jamais installer les outils dans `/` via `pacman`.
- **Android SDK (`ANDROID_HOME` / `GRADLE_USER_HOME`) :** éviter de l'installer sur un SSD 64 Go (il consomme 10 à 20 Go). Privilégier **GitHub Actions (`build-apk.yml`)** pour générer l'APK, ou déporter `ANDROID_HOME` et `GRADLE_USER_HOME` sur une carte microSD formatée en **`ext4`** (ex. `/run/media/deck/SR128/android-sdk`).
- **Google Chrome sous SteamOS :** Chrome est généralement installé en Flatpak (`com.google.Chrome`). Pour le dev web local, privilégier `flutter run -d web-server` ou `node ./tool/local-web-preview.js` (aucun binaire Chrome natif requis).

Variables à configurer dans `~/.bashrc` / `~/.bash_profile` :

```bash
export PATH="/home/deck/dev/node/bin:/home/deck/dev/flutter/bin:$PATH"
export FLUTTER_BIN="/home/deck/dev/flutter/bin/flutter"
# Optionnel si Chrome est utilisé en Flatpak pour `flutter run -d chrome` :
export CHROME_EXECUTABLE="/var/lib/flatpak/exports/bin/com.google.Chrome"
```

## Fast local check

### Windows (PowerShell `.ps1`)

If Flutter commands hang locally on Windows, first check:

```powershell
C:\dev\flutter\bin\flutter.bat doctor -v
git config --global --add safe.directory C:/dev/flutter
C:\dev\flutter\bin\flutter.bat doctor --android-licenses
```

For Codex tool calls, request/run Flutter with elevated/system permissions so the tool can access AppData and the Flutter SDK cache. Do not repeatedly rerun analyze/test inside the sandbox if it times out; switch to elevated Flutter or GitHub Actions.

The default check builds only the requested target and stops a stuck Flutter process:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\verify-fast.ps1 -Target web -TimeoutSeconds 180
powershell -ExecutionPolicy Bypass -File .\tool\verify-fast.ps1 -Target apk -TimeoutSeconds 300
```

Add `-WithAnalyze` only for a deliberate full check. A successful web or APK build already compiles the application and is the fast feedback loop.

### Linux / SteamOS (Bash `.sh`)

Initial check (one-time if Flutter complains about git ownership):

```bash
flutter doctor -v
git config --global --add safe.directory /home/deck/dev/flutter
```

Fast target check:

```bash
./tool/verify-fast.sh --target web --timeout 180
./tool/verify-fast.sh --target analyze --timeout 180
# Pour build APK local (uniquement si Android SDK est configuré) :
./tool/verify-fast.sh --target apk --timeout 300
```

Add `--with-analyze` for a deliberate full check before pushing.

## Local web preview

Use this when you want to test the mobile web build locally before pushing to GitHub Pages.

1. Build the web release:

**Windows:**

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\verify-fast.ps1 -Target web -TimeoutSeconds 900
```

**Linux / SteamOS:**

```bash
./tool/verify-fast.sh --target web --timeout 900
```

2. Start the local preview server (cross-platform Node.js):

```bash
node ./tool/local-web-preview.js
```

*(If `node` is not in the Windows `PATH`, use the bundled Node runtime, e.g. `& "C:\Users\Focus on you\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe" .\tool\local-web-preview.js`.)*

3. Open the local preview:

```text
http://127.0.0.1:8083/Dice-throne-Solo/
```

When an automation agent starts the preview in the background, stop that server with:

- **Windows:** `Stop-Process -Id <PID>`
- **Linux:** `kill <PID>` (or `PORT=8084 node ./tool/local-web-preview.js` if 8083 is busy)

## GitHub Actions

The web and APK workflows are independent manual workflows. Each has a job timeout, a concurrency group, and an optional `run_analyze` input disabled by default. Trigger only the artifact needed for the current iteration. The workflow run itself is the build history; do not launch both workflows for a UI-only change.

```powershell
gh api repos/bdewev18-droid/Dice-throne-Solo/actions/workflows/deploy-pages.yml/dispatches -f ref=main
gh api repos/bdewev18-droid/Dice-throne-Solo/actions/workflows/build-apk.yml/dispatches -f ref=main
```

If a previous run is still active, the concurrency group cancels it when a newer run is dispatched. This prevents several obsolete deployments from consuming the queue.
