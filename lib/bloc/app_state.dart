import "dart:async";

import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:semo/models/episode.dart";
import "package:semo/models/genre.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/models/stream_subtitles.dart";
import "package:semo/models/movie.dart";
import "package:semo/models/person.dart";
import "package:semo/models/season.dart";
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
    this.movieTrailers,
    this.movieImdbIds,
    this.movieCast,
    this.movieRecommendationsPagingControllers,
    this.similarMoviesPagingControllers,
    this.tvShowSeasons,
    this.tvShowEpisodes,
    this.tvShowCast,
    this.tvShowTrailers,
    this.tvShowImdbIds,
    this.tvShowRecommendationsPagingControllers,
    this.similarTvShowsPagingControllers,
    this.personMovies,
    this.personTvShows,
    this.moviesRecentSearches,
    this.tvShowsRecentSearches,
    this.movieStreams,
    this.episodeStreams,
    this.movieSubtitles,
    this.episodeSubtitles,
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
    this.isExtractingMovieStream,
    this.isExtractingEpisodeStream,
    this.error,
    this.cacheTimer,
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
  final Map<String, String>? movieImdbIds;
  final Map<String, PagingController<int, Movie>>? movieRecommendationsPagingControllers;
  final Map<String, PagingController<int, Movie>>? similarMoviesPagingControllers;

  final Map<String, List<Season>>? tvShowSeasons;
  final Map<String, Map<int, List<Episode>>>? tvShowEpisodes;
  final Map<String, List<Person>>? tvShowCast;
  final Map<String, String>? tvShowTrailers;
  final Map<String, String>? tvShowImdbIds;
  final Map<String, PagingController<int, TvShow>>? tvShowRecommendationsPagingControllers;
  final Map<String, PagingController<int, TvShow>>? similarTvShowsPagingControllers;

  final Map<String, List<Movie>>? personMovies;
  final Map<String, List<TvShow>>? personTvShows;

  final List<String>? moviesRecentSearches;
  final List<String>? tvShowsRecentSearches;

  final Map<String, List<MediaStream>>? movieStreams;
  final Map<String, List<MediaStream>>? episodeStreams;

  final Map<String, List<StreamSubtitles>>? movieSubtitles;
  final Map<String, List<StreamSubtitles>>? episodeSubtitles;

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
  final Map<String, bool>? isExtractingMovieStream;
  final Map<String, bool>? isExtractingEpisodeStream;

  final String? error;

  final Timer? cacheTimer;

  static const Object _notProvided = Object();

  AppState copyWith({
    Object? nowPlayingMovies = _notProvided,
    Object? onTheAirTvShows = _notProvided,
    Object? trendingMoviesPagingController = _notProvided,
    Object? trendingTvShowsPagingController = _notProvided,
    Object? popularMoviesPagingController = _notProvided,
    Object? popularTvShowsPagingController = _notProvided,
    Object? topRatedMoviesPagingController = _notProvided,
    Object? topRatedTvShowsPagingController = _notProvided,
    Object? streamingPlatformMoviesPagingControllers = _notProvided,
    Object? streamingPlatformTvShowsPagingControllers = _notProvided,
    Object? incompleteMovies = _notProvided,
    Object? incompleteTvShows = _notProvided,
    Object? movies = _notProvided,
    Object? tvShows = _notProvided,
    Object? recentlyWatched = _notProvided,
    Object? recentlyWatchedMovies = _notProvided,
    Object? recentlyWatchedTvShows = _notProvided,
    Object? favorites = _notProvided,
    Object? favoriteMovies = _notProvided,
    Object? favoriteTvShows = _notProvided,
    Object? movieGenres = _notProvided,
    Object? tvShowGenres = _notProvided,
    Object? genreMoviesPagingControllers = _notProvided,
    Object? genreTvShowsPagingControllers = _notProvided,
    Object? movieTrailers = _notProvided,
    Object? movieImdbIds = _notProvided,
    Object? movieCast = _notProvided,
    Object? movieRecommendationsPagingControllers = _notProvided,
    Object? similarMoviesPagingControllers = _notProvided,
    Object? tvShowSeasons = _notProvided,
    Object? tvShowEpisodes = _notProvided,
    Object? tvShowCast = _notProvided,
    Object? tvShowTrailers = _notProvided,
    Object? tvShowImdbIds = _notProvided,
    Object? tvShowRecommendationsPagingControllers = _notProvided,
    Object? similarTvShowsPagingControllers = _notProvided,
    Object? personMovies = _notProvided,
    Object? personTvShows = _notProvided,
    Object? moviesRecentSearches = _notProvided,
    Object? tvShowsRecentSearches = _notProvided,
    Object? movieStreams = _notProvided,
    Object? episodeStreams = _notProvided,
    Object? movieSubtitles = _notProvided,
    Object? episodeSubtitles = _notProvided,
    Object? isLoadingMovies = _notProvided,
    Object? isLoadingTvShows = _notProvided,
    Object? isLoadingStreamingPlatformsMedia = _notProvided,
    Object? isLoadingMovieGenres = _notProvided,
    Object? isLoadingTvShowGenres = _notProvided,
    Object? isLoadingRecentlyWatched = _notProvided,
    Object? isLoadingFavorites = _notProvided,
    Object? isMovieLoading = _notProvided,
    Object? isTvShowLoading = _notProvided,
    Object? isSeasonEpisodesLoading = _notProvided,
    Object? isLoadingPersonMedia = _notProvided,
    Object? isExtractingMovieStream = _notProvided,
    Object? isExtractingEpisodeStream = _notProvided,
    Object? error = _notProvided,
    Object? cacheTimer = _notProvided,
  }) =>
      AppState(
        nowPlayingMovies: nowPlayingMovies == _notProvided ? this.nowPlayingMovies : nowPlayingMovies as List<Movie>?,
        onTheAirTvShows: onTheAirTvShows == _notProvided ? this.onTheAirTvShows : onTheAirTvShows as List<TvShow>?,
        trendingMoviesPagingController: trendingMoviesPagingController == _notProvided ? this.trendingMoviesPagingController : trendingMoviesPagingController as PagingController<int, Movie>?,
        trendingTvShowsPagingController: trendingTvShowsPagingController == _notProvided ? this.trendingTvShowsPagingController : trendingTvShowsPagingController as PagingController<int, TvShow>?,
        popularMoviesPagingController: popularMoviesPagingController == _notProvided ? this.popularMoviesPagingController : popularMoviesPagingController as PagingController<int, Movie>?,
        popularTvShowsPagingController: popularTvShowsPagingController == _notProvided ? this.popularTvShowsPagingController : popularTvShowsPagingController as PagingController<int, TvShow>?,
        topRatedMoviesPagingController: topRatedMoviesPagingController == _notProvided ? this.topRatedMoviesPagingController : topRatedMoviesPagingController as PagingController<int, Movie>?,
        topRatedTvShowsPagingController: topRatedTvShowsPagingController == _notProvided ? this.topRatedTvShowsPagingController : topRatedTvShowsPagingController as PagingController<int, TvShow>?,
        streamingPlatformMoviesPagingControllers: streamingPlatformMoviesPagingControllers == _notProvided ? this.streamingPlatformMoviesPagingControllers : streamingPlatformMoviesPagingControllers as Map<String, PagingController<int, Movie>>?,
        streamingPlatformTvShowsPagingControllers: streamingPlatformTvShowsPagingControllers == _notProvided ? this.streamingPlatformTvShowsPagingControllers : streamingPlatformTvShowsPagingControllers as Map<String, PagingController<int, TvShow>>?,
        incompleteMovies: incompleteMovies == _notProvided ? this.incompleteMovies : incompleteMovies as List<Movie>?,
        incompleteTvShows: incompleteTvShows == _notProvided ? this.incompleteTvShows : incompleteTvShows as List<TvShow>?,
        movies: movies == _notProvided ? this.movies : movies as List<Movie>?,
        tvShows: tvShows == _notProvided ? this.tvShows : tvShows as List<TvShow>?,
        recentlyWatched: recentlyWatched == _notProvided ? this.recentlyWatched : recentlyWatched as Map<String, dynamic>?,
        recentlyWatchedMovies: recentlyWatchedMovies == _notProvided ? this.recentlyWatchedMovies : recentlyWatchedMovies as List<Movie>?,
        recentlyWatchedTvShows: recentlyWatchedTvShows == _notProvided ? this.recentlyWatchedTvShows : recentlyWatchedTvShows as List<TvShow>?,
        favorites: favorites == _notProvided ? this.favorites : favorites as Map<String, dynamic>?,
        favoriteMovies: favoriteMovies == _notProvided ? this.favoriteMovies : favoriteMovies as List<Movie>?,
        favoriteTvShows: favoriteTvShows == _notProvided ? this.favoriteTvShows : favoriteTvShows as List<TvShow>?,
        movieGenres: movieGenres == _notProvided ? this.movieGenres : movieGenres as List<Genre>?,
        tvShowGenres: tvShowGenres == _notProvided ? this.tvShowGenres : tvShowGenres as List<Genre>?,
        genreMoviesPagingControllers: genreMoviesPagingControllers == _notProvided ? this.genreMoviesPagingControllers : genreMoviesPagingControllers as Map<String, PagingController<int, Movie>>?,
        genreTvShowsPagingControllers: genreTvShowsPagingControllers == _notProvided ? this.genreTvShowsPagingControllers : genreTvShowsPagingControllers as Map<String, PagingController<int, TvShow>>?,
        movieCast: movieCast == _notProvided ? this.movieCast : movieCast as Map<String, List<Person>>?,
        movieTrailers: movieTrailers == _notProvided ? this.movieTrailers : movieTrailers as Map<String, String>?,
        movieImdbIds: movieImdbIds == _notProvided ? this.movieImdbIds : movieImdbIds as Map<String, String>?,
        movieRecommendationsPagingControllers: movieRecommendationsPagingControllers == _notProvided ? this.movieRecommendationsPagingControllers : movieRecommendationsPagingControllers as Map<String, PagingController<int, Movie>>?,
        similarMoviesPagingControllers: similarMoviesPagingControllers == _notProvided ? this.similarMoviesPagingControllers : similarMoviesPagingControllers as Map<String, PagingController<int, Movie>>?,
        tvShowSeasons: tvShowSeasons == _notProvided ? this.tvShowSeasons : tvShowSeasons as Map<String, List<Season>>?,
        tvShowEpisodes: tvShowEpisodes == _notProvided ? this.tvShowEpisodes : tvShowEpisodes as Map<String, Map<int, List<Episode>>>?,
        tvShowCast: tvShowCast == _notProvided ? this.tvShowCast : tvShowCast as Map<String, List<Person>>?,
        tvShowTrailers: tvShowTrailers == _notProvided ? this.tvShowTrailers : tvShowTrailers as Map<String, String>?,
        tvShowImdbIds: tvShowImdbIds == _notProvided ? this.tvShowImdbIds : tvShowImdbIds as Map<String, String>?,
        tvShowRecommendationsPagingControllers: tvShowRecommendationsPagingControllers == _notProvided ? this.tvShowRecommendationsPagingControllers : tvShowRecommendationsPagingControllers as Map<String, PagingController<int, TvShow>>?,
        similarTvShowsPagingControllers: similarTvShowsPagingControllers == _notProvided ? this.similarTvShowsPagingControllers : similarTvShowsPagingControllers as Map<String, PagingController<int, TvShow>>?,
        personMovies: personMovies == _notProvided ? this.personMovies : personMovies as Map<String, List<Movie>>?,
        personTvShows: personTvShows == _notProvided ? this.personTvShows : personTvShows as Map<String, List<TvShow>>?,
        moviesRecentSearches: moviesRecentSearches == _notProvided ? this.moviesRecentSearches : moviesRecentSearches as List<String>?,
        tvShowsRecentSearches: tvShowsRecentSearches == _notProvided ? this.tvShowsRecentSearches : tvShowsRecentSearches as List<String>?,
        movieStreams: movieStreams == _notProvided ? this.movieStreams : movieStreams as Map<String, List<MediaStream>>?,
        episodeStreams: episodeStreams == _notProvided ? this.episodeStreams : episodeStreams as Map<String, List<MediaStream>>?,
        movieSubtitles: movieSubtitles == _notProvided ? this.movieSubtitles : movieSubtitles as Map<String, List<StreamSubtitles>>?,
        episodeSubtitles: episodeSubtitles == _notProvided ? this.episodeSubtitles : episodeSubtitles as Map<String, List<StreamSubtitles>>?,
        isLoadingMovies: isLoadingMovies == _notProvided ? this.isLoadingMovies : isLoadingMovies as bool,
        isLoadingTvShows: isLoadingTvShows == _notProvided ? this.isLoadingTvShows : isLoadingTvShows as bool,
        isLoadingStreamingPlatformsMedia: isLoadingStreamingPlatformsMedia == _notProvided ? this.isLoadingStreamingPlatformsMedia : isLoadingStreamingPlatformsMedia as bool,
        isLoadingMovieGenres: isLoadingMovieGenres == _notProvided ? this.isLoadingMovieGenres : isLoadingMovieGenres as bool,
        isLoadingTvShowGenres: isLoadingTvShowGenres == _notProvided ? this.isLoadingTvShowGenres : isLoadingTvShowGenres as bool,
        isLoadingRecentlyWatched: isLoadingRecentlyWatched == _notProvided ? this.isLoadingRecentlyWatched : isLoadingRecentlyWatched as bool,
        isLoadingFavorites: isLoadingFavorites == _notProvided ? this.isLoadingFavorites : isLoadingFavorites as bool,
        isMovieLoading: isMovieLoading == _notProvided ? this.isMovieLoading : isMovieLoading as Map<String, bool>?,
        isTvShowLoading: isTvShowLoading == _notProvided ? this.isTvShowLoading : isTvShowLoading as Map<String, bool>?,
        isSeasonEpisodesLoading: isSeasonEpisodesLoading == _notProvided ? this.isSeasonEpisodesLoading : isSeasonEpisodesLoading as Map<String, Map<int, bool>>?,
        isLoadingPersonMedia: isLoadingPersonMedia == _notProvided ? this.isLoadingPersonMedia : isLoadingPersonMedia as Map<String, bool>?,
        isExtractingMovieStream: isExtractingMovieStream == _notProvided ? this.isExtractingMovieStream : isExtractingMovieStream as Map<String, bool>?,
        isExtractingEpisodeStream: isExtractingEpisodeStream == _notProvided ? this.isExtractingEpisodeStream : isExtractingEpisodeStream as Map<String, bool>?,
        error: error == _notProvided ? this.error : error as String?,
        cacheTimer: cacheTimer == _notProvided ? this.cacheTimer : cacheTimer as Timer?,
      );
}
