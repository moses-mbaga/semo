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
  }) : assert(mediaType != MediaType.tvShows || (seasonId != null && episodeId != null),
  "seasonId and episodeId must be provided when mediaType is tvShows"
  );

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

  Future<void> _forceLandscape() async {
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _forcePortrait() async {
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  void _onProgress(Duration progress, Duration total) {
    if (total.inSeconds > 0) {
      final int progressSeconds = progress.inSeconds;
      if (progressSeconds > 0) {
        _updateRecentlyWatched(progressSeconds);
      }
    }
  }

  //ignore: avoid_annotating_with_dynamic
  void _onError(dynamic error) {
    logger.e("Playback error", error: error);
    if (mounted) {
      Navigator.pop(context, <String, dynamic>{"error": error});
    }
  }

  Future<void> _saveThenGoBack(int progressSeconds) async {
    if (mounted) {
      _updateRecentlyWatched(progressSeconds);
      Navigator.pop(context);
    }
  }

  @override
  String get screenName => "Semo Player - ${widget.tmdbId}";

  @override
  Future<void> initializeScreen() async {
    await WakelockPlus.enable();
    await _forceLandscape();
  }

  @override
  void handleDispose() {
    _forcePortrait();
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
          onPlaybackComplete: _saveThenGoBack,
          onBack: _saveThenGoBack,
          onError: _onError,
        ),
      );
    },
  );
}