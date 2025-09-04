import "dart:async";
import "dart:io";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:semo/bloc/app_bloc.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/bloc/app_state.dart";
import "package:semo/components/semo_player.dart";
import "package:semo/components/snack_bar.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/screens/base_screen.dart";
import "package:semo/services/recently_watched_service.dart";
import "package:semo/enums/media_type.dart";
import "package:wakelock_plus/wakelock_plus.dart";

class PlayerScreen extends BaseScreen {
  const PlayerScreen({
    super.key,
    required this.tmdbId,
    this.seasonId,
    this.episodeId,
    required this.title,
    this.subtitle,
    required this.stream,
    required this.mediaType,
  }) : assert(mediaType != MediaType.tvShows || (seasonId != null && episodeId != null), "seasonId and episodeId must be provided when mediaType is tvShows");

  final int tmdbId;
  final int? seasonId;
  final int? episodeId;
  final String title;
  final String? subtitle;
  final MediaStream stream;
  final MediaType mediaType;

  @override
  BaseScreenState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends BaseScreenState<PlayerScreen> {
  final RecentlyWatchedService _recentlyWatchedService = RecentlyWatchedService();
  List<File>? _subtitleFiles;
  bool _initialLandscapeLike = false;
  bool _forcedLandscape = false;
  bool _didLogPlaybackStart = false;
  bool _didLogSubtitlesAvailable = false;

  void _updateRecentlyWatched(int progressSeconds) {
    try {
      if (widget.mediaType == MediaType.movies) {
        context.read<AppBloc>().add(
              UpdateMovieProgress(
                widget.tmdbId,
                progressSeconds,
              ),
            );
      } else {
        context.read<AppBloc>().add(
              UpdateEpisodeProgress(
                widget.tmdbId,
                widget.seasonId!,
                widget.episodeId!,
                progressSeconds,
              ),
            );
      }
    } catch (_) {}
  }

  Future<void> _applyLandscapeIfNeeded() async {
    final Size size = MediaQuery.of(context).size;
    _initialLandscapeLike = size.width >= size.height; // Robust across TVs/tablets

    if (!_initialLandscapeLike) {
      await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
      _forcedLandscape = true;
    }

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _restoreOnExit() async {
    if (_forcedLandscape) {
      await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.portraitUp,
      ]);
    }

    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  void _onProgress(Duration progress, Duration total) {
    if (total.inSeconds > 0) {
      final int progressSeconds = progress.inSeconds;
      if (!_didLogPlaybackStart && progressSeconds > 0) {
        _didLogPlaybackStart = true;
        unawaited(logEvent(
          "playback_start",
          parameters: <String, Object?>{
            "tmdb_id": widget.tmdbId,
            "media_type": widget.mediaType.toJsonField(),
          },
        ));
      }
      if (progressSeconds > 0) {
        _updateRecentlyWatched(progressSeconds);
      }
    }
  }

  void _onError(Object? error) {
    logger.e("Playback error", error: error);
    unawaited(logEvent(
      "player_error",
      parameters: <String, Object?>{
        "tmdb_id": widget.tmdbId,
        "media_type": widget.mediaType.toJsonField(),
        "error": error?.toString(),
      },
    ));
    if (mounted) {
      if (widget.mediaType == MediaType.movies) {
        context.read<AppBloc>().add(RemoveMovieStream(widget.tmdbId));
      } else if (widget.mediaType == MediaType.tvShows) {
        context.read<AppBloc>().add(RemoveEpisodeStream(widget.episodeId!));
      }
      context.read<AppBloc>().add(const AddError("An error occurred during playback."));
      Navigator.pop(context);
    }
  }

  Future<void> _saveThenGoBack(int progressSeconds) async {
    unawaited(logEvent(
      "player_exit",
      parameters: <String, Object?>{
        "tmdb_id": widget.tmdbId,
        "media_type": widget.mediaType.toJsonField(),
        "progress_seconds": progressSeconds,
      },
    ));
    if (mounted) {
      _updateRecentlyWatched(progressSeconds);
      Navigator.pop(context);
    }
  }

  Future<void> _onPlaybackComplete(int progressSeconds) async {
    unawaited(logEvent(
      "player_complete",
      parameters: <String, Object?>{
        "tmdb_id": widget.tmdbId,
        "media_type": widget.mediaType.toJsonField(),
        "progress_seconds": progressSeconds,
      },
    ));
    await _saveThenGoBack(progressSeconds);
  }

  Future<void> _onBack(int progressSeconds) async {
    await _saveThenGoBack(progressSeconds);
  }

  @override
  String get screenName => "Player";

  @override
  Map<String, Object?> get screenParameters => <String, Object?>{
        "media_id": widget.tmdbId,
        "media_type": widget.mediaType.toJsonField(),
        if (widget.seasonId != null) "season_id": widget.seasonId,
        if (widget.episodeId != null) "episode_id": widget.episodeId,
        "title": widget.title,
        if (widget.subtitle != null) "subtitle": widget.subtitle,
      };

  @override
  Future<void> initializeScreen() async {
    await WakelockPlus.enable();
    await _applyLandscapeIfNeeded();
    try {
      final Uri? uri = Uri.tryParse(widget.stream.url);
      await logEvent(
        "player_open",
        parameters: <String, Object?>{
          "tmdb_id": widget.tmdbId,
          "media_type": widget.mediaType.toJsonField(),
          "has_stream_url": widget.stream.url.isNotEmpty,
          if (uri != null) "stream_host": uri.host,
        },
      );
    } catch (_) {}
  }

  @override
  void handleDispose() {
    _restoreOnExit();
    WakelockPlus.disable();
  }

  @override
  Widget buildContent(BuildContext context) => BlocConsumer<AppBloc, AppState>(
        listener: (BuildContext context, AppState state) {
          if (mounted) {
            if (widget.mediaType == MediaType.movies) {
              setState(() => _subtitleFiles = state.movieSubtitles?["${widget.tmdbId}"]);
            } else {
              setState(() => _subtitleFiles = state.episodeSubtitles?["${widget.episodeId}"]);
            }
            if (!_didLogSubtitlesAvailable && (_subtitleFiles?.isNotEmpty ?? false)) {
              _didLogSubtitlesAvailable = true;
              unawaited(logEvent(
                "subtitles_available",
                parameters: <String, Object?>{
                  "tmdb_id": widget.tmdbId,
                  "media_type": widget.mediaType.toJsonField(),
                  "count": _subtitleFiles!.length,
                },
              ));
            }
          }

          if (state.error != null) {
            showSnackBar(context, state.error!);
            context.read<AppBloc>().add(ClearError());
          }
        },
        builder: (BuildContext context, AppState state) {
          int progressSeconds;

          if (widget.mediaType == MediaType.movies) {
            progressSeconds = _recentlyWatchedService.getMovieProgress(widget.tmdbId, state.recentlyWatched);
          } else {
            progressSeconds = _recentlyWatchedService.getEpisodeProgress(
              widget.tmdbId,
              widget.seasonId!,
              widget.episodeId!,
              state.recentlyWatched,
            );
          }

          if (widget.mediaType == MediaType.movies) {
            _subtitleFiles = state.movieSubtitles?["${widget.tmdbId}"];
          } else {
            _subtitleFiles = state.episodeSubtitles?["${widget.episodeId}"];
          }

          return Scaffold(
            body: SemoPlayer(
              stream: widget.stream,
              title: widget.title,
              subtitle: widget.subtitle,
              subtitleFiles: _subtitleFiles,
              initialProgress: progressSeconds,
              onProgress: _onProgress,
              onPlaybackComplete: _onPlaybackComplete,
              onBack: _onBack,
              onError: _onError,
            ),
          );
        },
      );
}
