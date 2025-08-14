import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:semo/bloc/app_bloc.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/bloc/app_state.dart";
import "package:semo/components/episode_card.dart";
import "package:semo/components/media_card_horizontal_list.dart";
import "package:semo/components/media_info.dart";
import "package:semo/components/media_poster.dart";
import "package:semo/components/person_card_horizontal_list.dart";
import "package:semo/components/season_selector.dart";
import "package:semo/components/snack_bar.dart";
import "package:semo/models/episode.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/models/person.dart";
import "package:semo/models/season.dart";
import "package:semo/models/tv_show.dart";
import "package:semo/screens/base_screen.dart";
import "package:semo/screens/player_screen.dart";
import "package:semo/services/recently_watched_service.dart";
import "package:semo/services/stream_extractor/extractor.dart";
import "package:semo/enums/media_type.dart";

class TvShowScreen extends BaseScreen {
  const TvShowScreen(this.tvShow, {super.key});

  final TvShow tvShow;

  @override
  BaseScreenState<TvShowScreen> createState() => _TvShowScreenState();
}

class _TvShowScreenState extends BaseScreenState<TvShowScreen> {
  final RecentlyWatchedService _recentlyWatchedService = RecentlyWatchedService();
  bool _isFavorite = false;
  bool _isLoading = true;
  int _currentSeasonIndex = 0;

  void _toggleFavorite() {
    try {
      Timer(const Duration(milliseconds: 500), () {
        AppEvent event = _isFavorite
            ? RemoveFavorite(widget.tvShow, MediaType.tvShows)
            : AddFavorite(widget.tvShow, MediaType.tvShows);
        context.read<AppBloc>().add(event);
      });
    } catch (_) {}
  }

