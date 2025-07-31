import "package:flutter_bloc/flutter_bloc.dart";
import "package:index/bloc/app_event.dart";
import "package:index/bloc/app_state.dart";
import "package:index/bloc/handlers/favorites_handler.dart";
import "package:index/bloc/handlers/genres_handler.dart";
import "package:index/bloc/handlers/movie_handler.dart";
import "package:index/bloc/handlers/movies_handler.dart";
import "package:index/bloc/handlers/person_handler.dart";
import "package:index/bloc/handlers/recent_searches_handler.dart";
import "package:index/bloc/handlers/recently_watched_handler.dart";
import "package:index/bloc/handlers/streaming_platforms_handler.dart";
import "package:index/bloc/handlers/tv_show_handler.dart";
import "package:index/bloc/handlers/tv_shows_handler.dart";
import "package:index/enums/media_type.dart";
import "package:index/services/auth_service.dart";

class AppBloc extends Bloc<AppEvent, AppState>
    with MoviesHandler, TvShowsHandler, StreamingPlatformsHandler, GenresHandler, RecentlyWatchedHandler, FavoritesHandler, MovieHandler, TvShowHandler, PersonHandler, RecentSearchesHandler {
  AppBloc() : super(const AppState()) {
    // General
    on<LoadInitialData>(_onLoadInitialData);
    on<ClearError>(_onClearError);

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

    // Favorites
    on<LoadFavorites>(onLoadFavorites);
    on<AddFavorite>(onAddFavorite);
    on<RemoveFavorite>(onRemoveFavorite);
    on<ClearFavorites>(onClearFavorites);

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
  }

  void init() {
    if (AuthService().isAuthenticated()) {
      add(LoadInitialData());
    }
  }

  void _onLoadInitialData(LoadInitialData event, Emitter<AppState> emit) {
    add(LoadMovies());
    add(LoadTvShows());
    add(LoadStreamingPlatformsMedia());
    add(const LoadGenres(MediaType.movies));
    add(const LoadGenres(MediaType.tvShows));
    add(LoadRecentlyWatched());
    add(LoadFavorites());
    add(LoadRecentSearches());
  }

  void _onClearError(ClearError event, Emitter<AppState> emit) {
    emit(state.copyWith(
      error: null,
    ));
  }
}