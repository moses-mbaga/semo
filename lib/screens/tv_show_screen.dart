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
import "package:semo/enums/media_type.dart";

class TvShowScreen extends BaseScreen {
  const TvShowScreen(this.tvShow, {super.key});

  final TvShow tvShow;

  @override
  BaseScreenState<TvShowScreen> createState() => _TvShowScreenState();
}

class _TvShowScreenState extends BaseScreenState<TvShowScreen> {
  bool _isFavorite = false;
  bool _isLoading = true;
  int _currentSeasonIndex = 0;
  int? _extractingEpisodeId;
  bool _hasSetInitialSeason = false;

  void _toggleFavorite() {
    try {
      final bool newState = !_isFavorite;
      unawaited(logEvent(
        "toggle_favorite",
        parameters: <String, Object?>{
          "media_type": "tv",
          "tv_show_id": widget.tvShow.id,
          "new_state": "$newState",
        },
      ));
      Timer(const Duration(milliseconds: 500), () {
        AppEvent event = _isFavorite ? RemoveFavorite(widget.tvShow, MediaType.tvShows) : AddFavorite(widget.tvShow, MediaType.tvShows);
        context.read<AppBloc>().add(event);
      });
    } catch (_) {}
  }

  Future<void> _extractEpisodeStream(Season season, Episode episode) async {
    await logEvent(
      "extract_episode_stream_start",
      parameters: <String, Object?>{
        "tv_show_id": widget.tvShow.id,
        "season_id": season.id,
        "season_number": season.number,
        "episode_id": episode.id,
        "episode_number": episode.number,
      },
    );
    setState(() {
      _extractingEpisodeId = episode.id;
    });

    if (mounted) {
      context.read<AppBloc>().add(ExtractEpisodeStream(widget.tvShow, episode));
    }
  }

  Future<void> _playEpisode(Season season, Episode episode, MediaStream stream) async {
    await logEvent(
      "play_episode",
      parameters: <String, Object?>{
        "tv_show_id": widget.tvShow.id,
        "season_id": season.id,
        "season_number": season.number,
        "episode_id": episode.id,
        "episode_number": episode.number,
        "has_stream_url": "${stream.url.isNotEmpty}",
      },
    );

    if (mounted) {
      context.read<AppBloc>().add(LoadEpisodeSubtitles(
            widget.tvShow.id,
            seasonNumber: season.number,
            episodeId: episode.id,
            episodeNumber: episode.number,
          ));
    }

    await navigate(
      PlayerScreen(
        tmdbId: widget.tvShow.id,
        title: widget.tvShow.name,
        subtitle: episode.name,
        seasonId: season.id,
        episodeId: episode.id,
        stream: stream,
        mediaType: MediaType.tvShows,
      ),
    );
  }

  Future<void> _markEpisodeAsWatched(Season season, Episode episode) async {
    unawaited(logEvent(
      "mark_episode_watched",
      parameters: <String, Object?>{
        "tv_show_id": widget.tvShow.id,
        "season_id": season.id,
        "episode_id": episode.id,
      },
    ));
    context.read<AppBloc>().add(UpdateEpisodeProgress(
          widget.tvShow.id,
          season.id,
          episode.id,
          episode.duration * 60,
        ));
  }

  Future<void> _removeEpisodeFromRecentlyWatched(Season season, Episode episode) async {
    unawaited(logEvent(
      "remove_episode_recently_watched",
      parameters: <String, Object?>{
        "tv_show_id": widget.tvShow.id,
        "season_id": season.id,
        "episode_id": episode.id,
      },
    ));
    context.read<AppBloc>().add(DeleteEpisodeProgress(
          widget.tvShow.id,
          season.id,
          episode.id,
        ));
  }

  Future<void> _onSeasonChanged(List<Season> seasons, Season season) async {
    final int selectedSeasonIndex = seasons.indexOf(season);

    if (selectedSeasonIndex != -1) {
      unawaited(logEvent(
        "change_season",
        parameters: <String, Object?>{
          "tv_show_id": widget.tvShow.id,
          "season_id": season.id,
          "season_number": season.number,
        },
      ));
      setState(() => _currentSeasonIndex = selectedSeasonIndex);
      context.read<AppBloc>().add(LoadSeasonEpisodes(widget.tvShow.id, season.number));
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _isFavorite = false;
      _currentSeasonIndex = 0;
      _hasSetInitialSeason = false;
    });

