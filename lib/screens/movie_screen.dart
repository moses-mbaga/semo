import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:semo/bloc/app_bloc.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/bloc/app_state.dart";
import "package:semo/components/media_card_horizontal_list.dart";
import "package:semo/components/media_info.dart";
import "package:semo/components/media_poster.dart";
import "package:semo/components/person_card_horizontal_list.dart";
import "package:semo/components/snack_bar.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/models/movie.dart";
import "package:semo/models/person.dart";
import "package:semo/screens/base_screen.dart";
import "package:semo/screens/player_screen.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/services/recently_watched_service.dart";
import "package:url_launcher/url_launcher.dart";

class MovieScreen extends BaseScreen {
  const MovieScreen(this.movie, {super.key});

  final Movie movie;

  @override
  BaseScreenState<MovieScreen> createState() => _MovieScreenState();
}

class _MovieScreenState extends BaseScreenState<MovieScreen> {
  late Movie _movie = widget.movie;
  bool _isFavorite = false;
  bool _isLoading = true;
  bool _isPlayTriggered = false;
  bool _isExtractingStream = false;
  bool _isTrailerPlayTriggered = false;
  String? _pendingTrailerUrl;
  final RecentlyWatchedService _recentlyWatchedService = RecentlyWatchedService();

  void _toggleFavorite() {
    try {
      final bool newState = !_isFavorite;
      unawaited(logEvent(
        "toggle_favorite",
        parameters: <String, Object?>{
          "media_type": "movie",
          "movie_id": _movie.id,
          "new_state": "$newState",
        },
      ));
      Timer(const Duration(milliseconds: 500), () {
        AppEvent event = _isFavorite ? RemoveFavorite(_movie, MediaType.movies) : AddFavorite(_movie, MediaType.movies);
        context.read<AppBloc>().add(event);
      });
    } catch (_) {}
  }

  Future<void> _extractMovieStream() async {
    await logEvent(
      "extract_movie_stream_start",
      parameters: <String, Object?>{
        "movie_id": _movie.id,
      },
    );
    setState(() => _isPlayTriggered = true);
    if (mounted) {
      context.read<AppBloc>().add(ExtractMovieStream(_movie));
    }
  }

  Future<void> _playMovie(List<MediaStream> streams) async {
    await logEvent(
      "play_movie",
      parameters: <String, Object?>{
        "movie_id": _movie.id,
        "has_stream_url": "${streams.isNotEmpty && streams.first.url.isNotEmpty}",
      },
    );

    await navigate(
      PlayerScreen(
        tmdbId: _movie.id,
        title: _movie.title,
        subtitle: "Movie",
        streams: streams,
        mediaType: MediaType.movies,
      ),
    );
  }

  String _trailerStreamKey() => "${MediaType.movies.toJsonField()}_${_movie.id}";

  Future<void> _openTrailer(List<MediaStream> streams) async {
    await logEvent(
      "play_trailer",
      parameters: <String, Object?>{
        "movie_id": _movie.id,
        "has_stream_url": "${streams.isNotEmpty && streams.first.url.isNotEmpty}",
      },
    );

    await navigate(
      PlayerScreen(
        tmdbId: _movie.id,
        title: _movie.title,
        subtitle: "Trailer",
        streams: streams,
        mediaType: MediaType.trailers,
      ),
    );
  }

