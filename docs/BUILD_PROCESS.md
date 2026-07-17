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

The default check builds only the requested target and stops a stuck Flutter process:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\verify-fast.ps1 -Target web -TimeoutSeconds 180
powershell -ExecutionPolicy Bypass -File .\tool\verify-fast.ps1 -Target apk -TimeoutSeconds 300
```

Add `-WithAnalyze` only for a deliberate full check. A successful web or APK build already compiles the application and is the fast feedback loop.

## GitHub Actions

The web and APK workflows are independent manual workflows. Each has a job timeout, a concurrency group, and an optional `run_analyze` input disabled by default. Trigger only the artifact needed for the current iteration. The workflow run itself is the build history; do not launch both workflows for a UI-only change.

```powershell
gh api repos/bdewev18-droid/Dice-throne-Solo/actions/workflows/deploy-pages.yml/dispatches -f ref=main
gh api repos/bdewev18-droid/Dice-throne-Solo/actions/workflows/build-apk.yml/dispatches -f ref=main
```

If a previous run is still active, the concurrency group cancels it when a newer run is dispatched. This prevents several obsolete deployments from consuming the queue.
