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

  void _toggleFavorite() {
    try {
      Timer(const Duration(milliseconds: 500), () {
        AppEvent event = _isFavorite
          ? RemoveFavorite(_movie, MediaType.movies)
          : AddFavorite(_movie, MediaType.movies);
        context.read<AppBloc>().add(event);
      });
    } catch (_) {}
  }

  Future<void> _extractMovieStream() async {
    setState(() => _isPlayTriggered = true);
    context.read<AppBloc>().add(ExtractMovieStream(_movie));
  }

  Future<void> _playMovie(MediaStream stream) async {
    context.read<AppBloc>().add(LoadMovieSubtitles(_movie.id));
    await navigate(
      PlayerScreen(
        tmdbId: _movie.id,
        title: _movie.title,
        stream: stream,
        mediaType: MediaType.movies,
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
      return "$hours ${hours == 1 ? "hr" : "hrs"}${mins > 0 ? " $mins ${mins == 1 ? "min" : "mins"}" : ''}";
    }

    return "$mins ${mins == 1 ? "min" : "mins"}";
  }

  Widget _buildPlayButton(MediaStream? stream) => Container(
    width: double.infinity,
    height: 50,
    margin: const EdgeInsets.only(top: 30),
    child: ElevatedButton(
      onPressed: !_isExtractingStream ? () {
        if (stream != null && stream.url.isNotEmpty) {
          _playMovie(stream);
        } else if (!_isExtractingStream) {
          _extractMovieStream();
        }
      } : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
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
            !_isExtractingStream ? "Play" : "Loading...",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 22,
            ),
          ),
        ],
      ),
    ),
  );

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
  String get screenName => "Movie - ${widget.movie.title}";

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
          _movie = state.movies?.firstWhere((Movie m) => m.id == widget.movie.id,
              orElse: () => widget.movie,
          ) ?? widget.movie;
          _isFavorite = state.favoriteMovies?.any((Movie m) => m.id == _movie.id) ?? false;
          _isExtractingStream = state.isExtractingMovieStream?[_movie.id.toString()] ?? false;
        });
      }

      final MediaStream? stream = state.movieStreams?[_movie.id.toString()];

      if (_isPlayTriggered && !_isExtractingStream && stream != null) {
        if (mounted) {
          setState(() => _isPlayTriggered = false);
        }
        _playMovie(stream);
      }

      if (state.error != null) {
        showSnackBar(context, state.error!);
        context.read<AppBloc>().add(ClearError());
      }
    },
    builder: (BuildContext context, AppState state) {
      final Movie displayMovie = state.movies?.firstWhere((Movie m) => m.id == widget.movie.id,
        orElse: () => _movie,
      ) ?? _movie;
      final bool isMovieLoaded = state.movies?.any((Movie m) => m.id == widget.movie.id) ?? false;
      final MediaStream? stream = state.movieStreams?[_movie.id.toString()];

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
        body: (isMovieLoaded || !_isLoading) ? SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: Theme.of(context).primaryColor,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  MediaPoster(
                    backdropPath: displayMovie.backdropPath,
                    trailerUrl: state.movieTrailers?[displayMovie.id.toString()],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        MediaInfo(
                          title: displayMovie.title,
                          subtitle: "${displayMovie.releaseDate.split("-").first} · ${_formatDuration(Duration(minutes: displayMovie.duration))}",
                          overview: displayMovie.overview,
                        ),
                        _buildPlayButton(stream),
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
        ) : const Center(child: CircularProgressIndicator()),
      );
    },
  );
}