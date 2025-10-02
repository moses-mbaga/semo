import "package:flutter_test/flutter_test.dart";
import "package:semo/models/streaming_server.dart";
import "package:semo/services/app_preferences_service.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppPreferencesService.init();
  });

  test("defaults to the Random streaming server", () {
    expect(AppPreferencesService().getStreamingServer(), "Random");
  });

  test("persists a selected streaming server", () async {
    const StreamingServer server = StreamingServer(name: "Custom", extractor: null);

    await AppPreferencesService().setStreamingServer(server);

    expect(AppPreferencesService().getStreamingServer(), server.name);
  });

  test("uses a default seek duration of 15 seconds", () {
    expect(AppPreferencesService().getSeekDuration(), 15);
  });

  test("stores a custom seek duration", () async {
    await AppPreferencesService().setSeekDuration(45);

    expect(AppPreferencesService().getSeekDuration(), 45);
  });

  test("clear resets stored values back to defaults", () async {
    await AppPreferencesService().setStreamingServer(
      const StreamingServer(name: "Another", extractor: null),
    );
    await AppPreferencesService().setSeekDuration(20);

    await AppPreferencesService().clear();

    expect(AppPreferencesService().getStreamingServer(), "Random");
    expect(AppPreferencesService().getSeekDuration(), 15);
  });
}
