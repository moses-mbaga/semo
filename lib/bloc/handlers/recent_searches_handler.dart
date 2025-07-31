import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:logger/logger.dart";
import "package:index/bloc/app_event.dart";
import "package:index/bloc/app_state.dart";
import "package:index/enums/media_type.dart";
import "package:index/services/recent_searches_service.dart";

mixin RecentSearchesHandler on Bloc<AppEvent, AppState> {
  final Logger _logger = Logger();
  final RecentSearchesService _recentSearchesService = RecentSearchesService();

  Future<void> onLoadRecentSearches(LoadRecentSearches event, Emitter<AppState> emit) async {
    if (state.moviesRecentSearches != null && state.tvShowsRecentSearches != null) {
      return;
    }

    try {
      List<String> moviesRecentSearches = await _recentSearchesService.getRecentSearches(MediaType.movies);
      List<String> tvShowsRecentSearches = await _recentSearchesService.getRecentSearches(MediaType.tvShows);

      emit(state.copyWith(
        moviesRecentSearches: moviesRecentSearches,
        tvShowsRecentSearches: tvShowsRecentSearches,
      ));
    } catch (e, s) {
      _logger.e("Error loading recent searches", error: e, stackTrace: s);
    }
  }

  void onAddRecentSearch(AddRecentSearch event, Emitter<AppState> emit) {
    try {
      unawaited(_recentSearchesService.add(event.mediaType, event.query));
    } catch (e, s) {
      _logger.e("Error adding recent searches", error: e, stackTrace: s);
    }

    if (event.mediaType == MediaType.movies) {
      final List<String> updatedSearches = state.moviesRecentSearches ?? <String>[];
      updatedSearches.add(event.query);

      emit(state.copyWith(
        moviesRecentSearches: updatedSearches,
      ));
    } else if (event.mediaType == MediaType.tvShows) {
      final List<String> updatedSearches = state.tvShowsRecentSearches ?? <String>[];
      updatedSearches.add(event.query);

      emit(state.copyWith(
        tvShowsRecentSearches: updatedSearches,
      ));
    }
  }

  void onRemoveRecentSearch(RemoveRecentSearch event, Emitter<AppState> emit) {
    try {
      unawaited(_recentSearchesService.remove(event.mediaType, event.query));
    } catch (e, s) {
      _logger.e("Error removing recent search", error: e, stackTrace: s);
    }

    if (event.mediaType == MediaType.movies) {
      final List<String> updatedSearches = state.moviesRecentSearches?.where((String search) => search != event.query).toList() ?? <String>[];
      emit(state.copyWith(
        moviesRecentSearches: updatedSearches,
      ));
    } else if (event.mediaType == MediaType.tvShows) {
      final List<String> updatedSearches = state.tvShowsRecentSearches?.where((String search) => search != event.query).toList() ?? <String>[];
      emit(state.copyWith(
        tvShowsRecentSearches: updatedSearches,
      ));
    }
  }

  void onClearRecentSearches(ClearRecentSearches event, Emitter<AppState> emit) {
    try {
      unawaited(_recentSearchesService.clear());
    } catch (e, s) {
      _logger.e("Error clearing recent searches", error: e, stackTrace: s);
    }

    emit(state.copyWith(
      moviesRecentSearches: null,
      tvShowsRecentSearches: null,
    ));
  }
}