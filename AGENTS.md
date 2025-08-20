# Repository Guidelines

## Project Structure & Modules
- `lib/`: App source code organized by feature.
  - `bloc/`: State management (flutter_bloc).
  - `components/`: Reusable widgets.
  - `screens/`: UI screens (suffix `_screen.dart`).
  - `services/`: Data/Firebase access (suffix `_service.dart`).
  - `models/`, 
  - `enums/`, 
  - `utils/`, 
  - `gen/` (generated assets),
  - `firebase_options.dart`.
- `assets/`: Images and lottie files declared in `pubspec.yaml`.
- `test/`: Widget/unit tests (`*_test.dart`).
- Platform folders: `android/`, `ios/`, `web/`.
- Config: `.env`, `.env.example`, `analysis_options.yaml`, `firebase.json`.

## Build, Test, and Dev Commands
- Install deps: `flutter pub get` — fetches packages.
- Generate code: `dart run build_runner build --delete-conflicting-outputs` — builds env/assets helpers.
- Analyze: `dart analyze` — static checks using `flutter_lints` config.
- Run app: `flutter run` (e.g., `-d chrome`, `-d ios`, `-d android`).
- Tests: `flutter test` (optionally `--coverage`).
- Release builds: `flutter build aab --release`, `flutter build apk --release`, `flutter build ios --release`.

## Coding Style & Naming
- Follow `analysis_options.yaml` (extends `flutter_lints`). Key prefs: double quotes, explicit types, package imports, constructors first, const where possible.
- Files: `snake_case.dart` (`file_names` lint). Classes: `PascalCase`. Fields/locals: `camelCase`.
- Screens end with `...Screen`; services end with `...Service`. Keep widgets small and reusable in `components/`.

## Testing Guidelines
- Framework: `flutter_test` with `testWidgets` and unit tests.
- Naming: mirror source path and use `*_test.dart` (e.g., `test/screens/landing_screen_test.dart`).
- Aim for fast widget smoke tests and service units; mock Firebase where needed. Run `flutter test` before pushing.

## Commits & Pull Requests
- Commits: use imperative, concise subjects; include scope when clear (e.g., `screens: fix crash on movie screen`). Prefer descriptive refactors over generic messages.
- PRs: include summary, linked issues, screenshots for UI, and test steps. Ensure: app builds, `dart analyze` passes, tests green, and `.env`/secrets are not committed.

## Security & Configuration
- Do not commit secrets. Use `.env` + `envied` to generate `lib/utils/env/env.g.dart` via build_runner.
