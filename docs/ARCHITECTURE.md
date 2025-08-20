# Architecture

This document explains how state management works in this app using Flutter BLoC. It’s written for contributors and maintainers of this open‑source project.

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

## Files & Folders

- `lib/bloc/app_bloc.dart`: BLoC that wires events to handler methods using `on<...>()`. Mixes in feature handler mixins.
- `lib/bloc/app_event.dart`: All event types. Pure data, no logic.
- `lib/bloc/app_state.dart`: Single immutable state. Holds lists, maps, and paging controllers, plus transient flags.
- `lib/bloc/handlers/*.dart`: Feature‑scoped logic grouped by domain (movies, tv shows, genres, favorites, streams, subtitles, cache, etc.). Each exposes `onXxxYyy` methods that match events.
- `lib/services/*.dart`: Side‑effect boundaries (TMDB API, persistence, auth, preferences, stream extraction, subtitles, etc.).
- `lib/components/` and `lib/screens/`: Render from state and dispatch events.

## AppBloc

- `AppBloc` composes feature logic using mixins from `lib/bloc/handlers/` and registers event → handler bindings:
- Composition: Each mixin contributes a set of `on<Event>` handlers, keeping the bloc file small and feature code cohesive.
- Lifecycle: `init()` kicks off initial loads if the user is authenticated. `close()` disposes any subscriptions.

## Events

- Defined in `lib/bloc/app_event.dart` and grouped by domain (movies, tv shows, genres, favorites, recently watched, person media, recent searches, streams, subtitles, cache, general).
- Events are plain data classes (no logic) and should be serializable and easily testable.
- UI dispatches events via `context.read<AppBloc>().add(Event(...))`.

## State

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

## Handlers (Feature Mixins)

- Each file in `lib/bloc/handlers/` encapsulates side‑effectful use cases: fetch, refresh, update, clear, etc.
- Handlers read current `state`, call services, derive new data, and `emit(state.copyWith(...))`.
- They should be the only place where services are invoked. UI never calls services directly.
- Keep them small and focused per event. Share helper utilities in `lib/bloc/handlers/helpers.dart` when needed.

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

## Caching

- A `cacheTimer` in state (created by cache handlers) periodically invalidates or refreshes computed/cached data.
- On bloc `close()`, the timer is cancelled to avoid leaks.
- Currently defaults to 12 hours, but can be adjusted in `handlers/cache_handlers.dart`.

## Error Handling

- Handlers catch and map exceptions to `state.error` and clear relevant loading flags.
- UI listens for `error` and surfaces a non‑blocking message/snackbar; `ClearError` resets it.

## Authentication & Boot

- `AppBloc.init()` checks `AuthService().isAuthenticated()` and dispatches `LoadInitialData` to prime the app.
- Screens may guard by authentication state externally; business logic assumes auth has been established when needed.

## Testing

TBD

## Adding a New Feature

1. Define events in `lib/bloc/app_event.dart`.
2. Extend `AppState` with any new fields and `copyWith` support.
3. Create a handler mixin in `lib/bloc/handlers/your_feature_handler.dart` with `onXxx` methods.
4. Wire the handler in `AppBloc` by mixing it in and registering `on<Event>(onEvent)`.
5. Add or extend services in `lib/services/` for I/O.
6. Build UI that selects needed slices via `BlocSelector` and dispatches events.
7. Add tests for handler logic and UI smoke tests.

Naming & style:
- Events: imperative verbs (`LoadX`, `RefreshX`, `AddX`, `RemoveX`).
- State fields: reflect domain (`movieGenres`, `tvShowSeasons`) and flags (`isLoadingX`).
- Keep widgets small and reusable; screens end with `Screen`, services with `Service`.

## Performance Notes

- Use `BlocSelector` to minimize rebuilds of large trees.
- Keep state updates scoped; avoid replacing large lists/maps unless necessary.
- Prefer normalized maps keyed by IDs for detail caches.
- Consider throttling/debouncing high‑frequency events in handlers where appropriate.