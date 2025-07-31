import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:index/bloc/app_bloc.dart";
import "package:index/bloc/app_event.dart";
import "package:index/bloc/app_state.dart";
import "package:index/components/media_card_horizontal_list.dart";
import "package:index/components/media_info.dart";
import "package:index/components/media_poster.dart";
import "package:index/components/person_card_horizontal_list.dart";
import "package:index/components/snack_bar.dart";
import "package:index/models/media_stream.dart";
import "package:index/models/movie.dart";
import "package:index/models/person.dart";
import "package:index/screens/base_screen.dart";
import "package:index/screens/player_screen.dart";
import "package:index/services/stream_extractor/extractor.dart";
import "package:index/services/subtitle_service.dart";
import "package:index/enums/media_type.dart";

class MovieScreen extends BaseScreen {
  const MovieScreen(this.movie, {super.key});

  final Movie movie;

  @override
  BaseScreenState<MovieScreen> createState() => _MovieScreenState();
}

class _MovieScreenState extends BaseScreenState<MovieScreen> {
  late Movie _movie = widget.movie;
  final SubtitleService _subtitleService = SubtitleService();
  bool _isFavorite = false;
  bool _isLoading = true;

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

  Future<void> _playMovie() async {
    spinner.show();

    try {
      final MediaStream? stream = await StreamExtractor.getStream(movie: _movie);

      if (stream != null && stream.url.isNotEmpty) {
        stream.subtitleFiles = await _subtitleService.getSubtitles(_movie.id);

        spinner.dismiss();

        final dynamic result = await navigate(
          PlayerScreen(
            tmdbId: _movie.id,
            title: _movie.title,
            stream: stream,
            mediaType: MediaType.movies,
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
    try {
      if (mounted) {
        if (result["error"] != null) {
          showSnackBar(context, "Playback error. Try again");
        }
      }
    } catch (_) {}
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _isFavorite = false;
    });

    context.read<AppBloc>().add(RefreshMovieDetails(_movie.id));
  }

  String _formatDuration(Duration d) {
    final int hours = d.inHours;
    final int mins = d.inMinutes.remainder(60);

    if (hours > 0) {
      return "$hours ${hours == 1 ? "hr" : "hrs"}${mins > 0 ? " $mins ${mins == 1 ? "min" : "mins"}" : ''}";
    }

    return "$mins ${mins == 1 ? "min" : "mins"}";
  }

  Widget _buildPlayButton() => Container(
    width: double.infinity,
    height: 50,
    margin: const EdgeInsets.only(top: 30),
    child: ElevatedButton(
      onPressed: _playMovie,
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
            "Play",
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
          _movie = state.movies?.firstWhere((Movie movie) => movie.id == _movie.id, orElse: () => widget.movie) ?? widget.movie;
          _isFavorite = state.favoriteMovies?.any((Movie movie) => movie.id == _movie.id) ?? false;
        });
      }

      if (state.error != null) {
        showSnackBar(context, state.error!);
        context.read<AppBloc>().add(ClearError());
      }
    },
    builder: (BuildContext context, AppState state) {
      Movie? movie;

      try {
        movie = state.movies?.firstWhere((Movie movie) => movie.id == widget.movie.id, orElse: () => widget.movie);

        if (mounted && movie != null) {
          setState(() => _movie = movie!);
        }
      } catch (_) {}

      bool isMovieLoaded = movie != null;

      return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => Navigator.pop(context, "refresh"),
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
                    backdropPath: _movie.backdropPath,
                    trailerUrl: state.movieTrailers?[_movie.id.toString()],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        MediaInfo(
                          title: _movie.title,
                          subtitle: "${_movie.releaseDate.split("-")[0]} · ${_formatDuration(Duration(minutes: _movie.duration))}",
                          overview: _movie.overview,
                        ),
                        _buildPlayButton(),
                        _buildPersonCardHorizontalList(state.movieCast?[_movie.id.toString()]),
                        _buildMediaCardHorizontalList(
                          title: "Recommendations",
                          controller: state.movieRecommendationsPagingControllers?[_movie.id.toString()],
                        ),
                        _buildMediaCardHorizontalList(
                          title: "Similar",
                          controller: state.similarMoviesPagingControllers?[_movie.id.toString()],
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