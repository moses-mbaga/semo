import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:semo/models/genre.dart";
import "package:semo/models/movie.dart";
import "package:semo/models/tv_show.dart";

class AppState {
  const AppState({
    this.nowPlayingMovies,
    this.onTheAirTvShows,
    this.trendingMoviesPagingController,
    this.trendingTvShowsPagingController,
    this.popularMoviesPagingController,
    this.popularTvShowsPagingController,
    this.topRatedMoviesPagingController,
    this.topRatedTvShowsPagingController,
    this.streamingPlatformMoviesPagingControllers,
    this.streamingPlatformTvShowsPagingControllers,
    this.incompleteMovies,
    this.incompleteTvShows,
    this.movies,
    this.tvShows,
    this.recentlyWatched,
    this.recentlyWatchedMovies,
    this.recentlyWatchedTvShows,
    this.favorites,
    this.favoriteMovies,
    this.favoriteTvShows,
    this.movieGenres,
    this.tvShowGenres,
    this.genreMoviesPagingControllers,
    this.genreTvShowsPagingControllers,
    this.isLoadingMovies = false,
    this.isLoadingTvShows = false,
    this.isLoadingStreamingPlatformsMedia = false,
    this.isLoadingMovieGenres = false,
    this.isLoadingTvShowGenres = false,
    this.isLoadingRecentlyWatched = false,
    this.isLoadingFavorites = false,
    this.currentlyPlayingProgress = 0,
    this.error,
  });

  final List<Movie>? nowPlayingMovies;
  final List<TvShow>? onTheAirTvShows;

  final PagingController<int, Movie>? trendingMoviesPagingController;
  final PagingController<int, TvShow>? trendingTvShowsPagingController;
  final PagingController<int, Movie>? popularMoviesPagingController;
  final PagingController<int, TvShow>? popularTvShowsPagingController;
  final PagingController<int, Movie>? topRatedMoviesPagingController;
  final PagingController<int, TvShow>? topRatedTvShowsPagingController;

  // Map of streaming platform IDs to their respective PagingControllers
  final Map<String, PagingController<int, Movie>>? streamingPlatformMoviesPagingControllers;
  final Map<String, PagingController<int, TvShow>>? streamingPlatformTvShowsPagingControllers;

  final List<Movie>? incompleteMovies; // Movies that have missing data (typically from search results)
  final List<TvShow>? incompleteTvShows; // TV Shows that have missing data (typically from search results)
  final List<Movie>? movies; // Movies with complete data
  final List<TvShow>? tvShows; // TV Shows with complete data

  final Map<String, dynamic>? recentlyWatched;
  final List<Movie>? recentlyWatchedMovies;
  final List<TvShow>? recentlyWatchedTvShows;

  final Map<String, dynamic>? favorites;
  final List<Movie>? favoriteMovies;
  final List<TvShow>? favoriteTvShows;

  final List<Genre>? movieGenres;
  final List<Genre>? tvShowGenres;
  final Map<String, PagingController<int, Movie>>? genreMoviesPagingControllers;
  final Map<String, PagingController<int, TvShow>>? genreTvShowsPagingControllers;

  final bool isLoadingMovies;
  final bool isLoadingTvShows;
  final bool isLoadingStreamingPlatformsMedia;
  final bool isLoadingMovieGenres;
  final bool isLoadingTvShowGenres;
  final bool isLoadingRecentlyWatched;
  final bool isLoadingFavorites;

  final int currentlyPlayingProgress; // Progress of the currently playing movie or episode

  final String? error;

