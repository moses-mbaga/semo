import "dart:convert";
import "package:logger/logger.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:index/services/firestore_collection_names.dart";
import "package:index/services/auth_service.dart";

class FavoritesService {
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  static final FavoritesService _instance = FavoritesService._internal();

  final AuthService _auth = AuthService();
  final Logger _logger = Logger();

  String _getPreferenceKey() {
    final user = _auth.getUser();
    if (user == null) {
      throw Exception("User isn't authenticated");
    }

    try {
      return "${PreferencesKeys.favorites}_${user.id}";
    } catch (e, s) {
      _logger.e("Error getting favorites preference key", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = _getPreferenceKey();
      final String? jsonData = prefs.getString(key);

      if (jsonData == null) {
        final initialData = <String, dynamic>{
          "movies": <int>[],
          "tv_shows": <int>[],
        };
        await prefs.setString(key, jsonEncode(initialData));
        return initialData;
      }

      return jsonDecode(jsonData) as Map<String, dynamic>;
    } catch (e, s) {
      _logger.e("Error getting favorites", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<List<int>> getMovies({Map<String, dynamic>? favorites}) async {
    favorites ??= await getFavorites();

    try {
      return ((favorites["movies"] ?? <dynamic>[]) as List<dynamic>).cast<int>();
    } catch (e, s) {
      _logger.e("Error getting favorite movies", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<List<int>> getTvShows({Map<String, dynamic>? favorites}) async {
    favorites ??= await getFavorites();

    try {
      return ((favorites["tv_shows"] ?? <dynamic>[]) as List<dynamic>).cast<int>();
    } catch (e, s) {
      _logger.e("Error getting favorite TV shows", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> _saveFavorites(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = _getPreferenceKey();
      await prefs.setString(key, jsonEncode(data));
    } catch (e, s) {
      _logger.e("Error saving favorites", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<dynamic> addMovie(int movieId, {Map<String, dynamic>? allFavorites}) async {
    final Map<String, dynamic> favorites = allFavorites ?? await getFavorites();
    final List<int> movies = await getMovies(favorites: favorites);

    if (!movies.contains(movieId)) {
      movies.add(movieId);
      favorites["movies"] = movies;
      try {
        await _saveFavorites(favorites);
      } catch (e, s) {
        _logger.e("Error adding movie to favorites", error: e, stackTrace: s);
        rethrow;
      }
    }
  }

  Future<dynamic> addTvShow(int tvShowId, {Map<String, dynamic>? allFavorites}) async {
    final Map<String, dynamic> favorites = allFavorites ?? await getFavorites();
    final List<int> tvShows = await getTvShows(favorites: favorites);

    if (!tvShows.contains(tvShowId)) {
      tvShows.add(tvShowId);
      favorites["tv_shows"] = tvShows;
      try {
        await _saveFavorites(favorites);
      } catch (e, s) {
        _logger.e("Error adding TV show to favorites", error: e, stackTrace: s);
        rethrow;
      }
    }
  }

  Future<dynamic> removeMovie(int movieId, {Map<String, dynamic>? allFavorites}) async {
    final Map<String, dynamic> favorites = allFavorites ?? await getFavorites();
    final List<int> movies = await getMovies(favorites: favorites);

    if (movies.contains(movieId)) {
      movies.remove(movieId);
      favorites["movies"] = movies;
      try {
        await _saveFavorites(favorites);
      } catch (e, s) {
        _logger.e("Error removing movie from favorites", error: e, stackTrace: s);
        rethrow;
      }
    }
  }

  Future<dynamic> removeTvShow(int tvShowId, {Map<String, dynamic>? allFavorites}) async {
    final Map<String, dynamic> favorites = allFavorites ?? await getFavorites();
    final List<int> tvShows = await getTvShows(favorites: favorites);

    if (tvShows.contains(tvShowId)) {
      tvShows.remove(tvShowId);
      favorites["tv_shows"] = tvShows;
      try {
        await _saveFavorites(favorites);
      } catch (e, s) {
        _logger.e("Error removing TV show from favorites", error: e, stackTrace: s);
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
      _logger.e("Error clearing favorites", error: e, stackTrace: s);
      rethrow;
    }
  }
}