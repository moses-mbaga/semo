import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/bloc/app_state.dart";

mixin CacheHandler on Bloc<AppEvent, AppState> {
  final Duration _cacheDuration = const Duration(hours: 12);

  void onInitCacheTimer(InitCacheTimer event, Emitter<AppState> emit) {
    if (state.cacheTimer != null) {
      state.cacheTimer!.cancel();
    }

    emit(state.copyWith(
      cacheTimer: Timer(_cacheDuration, () => add(InvalidateCache())),
    ));
  }

  void onInvalidateCache(InvalidateCache event, Emitter<AppState> emit) {
    emit(const AppState());
    add(LoadInitialData());
  }
}