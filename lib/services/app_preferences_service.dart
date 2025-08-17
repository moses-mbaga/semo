import "dart:convert";

import "package:logger/logger.dart";
import "package:semo/models/streaming_server.dart";
import "package:semo/models/subtitle_style.dart";
import "package:shared_preferences/shared_preferences.dart";

class AppPreferencesService {
  factory AppPreferencesService() => _instance;

  AppPreferencesService._internal();
  static final AppPreferencesService _instance = AppPreferencesService._internal();
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool?> setStreamingServer(StreamingServer server) async => await _prefs?.setString("server", server.name);

  Future<bool?> setSeekDuration(int seekDuration) async => await _prefs?.setInt("seek_duration", seekDuration);

  Future<bool?> setSubtitlesStyle(SubtitleStyle subtitlesStyle) async => await _prefs?.setString("subtitle_style", json.encode(subtitlesStyle.toJson()));

  String getStreamingServer() => _prefs?.getString("server") ?? "Random";

  int getSeekDuration() => _prefs?.getInt("seek_duration") ?? 15;

  SubtitleStyle getSubtitlesStyle() {
    Map<String, dynamic> data = <String, dynamic>{};

    try {
      data = json.decode(_prefs?.getString("subtitle_style") ?? "{}");
    } catch (e, stackTrace) {
      Logger logger = Logger();
      logger.e("Error decoding subtitle style", error: e, stackTrace: stackTrace);
    }

    return SubtitleStyle.fromJson(data);
  }

  Future<bool?> clear() async => await _prefs?.clear();
}