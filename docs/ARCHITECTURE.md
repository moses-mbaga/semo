# Architecture

This document explains how the app is organized and how state management works using Flutter BLoC. It’s written for contributors and maintainers of this open‑source project.

## Project Structure

High‑level folders and the most important files:

```
.
├─ lib/
│  ├─ bloc/                 # flutter_bloc state management (events/state/handlers)
│  │  ├─ app_bloc.dart
│  │  ├─ app_event.dart
│  │  ├─ app_state.dart
│  │  └─ handlers/          # Feature mixins (genres, general, ...)
│  ├─ components/           # Reusable widgets (small, composable)
│  ├─ screens/              # UI screens (end with *Screen)
│  ├─ services/             # Data access, APIs, persistence, secrets
│  │  └─ secrets_service.dart  # envied source → generates secrets_service.g.dart
│  ├─ models/               # Domain models
│  ├─ enums/                # Enums shared across features
│  ├─ utils/                # Helpers, formatters, extensions
│  ├─ gen/                  # Generated assets helper (assets.gen.dart)
│  ├─ firebase_options.dart # FlutterFire config
│  └─ main.dart             # App entry
├─ assets/                  # Images, lottie, etc. Declared in pubspec.yaml
├─ docs/                    # Project documentation (this file, API notes, etc.)
├─ test/                    # Unit/widget tests (*_test.dart)
├─ android/ ios/ web/      # Platform folders
├─ .env / .env.example      # Local secrets (never commit real secrets)
├─ analysis_options.yaml    # Lints (extends flutter_lints)
├─ firebase.json            # Firebase config
└─ pubspec.yaml             # Dependencies and assets declarations
```

Conventions and naming:
- Files use `snake_case.dart`; classes use `PascalCase`; fields/locals use `camelCase`.
- Screens end with `...Screen`; services end with `...Service`.
- Keep widgets small and reusable under `components/`. Put large page layouts in `screens/`.

## Overview

- Pattern: Single, app‑wide `AppBloc` orchestrating features via typed `AppEvent` and immutable `AppState`.
- Organization: Feature handlers live in `lib/bloc/handlers/` and are mixed into `AppBloc` as composable units.
- UI: Screens and components render from state via `BlocBuilder`/`BlocSelector` and dispatch events to `AppBloc`.
- Data: Side effects are isolated in services under `lib/services/` (TMDB, favorites, subtitles, auth, etc.).
- Immutability: State is a single immutable object with a `copyWith` API for precise updates.

```
┌──────────┐      ┌───────────┐      ┌─────────────┐
│   UI     │ ───▶ │  AppEvent │ ───▶ │   Handlers  │
│(Screens, │      └───────────┘      │ (mixins)    │
│Components)│            ▲            └──────┬──────┘
└─────┬────┘            │                   │ calls
      │           `add(event)`               ▼
      │                                     Services  ──▶ Network/Storage
      ▼                                     (pure I/O)
┌──────────┐      ┌───────────┐
│  State   │ ◀─── │  emit(...)│
└──────────┘      └───────────┘
```



## Bloc

- `AppBloc` composes feature logic using mixins from `lib/bloc/handlers/` and registers event → handler bindings:
- Composition: Each mixin contributes a set of `on<Event>` handlers, keeping the bloc file small and feature code cohesive.
- Lifecycle: `init()` kicks off initial loads if the user is authenticated. `close()` disposes any subscriptions.

## Bloc Events

- Defined in `lib/bloc/app_event.dart` and grouped by domain (movies, tv shows, genres, favorites, recently watched, person media, recent searches, streams, subtitles, cache, general).
- Events are plain data classes (no logic) and should be serializable and easily testable.
- UI dispatches events via `context.read<AppBloc>().add(Event(...))`.

## Bloc State

- Defined in `lib/bloc/app_state.dart` as an immutable class with final fields and a `copyWith` method that uses a sentry `_notProvided` to distinguish “no change” vs “set to null”.
- Holds:
  - Domain data: movies, tv shows, genres, casts, trailers.
  - Feature maps keyed by IDs: detailed entities, recommendations, similar lists.
  - UI flags: `isLoading*`, fine‑grained maps like `isMovieLoading[movieId]`.
  - Pagination: `PagingController<int, T>` instances for infinite lists (global, by genre, and by streaming platform).
  - Utilities: `cacheTimer`, `error` message, search lists, streams/subtitles caches.

Guidelines:
- Keep fields normalized and keyed by stable IDs when possible.
- Prefer `copyWith` updates that narrow changes to affected subtrees.

## Bloc Handlers (Feature Mixins)

- Each file in `lib/bloc/handlers/` encapsulates side‑effectful use cases: fetch, refresh, update, clear, etc.
- Handlers read current `state`, call services, derive new data, and `emit(state.copyWith(...))`.
- They should be the only place where services are invoked. UI never calls services directly.
- Keep them small and focused per event. Share helper utilities in `lib/bloc/handlers/helpers.dart` when needed.

