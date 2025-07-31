import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:logger/logger.dart";
import "package:index/bloc/app_event.dart";
import "package:index/bloc/app_state.dart";
import "package:index/enums/media_type.dart";
import "package:index/models/movie.dart";
import "package:index/models/search_results.dart";
import "package:index/models/streaming_platform.dart";
import "package:index/models/tv_show.dart";
import "package:index/services/tmdb_service.dart";
import "package:index/utils/streaming_platforms.dart";

mixin StreamingPlatformsHandler on Bloc<AppEvent, AppState> {
  final Logger _logger = Logger();
  final TMDBService _tmdbService = TMDBService();

  Future<void> onLoadStreamingPlatformsMedia(LoadStreamingPlatformsMedia event, Emitter<AppState> emit) async {
    if (state.isLoadingStreamingPlatformsMedia) {
      return;
    }

    emit(state.copyWith(
      isLoadingStreamingPlatformsMedia: true,
      error: null,
    ));

    try {
      final Map<String, PagingController<int, Movie>> movieControllers = <String, PagingController<int, Movie>>{};
      final Map<String, PagingController<int, TvShow>> tvShowControllers = <String, PagingController<int, TvShow>>{};

      for (final StreamingPlatform streamingPlatform in streamingPlatforms) {
        final String platformId = streamingPlatform.id.toString();

        movieControllers[platformId] = PagingController<int, Movie>(
          getNextPageKey: (PagingState<int, Movie> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
          fetchPage: (int pageKey) async {
            final SearchResults results = await _tmdbService.discoverMovies(
              pageKey,
              parameters: <String, String>{
                "with_watch_providers": platformId,
                "watch_region": "US",
              },
            );
            final List<Movie> movies = results.movies ?? <Movie>[];
            add(AddIncompleteMovies(movies));
            return movies;
          },
        );

        tvShowControllers[platformId] = PagingController<int, TvShow>(
          getNextPageKey: (PagingState<int, TvShow> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
          fetchPage: (int pageKey) async {
            final SearchResults results = await _tmdbService.discoverTvShows(
              pageKey,
              parameters: <String, String>{
                "with_watch_providers": platformId,
                "watch_region": "US",
              },
            );
            final List<TvShow> tvShows = results.tvShows ?? <TvShow>[];
            add(AddIncompleteTvShows(tvShows));
            return tvShows;
          },
        );
      }

      emit(state.copyWith(
        streamingPlatformMoviesPagingControllers: movieControllers,
        streamingPlatformTvShowsPagingControllers: tvShowControllers,
        isLoadingStreamingPlatformsMedia: false,
      ));
    } catch (e, s) {
      _logger.e("Error loading streaming platforms media", error: e, stackTrace: s);
      emit(state.copyWith(
        isLoadingStreamingPlatformsMedia: false,
        error: "Failed to load streaming platforms media",
      ));
    }
  }

  void onRefreshStreamingPlatformsMedia(RefreshStreamingPlatformsMedia event, Emitter<AppState> emit) {
    if (state.isLoadingStreamingPlatformsMedia) {
      return;
    }

    emit(state.copyWith(
      isLoadingStreamingPlatformsMedia: true,
      error: null,
    ));

    try {
      if (event.mediaType == MediaType.movies) {
        state.streamingPlatformMoviesPagingControllers?.forEach((String platformId, PagingController<int, Movie> controller) {
          controller.refresh();
        });
      } else if (event.mediaType == MediaType.tvShows) {
        state.streamingPlatformTvShowsPagingControllers?.forEach((String platformId, PagingController<int, TvShow> controller) {
          controller.refresh();
        });
      }

      emit(state.copyWith(
        isLoadingStreamingPlatformsMedia: false,
      ));
    } catch (e, s) {
      _logger.e("Error refreshing streaming platforms media", error: e, stackTrace: s);
      emit(state.copyWith(
        isLoadingStreamingPlatformsMedia: false,
        error: "Failed to refresh streaming platforms media",
      ));
    }
  }
}