  Future<void> _openTrailerExternally(String url) async {
    final Uri? trailerUri = Uri.tryParse(url);

    if (trailerUri == null) {
      if (mounted) {
        showSnackBar(context, "Unable to open trailer");
      }
      return;
    }

    try {
      final bool didLaunch = await launchUrl(
        trailerUri,
        mode: LaunchMode.externalNonBrowserApplication,
      );

      if (!mounted) {
        return;
      }

      if (!didLaunch) {
        showSnackBar(context, "Unable to open trailer");
      }
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "Unable to open trailer");
      }
    }
  }

  Future<void> _playTrailer(String? trailerUrl) async {
    final String? sanitizedUrl = trailerUrl?.trim();

    if (sanitizedUrl == null || sanitizedUrl.isEmpty) {
      if (mounted) {
        showSnackBar(context, "No trailer found");
      }
      return;
    }

    await logEvent(
      "extract_trailer_stream_start",
      parameters: <String, Object?>{
        "movie_id": _movie.id,
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isTrailerPlayTriggered = true;
      _pendingTrailerUrl = sanitizedUrl;
    });

    context.read<AppBloc>().add(
          ExtractTrailerStreams(
            tmdbId: _movie.id,
            mediaType: MediaType.movies,
            trailerUrl: sanitizedUrl,
          ),
        );
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _isFavorite = false;
    });

    context.read<AppBloc>().add(RefreshMovieDetails(_movie.id));
    context.read<AppBloc>().add(RefreshRecentlyWatched());
    context.read<AppBloc>().add(RefreshFavorites());
  }

  String _formatDuration(Duration d) {
    final int hours = d.inHours;
    final int mins = d.inMinutes.remainder(60);

    if (hours > 0) {
      return "$hours ${hours == 1 ? "hr" : "hrs"}${mins > 0 ? " $mins ${mins == 1 ? "min" : "mins"}" : ""}";
    }

    return "$mins ${mins == 1 ? "min" : "mins"}";
  }

  Widget _buildPlayButton(List<MediaStream>? streams, {required int progressSeconds, required int durationSeconds}) {
    final double progress = durationSeconds > 0 ? (progressSeconds / durationSeconds).clamp(0.0, 1.0) : 0.0;
    final bool isRecentlyWatched = progressSeconds > 0 && progress < 1.0;

    final String label = _isExtractingStream ? "Loading..." : (isRecentlyWatched ? "Resume" : "Play");

    return Container(
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.only(top: 30),
      child: Stack(
        children: <Widget>[
          // Progress background
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 50,
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.25),
              color: Theme.of(context).primaryColor,
            ),
          ),
          // Clickable layer
          Positioned.fill(
            child: ElevatedButton(
              onPressed: !_isExtractingStream
                  ? () {
                      final bool hasStreams = streams != null && streams.isNotEmpty;
                      final bool hasPlayableStream = hasStreams && streams.first.url.isNotEmpty;

                      if (hasPlayableStream) {
                        unawaited(logEvent(
                          "cta_click",
                          parameters: <String, Object?>{
                            "button": "play_movie",
                            "movie_id": _movie.id,
                            "resume": progress > 0 && progress < 1.0,
                          },
                        ));
                      } else {
                        unawaited(logEvent(
                          "cta_click",
                          parameters: <String, Object?>{
                            "button": "extract_stream",
                            "movie_id": _movie.id,
                          },
                        ));
                      }
                      if (hasPlayableStream) {
                        _playMovie(streams);
                      } else if (!_isExtractingStream) {
                        _extractMovieStream();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.play_arrow,
                    size: 28,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 22,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildMediaCardHorizontalList({required PagingController<int, Movie>? controller, required String title}) {
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: MediaCardHorizontalList(
        title: title,
        pagingController: controller,
        mediaType: MediaType.movies,
        //ignore: avoid_annotating_with_dynamic
        onTap: (dynamic media) => navigate(
          MovieScreen(media as Movie),
        ),
      ),
    );
  }

  @override
  String get screenName => "Movie";

  @override
  Map<String, Object?> get screenParameters => <String, Object?>{
        "movie_id": widget.movie.id,
        "movie_title": widget.movie.title,
      };

  @override
  Future<void> initializeScreen() async {
    context.read<AppBloc>().add(LoadMovieDetails(widget.movie.id));
  }

  @override
  Widget buildContent(BuildContext context) => BlocConsumer<AppBloc, AppState>(
        listener: (BuildContext context, AppState state) {
          if (mounted) {
            setState(() {
              _isLoading = state.isMovieLoading?[_movie.id.toString()] ?? true;
              _movie = state.movies?.firstWhere(
                    (Movie m) => m.id == widget.movie.id,
                    orElse: () => widget.movie,
                  ) ??
                  widget.movie;
              _isFavorite = state.favoriteMovies?.any((Movie m) => m.id == _movie.id) ?? false;
              _isExtractingStream = state.isExtractingMovieStream?[_movie.id.toString()] ?? false;
            });
          }

          final String trailerKey = _trailerStreamKey();
          final List<MediaStream>? trailerStreams = state.trailerStreams?[trailerKey];
          final bool isExtractingTrailer = state.isExtractingTrailerStream?[trailerKey] ?? false;
          final List<MediaStream>? streams = state.movieStreams?[_movie.id.toString()];

          if (_isTrailerPlayTriggered && !isExtractingTrailer) {
            if (mounted) {
              setState(() => _isTrailerPlayTriggered = false);
            }

            if (trailerStreams != null && trailerStreams.isNotEmpty) {
              _pendingTrailerUrl = null;
              _openTrailer(trailerStreams);
            } else if (_pendingTrailerUrl != null) {
              final String pendingUrl = _pendingTrailerUrl!;
              _pendingTrailerUrl = null;
              unawaited(_openTrailerExternally(pendingUrl));
            }
          }

          if (_isPlayTriggered && !_isExtractingStream && (streams?.isNotEmpty ?? false)) {
            if (mounted) {
              setState(() => _isPlayTriggered = false);
            }
            _playMovie(streams!);
          }

          if (state.error != null) {
            showSnackBar(context, state.error!);
            context.read<AppBloc>().add(ClearError());
          }
        },
        builder: (BuildContext context, AppState state) {
          final Movie displayMovie = state.movies?.firstWhere(
                (Movie m) => m.id == widget.movie.id,
                orElse: () => _movie,
              ) ??
              _movie;
          final bool isMovieLoaded = state.movies?.any((Movie m) => m.id == widget.movie.id) ?? false;
          final List<MediaStream>? streams = state.movieStreams?[_movie.id.toString()];
          final String? trailerUrl = state.movieTrailers?[displayMovie.id.toString()];

          return Scaffold(
            appBar: AppBar(
              leading: BackButton(
                onPressed: () => Navigator.pop(context),
              ),
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
            body: (isMovieLoaded || !_isLoading)
                ? SafeArea(
                    child: RefreshIndicator(
                      onRefresh: _refreshData,
                      color: Theme.of(context).primaryColor,
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      child: SingleChildScrollView(
                        child: Column(
                          children: <Widget>[
                            MediaPoster(
                              backdropPath: displayMovie.backdropPath,
                              trailerUrl: trailerUrl,
                              onPlayTrailer: () => _playTrailer(trailerUrl),
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
                                    title: displayMovie.title,
                                    subtitle: "${displayMovie.releaseDate.split("-").first} · ${_formatDuration(Duration(minutes: displayMovie.duration))}",
                                    overview: displayMovie.overview,
                                  ),
                                  _buildPlayButton(
                                    streams,
                                    progressSeconds: _recentlyWatchedService.getMovieProgress(displayMovie.id, state.recentlyWatched),
                                    durationSeconds: (displayMovie.duration) * 60,
                                  ),
                                  _buildPersonCardHorizontalList(state.movieCast?[displayMovie.id.toString()]),
                                  _buildMediaCardHorizontalList(
                                    title: "Recommendations",
                                    controller: state.movieRecommendationsPagingControllers?[displayMovie.id.toString()],
                                  ),
                                  _buildMediaCardHorizontalList(
                                    title: "Similar",
                                    controller: state.similarMoviesPagingControllers?[displayMovie.id.toString()],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          );
        },
      );
}
