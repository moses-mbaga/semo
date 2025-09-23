import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/bloc/app_state.dart";
import "package:semo/bloc/handlers/cache_handler.dart";
import "package:semo/bloc/handlers/favorites_handler.dart";
import "package:semo/bloc/handlers/general_handler.dart";
import "package:semo/bloc/handlers/genres_handler.dart";
import "package:semo/bloc/handlers/movie_handler.dart";
import "package:semo/bloc/handlers/movies_handler.dart";
import "package:semo/bloc/handlers/person_handler.dart";
import "package:semo/bloc/handlers/recent_searches_handler.dart";
import "package:semo/bloc/handlers/recently_watched_handler.dart";
import "package:semo/bloc/handlers/stream_handler.dart";
import "package:semo/bloc/handlers/trailer_handler.dart";
import "package:semo/bloc/handlers/streaming_platforms_handler.dart";
import "package:semo/bloc/handlers/tv_show_handler.dart";
import "package:semo/bloc/handlers/tv_shows_handler.dart";
import "package:semo/services/auth_service.dart";

class AppBloc extends Bloc<AppEvent, AppState>
    with GeneralHandler, CacheHandler, MoviesHandler, TvShowsHandler, StreamingPlatformsHandler, GenresHandler, RecentlyWatchedHandler, FavoritesHandler, MovieHandler, TvShowHandler, PersonHandler, RecentSearchesHandler, StreamHandler, TrailerHandler {
  AppBloc() : super(const AppState()) {
    // General
    on<LoadInitialData>(onLoadInitialData);
    on<AddError>(onAddError);
    on<ClearError>(onClearError);

    // Cache
    on<InitCacheTimer>(onInitCacheTimer);
    on<InvalidateCache>(onInvalidateCache);

    // Movies
    on<LoadMovies>(onLoadMovies);
    on<RefreshMovies>(onRefreshMovies);
    on<AddIncompleteMovies>(onAddIncompleteMovies);

    // TV Shows
    on<LoadTvShows>(onLoadTvShows);
    on<RefreshTvShows>(onRefreshTvShows);
    on<AddIncompleteTvShows>(onAddIncompleteTvShows);

    // Streaming Platforms
    on<LoadStreamingPlatformsMedia>(onLoadStreamingPlatformsMedia);
    on<RefreshStreamingPlatformsMedia>(onRefreshStreamingPlatformsMedia);

    // Genres
    on<LoadGenres>(onLoadGenres);
    on<RefreshGenres>(onRefreshGenres);

    // Recently Watched
    on<LoadRecentlyWatched>(onLoadRecentlyWatched);
    on<UpdateMovieProgress>(onUpdateMovieProgress);
    on<UpdateEpisodeProgress>(onUpdateEpisodeProgress);
    on<DeleteMovieProgress>(onDeleteMovieProgress);
    on<DeleteEpisodeProgress>(onDeleteEpisodeProgress);
    on<DeleteTvShowProgress>(onDeleteTvShowProgress);
    on<HideTvShowProgress>(onHideTvShowProgress);
    on<ClearRecentlyWatched>(onClearRecentlyWatched);
    on<RefreshRecentlyWatched>(onRefreshRecentlyWatched);

    // Favorites
    on<LoadFavorites>(onLoadFavorites);
    on<AddFavorite>(onAddFavorite);
    on<RemoveFavorite>(onRemoveFavorite);
    on<ClearFavorites>(onClearFavorites);
    on<RefreshFavorites>(onRefreshFavorites);

    // Movie
    on<LoadMovieDetails>(onLoadMovieDetails);
    on<RefreshMovieDetails>(onRefreshMovieDetails);

    // TV Show
    on<LoadTvShowDetails>(onLoadTvShowDetails);
    on<LoadSeasonEpisodes>(onLoadSeasonEpisodes);
    on<RefreshTvShowDetails>(onRefreshTvShowDetails);

    // Person
    on<LoadPersonMedia>(onLoadPersonMedia);

    // Recent Searches
    on<LoadRecentSearches>(onLoadRecentSearches);
    on<AddRecentSearch>(onAddRecentSearch);
    on<RemoveRecentSearch>(onRemoveRecentSearch);
    on<ClearRecentSearches>(onClearRecentSearches);

    // Streams
    on<ExtractTrailerStreams>(onExtractTrailerStreams);
    on<ExtractMovieStream>(onExtractMovieStream);
    on<ExtractEpisodeStream>(onExtractEpisodeStream);
    on<RemoveMovieStream>(onRemoveMovieStream);
    on<RemoveEpisodeStream>(onRemoveEpisodeStream);
  }

  void init() {
    if (AuthService().isAuthenticated()) {
      add(LoadInitialData());
    }
  }

  @override
  Future<void> close() {
    state.cacheTimer?.cancel();
    return super.close();
  }
}
