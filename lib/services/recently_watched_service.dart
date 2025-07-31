import "dart:math" as math;

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:logger/logger.dart";
import "package:index/services/firestore_collection_names.dart";

class RecentlyWatchedService {
  factory RecentlyWatchedService() => _instance;
  RecentlyWatchedService._internal();

  static final RecentlyWatchedService _instance = RecentlyWatchedService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  DocumentReference<Map<String, dynamic>> _getDocReference() {
    if (_auth.currentUser == null) {
      throw Exception("User isn't authenticated");
    }

    try {
      return _firestore
          .collection(FirestoreCollection.recentlyWatched)
          .doc(_auth.currentUser?.uid);
    } catch (e, s) {
      _logger.e("Error getting recently watched document reference", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRecentlyWatched() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _getDocReference().get();

      if (!doc.exists) {
        await _getDocReference().set(<String, dynamic>{
          "movies": <String, Map<String, dynamic>>{},
          "tv_shows": <String, Map<String, dynamic>>{},
        });
      }

      return doc.data() ?? <String, dynamic>{};
    } catch (e, s) {
      _logger.e("Error getting recently watched", error: e, stackTrace: s);
      rethrow;
    }
  }

  //ignore: prefer_expression_function_bodies
  Map<String, Map<String, dynamic>> _mapDynamicDynamicToMapStringDynamic(Map<dynamic, dynamic> map) {
    //ignore: always_specify_types
    return map.map<String, Map<String, dynamic>>((key, value) => MapEntry<String, Map<String, dynamic>>(key, Map<String, dynamic>.from(value)));
  }

  int getMovieProgress(int movieId, Map<String, dynamic>? recentlyWatched) {
    if (recentlyWatched == null) {
      return 0;
    }

    try {
      final Map<String, Map<String, dynamic>> movies = _mapDynamicDynamicToMapStringDynamic((recentlyWatched["movies"] ?? <dynamic, dynamic>{}) as Map<dynamic, dynamic>);

      final Map<String, dynamic>? movie = movies["$movieId"];
      return movie?["progress"] ?? 0;
    } catch (e, s) {
      _logger.e("Error getting recently watched movie", error: e, stackTrace: s);
      return 0;
    }
  }

  Future<Map<String, Map<String, dynamic>>?> getEpisodes(int tvShowId, int seasonId, {Map<String, dynamic>? recentlyWatched}) async {
    recentlyWatched ??= await getRecentlyWatched();

    try {
      final Map<String, Map<String, dynamic>> tvShows = _mapDynamicDynamicToMapStringDynamic((recentlyWatched["tv_shows"] ?? <dynamic, dynamic>{}) as Map<dynamic, dynamic>);

      if (tvShows.containsKey("$tvShowId")) {
        tvShows["$tvShowId"]!.remove("visibleInMenu");
        final Map<String, Map<String, dynamic>> seasons = _mapDynamicDynamicToMapStringDynamic(tvShows["$tvShowId"]!);

        if (seasons.containsKey("$seasonId")) {
          final Map<String, dynamic> episodes = seasons["$seasonId"] ?? <String, dynamic>{};
          return _mapDynamicDynamicToMapStringDynamic(episodes as Map<dynamic, dynamic>);
        }
      }
    } catch (e, s) {
      _logger.e("Error getting recently watched episodes for the TV show", error: e, stackTrace: s);
      rethrow;
    }

    return null;
  }

  Map<String, Map<String, dynamic>> getEpisodesFromCache(int tvShowId, int seasonId, Map<String, dynamic>? recentlyWatched) {
    if (recentlyWatched == null) {
      return <String, Map<String, dynamic>>{};
    }

    try {
      final Map<String, Map<String, dynamic>> tvShows = _mapDynamicDynamicToMapStringDynamic((recentlyWatched["tv_shows"] ?? <dynamic, dynamic>{}) as Map<dynamic, dynamic>);

      if (tvShows.containsKey("$tvShowId")) {
        tvShows["$tvShowId"]!.remove("visibleInMenu");
        final Map<String, Map<String, dynamic>> seasons = _mapDynamicDynamicToMapStringDynamic(tvShows["$tvShowId"]!);

        if (seasons.containsKey("$seasonId")) {
          final Map<String, dynamic> episodes = seasons["$seasonId"] ?? <String, dynamic>{};
          return _mapDynamicDynamicToMapStringDynamic(episodes as Map<dynamic, dynamic>);
        }
      }
    } catch (e, s) {
      _logger.e("Error getting recently watched episodes for the TV show", error: e, stackTrace: s);
    }

    return <String, Map<String, dynamic>>{};
  }

  int getEpisodeProgress(int tvShowId, int seasonId, int episodeId, Map<String, dynamic>? recentlyWatched) {
    try {
      final Map<String, Map<String, dynamic>> episodes = getEpisodesFromCache(tvShowId, seasonId, recentlyWatched);
      final Map<String, dynamic>? episode = episodes["$episodeId"];
      return episode?["progress"] ?? 0;
    } catch (e, s) {
      _logger.e("Error getting recently watched episode progress", error: e, stackTrace: s);
      return 0;
    }
  }

  Future<Map<String, dynamic>> updateMovieProgress(int movieId, int progress, {Map<String, dynamic>? recentlyWatched}) async {
    recentlyWatched ??= await getRecentlyWatched();

    recentlyWatched["movies"]["$movieId"] = <String, dynamic>{
      "progress": progress,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };

    try {
      await _getDocReference().set(<String, dynamic>{"movies": recentlyWatched["movies"]}, SetOptions(merge: true));
    } catch (e, s) {
      _logger.e("Error updating movie's watch progress", error: e, stackTrace: s);
      rethrow;
    }

    return recentlyWatched;
  }

  Future<Map<String, dynamic>> updateEpisodeProgress(int tvShowId, int seasonId, int episodeId, int progress, {Map<String, dynamic>? recentlyWatched}) async {
    recentlyWatched ??= await getRecentlyWatched();
    Map<String, Map<String, dynamic>> watchedEpisodes = await getEpisodes(tvShowId, seasonId) ?? <String, Map<String, dynamic>>{};
    final Map<String, dynamic> updatedEpisodeData = <String, dynamic>{
      "progress": progress,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };

    try {
      final Map<String, Map<String, dynamic>> tvShows = _mapDynamicDynamicToMapStringDynamic((recentlyWatched["tv_shows"] ?? <dynamic, dynamic>{}) as Map<dynamic, dynamic>);

      if (!tvShows.containsKey("$tvShowId")) {
        tvShows["$tvShowId"] = <String, dynamic>{};
      }

      if (!tvShows["$tvShowId"]!.containsKey("$seasonId")) {
        tvShows["$tvShowId"]!["$seasonId"] = <String, dynamic>{};
      }

      watchedEpisodes["$episodeId"] = updatedEpisodeData;
      tvShows["$tvShowId"]!["$seasonId"] = watchedEpisodes;
      tvShows["$tvShowId"] = <String, dynamic>{
        "visibleInMenu": true,
        ...tvShows["$tvShowId"]!
      };

      await _getDocReference().set(<String, dynamic>{"tv_shows": tvShows}, SetOptions(merge: true));
    } catch (e, s) {
      _logger.e("Error updating episode's watch progress", error: e, stackTrace: s);
      rethrow;
    }

    return recentlyWatched;
  }

  Future<Map<String, dynamic>> removeEpisodeProgress(int tvShowId, int seasonId, int episodeId, {Map<String, dynamic>? recentlyWatched}) async {
    recentlyWatched ??= await getRecentlyWatched();
    Map<String, Map<String, dynamic>> watchedEpisodes = await getEpisodes(tvShowId, seasonId) ?? <String, Map<String, dynamic>>{};

    try {
      final Map<String, Map<String, dynamic>> tvShows = _mapDynamicDynamicToMapStringDynamic((recentlyWatched["tv_shows"] ?? <dynamic, dynamic>{}) as Map<dynamic, dynamic>);

      if (!tvShows.containsKey("$tvShowId")) {
        tvShows["$tvShowId"] = <String, dynamic>{};
      }

      if (!tvShows["$tvShowId"]!.containsKey("$seasonId")) {
        tvShows["$tvShowId"]!["$seasonId"] = <String, dynamic>{};
      }

      watchedEpisodes.remove("$episodeId");

      tvShows["$tvShowId"]!["$seasonId"] = watchedEpisodes;
      tvShows["$tvShowId"] = <String, dynamic>{
        "visibleInMenu": true,
        ...tvShows["$tvShowId"]!
      };

      await _getDocReference().set(<String, dynamic>{"tv_shows": tvShows}, SetOptions(merge: true));
    } catch (e, s) {
      _logger.e("Error removing episode's watch progress", error: e, stackTrace: s);
      rethrow;
    }

    return recentlyWatched;
  }

  Future<List<int>> getMovieIds({Map<String, dynamic>? recentlyWatched}) async {
    recentlyWatched ??= await getRecentlyWatched();

    try {
      final Map<String, Map<String, dynamic>> movies = _mapDynamicDynamicToMapStringDynamic((recentlyWatched["movies"] ?? <dynamic, dynamic>{}) as Map<dynamic, dynamic>);

      // Sort by timestamp (most recent first)
      final List<MapEntry<String, Map<String, dynamic>>> sortedEntries = movies.entries.toList()..sort((MapEntry<String, Map<String, dynamic>> a, MapEntry<String, Map<String, dynamic>> b) {
        final int timestampA = a.value["timestamp"] ?? 0;
        final int timestampB = b.value["timestamp"] ?? 0;
        return timestampB.compareTo(timestampA);
      });

      return sortedEntries.map((MapEntry<String, Map<String, dynamic>> entry) => int.parse(entry.key)).toList();
    } catch (e, s) {
      _logger.e("Error getting recently watched movie IDs", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> removeMovie(int movieId, {Map<String, dynamic>? recentlyWatched}) async {
    recentlyWatched ??= await getRecentlyWatched();

    try {
      final Map<String, Map<String, dynamic>> movies = _mapDynamicDynamicToMapStringDynamic((recentlyWatched["movies"] ?? <dynamic, dynamic>{}) as Map<dynamic, dynamic>);
      movies.remove("$movieId");
      await _getDocReference().set(<String, dynamic>{"movies": movies}, SetOptions(merge: true));
    } catch (e, s) {
      _logger.e("Error removing movie from recently watched", error: e, stackTrace: s);
      rethrow;
    }

    return recentlyWatched;
  }

  Future<List<int>> getTvShowIds({Map<String, dynamic>? recentlyWatched}) async {
    recentlyWatched ??= await getRecentlyWatched();

    try {
      final Map<String, Map<String, dynamic>> tvShows = _mapDynamicDynamicToMapStringDynamic((recentlyWatched["tv_shows"] ?? <dynamic, dynamic>{}) as Map<dynamic, dynamic>);

      // Filter only visible shows and sort by timestamp
      final List<MapEntry<String, Map<String, dynamic>>> visibleShows = tvShows.entries
          .where((MapEntry<String, Map<String, dynamic>> entry) => entry.value["visibleInMenu"] == true)
          .toList();

      visibleShows.sort((MapEntry<String, Map<String, dynamic>> a, MapEntry<String, Map<String, dynamic>> b) {
        // Get the latest timestamp from any episode in the show
        final Map<String, dynamic> aSeasons = Map<String, dynamic>.from(a.value)..remove("visibleInMenu");
        final Map<String, dynamic> bSeasons = Map<String, dynamic>.from(b.value)..remove("visibleInMenu");

        int aLatest = 0;
        int bLatest = 0;

        for (final dynamic season in aSeasons.values) {
          if (season is Map) {
            for (final dynamic episode in season.values) {
              if (episode is Map && episode["timestamp"] != null) {
                aLatest = math.max(aLatest, episode["timestamp"] as int);
              }
            }
          }
        }

        for (final dynamic season in bSeasons.values) {
          if (season is Map) {
            for (final dynamic episode in season.values) {
              if (episode is Map && episode["timestamp"] != null) {
                bLatest = math.max(bLatest, episode["timestamp"] as int);
              }
            }
          }
        }

        return bLatest.compareTo(aLatest);
      });

      return visibleShows.map((MapEntry<String, Map<String, dynamic>> entry) => int.parse(entry.key)).toList();
    } catch (e, s) {
      _logger.e("Error getting recently watched TV show IDs", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> hideTvShow(int tvShowId, {Map<String, dynamic>? recentlyWatched}) async {
    recentlyWatched ??= await getRecentlyWatched();

    try {
      final Map<String, Map<String, dynamic>> tvShows = _mapDynamicDynamicToMapStringDynamic((recentlyWatched["tv_shows"] ?? <dynamic, dynamic>{}) as Map<dynamic, dynamic>);

      if (tvShows.containsKey("$tvShowId")) {
        tvShows["$tvShowId"]!["visibleInMenu"] = false;
        await _getDocReference().set(<String, dynamic>{"tv_shows": tvShows}, SetOptions(merge: true));
      }
    } catch (e, s) {
      _logger.e("Error removing TV show from recently watched", error: e, stackTrace: s);
      rethrow;
    }

    return recentlyWatched;
  }

  Future<Map<String, dynamic>> removeTvShow(int tvShowId, {Map<String, dynamic>? recentlyWatched}) async {
    recentlyWatched ??= await getRecentlyWatched();

    try {
      final Map<String, Map<String, dynamic>> tvShows = _mapDynamicDynamicToMapStringDynamic((recentlyWatched["tv_shows"] ?? <dynamic, dynamic>{}) as Map<dynamic, dynamic>);

      if (tvShows.containsKey("$tvShowId")) {
        tvShows.remove("$tvShowId");
        await _getDocReference().set(<String, dynamic>{"tv_shows": tvShows}, SetOptions(merge: true));
      }
    } catch (e, s) {
      _logger.e("Error removing TV show from recently watched", error: e, stackTrace: s);
      rethrow;
    }

    return recentlyWatched;
  }

  Future<dynamic> clear() async {
    try {
      await _getDocReference().delete();
    } catch (e, s) {
      _logger.e("Error clearing recently watched", error: e, stackTrace: s);
      rethrow;
    }
  }
}