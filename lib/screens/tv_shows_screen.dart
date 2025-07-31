import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:index/bloc/app_bloc.dart";
import "package:index/bloc/app_event.dart";
import "package:index/bloc/app_state.dart";
import "package:index/components/carousel_slider.dart";
import "package:index/components/genres_horizontal_list.dart";
import "package:index/components/horizontal_media_list.dart";
import "package:index/components/media_card.dart";
import "package:index/components/media_card_horizontal_list.dart";
import "package:index/components/snack_bar.dart";
import "package:index/components/streaming_platform_card_horizontal_list.dart";
import "package:index/models/genre.dart";
import "package:index/models/tv_show.dart";
import "package:index/screens/base_screen.dart";
import "package:index/screens/tv_show_screen.dart";
import "package:index/enums/media_type.dart";
import "package:index/utils/urls.dart";

class TvShowsScreen extends BaseScreen {
  const TvShowsScreen({super.key});

  @override
  BaseScreenState<TvShowsScreen> createState() => _TvShowsScreenState();
}

class _TvShowsScreenState extends BaseScreenState<TvShowsScreen> {
  int _currentOnTheAirIndex = 0;

  void _hideFromMenu(TvShow tvShow) {
    Timer(const Duration(milliseconds: 500), () {
      context.read<AppBloc>().add(HideTvShowProgress(tvShow.id));
    });
  }

  void _removeFromRecentlyWatched(TvShow tvShow) {
    Timer(const Duration(milliseconds: 500), () {
      context.read<AppBloc>().add(DeleteTvShowProgress(tvShow.id));
    });
  }

  Future<void> _refreshData() async {
    Timer(const Duration(milliseconds: 500), () {
      try {
        context.read<AppBloc>().add(RefreshTvShows());
        context.read<AppBloc>().add(const RefreshGenres(MediaType.tvShows));
      } catch (_) {}
    });
  }

  Widget _buildOnTheAir(List<TvShow>? onTheAir) {
    if (onTheAir == null || onTheAir.isEmpty) {
      return const SizedBox.shrink();
    }

    return CarouselSlider(
      items: onTheAir,
      currentItemIndex: _currentOnTheAirIndex,
      onItemChanged: (int index) => setState(() => _currentOnTheAirIndex = index),
      onItemTap: (int index) => navigate(TvShowScreen(onTheAir[index])),
      mediaType: MediaType.tvShows,
    );
  }

  Widget _buildRecentlyWatchedSection(List<TvShow>? recentlyWatched) {
    if (recentlyWatched == null || recentlyWatched.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: HorizontalMediaList<TvShow>(
        title: "Recently watched",
        items: recentlyWatched,
        itemBuilder: (BuildContext context, TvShow tvShow, int index) => Padding(
          padding: EdgeInsets.only(
            right: index < (recentlyWatched.length) - 1 ? 18 : 0,
          ),
          child: MediaCard(
            media: tvShow,
            mediaType: MediaType.tvShows,
            onTap: () => navigate(TvShowScreen(tvShow)),
            showHideOption: true,
            onHide: () => _hideFromMenu(tvShow),
            showRemoveOption: true,
            onRemove: () => _removeFromRecentlyWatched(tvShow),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaCardHorizontalList({
    required PagingController<int, TvShow>? controller,
    required String title,
    required String viewAllSource,
  }) {
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: MediaCardHorizontalList(
        title: title,
        pagingController: controller,
        mediaType: MediaType.tvShows,
        //ignore: avoid_annotating_with_dynamic
        onTap: (dynamic media) => navigate(TvShowScreen(media as TvShow)),
      ),
    );
  }

  Widget _buildStreamingPlatforms(Map<String, PagingController<int, TvShow>>? pagingControllers) {
    if (pagingControllers == null || pagingControllers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: StreamingPlatformCardHorizontalList(
        mediaType: MediaType.tvShows,
        pagingControllers: pagingControllers,
      ),
    );
  }

  Widget _buildGenres(List<Genre>? genres, Map<String, PagingController<int, TvShow>>? tvShowsPagingControllers) {
    if (tvShowsPagingControllers == null || tvShowsPagingControllers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: GenresList(
        genres: genres ?? <Genre>[],
        mediaPagingControllers: tvShowsPagingControllers,
        mediaType: MediaType.tvShows,
      ),
    );
  }

  @override
  String get screenName => "TV Shows";

  @override
  Widget buildContent(BuildContext context) => BlocConsumer<AppBloc, AppState>(
    listener: (BuildContext context, AppState state) {
      if (state.error != null) {
        showSnackBar(context, state.error!);
        context.read<AppBloc>().add(ClearError());
      }
    },
    builder: (BuildContext context, AppState state) => Scaffold(
      body: RefreshIndicator(
        color: Theme.of(context).primaryColor,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        onRefresh: _refreshData,
        child: !state.isLoadingTvShows ? SingleChildScrollView(
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(18),
              child: Column(
                children: <Widget>[
                  _buildOnTheAir(state.onTheAirTvShows),
                  _buildRecentlyWatchedSection(state.recentlyWatchedTvShows),
                  _buildMediaCardHorizontalList(
                    title: "Trending",
                    controller: state.trendingTvShowsPagingController,
                    viewAllSource: Urls.trendingTvShows,
                  ),
                  _buildMediaCardHorizontalList(
                    title: "Popular",
                    controller: state.popularTvShowsPagingController,
                    viewAllSource: Urls.popularTvShows,
                  ),
                  _buildMediaCardHorizontalList(
                    title: "Top rated",
                    controller: state.topRatedTvShowsPagingController,
                    viewAllSource: Urls.topRatedTvShows,
                  ),
                  _buildStreamingPlatforms(state.streamingPlatformTvShowsPagingControllers),
                  _buildGenres(state.tvShowGenres, state.genreTvShowsPagingControllers),
                ],
              ),
            ),
          ),
        ) : const Center(child: CircularProgressIndicator()),
      ),
    ),
  );
}