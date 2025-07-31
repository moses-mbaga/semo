import "dart:convert";
import "package:logger/logger.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:index/services/firestore_collection_names.dart";
import "package:index/enums/media_type.dart";
import "package:index/services/auth_service.dart";

class RecentSearchesService {
  factory RecentSearchesService() => _instance;
  RecentSearchesService._internal();

  static final RecentSearchesService _instance = RecentSearchesService._internal();

  final AuthService _auth = AuthService();
  final Logger _logger = Logger();

  String _getPreferenceKey() {
    final user = _auth.getUser();
    if (user == null) {
      throw Exception("User isn't authenticated");
    }

    try {
      return "${PreferencesKeys.recentSearches}_${user.id}";
    } catch (e, s) {
      _logger.e("Error getting recent searches preference key", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getSearchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = _getPreferenceKey();
      final String? jsonData = prefs.getString(key);

      if (jsonData == null) {
        final initialData = <String, dynamic>{
          "movies": <String>[],
          "tv_shows": <String>[],
        };
        await prefs.setString(key, jsonEncode(initialData));
        return initialData;
      }

      return jsonDecode(jsonData) as Map<String, dynamic>;
    } catch (e, s) {
      _logger.e("Error getting search data", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> _saveSearchData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = _getPreferenceKey();
      await prefs.setString(key, jsonEncode(data));
    } catch (e, s) {
      _logger.e("Error saving search data", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<List<String>> getRecentSearches(MediaType mediaType) async {
    try {
      final Map<String, dynamic> data = await _getSearchData();
      final String fieldName = mediaType.toJsonField();
      final List<String> searches = ((data[fieldName] ?? <dynamic>[]) as List<dynamic>).cast<String>();

      // Return in reverse order (most recent first)
      return searches.reversed.toList();
    } catch (e, s) {
      _logger.e("Error getting recent searches", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<dynamic> add(MediaType mediaType, String query) async {
    final String fieldName = mediaType.toJsonField();
    final Map<String, dynamic> data = await _getSearchData();
    final List<String> searches = ((data[fieldName] ?? <dynamic>[]) as List<dynamic>).cast<String>();

    // Remove duplicate entry
    if (searches.contains(query)) {
      searches.remove(query);
    }

    // Add to beginning
    searches.insert(0, query);

    // Limit to 20 recent searches
    if (searches.length > 20) {
      searches.removeRange(20, searches.length);
    }

    try {
      data[fieldName] = searches;
      await _saveSearchData(data);
    } catch (e, s) {
      _logger.e("Error adding query to recent searches", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<dynamic> remove(MediaType mediaType, String query) async {
    final String fieldName = mediaType.toJsonField();
    final Map<String, dynamic> data = await _getSearchData();
    final List<String> searches = ((data[fieldName] ?? <dynamic>[]) as List<dynamic>).cast<String>();

    if (searches.contains(query)) {
      searches.remove(query);
      try {
        data[fieldName] = searches;
        await _saveSearchData(data);
      } catch (e, s) {
        _logger.e("Error removing query from recent searches", error: e, stackTrace: s);
        rethrow;
      }
    }
  }

  Future<dynamic> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = _getPreferenceKey();
      await prefs.remove(key);
    } catch (e, s) {
      _logger.e("Error clearing recent searches", error: e, stackTrace: s);
      rethrow;
    }
  }
}