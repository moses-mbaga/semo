import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:logger/logger.dart";
import "package:index/services/firestore_collection_names.dart";

class FavoritesService {
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  static final FavoritesService _instance = FavoritesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  DocumentReference<Map<String, dynamic>> _getDocReference() {
    if (_auth.currentUser == null) {
      throw Exception("User isn't authenticated");
    }

    try {
      return _firestore
          .collection(FirestoreCollection.favorites)
          .doc(_auth.currentUser?.uid);
    } catch (e, s) {
      _logger.e("Error getting favorites document reference", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFavorites() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _getDocReference().get();

      if (!doc.exists) {
        await _getDocReference().set(<String, dynamic>{
          "movies": <int>[],
          "tv_shows": <int>[],
        });
      }

      return doc.data() ?? <String, dynamic>{};
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

  Future<dynamic> addMovie(int movieId, {Map<String, dynamic>? allFavorites}) async {
    final List<int> favorites = await getMovies(favorites: allFavorites);

    if (!favorites.contains(movieId)) {
      favorites.add(movieId);
      try {
        await _getDocReference().set(<String, dynamic>{"movies": favorites}, SetOptions(merge: true));
      } catch (e, s) {
        _logger.e("Error adding movie to favorites", error: e, stackTrace: s);
        rethrow;
      }
    }
  }

  Future<dynamic> addTvShow(int tvShowId, {Map<String, dynamic>? allFavorites}) async {
    final List<int> favorites = await getTvShows(favorites: allFavorites);

    if (!favorites.contains(tvShowId)) {
      favorites.add(tvShowId);
      try {
        await _getDocReference().set(<String, dynamic>{"tv_shows": favorites}, SetOptions(merge: true));
      } catch (e, s) {
        _logger.e("Error adding TV show to favorites", error: e, stackTrace: s);
        rethrow;
      }
    }
  }

  Future<dynamic> removeMovie(int movieId, {Map<String, dynamic>? allFavorites}) async {
    final List<int> favorites = await getMovies(favorites: allFavorites);

    if (favorites.contains(movieId)) {
      favorites.remove(movieId);
      try {
        await _getDocReference().set(<String, dynamic>{"movies": favorites}, SetOptions(merge: true));
      } catch (e, s) {
        _logger.e("Error removing movie from favorites", error: e, stackTrace: s);
        rethrow;
      }
    }
  }

  Future<dynamic> removeTvShow(int tvShowId, {Map<String, dynamic>? allFavorites}) async {
    final List<int> favorites = await getTvShows(favorites: allFavorites);

    if (favorites.contains(tvShowId)) {
      favorites.remove(tvShowId);
      try {
        await _getDocReference().set(<String, dynamic>{"tv_shows": favorites}, SetOptions(merge: true));
      } catch (e, s) {
        _logger.e("Error removing TV show from favorites", error: e, stackTrace: s);
        rethrow;
      }
    }
  }

  Future<dynamic> clear() async {
    try {
      await _getDocReference().delete();
    } catch (e, s) {
      _logger.e("Error clearing favorites", error: e, stackTrace: s);
      rethrow;
    }
  }
}