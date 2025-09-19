import "package:semo/models/streaming_server.dart";
import "package:semo/services/streams_extractor_service/streams_extractor_service.dart";
import "package:shared_preferences/shared_preferences.dart";

class AppPreferencesService {
  factory AppPreferencesService() => _instance;

  AppPreferencesService._internal();
  static final AppPreferencesService _instance = AppPreferencesService._internal();
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await ensureActiveStreamingServerValidity();
  }

  static Future<void> ensureActiveStreamingServerValidity() async {
    try {
      AppPreferencesService appPreferencesService = AppPreferencesService();
      List<StreamingServer> servers = StreamsExtractorService().getStreamingServers();
      String savedServerName = appPreferencesService.getStreamingServer();
      int selectedServerIndex = servers.indexWhere((StreamingServer server) => server.name == savedServerName);

      if (selectedServerIndex == -1) {
        savedServerName = "Random";
        StreamingServer server = servers.firstWhere((StreamingServer s) => s.name == savedServerName);
        await appPreferencesService.setStreamingServer(server);
      }
    } catch (_) {}
  }

  Future<bool?> setStreamingServer(StreamingServer server) async => await _prefs?.setString("server", server.name);

  Future<bool?> setSeekDuration(int seekDuration) async => await _prefs?.setInt("seek_duration", seekDuration);

  String getStreamingServer() => _prefs?.getString("server") ?? "Random";

  int getSeekDuration() => _prefs?.getInt("seek_duration") ?? 15;

  Future<bool?> clear() async => await _prefs?.clear();
}
