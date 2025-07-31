import "dart:io";
import "dart:math";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:logger/logger.dart";
import "package:pretty_dio_logger/pretty_dio_logger.dart";
import "package:index/models/episode.dart";
import "package:index/models/genre.dart";
import "package:index/models/movie.dart";
import "package:index/models/season.dart";
import "package:index/models/tv_show.dart";
import "package:index/models/person.dart";
import "package:index/models/search_results.dart";
import "package:index/utils/secrets.dart";
import "package:index/enums/media_type.dart";
import "package:index/utils/urls.dart";

class TMDBService {
  factory TMDBService() {
    if (!_instance._isDioLoggerInitialized) {
      TMDBService._dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          enabled: kDebugMode,
        ),
      );

      _instance._isDioLoggerInitialized = true;
    }

    return _instance;
  }

  TMDBService._internal();

  static final TMDBService _instance = TMDBService._internal();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: <String, String>{
        HttpHeaders.authorizationHeader: "Bearer ${Secrets.tmdbAccessToken}",
      },
    ),
  );
  bool _isDioLoggerInitialized = false;
  final Logger _logger = Logger();

  // Movie Methods
  Future<SearchResults> getNowPlayingMovies() => _search(MediaType.movies, Urls.nowPlayingMovies, 1);
  Future<SearchResults> getTrendingMovies(int page) => _search(MediaType.movies, Urls.trendingMovies, page);
  Future<SearchResults> getPopularMovies(int page) => _search(MediaType.movies, Urls.popularMovies, page);
  Future<SearchResults> getTopRatedMovies(int page) async => _search(MediaType.movies, Urls.topRatedMovies, page);
  Future<SearchResults> discoverMovies(int page, {Map<String, String>? parameters}) => _search(MediaType.movies, Urls.discoverMovie, page, parameters: parameters);
  Future<SearchResults> searchMovies(String query, int page) => _search(
    MediaType.movies,
    Urls.searchMovies,
    page,
    parameters: <String, String>{
      "query": query,
      "include_adult": "false",
    },
  );
  Future<List<Genre>> getMovieGenres() => _getGenres(MediaType.movies);

  Future<Movie?> getMovie(int id) async {
    try {
      final Response<dynamic> response = await _dio.get(Urls.getMovieDetails(id));

      if (response.statusCode == 200 && response.data.isNotEmpty) {
        return Movie.fromJson(response.data);
      }

      throw Exception("Failed to get movie details for ID: $id");
    } catch (e, s) {
      _logger.e("Error getting movie details for ID: $id", error: e, stackTrace: s);
      rethrow;
    }
  }

  // TV Show Methods
  Future<SearchResults> getOnTheAirTvShows() => _search(MediaType.tvShows, Urls.onTheAirTvShows, 1);
  Future<SearchResults> getTrendingTvShows(int page) => _search(MediaType.tvShows, Urls.trendingTvShows, page);
  Future<SearchResults> getPopularTvShows(int page) => _search(MediaType.tvShows, Urls.popularTvShows, page);
  Future<SearchResults> getTopRatedTvShows(int page) => _search(MediaType.tvShows, Urls.topRatedTvShows, page);
  Future<SearchResults> discoverTvShows(int page, {Map<String, String>? parameters}) => _search(MediaType.tvShows, Urls.discoverTvShow, page, parameters: parameters);
  Future<SearchResults> searchTvShows(String query, int page) => _search(
    MediaType.tvShows,
    Urls.searchTvShows,
    page,
    parameters: <String, String>{
      "query": query,
      "include_adult": "false",
    },
  );
  Future<List<Genre>> getTvShowGenres() => _getGenres(MediaType.tvShows);

  Future<TvShow?> getTvShow(int id) async {
    try {
      final Response<dynamic> response = await _dio.get(Urls.getTvShowDetails(id));

      if (response.statusCode == 200 && response.data.isNotEmpty) {
        return TvShow.fromJson(response.data);
      }

      throw Exception("Error getting TV show details for ID: $id");
    } catch (e, s) {
      _logger.e("Error getting TV show details for ID: $id", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<List<Season>> getTvShowSeasons(int id) async {
    try {
      final Response<dynamic> response = await _dio.get(Urls.getTvShowDetails(id));

      if (response.statusCode == 200 && response.data.isNotEmpty) {
        final List<Map<String, dynamic>> seasonsMap = (response.data["seasons"] as List<dynamic>).cast<Map<String, dynamic>>();
        final List<Season> seasons = <Season>[];

        for (final Map<String, dynamic> seasonMap in seasonsMap) {
          final Season season = Season.fromJson(seasonMap);
          if (season.number > 0 && season.airDate != null) {
            seasons.add(season);
          }
        }

        return seasons;
      }

      throw Exception("Error getting TV show seasons for ID: $id");
    } catch (e, s) {
      _logger.e("Error getting TV show seasons for ID: $id", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<List<Episode>> getEpisodes(int showId, int seasonNumber) async {
    try {
      final Response<dynamic> response = await _dio.get(Urls.getEpisodes(showId, seasonNumber));

      if (response.statusCode == 200 && response.data.isNotEmpty) {
        final List<Map<String, dynamic>> episodesMap = (response.data["episodes"] as List<dynamic>).cast<Map<String, dynamic>>();
        final List<Episode> episodes = <Episode>[];

        for (Map<String, dynamic> episodeMap in episodesMap) {
          final Episode episode = Episode.fromJson(episodeMap);
          if (episode.airDate != null) {
            episodes.add(episode);
          }
        }

        return episodes;
      }

      throw Exception("Error getting episodes for season $seasonNumber in TV show with ID $showId");
    } catch (e, s) {
      _logger.e("Error getting episodes for season $seasonNumber in TV show with ID $showId", error: e, stackTrace: s);
      rethrow;
    }
  }

  // Common methods for both movies and TV shows
  Future<SearchResults> _search(MediaType mediaType, String url, int page, {Map<String, String>? parameters}) async {
    try {
      final Response<dynamic> response = await _dio.get(url, queryParameters: <String, String>{
        "page": "$page",
        ...?parameters,
      });

      if (response.statusCode == 200 && response.data.isNotEmpty) {
        return SearchResults.fromJson(
          response.data,
          mediaType,
        );
      }

      throw Exception("Failed to get ${mediaType.toString()} search results");
    } catch (e, s) {
      _logger.e("Error getting ${mediaType.toString()} search results", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<SearchResults> searchFromUrl(MediaType mediaType, String url, int page, Map<String, String>? parameters) => _search(mediaType, url, page, parameters: parameters);

  Future<List<Genre>> _getGenres(MediaType mediaType) async {
    String url = mediaType == MediaType.movies ? Urls.movieGenres : Urls.tvShowGenres;

    try {
      final Response<dynamic> response = await _dio.get(url);

      if (response.statusCode == 200 && response.data.isNotEmpty) {
        final List<Map<String, dynamic>> data = (response.data["genres"] as List<dynamic>).cast<Map<String, dynamic>>();
        return data.map((Map<String, dynamic> json) => Genre.fromJson(json)).toList();
      }

      throw Exception("Failed to get genres");
    } catch (e, s) {
      _logger.e("Error getting genres", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<String> getGenreBackdrop(MediaType mediaType, Genre genre) async {
    if (genre.backdropPath != null && genre.backdropPath!.isNotEmpty) {
      return genre.backdropPath!;
    }

    bool isMovie = mediaType == MediaType.movies;

    try {
      final SearchResults result = isMovie
          ? await discoverMovies(1, parameters: <String, String>{"with_genres": "${genre.id}"})
          : await discoverTvShows(1, parameters: <String, String>{"with_genres": "${genre.id}"});

      if ((isMovie ? result.movies : result.tvShows) != null && (isMovie ? result.movies!.isNotEmpty : result.tvShows!.isNotEmpty)) {
        final Random random = Random();
        final List<dynamic> items = isMovie ? result.movies! : result.tvShows!;
        final int randomIndex = random.nextInt(items.length);
        final String backdropPath = isMovie
            ? (items[randomIndex] as Movie).backdropPath
            : (items[randomIndex] as TvShow).backdropPath;

        return backdropPath;
      }

      throw Exception("Error getting genre backdrop for name: ${genre.name}");
    } catch (e, s) {
      _logger.e("Error getting genre backdrop for name: ${genre.name}", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<SearchResults> getRecommendations(MediaType mediaType, int id, int page) {
    final String url = mediaType == MediaType.movies
        ? Urls.getMovieRecommendations(id)
        : Urls.getTvShowRecommendations(id);
    return _search(mediaType, url, page);
  }

  Future<SearchResults> getSimilar(MediaType mediaType, int id, int page) {
    final String url = mediaType == MediaType.movies
        ? Urls.getMovieSimilar(id)
        : Urls.getTvShowSimilar(id);
    return _search(mediaType, url, page);
  }
  
  Future<String?> getTrailerUrl(MediaType mediaType, int mediaId) async {
    try {
      final String url = mediaType == MediaType.movies
          ? Urls.getMovieVideosUrl(mediaId)
          : Urls.getTvShowVideosUrl(mediaId);

      final Response<dynamic> response = await _dio.get(url);

      if (response.statusCode == 200 && response.data.isNotEmpty) {
        final List<Map<String, dynamic>> videos = (response.data["results"] as List<dynamic>).cast<Map<String, dynamic>>();
        final List<Map<String, dynamic>> youtubeVideos = videos
            .where((Map<String, dynamic> video) => video["site"] == "YouTube" && video["type"] == "Trailer" && video["official"] == true)
            .toList();

        if (youtubeVideos.isNotEmpty) {
          youtubeVideos.sort((Map<String, dynamic> a, Map<String, dynamic> b) => b["size"].compareTo(a["size"]));
          final String youtubeId = youtubeVideos[0]["key"] ?? "";
          return "https://www.youtube.com/watch?v=$youtubeId";
        }
      }

      throw Exception("Error getting ${mediaType.toString()} trailer for ID: $mediaId");
    } catch (e, s) {
      _logger.e("Error getting ${mediaType.toString()} trailer for ID: $mediaId", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<List<Person>> getCast(MediaType mediaType, int mediaId) async {
    try {
      final String url = mediaType == MediaType.movies
          ? Urls.getMovieCast(mediaId)
          : Urls.getTvShowCast(mediaId);

      final Response<dynamic> response = await _dio.get(url);

      if (response.statusCode == 200 && response.data.isNotEmpty) {
        final List<Map<String, dynamic>> data = (response.data["cast"] as List<dynamic>).cast<Map<String, dynamic>>();
        final List<Person> allCast = data.map((Map<String, dynamic> json) => Person.fromJson(json)).toList();
        return allCast.where((Person person) => person.department == "Acting").toList();
      }

      throw Exception("Error getting ${mediaType.toString()} cast for ID: $mediaId");
    } catch (e, s) {
      _logger.e("Error getting ${mediaType.toString()} cast for ID: $mediaId", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _getPersonMedia(int personId, MediaType mediaType) async {
    try {
      final String url = mediaType == MediaType.movies
          ? Urls.getPersonMovies(personId)
          : Urls.getPersonTvShows(personId);

      final Response<dynamic> response = await _dio.get(url);

      if (response.statusCode == 200 && response.data.isNotEmpty) {
        return (response.data["cast"] as List<dynamic>).cast<Map<String, dynamic>>();
      }

      throw Exception("Error getting ${mediaType.toString()} for person $personId");
    } catch (e, s) {
      _logger.e("Error getting ${mediaType.toString()} for person $personId", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<List<Movie>> getPersonMovies(int personId) async {
    try {
      final List<Map<String, dynamic>> moviesData = await _getPersonMedia(personId, MediaType.movies);
      return moviesData.map((Map<String, dynamic> json) => Movie.fromJson(json)).toList();
    } catch (e, s) {
      _logger.e("Error getting movies for cast for person $personId", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<List<TvShow>> getPersonTvShows(int personId) async {
    try {
      final List<Map<String, dynamic>> tvShowsData = await _getPersonMedia(personId, MediaType.tvShows);
      return tvShowsData.map((Map<String, dynamic> json) => TvShow.fromJson(json)).toList();
    } catch (e, s) {
      _logger.e("Error getting TV shows for cast for person $personId", error: e, stackTrace: s);
      rethrow;
    }
  }
}