  AppState copyWith({
    List<Movie>? nowPlayingMovies,
    List<TvShow>? onTheAirTvShows,
    PagingController<int, Movie>? trendingMoviesPagingController,
    PagingController<int, TvShow>? trendingTvShowsPagingController,
    PagingController<int, Movie>? popularMoviesPagingController,
    PagingController<int, TvShow>? popularTvShowsPagingController,
    PagingController<int, Movie>? topRatedMoviesPagingController,
    PagingController<int, TvShow>? topRatedTvShowsPagingController,
    Map<String, PagingController<int, Movie>>? streamingPlatformMoviesPagingControllers,
    Map<String, PagingController<int, TvShow>>? streamingPlatformTvShowsPagingControllers,
    List<Movie>? incompleteMovies,
    List<TvShow>? incompleteTvShows,
    List<Movie>? movies,
    List<TvShow>? tvShows,
    Map<String, dynamic>? recentlyWatched,
    List<Movie>? recentlyWatchedMovies,
    List<TvShow>? recentlyWatchedTvShows,
    Map<String, dynamic>? favorites,
    List<Movie>? favoriteMovies,
    List<TvShow>? favoriteTvShows,
    List<Genre>? movieGenres,
    List<Genre>? tvShowGenres,
    Map<String, PagingController<int, Movie>>? genreMoviesPagingControllers,
    Map<String, PagingController<int, TvShow>>? genreTvShowsPagingControllers,
    bool? isLoadingMovies,
    bool? isLoadingTvShows,
    bool? isLoadingStreamingPlatformsMedia,
    bool? isLoadingMovieGenres,
    bool? isLoadingTvShowGenres,
    bool? isLoadingRecentlyWatched,
    bool? isLoadingFavorites,
    int? currentlyPlayingProgress,
    String? error,
  }) => AppState(
    nowPlayingMovies: nowPlayingMovies ?? this.nowPlayingMovies,
    onTheAirTvShows: onTheAirTvShows ?? this.onTheAirTvShows,
    trendingMoviesPagingController: trendingMoviesPagingController ?? this.trendingMoviesPagingController,
    trendingTvShowsPagingController: trendingTvShowsPagingController ?? this.trendingTvShowsPagingController,
    popularMoviesPagingController: popularMoviesPagingController ?? this.popularMoviesPagingController,
    popularTvShowsPagingController: popularTvShowsPagingController ?? this.popularTvShowsPagingController,
    topRatedMoviesPagingController: topRatedMoviesPagingController ?? this.topRatedMoviesPagingController,
    topRatedTvShowsPagingController: topRatedTvShowsPagingController ?? this.topRatedTvShowsPagingController,
    streamingPlatformMoviesPagingControllers: streamingPlatformMoviesPagingControllers ?? this.streamingPlatformMoviesPagingControllers,
    streamingPlatformTvShowsPagingControllers: streamingPlatformTvShowsPagingControllers ?? this.streamingPlatformTvShowsPagingControllers,
    incompleteMovies: incompleteMovies ?? this.incompleteMovies,
    incompleteTvShows: incompleteTvShows ?? this.incompleteTvShows,
    movies: movies ?? this.movies,
    tvShows: tvShows ?? this.tvShows,
    recentlyWatched: recentlyWatched ?? this.recentlyWatched,
    recentlyWatchedMovies: recentlyWatchedMovies ?? this.recentlyWatchedMovies,
    recentlyWatchedTvShows: recentlyWatchedTvShows ?? this.recentlyWatchedTvShows,
    favorites: favorites ?? this.favorites,
    favoriteMovies: favoriteMovies ?? this.favoriteMovies,
    favoriteTvShows: favoriteTvShows ?? this.favoriteTvShows,
    movieGenres: movieGenres ?? this.movieGenres,
    tvShowGenres: tvShowGenres ?? this.tvShowGenres,
    genreMoviesPagingControllers: genreMoviesPagingControllers ?? this.genreMoviesPagingControllers,
    genreTvShowsPagingControllers: genreTvShowsPagingControllers ?? this.genreTvShowsPagingControllers,
    isLoadingMovies: isLoadingMovies ?? this.isLoadingMovies,
    isLoadingTvShows: isLoadingTvShows ?? this.isLoadingTvShows,
    isLoadingStreamingPlatformsMedia: isLoadingStreamingPlatformsMedia ?? this.isLoadingStreamingPlatformsMedia,
    isLoadingMovieGenres: isLoadingMovieGenres ?? this.isLoadingMovieGenres,
    isLoadingTvShowGenres: isLoadingTvShowGenres ?? this.isLoadingTvShowGenres,
    isLoadingRecentlyWatched: isLoadingRecentlyWatched ?? this.isLoadingRecentlyWatched,
    isLoadingFavorites: isLoadingFavorites ?? this.isLoadingFavorites,
    currentlyPlayingProgress: currentlyPlayingProgress ?? this.currentlyPlayingProgress,
    error: error ?? this.error,
  );
}