  Future<void> _playEpisode(Season season, Episode episode) async {
    spinner.show();

    try {
      final MediaStream? stream = await StreamExtractor.getStream(tvShow: widget.tvShow, episode: episode);

      if (stream != null && stream.url.isNotEmpty) {
        spinner.dismiss();

        final dynamic result = await navigate(
          PlayerScreen(
            tmdbId: widget.tvShow.id,
            seasonId: season.id,
            episodeId: episode.id,
            title: episode.name,
            stream: stream,
            mediaType: MediaType.tvShows,
          ),
        );

        if (result != null) {
          _handlePlayerResult(result);
        }
      } else {
        if (mounted) {
          showSnackBar(context, "No stream found");
        }
      }
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "Failed to load stream");
      }
    }

    spinner.dismiss();
  }

  void _handlePlayerResult(Map<String, dynamic> result) {
    if (result["error"] != null) {
      showSnackBar(context, "Playback error. Try again");
      return;
    }
  }

  Future<void> _markEpisodeAsWatched(Season season, Episode episode) async {
    try {
      unawaited(
        _recentlyWatchedService.updateEpisodeProgress(
          widget.tvShow.id,
          season.id,
          episode.id,
          episode.duration * 60,
        ),
      );
    } catch (_) {}

    setState(() {
      episode.isRecentlyWatched = true;
      episode.watchedProgress = episode.duration * 60;
    });
  }

  Future<void> _removeEpisodeFromRecentlyWatched(Season season, Episode episode) async {
    try {
      unawaited(
        _recentlyWatchedService.removeEpisodeProgress(
          widget.tvShow.id,
          season.id,
          episode.id,
        ),
      );
    } catch (_) {}

    setState(() {
      episode.isRecentlyWatched = false;
      episode.watchedProgress = null;
    });
  }

  Future<void> _onSeasonChanged(List<Season> seasons, Season season) async {
    final int selectedSeasonIndex = seasons.indexOf(season);

    if (selectedSeasonIndex != -1) {
      setState(() => _currentSeasonIndex = selectedSeasonIndex);
      context.read<AppBloc>().add(LoadSeasonEpisodes(widget.tvShow.id, season.number));
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _isFavorite = false;
      _currentSeasonIndex = 0;
    });

    context.read<AppBloc>().add(RefreshTvShowDetails(widget.tvShow.id));
    context.read<AppBloc>().add(RefreshRecentlyWatched());
    context.read<AppBloc>().add(RefreshFavorites());
  }

  Widget _buildSeasonSelector(List<Season>? seasons) {
    if (seasons == null || seasons.isEmpty) {
      return const SizedBox.shrink();
    }

    final Season selectedSeason = seasons[_currentSeasonIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            SeasonSelector(
              seasons: seasons,
              selectedSeason: selectedSeason,
              onSeasonChanged: _onSeasonChanged,
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedSeasonEpisodes(List<Season>? seasons, List<Episode>? episodes, {bool isLoadingEpisodes = false}) {
    if (seasons == null || seasons.isEmpty) {
      return const SizedBox.shrink();
    }

    if (isLoadingEpisodes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (episodes == null) {
      return const Text("No episodes available for this season.");
    }

    Season selectedSeason = seasons[_currentSeasonIndex];

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: episodes.length,
      itemBuilder: (BuildContext context, int index) {
        final Episode episode = episodes[index];
        return EpisodeCard(
          episode: episode,
          onTap: () => _playEpisode(selectedSeason, episode),
          onMarkWatched: () => _markEpisodeAsWatched(selectedSeason, episode),
          onRemove: episode.isRecentlyWatched ? () => _removeEpisodeFromRecentlyWatched(selectedSeason, episode) : null,
        );
      },
    );
  }

  Widget _buildPersonCardHorizontalList(List<Person>? cast) {
    if (cast == null || cast.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: PersonCardHorizontalList(
        title: "Cast",
        people: cast,
      ),
    );
  }

  Widget _buildMediaCardHorizontalList({required PagingController<int, TvShow>? controller, required String title}) {
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
        onTap: (dynamic media) => navigate(
          TvShowScreen(media as TvShow),
        ),
      ),
    );
  }

  @override
  String get screenName => "TV Show - ${widget.tvShow.name}";

  @override
  Future<void> initializeScreen() async {
    context.read<AppBloc>().add(LoadTvShowDetails(widget.tvShow.id));
  }

  @override
  Widget buildContent(BuildContext context) => BlocConsumer<AppBloc, AppState>(
    listener: (BuildContext context, AppState state) {
      if (mounted) {
        setState(() {
          _isLoading = state.isTvShowLoading?[widget.tvShow.id.toString()] ?? true;
          _isFavorite = state.favoriteTvShows?.any((TvShow tvShow) => tvShow.id == widget.tvShow.id) ?? false;
        });
      }

      if (state.error != null) {
        showSnackBar(context, state.error!);
        context.read<AppBloc>().add(ClearError());
      }
    },
    builder: (BuildContext context, AppState state) {
      List<Season>? seasons = state.tvShowSeasons?[widget.tvShow.id.toString()];
      Season? selectedSeason = seasons?[_currentSeasonIndex];
      List<Episode>? episodes = state.tvShowEpisodes?[widget.tvShow.id.toString()]?[selectedSeason?.number];
      bool isLoadingEpisodes = state.isSeasonEpisodesLoading?[widget.tvShow.id.toString()]?[selectedSeason?.number] ?? false;
      List<Person>? cast = state.tvShowCast?[widget.tvShow.id.toString()];
      bool isTvShowLoaded = seasons != null && seasons.isNotEmpty && episodes != null && episodes.isNotEmpty;

      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => Navigator.pop(context, "refresh")),
          actions: <Widget>[
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
              ),
              color: _isFavorite ? Colors.red : Colors.white,
              onPressed: _toggleFavorite,
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: Theme.of(context).primaryColor,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: (isTvShowLoaded || !_isLoading) ? SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  MediaPoster(
                    backdropPath: widget.tvShow.backdropPath,
                    trailerUrl: state.tvShowTrailers?[widget.tvShow.id.toString()],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        MediaInfo(
                          title: widget.tvShow.name,
                          subtitle: "${widget.tvShow.firstAirDate.split("-")[0]} · ${seasons?.length ?? 1} Seasons",
                          overview: widget.tvShow.overview,
                        ),
                        const SizedBox(height: 30),
                        _buildSeasonSelector(seasons),
                        const SizedBox(height: 30),
                        _buildSelectedSeasonEpisodes(seasons, episodes, isLoadingEpisodes: isLoadingEpisodes),
                        _buildPersonCardHorizontalList(cast),
                        _buildMediaCardHorizontalList(
                          title: "Recommendations",
                          controller: state.tvShowRecommendationsPagingControllers?[widget.tvShow.id.toString()],
                        ),
                        _buildMediaCardHorizontalList(
                          title: "Similar",
                          controller: state.similarTvShowsPagingControllers?[widget.tvShow.id.toString()],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ) : const Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    },
  );
}
