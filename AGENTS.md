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
- `docs/`: Markdown documentation and guides.
- Platform folders: `android/`, `ios/`.
- Config: `.env`, `.env.example`, `analysis_options.yaml`, `pubspec.yaml`.

## Environment Setup
### Flutter
- If `flutter` is not installed, download it for your OS:
  - [Windows](https://docs.flutter.dev/get-started/install/windows)
  - [macOS](https://docs.flutter.dev/get-started/install/macos)
  - [Linux](https://docs.flutter.dev/get-started/install/linux) (or `sudo snap install flutter --classic`)
- Run `flutter doctor` to ensure all required tooling is configured.
- Fetch dependencies with `flutter pub get`.


## Build and Dev Commands
- Generate code: `dart run build_runner build --delete-conflicting-outputs` — builds env/assets helpers.
- Analyze: `dart analyze` — static checks using `flutter_lints` config.
- Run app: `flutter run` (e.g., `-d chrome`, `-d ios`, `-d android`).
- Release builds: `flutter build aab --release`, `flutter build apk --release`, `flutter build ios --release`.

## Linting
- Run `dart analyze` regularly to catch issues early.
- Lints extend `flutter_lints` and are configured in `analysis_options.yaml`.
- Keep PRs lint-clean; fix all reported lints before merging.
- Apply fixes with `dart fix --apply` and format with `dart format .` when needed.

### Configured Rules (explicit)
- Enabled: `avoid_print`, `always_specify_types`, `always_declare_return_types`, `annotate_overrides`, `avoid_empty_else`, `prefer_const_constructors`, `prefer_final_fields`, `use_key_in_widget_constructors`, `unnecessary_this`, `sort_constructors_first`, `prefer_const_literals_to_create_immutables`, `avoid_init_to_null`, `type_annotate_public_apis`, `always_put_control_body_on_new_line`, `always_use_package_imports`, `avoid_annotating_with_dynamic`, `avoid_escaping_inner_quotes`, `avoid_final_parameters`, `avoid_multiple_declarations_per_line`, `avoid_type_to_string`, `avoid_unused_constructor_parameters`, `avoid_void_async`, `cancel_subscriptions`, `empty_catches`, `empty_constructor_bodies`, `exhaustive_cases`, `file_names`, `no_duplicate_case_values`, `no_literal_bool_comparisons`, `no_leading_underscores_for_local_identifiers`, `no_self_assignments`, `prefer_conditional_assignment`, `prefer_double_quotes`, `prefer_equal_for_default_values`, `prefer_expression_function_bodies`, `prefer_if_null_operators`, `prefer_is_empty`, `prefer_is_not_empty`, `prefer_null_aware_method_calls`, `prefer_null_aware_operators`, `unawaited_futures`, `unnecessary_await_in_return`, `unnecessary_brace_in_string_interps`, `unnecessary_breaks`, `unnecessary_const`, `unnecessary_late`, `unnecessary_null_aware_assignments`, `unnecessary_null_aware_operator_on_extension_on_nullable`, `unnecessary_null_in_if_null_operators`, `unnecessary_string_escapes`, `unnecessary_raw_strings`, `unnecessary_parenthesis`, `unnecessary_string_interpolations`, `unnecessary_to_list_in_spreads`, `unnecessary_underscores`, `use_named_constants`, `use_string_in_part_of_directives`, `implementation_imports`, `avoid_relative_lib_imports`, `prefer_adjacent_string_concatenation`, `prefer_interpolation_to_compose_strings`, `prefer_collection_literals`, `avoid_function_literals_in_foreach_calls`.
- Disabled: `non_constant_identifier_names`, `sized_box_for_whitespace`.

## Coding Style & Naming
- Follow `analysis_options.yaml` (extends `flutter_lints`). Key prefs: double quotes, explicit types, package imports, constructors first, const where possible.
- Files: `snake_case.dart` (`file_names` lint). Classes: `PascalCase`. Fields/locals: `camelCase`.
- Always spell out descriptive variable and property names; avoid abbreviations like `lang`, `idx`, or bare `controller` when a more specific full word (e.g., `language`, `index`, `videoController`) communicates intent better.
- Screens end with `...Screen`; services end with `...Service`. Keep widgets small and reusable in `components/`.

## Pre-commit Checks
- Before committing, run `dart analyze`.

## Commits & Pull Requests
- Commits: use imperative, concise subjects; include scope when clear (e.g., `screens: fix crash on movie screen`). Prefer descriptive refactors over generic messages.
- PRs: include summary, linked issues, screenshots for UI, and verification steps. Ensure: app builds, `dart analyze` passes, and `.env`/secrets are not committed.

## Security & Configuration
- Do not commit secrets. Use `.env` + `envied` to generate `lib/utils/env/env.g.dart` via build_runner.