    context.read<AppBloc>().add(RefreshTvShowDetails(widget.tvShow.id));
    context.read<AppBloc>().add(RefreshRecentlyWatched());
    context.read<AppBloc>().add(RefreshFavorites());
  }

  Widget _buildSeasonSelector(List<Season>? seasons, List<Episode>? episodes, {Map<String, bool>? extractingMap}) {
    if (seasons == null || seasons.isEmpty) {
      return const SizedBox.shrink();
    }

    final Season selectedSeason = seasons[_currentSeasonIndex];
    // ignore: prefer_expression_function_bodies
    final bool anyExtracting = extractingMap?.entries.any((MapEntry<String, bool> entry) {
          return (episodes?.any((Episode episode) => episode.id == int.tryParse(entry.key)) ?? false) && entry.value;
        }) ??
        false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            SeasonSelector(
              seasons: seasons,
              selectedSeason: selectedSeason,
              onSeasonChanged: _onSeasonChanged,
              enabled: !anyExtracting,
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedSeasonEpisodes(List<Season>? seasons, List<Episode>? episodes, {bool isLoadingEpisodes = false, Map<String, dynamic>? recentlyWatchedEpisodes, Map<String, bool>? extractingMap, Map<String, MediaStream>? episodeStreams}) {
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
    // ignore: prefer_expression_function_bodies
    final bool anyExtracting = extractingMap?.entries.any((MapEntry<String, bool> entry) {
          return episodes.any((Episode episode) => episode.id == int.tryParse(entry.key)) && entry.value;
        }) ??
        false;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: episodes.length,
      itemBuilder: (BuildContext context, int index) {
        final Episode episode = episodes[index];
        final bool isExtracting = extractingMap?[episode.id.toString()] ?? false;
        final bool disableAll = anyExtracting && !isExtracting;
        final MediaStream? stream = episodeStreams?[episode.id.toString()];
        final bool isRecentlyWatched = recentlyWatchedEpisodes?.keys.contains(episode.id.toString()) ?? false;
        final int watchedProgress = recentlyWatchedEpisodes?[episode.id.toString()]?["progress"] ?? 0;

        return EpisodeCard(
          episode: episode,
          isRecentlyWatched: isRecentlyWatched,
          watchedProgress: watchedProgress,
          onTap: (disableAll || isExtracting)
              ? null
              : () {
                  unawaited(logEvent(
                    "cta_click",
                    parameters: <String, Object?>{
                      "button": "episode_${stream == null ? "extract" : "stream"}",
                      "tv_show_id": widget.tvShow.id,
                      "season_id": selectedSeason.id,
                      "episode_id": episode.id,
                      "has_stream": "${stream != null && stream.url.isNotEmpty}",
                    },
                  ));
                  if (stream == null) {
                    _extractEpisodeStream(selectedSeason, episode);
                  } else {
                    _playEpisode(selectedSeason, episode, stream);
                  }
                },
          onMarkWatched: () => _markEpisodeAsWatched(selectedSeason, episode),
          onRemoveFromWatched: isRecentlyWatched ? () => _removeEpisodeFromRecentlyWatched(selectedSeason, episode) : null,
          isLoading: isExtracting,
          disabled: disableAll,
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
  String get screenName => "TV Show";

  @override
  Map<String, Object?> get screenParameters => <String, Object?>{
        "tv_show_id": widget.tvShow.id,
        "tv_show_name": widget.tvShow.name,
      };

  @override
  Future<void> initializeScreen() async {
    context.read<AppBloc>().add(LoadTvShowDetails(widget.tvShow.id));
  }

  @override
  Widget buildContent(BuildContext context) => BlocConsumer<AppBloc, AppState>(
        listener: (BuildContext context, AppState state) {
          final List<Season>? seasons = state.tvShowSeasons?[widget.tvShow.id.toString()];
          final Season? selectedSeason = state.tvShowSeasons?[widget.tvShow.id.toString()]?[_currentSeasonIndex];
          final List<Episode> episodes = state.tvShowEpisodes?[widget.tvShow.id.toString()]?[selectedSeason?.number] ?? <Episode>[];
          final Map<String, MediaStream>? episodeStreams = state.episodeStreams;
          final Map<String, bool>? extractingMap = state.isExtractingEpisodeStream;

          if (mounted) {
            setState(() {
              _isLoading = state.isTvShowLoading?[widget.tvShow.id.toString()] ?? true;
              _isFavorite = state.favoriteTvShows?.any((TvShow tvShow) => tvShow.id == widget.tvShow.id) ?? false;

              // Track extracting episode id for UI
              if (extractingMap != null && extractingMap.containsValue(true)) {
                try {
                  final MapEntry<String, bool> found = extractingMap.entries.firstWhere((MapEntry<String, bool> entry) => entry.value);
                  _extractingEpisodeId = int.tryParse(found.key);
                } catch (e, s) {
                  logger.e("Error extracting episode id", error: e, stackTrace: s);
                }
              }
            });
          }

          // Set initial season based on recently watched (only once)
          if (!_hasSetInitialSeason && seasons != null && seasons.isNotEmpty && state.recentlyWatched != null) {
            int? mostRecentSeasonId;
            int mostRecentTimestamp = 0;

            final Map<String, dynamic>? tvShowsMap = state.recentlyWatched?[MediaType.tvShows.toJsonField()];
            final Map<String, dynamic>? tvShowProgress = tvShowsMap?[widget.tvShow.id.toString()] as Map<String, dynamic>?;

            if (tvShowProgress != null) {
              final Map<String, dynamic> seasonsProgress = Map<String, dynamic>.from(tvShowProgress)..remove("visibleInMenu");

              for (final MapEntry<String, dynamic> seasonEntry in seasonsProgress.entries) {
                final dynamic seasonData = seasonEntry.value;

                if (seasonData is Map) {
                  for (final dynamic episodeData in seasonData.values) {
                    if (episodeData is Map && episodeData["timestamp"] != null) {
                      final int ts = episodeData["timestamp"] as int? ?? 0;

                      if (ts > mostRecentTimestamp) {
                        mostRecentTimestamp = ts;
                        mostRecentSeasonId = int.tryParse(seasonEntry.key);
                      }
                    }
                  }
                }
              }
            }

            if (mostRecentSeasonId != null) {
              final int idx = seasons.indexWhere((Season s) => s.id == mostRecentSeasonId);

              if (idx != -1) {
                setState(() => _currentSeasonIndex = idx);
                context.read<AppBloc>().add(LoadSeasonEpisodes(widget.tvShow.id, seasons[idx].number));
              }
            }

            _hasSetInitialSeason = true;
          }

          // Handle stream extraction result
          if (_extractingEpisodeId != null && extractingMap?[_extractingEpisodeId.toString()] == false && episodeStreams?[_extractingEpisodeId.toString()] != null) {
            try {
              final Episode selectedEpisode = episodes.firstWhere((Episode e) => e.id == _extractingEpisodeId);
              final MediaStream? stream = episodeStreams?[_extractingEpisodeId.toString()];

              if (selectedSeason != null && selectedEpisode.id != 0 && stream != null) {
                setState(() => _extractingEpisodeId = null);
                _playEpisode(selectedSeason, selectedEpisode, stream);
              }
            } catch (e, s) {
              logger.e("Error playing episode", error: e, stackTrace: s);
              showSnackBar(context, "No stream found");
            }
          }

          if (state.error != null) {
            showSnackBar(context, state.error!);
            context.read<AppBloc>().add(ClearError());
          }
        },
        builder: (BuildContext context, AppState state) {
          final List<Season>? seasons = state.tvShowSeasons?[widget.tvShow.id.toString()];
          final Season? selectedSeason = seasons?[_currentSeasonIndex];
          final List<Episode>? episodes = state.tvShowEpisodes?[widget.tvShow.id.toString()]?[selectedSeason?.number];
          final bool isLoadingEpisodes = state.isSeasonEpisodesLoading?[widget.tvShow.id.toString()]?[selectedSeason?.number] ?? false;
          final List<Person>? cast = state.tvShowCast?[widget.tvShow.id.toString()];
          final bool isTvShowLoaded = seasons != null && seasons.isNotEmpty && episodes != null && episodes.isNotEmpty;
          final Map<String, bool>? extractingMap = state.isExtractingEpisodeStream;
          final Map<String, MediaStream>? episodeStreams = state.episodeStreams;
          final Map<String, dynamic>? recentlyWatchedEpisodes = state.recentlyWatched?[MediaType.tvShows.toJsonField()]?[widget.tvShow.id.toString()]?[selectedSeason?.id.toString()];

          return Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: () => Navigator.pop(context)),
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
                child: (isTvShowLoaded || !_isLoading)
                    ? SingleChildScrollView(
                        child: Column(
                          children: <Widget>[
                            MediaPoster(
                              backdropPath: widget.tvShow.backdropPath,
                              trailerUrl: state.tvShowTrailers?[widget.tvShow.id.toString()],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 18,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  MediaInfo(
                                    title: widget.tvShow.name,
                                    subtitle: "${widget.tvShow.firstAirDate.split("-")[0]} ·  ${seasons?.length ?? 1} Seasons",
                                    overview: widget.tvShow.overview,
                                  ),
                                  const SizedBox(height: 30),
                                  _buildSeasonSelector(
                                    seasons,
                                    episodes,
                                    extractingMap: extractingMap,
                                  ),
                                  const SizedBox(height: 30),
                                  _buildSelectedSeasonEpisodes(
                                    seasons,
                                    episodes,
                                    isLoadingEpisodes: isLoadingEpisodes,
                                    recentlyWatchedEpisodes: recentlyWatchedEpisodes,
                                    extractingMap: extractingMap,
                                    episodeStreams: episodeStreams,
                                  ),
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
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
          );
        },
      );
}
