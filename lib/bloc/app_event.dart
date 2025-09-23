import "package:semo/enums/media_type.dart";
import "package:semo/models/episode.dart";
import "package:semo/models/movie.dart";
import "package:semo/models/tv_show.dart";

abstract class AppEvent {
  const AppEvent();
}

// General

class LoadInitialData extends AppEvent {}

class AddError extends AppEvent {
  const AddError(this.error);

  final String error;
}

class ClearError extends AppEvent {}

// Cache

class InitCacheTimer extends AppEvent {}

class InvalidateCache extends AppEvent {}

// Movies

class LoadMovies extends AppEvent {}

class RefreshMovies extends AppEvent {}

class AddIncompleteMovies extends AppEvent {
  const AddIncompleteMovies(this.movies);

  final List<Movie> movies;
}

// TV Shows

class LoadTvShows extends AppEvent {}

class RefreshTvShows extends AppEvent {}

class AddIncompleteTvShows extends AppEvent {
  const AddIncompleteTvShows(this.tvShows);

  final List<TvShow> tvShows;
}

// Streaming Platforms

class LoadStreamingPlatformsMedia extends AppEvent {}

class RefreshStreamingPlatformsMedia extends AppEvent {
  const RefreshStreamingPlatformsMedia(this.mediaType);

  final MediaType mediaType;
}

// Genres

class LoadGenres extends AppEvent {
  const LoadGenres(this.mediaType);

  final MediaType mediaType;
}

class RefreshGenres extends AppEvent {
  const RefreshGenres(this.mediaType);

  final MediaType mediaType;
}

// Recently Watched

class LoadRecentlyWatched extends AppEvent {}

class RefreshRecentlyWatched extends AppEvent {}

class UpdateMovieProgress extends AppEvent {
  const UpdateMovieProgress(this.movieId, this.progress);

  final int movieId;
  final int progress;
}

class UpdateEpisodeProgress extends AppEvent {
  const UpdateEpisodeProgress(this.tvShowId, this.seasonId, this.episodeId, this.progress);

  final int tvShowId;
  final int seasonId;
  final int episodeId;
  final int progress;
}

class DeleteMovieProgress extends AppEvent {
  const DeleteMovieProgress(this.movieId);

  final int movieId;
}

class DeleteEpisodeProgress extends AppEvent {
  const DeleteEpisodeProgress(this.tvShowId, this.seasonId, this.episodeId);

  final int tvShowId;
  final int seasonId;
  final int episodeId;
}

class DeleteTvShowProgress extends AppEvent {
  const DeleteTvShowProgress(this.tvShowId);

  final int tvShowId;
}

class HideTvShowProgress extends AppEvent {
  const HideTvShowProgress(this.tvShowId);

  final int tvShowId;
}

class ClearRecentlyWatched extends AppEvent {}

// Favorites

class LoadFavorites extends AppEvent {}

class AddFavorite extends AppEvent {
  const AddFavorite(this.media, this.mediaType);

  final dynamic media;
  final MediaType mediaType;
}

class RemoveFavorite extends AppEvent {
  const RemoveFavorite(this.media, this.mediaType);

  final dynamic media;
  final MediaType mediaType;
}

class ClearFavorites extends AppEvent {}

class RefreshFavorites extends AppEvent {}

// Movie

class LoadMovieDetails extends AppEvent {
  const LoadMovieDetails(this.movieId);

  final int movieId;
}

class RefreshMovieDetails extends AppEvent {
  const RefreshMovieDetails(this.movieId);

  final int movieId;
}

// TV Show

class LoadTvShowDetails extends AppEvent {
  const LoadTvShowDetails(this.tvShowId);

  final int tvShowId;
}

class LoadSeasonEpisodes extends AppEvent {
  const LoadSeasonEpisodes(this.tvShowId, this.seasonNumber);

  final int tvShowId;
  final int seasonNumber;
}

class RefreshTvShowDetails extends AppEvent {
  const RefreshTvShowDetails(this.tvShowId);

  final int tvShowId;
}

// Person

class LoadPersonMedia extends AppEvent {
  const LoadPersonMedia(this.personId);

  final int personId;
}

// Recent Searches

class LoadRecentSearches extends AppEvent {}

class AddRecentSearch extends AppEvent {
  const AddRecentSearch(this.query, this.mediaType);

  final String query;
  final MediaType mediaType;
}

class RemoveRecentSearch extends AppEvent {
  const RemoveRecentSearch(this.query, this.mediaType);

  final String query;
  final MediaType mediaType;
}

class ClearRecentSearches extends AppEvent {}

// Streams

class ExtractTrailerStreams extends AppEvent {
  const ExtractTrailerStreams({
    required this.tmdbId,
    required this.mediaType,
    required this.trailerUrl,
  });

  final int tmdbId;
  final MediaType mediaType;
  final String trailerUrl;
}

class ExtractMovieStream extends AppEvent {
  const ExtractMovieStream(this.movie);

  final Movie movie;
}

class ExtractEpisodeStream extends AppEvent {
  const ExtractEpisodeStream(this.tvShow, this.episode);

  final TvShow tvShow;
  final Episode episode;
}

class RemoveMovieStream extends AppEvent {
  const RemoveMovieStream(this.movieId);

  final int movieId;
}

class RemoveEpisodeStream extends AppEvent {
  const RemoveEpisodeStream(this.episodeId);

  final int episodeId;
}

// Subtitles

class LoadMovieSubtitles extends AppEvent {
  const LoadMovieSubtitles(this.movieId, {this.locale = "EN"});

  final int movieId;
  final String? locale;
}

class LoadEpisodeSubtitles extends AppEvent {
  const LoadEpisodeSubtitles(
    this.tvShowId, {
    required this.seasonNumber,
    required this.episodeId,
    required this.episodeNumber,
    this.locale = "EN",
  });

  final int tvShowId;
  final int seasonNumber;
  final int episodeId;
  final int episodeNumber;
  final String locale;
}
