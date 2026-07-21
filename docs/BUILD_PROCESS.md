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

Use one command from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\set-version.ps1 -Version 1.2.30 -BuildNumber 43
```

The command updates both `pubspec.yaml` and the version displayed in the app.

## Fast local check

Important for Codex/local automation: Flutter must be executed with system
permissions, outside the restricted filesystem sandbox. The Flutter tool writes
to `%APPDATA%\.flutter_tool_state` and reads `C:\dev\flutter`; sandboxed runs can
hang or timeout before returning useful output.

Known-good local setup:

- Flutter: `C:\dev\flutter\bin\flutter.bat`
- Android SDK: `C:\dev\sdk`
- Local Flutter observed: `3.44.4`
- GitHub Actions Flutter: `3.44.5`
- Dart: `3.12.2`

If Flutter commands hang locally, first check:

```powershell
C:\dev\flutter\bin\flutter.bat doctor -v
git config --global --add safe.directory C:/dev/flutter
C:\dev\flutter\bin\flutter.bat doctor --android-licenses
```

For Codex tool calls, request/run Flutter with elevated/system permissions so
the tool can access AppData and the Flutter SDK cache. Do not repeatedly rerun
analyze/test inside the sandbox if it times out; switch to elevated Flutter or
GitHub Actions.

The default check builds only the requested target and stops a stuck Flutter process:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\verify-fast.ps1 -Target web -TimeoutSeconds 180
powershell -ExecutionPolicy Bypass -File .\tool\verify-fast.ps1 -Target apk -TimeoutSeconds 300
```

Add `-WithAnalyze` only for a deliberate full check. A successful web or APK build already compiles the application and is the fast feedback loop.

## Local web preview

Use this when you want to test the mobile web build locally before pushing to
GitHub Pages.

1. Build the web release outside the Codex sandbox / with system permissions:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\verify-fast.ps1 -Target web -TimeoutSeconds 900
```

2. Start the local preview server:

```powershell
node .\tool\local-web-preview.js
```

If `node` is not in the Windows `PATH`, use the Codex bundled Node runtime:

```powershell
& "C:\Users\Focus on you\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe" .\tool\local-web-preview.js
```

3. Open the local preview:

```text
http://127.0.0.1:8082/Dice-throne-Solo/
```

When Codex starts the preview in the background, it reports a process id. Stop
that server with:

```powershell
Stop-Process -Id <PID>
```

## GitHub Actions

The web and APK workflows are independent manual workflows. Each has a job timeout, a concurrency group, and an optional `run_analyze` input disabled by default. Trigger only the artifact needed for the current iteration. The workflow run itself is the build history; do not launch both workflows for a UI-only change.

```powershell
gh api repos/bdewev18-droid/Dice-throne-Solo/actions/workflows/deploy-pages.yml/dispatches -f ref=main
gh api repos/bdewev18-droid/Dice-throne-Solo/actions/workflows/build-apk.yml/dispatches -f ref=main
```

If a previous run is still active, the concurrency group cancels it when a newer run is dispatched. This prevents several obsolete deployments from consuming the queue.
