import "dart:convert";

import "package:logger/logger.dart";
import "package:index/models/streaming_server.dart";
import "package:index/models/subtitle_style.dart";
import "package:shared_preferences/shared_preferences.dart";

class AppPreferences {
  factory AppPreferences() => _instance;

  AppPreferences._internal();
  static final AppPreferences _instance = AppPreferences._internal();
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool?> setStreamingServer(StreamingServer server) async => await _prefs?.setString("server", server.name);

  Future<bool?> setSeekDuration(int seekDuration) async => await _prefs?.setInt("seekDuration", seekDuration);

  Future<bool?> setSubtitlesStyle(SubtitleStyle subtitlesStyle) async => await _prefs?.setString("subtitleStyle", json.encode(subtitlesStyle.toJson()));

  String getStreamingServer() => _prefs?.getString("server") ?? "Random";

  int getSeekDuration() => _prefs?.getInt("seekDuration") ?? 15;

  SubtitleStyle getSubtitlesStyle() {
    Map<String, dynamic> data = <String, dynamic>{};

    try {
      data = json.decode(_prefs?.getString("subtitleStyle") ?? "{}");
    } catch (e, stackTrace) {
      Logger logger = Logger();
      logger.e("Error decoding subtitle style", error: e, stackTrace: stackTrace);
    }

    return SubtitleStyle.fromJson(data);
  }

  Future<bool?> clear() async => await _prefs?.clear();
}