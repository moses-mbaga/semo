import "package:logger/logger.dart";
import "package:index/bloc/app_state.dart";
import "package:index/models/movie.dart";
import "package:index/models/tv_show.dart";
import "package:index/services/tmdb_service.dart";

class HandlerHelpers {
  HandlerHelpers();

  final Logger _logger = Logger();
  final TMDBService _tmdbService = TMDBService();

  Future<Movie> fetchMovieById(AppState state, int id) async {
    if (state.movies != null && state.movies!.any((Movie movie) => movie.id == id)) {
      return state.movies!.firstWhere((Movie movie) => movie.id == id);
    } else if (state.incompleteMovies != null && state.incompleteMovies!.any((Movie movie) => movie.id == id)) {
      return state.incompleteMovies!.firstWhere((Movie movie) => movie.id == id);
    } else {
      try {
        final Movie? movie = await _tmdbService.getMovie(id);
        if (movie != null) {
          return movie;
        } else {
          throw Exception("Movie with ID $id not found");
        }
      } catch (e, s) {
        _logger.e("Error fetching movie with ID $id", error: e, stackTrace: s);
        rethrow;
      }
    }
  }

  Future<List<Movie>> fetchMoviesByIds(AppState state, List<int> ids) async {
    List<Movie> movies = <Movie>[];

    for (final int id in ids) {
      try {
        Movie movie = await fetchMovieById(state, id);
        movies.add(movie);
      } catch (_) {}
    }

    return movies;
  }

  Future<TvShow> fetchTvShowById(AppState state, int id) async {
    if (state.tvShows != null && state.tvShows!.any((TvShow tvShow) => tvShow.id == id)) {
      return state.tvShows!.firstWhere((TvShow tvShow) => tvShow.id == id);
    } else if (state.incompleteTvShows != null && state.incompleteTvShows!.any((TvShow tvShow) => tvShow.id == id)) {
      return state.incompleteTvShows!.firstWhere((TvShow tvShow) => tvShow.id == id);
    } else {
      try {
        final TvShow? tvShow = await _tmdbService.getTvShow(id);
        if (tvShow != null) {
          return tvShow;
        } else {
          throw Exception("TV Show with ID $id not found");
        }
      } catch (e, s) {
        _logger.e("Error fetching TV Show with ID $id", error: e, stackTrace: s);
        rethrow;
      }
    }
  }

  Future<List<TvShow>> fetchTvShowsByIds(AppState state, List<int> ids) async {
    List<TvShow> tvShows = <TvShow>[];

    for (final int id in ids) {
      try {
        TvShow tvShow = await fetchTvShowById(state, id);
        tvShows.add(tvShow);
      } catch (_) {}
    }

    return tvShows;
  }
}