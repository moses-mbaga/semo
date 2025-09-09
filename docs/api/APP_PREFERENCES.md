**App Preferences Service**

- **Location:** `lib/services/app_preferences_service.dart`
- **Storage:** `SharedPreferences` for lightweight, device-local settings.
- **Pattern:** Singleton (`AppPreferencesService()` returns one shared instance).
- **Init required:** Call and await `AppPreferencesService.init()` before any access.

**Keys & Defaults**

- `server` (String): selected streaming server name. Default: `"Random"`.
- `seek_duration` (int, seconds): skip forward/back duration. Default: `15`.
- `subtitle_style` (JSON String): serialized `SubtitleStyle`. Defaults via `SubtitleStyle.fromJson({})`:
  - `font_size`: `18.0`, `color`: `"Black"`, `has_border`: `true`.
  - `border_width`: `5.0`, `border_style`: `"stroke"`, `border_color`: `"White"`.

**API**

- `static Future<void> init()`
- `Future<bool?> setStreamingServer(StreamingServer server)`
- `Future<bool?> setSeekDuration(int seconds)`
- `Future<bool?> setSubtitlesStyle(SubtitleStyle style)`
- `String getStreamingServer()`
- `int getSeekDuration()`
- `SubtitleStyle getSubtitlesStyle()`
- `Future<bool?> clear()`

Notes:
- Setters return `Future<bool?>` from `SharedPreferences`; may be `null` if `init()` wasn’t called.
- Getters safely fall back to sane defaults if unset or if decoding fails.

**Initialization**

- Call during app bootstrap (before `runApp`):
  - `await AppPreferencesService.init();`
- Example in repo: `lib/main.dart`.

**Common Usage**

- **Read server preference:**
  - `final name = AppPreferencesService().getStreamingServer();`
  - Used by stream extraction to select a provider.
  - Example: `lib/services/stream_extractor_service/stream_extractor_service.dart`.

- **Update server preference (Settings):**
  - `await AppPreferencesService().setStreamingServer(server);`
  - Example: `lib/screens/settings_screen.dart` (bottom sheet selector).

- **Read seek duration (Player controls):**
  - `final seconds = AppPreferencesService().getSeekDuration();`
  - Example: `lib/components/semo_player.dart` uses it for double‑tap/seek buttons.

- **Update seek duration (Settings):**
  - `await AppPreferencesService().setSeekDuration(30);`
  - Example: `lib/screens/settings_screen.dart` (seek duration selector).

- **Read/Write subtitle style:**
  - Read: `final style = AppPreferencesService().getSubtitlesStyle();`
  - Write: `await AppPreferencesService().setSubtitlesStyle(style.copyWith(...));`
  - Example read/transform: `lib/components/semo_player.dart` maps to UI `SubtitleStyle`.
  - Example editor: `lib/screens/subtitles_preferences_screen.dart` updates and persists on change.

- **Clear all preferences:**
  - `await AppPreferencesService().clear();`
  - Example: `lib/screens/settings_screen.dart` during account deletion/cleanup.

**Model References**

- `StreamingServer`: `lib/models/streaming_server.dart` (stores `name`, used for persistence).
- `SubtitleStyle`: `lib/models/subtitle_style.dart` (JSON shape, defaults, color options).

**Error Handling & Robustness**

- Subtitle style JSON decoding is wrapped; on error it logs and returns defaults.
- Treat setter returns of `null` as “not persisted” (likely `init()` missing).
- For reactive UIs, read once at screen init and update after setter completes.

**Testing Tips**

TBD