## Bloc State Caching

- A `cacheTimer` in state (created by cache handlers) periodically invalidates or refreshes computed/cached data.
- On bloc `close()`, the timer is cancelled to avoid leaks.
- Currently defaults to 12 hours, but can be adjusted in `handlers/cache_handlers.dart`.

## Services and Side Effects

- Located under `lib/services/` and wrap networking, caching, persistence and platform I/O.
- Services are stateless (or internally stateful) adapters. Handlers orchestrate them.
- Errors should be caught in handlers and surfaced via `state.error` plus any appropriate loading flag resets.

## UI Layer

- Screens in `lib/screens/` subscribe via `BlocBuilder<AppBloc, AppState>` or `BlocSelector` for fine‑grained rebuilds.
- UI triggers work by dispatching typed events.
- Reusable widgets live in `lib/components/` and receive data from the current state or via props.
- Navigation should be decoupled from business logic; derive what to show from state and route arguments.

## Pagination

- Infinite lists are powered by `infinite_scroll_pagination`.
- `PagingController` instances are stored in state to allow consistent paging per feed (global lists, by genre, by platform).
- Handlers load pages on demand and append results to the active controller.

## Error Handling

- Handlers catch and map exceptions to `state.error` and clear relevant loading flags.
- UI listens for `error` and surfaces a non‑blocking message/snackbar; `ClearError` resets it.

## Authentication & Boot

- `AppBloc.init()` checks `AuthService().isAuthenticated()` and dispatches `LoadInitialData` to prime the app.
- Screens may guard by authentication state externally; business logic assumes auth has been established when needed.

## Testing

TBD

## Generated Code (Assets & Env)

Some files are generated via build_runner and should not be edited by hand:

- `lib/gen/assets.gen.dart`: Strongly‑typed asset accessors generated from `pubspec.yaml` assets. Update assets under `assets/` and their declarations in `pubspec.yaml`, then regenerate.
- `lib/services/secrets_service.g.dart`: Generated by `envied` from `.env` based on annotations in `lib/services/secrets_service.dart`. Do not commit actual secrets; only commit `.env.example`.

Commands:
- One‑off generation: `dart run build_runner build --delete-conflicting-outputs`
- Continuous watch: `dart run build_runner watch --delete-conflicting-outputs`

Notes:
- Re‑run the command after adding/removing assets or changing `.env` values.
- If generation fails, verify assets are declared in `pubspec.yaml` and required env keys exist in `.env` (see `docs/api/SECRETS.md`).
- Do not edit generated files; changes will be overwritten on the next build.

## Adding a New Feature

Keep changes scoped to the type of feature you are adding. A few common paths:

- New screen: Create under `lib/screens/` with a `...Screen` suffix. Render state with `BlocBuilder`/`BlocSelector` and dispatch events to trigger work. Extract reusable parts into `lib/components/`. Wire up navigation where appropriate.
- New component: Add to `lib/components/` as a small, reusable widget. Keep it presentational; take typed inputs and avoid side effects.
- New service: Add under `lib/services/` with a `...Service` suffix. Encapsulate I/O (network, storage, platform). Surface clear methods and errors (throw or typed results). If secrets are needed, read via `SecretsService` (generated by `envied`).
- Update BLoC (when business logic is needed): Add events in `lib/bloc/app_event.dart`, state fields in `lib/bloc/app_state.dart`, and handler methods in a mixin inside `lib/bloc/handlers/`. Register handlers in `AppBloc`. UI should never call services directly.
- New model/enum: Add to `lib/models/` or `lib/enums/`. Keep models immutable with explicit fields and constructors. Provide serialization if required.
- New assets: Place files under `assets/` and declare in `pubspec.yaml`. Regenerate helpers with `dart run build_runner build --delete-conflicting-outputs`, then reference via `lib/gen/assets.gen.dart`.
- Tests: For logic, add unit tests (handlers/services). For UI, add widget tests. Keep tests close to the feature.

Before opening a PR: run `flutter pub get`, `dart analyze`, optional `flutter test`, and regenerate code if assets or env changed.

Naming & style:
- Events: imperative verbs (`LoadX`, `RefreshX`, `AddX`, `RemoveX`).
- State fields: reflect domain (`movieGenres`, `tvShowSeasons`) and flags (`isLoadingX`).
- Keep widgets small and reusable; screens end with `Screen`, services with `Service`.

## Performance Notes

- Use `BlocSelector` to minimize rebuilds of large trees.
- Keep state updates scoped; avoid replacing large lists/maps unless necessary.
- Prefer normalized maps keyed by IDs for detail caches.
- Consider throttling/debouncing high‑frequency events in handlers where appropriate.