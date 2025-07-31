import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:index/models/episode.dart";
import "package:index/models/genre.dart";
import "package:index/models/movie.dart";
import "package:index/models/person.dart";
import "package:index/models/season.dart";
import "package:index/models/tv_show.dart";

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
    this.movieTrailers,
    this.movieCast,
    this.movieRecommendationsPagingControllers,
    this.similarMoviesPagingControllers,
    this.tvShowSeasons,
    this.tvShowEpisodes,
    this.tvShowCast,
    this.tvShowTrailers,
    this.tvShowRecommendationsPagingControllers,
    this.similarTvShowsPagingControllers,
    this.personMovies,
    this.personTvShows,
    this.moviesRecentSearches,
    this.tvShowsRecentSearches,
    this.isLoadingMovies = false,
    this.isLoadingTvShows = false,
    this.isLoadingStreamingPlatformsMedia = false,
    this.isLoadingMovieGenres = false,
    this.isLoadingTvShowGenres = false,
    this.isLoadingRecentlyWatched = false,
    this.isLoadingFavorites = false,
    this.isMovieLoading,
    this.isTvShowLoading,
    this.isSeasonEpisodesLoading,
    this.isLoadingPersonMedia,
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

  final Map<String, List<Person>>? movieCast;
  final Map<String, String>? movieTrailers;
  final Map<String, PagingController<int, Movie>>? movieRecommendationsPagingControllers;
  final Map<String, PagingController<int, Movie>>? similarMoviesPagingControllers;

  final Map<String, List<Season>>? tvShowSeasons;
  final Map<String, Map<int, List<Episode>>>? tvShowEpisodes;
  final Map<String, List<Person>>? tvShowCast;
  final Map<String, String>? tvShowTrailers;
  final Map<String, PagingController<int, TvShow>>? tvShowRecommendationsPagingControllers;
  final Map<String, PagingController<int, TvShow>>? similarTvShowsPagingControllers;

  final Map<String, List<Movie>>? personMovies;
  final Map<String, List<TvShow>>? personTvShows;

  final List<String>? moviesRecentSearches;
  final List<String>? tvShowsRecentSearches;

  final bool isLoadingMovies;
  final bool isLoadingTvShows;
  final bool isLoadingStreamingPlatformsMedia;
  final bool isLoadingMovieGenres;
  final bool isLoadingTvShowGenres;
  final bool isLoadingRecentlyWatched;
  final bool isLoadingFavorites;
  final Map<String, bool>? isMovieLoading;
  final Map<String, bool>? isTvShowLoading;
  final Map<String, Map<int, bool>>? isSeasonEpisodesLoading;
  final Map<String, bool>? isLoadingPersonMedia;

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
    Map<String, String>? movieTrailers,
    Map<String, List<Person>>? movieCast,
    Map<String, PagingController<int, Movie>>? movieRecommendationsPagingControllers,
    Map<String, PagingController<int, Movie>>? similarMoviesPagingControllers,
    Map<String, List<Season>>? tvShowSeasons,
    Map<String, Map<int, List<Episode>>>? tvShowEpisodes,
    Map<String, List<Person>>? tvShowCast,
    Map<String, String>? tvShowTrailers,
    Map<String, PagingController<int, TvShow>>? tvShowRecommendationsPagingControllers,
    Map<String, PagingController<int, TvShow>>? similarTvShowsPagingControllers,
    Map<String, List<Movie>>? personMovies,
    Map<String, List<TvShow>>? personTvShows,
    List<String>? moviesRecentSearches,
    List<String>? tvShowsRecentSearches,
    bool? isLoadingMovies,
    bool? isLoadingTvShows,
    bool? isLoadingStreamingPlatformsMedia,
    bool? isLoadingMovieGenres,
    bool? isLoadingTvShowGenres,
    bool? isLoadingRecentlyWatched,
    bool? isLoadingFavorites,
    Map<String, bool>? isMovieLoading,
    Map<String, bool>? isTvShowLoading,
    Map<String, Map<int, bool>>? isSeasonEpisodesLoading,
    Map<String, bool>? isLoadingPersonMedia,
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
    movieTrailers: movieTrailers ?? this.movieTrailers,
    movieCast: movieCast ?? this.movieCast,
    movieRecommendationsPagingControllers: movieRecommendationsPagingControllers ?? this.movieRecommendationsPagingControllers,
    similarMoviesPagingControllers: similarMoviesPagingControllers ?? this.similarMoviesPagingControllers,
    tvShowSeasons: tvShowSeasons ?? this.tvShowSeasons,
    tvShowEpisodes: tvShowEpisodes ?? this.tvShowEpisodes,
    tvShowCast: tvShowCast ?? this.tvShowCast,
    tvShowTrailers: tvShowTrailers ?? this.tvShowTrailers,
    tvShowRecommendationsPagingControllers: tvShowRecommendationsPagingControllers ?? this.tvShowRecommendationsPagingControllers,
    similarTvShowsPagingControllers: similarTvShowsPagingControllers ?? this.similarTvShowsPagingControllers,
    personMovies: personMovies ?? this.personMovies,
    personTvShows: personTvShows ?? this.personTvShows,
    moviesRecentSearches: moviesRecentSearches ?? this.moviesRecentSearches,
    tvShowsRecentSearches: tvShowsRecentSearches ?? this.tvShowsRecentSearches,
    isLoadingMovies: isLoadingMovies ?? this.isLoadingMovies,
    isLoadingTvShows: isLoadingTvShows ?? this.isLoadingTvShows,
    isLoadingStreamingPlatformsMedia: isLoadingStreamingPlatformsMedia ?? this.isLoadingStreamingPlatformsMedia,
    isLoadingMovieGenres: isLoadingMovieGenres ?? this.isLoadingMovieGenres,
    isLoadingTvShowGenres: isLoadingTvShowGenres ?? this.isLoadingTvShowGenres,
    isLoadingRecentlyWatched: isLoadingRecentlyWatched ?? this.isLoadingRecentlyWatched,
    isLoadingFavorites: isLoadingFavorites ?? this.isLoadingFavorites,
    isMovieLoading: isMovieLoading ?? this.isMovieLoading,
    isTvShowLoading: isTvShowLoading ?? this.isTvShowLoading,
    isSeasonEpisodesLoading: isSeasonEpisodesLoading ?? this.isSeasonEpisodesLoading,
    isLoadingPersonMedia: isLoadingPersonMedia ?? this.isLoadingPersonMedia,
    error: error ?? this.error,
  );
}