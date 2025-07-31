import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:index/bloc/app_bloc.dart";
import "package:index/bloc/app_event.dart";
import "package:index/bloc/app_state.dart";
import "package:index/components/media_card.dart";
import "package:index/components/vertical_media_list.dart";
import "package:index/models/movie.dart";
import "package:index/models/person.dart";
import "package:index/models/tv_show.dart" ;
import "package:index/screens/base_screen.dart";
import "package:index/screens/movie_screen.dart";
import "package:index/screens/tv_show_screen.dart";
import "package:index/enums/media_type.dart";

class PersonMediaScreen extends BaseScreen {
  const PersonMediaScreen(this.person, {super.key});

  final Person person;

  @override
  BaseScreenState<PersonMediaScreen> createState() => _PersonMediaScreenState();
}

class _PersonMediaScreenState extends BaseScreenState<PersonMediaScreen> with TickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);
  MediaType _mediaType = MediaType.movies;
  bool _isLoading = true;

  void onTabChanged() {
    MediaType mediaType = _tabController.index == 0 ? MediaType.movies : MediaType.tvShows;
    setState(() => _mediaType = mediaType);
  }

  // ignore: avoid_annotating_with_dynamic
  Future<void> _navigateToMediaScreen(dynamic media, MediaType mediaType) async {
    if (mediaType == MediaType.movies) {
      await navigate(MovieScreen(media));
    } else if (mediaType == MediaType.tvShows) {
      await navigate(TvShowScreen(media));
    }
  }

  Widget _buildList(List<dynamic>? media, MediaType mediaType, {bool isLoading = false}) => VerticalMediaList<dynamic>(
    isLoading: isLoading,
    items: media ?? <dynamic>[],
    // ignore: avoid_annotating_with_dynamic
    itemBuilder: (BuildContext context, dynamic media, int index) => MediaCard(
      media: media,
      mediaType: mediaType,
      onTap: () => _navigateToMediaScreen(media, mediaType),
    ),
    crossAxisCount: 3,
    childAspectRatio: 0.5,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    emptyStateMessage: "No ${mediaType.toString()} found",
    errorMessage: "Failed to load ${mediaType.toString()}",
    shrinkWrap: true,
    physics: const AlwaysScrollableScrollPhysics(),
  );

  @override
  String get screenName => "${widget.person.name} - ${_mediaType.toString()}";

  @override
  Future<void> initializeScreen() async {
    _tabController.addListener(onTabChanged);
    context.read<AppBloc>().add(LoadPersonMedia(widget.person.id));
  }

  @override
  void handleDispose() {
    _tabController.removeListener(onTabChanged);
    _tabController.dispose();
  }

  @override
  Widget buildContent(BuildContext context) => BlocConsumer<AppBloc, AppState>(
    listener: (BuildContext context, AppState state) {
      if (mounted) {
        setState(() {
          _isLoading = state.isLoadingPersonMedia?[widget.person.id.toString()] ?? true;
        });
      }

      if (state.error != null) {
        context.read<AppBloc>().add(ClearError());
      }
    },
    builder: (BuildContext context, AppState state) {
      List<Movie> movies = state.personMovies?[widget.person.id.toString()] ?? <Movie>[];
      List<TvShow> tvShows = state.personTvShows?[widget.person.id.toString()] ?? <TvShow>[];
      bool isPersonMediaLoaded = movies.isNotEmpty && tvShows.isNotEmpty;

      if (mounted && isPersonMediaLoaded) {
         _isLoading = false;
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(widget.person.name),
          bottom: TabBar(
            controller: _tabController,
            tabs: const <Tab>[
              Tab(
                icon: Icon(Icons.movie),
                text: "Movies",
              ),
              Tab(
                icon: Icon(Icons.video_library),
                text: "TV Shows",
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Container(
            margin: const EdgeInsets.all(18),
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _buildList(
                  movies,
                  MediaType.movies,
                  isLoading: _isLoading,
                ),
                _buildList(
                  tvShows,
                  MediaType.tvShows,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}