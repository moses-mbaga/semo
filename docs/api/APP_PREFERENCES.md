**App Preferences Service**

- **Location:** `lib/services/app_preferences_service.dart`
- **Storage:** `SharedPreferences` for lightweight, device-local settings.
- **Pattern:** Singleton (`AppPreferencesService()` returns one shared instance).
- **Init required:** Call and await `AppPreferencesService.init()` before any access.

**Keys & Defaults**

- `server` (`String`): selected streaming server name. Default: `"Random"`.
- `seek_duration` (`int`, seconds): skip forward/back duration. Default: `15`.

**API**

- `static Future<void> init()`
  - Initializes the shared preferences instance and validates the saved streaming server.
- `static Future<void> ensureActiveStreamingServerValidity()`
  - Helper invoked from `init()` that resets the saved server to `Random` if it no longer exists.
- `Future<bool?> setStreamingServer(StreamingServer server)`
- `Future<bool?> setSeekDuration(int seconds)`
- `String getStreamingServer()`
- `int getSeekDuration()`
- `Future<bool?> clear()`

Notes:
- Setters return `Future<bool?>` from `SharedPreferences`; this is `null` if `init()` wasn’t called.
- Getters fall back to defaults if values are missing or storage failed to initialize.

**Initialization**

- Call during app bootstrap (before `runApp`):
  - `await AppPreferencesService.init();`
- Example in repo: `lib/main.dart`.

**Common Usage**

- **Read server preference:**
  - `final name = AppPreferencesService().getStreamingServer();`
  - Used by stream extraction to select a provider.
  - Example: `lib/services/streams_extractor_service/streams_extractor_service.dart`.

- **Update server preference (Settings):**
  - `await AppPreferencesService().setStreamingServer(server);`
  - Example: `lib/screens/settings_screen.dart` (server selector bottom sheet).

- **Read seek duration (Player controls):**
  - `final seconds = AppPreferencesService().getSeekDuration();`
  - Example: `lib/components/semo_player.dart` uses it for double-tap/seek buttons.

- **Update seek duration (Settings):**
  - `await AppPreferencesService().setSeekDuration(30);`
  - Example: `lib/screens/settings_screen.dart` (seek duration selector).

- **Clear all preferences:**
  - `await AppPreferencesService().clear();`
  - Example: `lib/screens/settings_screen.dart` during account deletion/cleanup.

**Model References**

- `StreamingServer`: `lib/models/streaming_server.dart` (stores the `name`, used for persistence).

**Error Handling & Robustness**

- `ensureActiveStreamingServerValidity` prevents the app from storing a server that has been removed from the extractor list.
- Treat setter returns of `null` as “not persisted” (likely `init()` missing).
- For reactive UIs, read once at screen init and update after setter completes.

**Testing Tips**

- Use `SharedPreferences.setMockInitialValues({});` to initialize storage in tests.
- After setting mock values, run your tests with `flutter test`.
