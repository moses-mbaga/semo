import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:index/bloc/app_bloc.dart";
import "package:index/bloc/app_event.dart";
import "package:index/bloc/app_state.dart";
import "package:index/components/media_card.dart";
import "package:index/components/snack_bar.dart";
import "package:index/components/vertical_media_list.dart";
import "package:index/models/movie.dart";
import "package:index/models/search_results.dart";
import "package:index/models/tv_show.dart";
import "package:index/screens/base_screen.dart";
import "package:index/screens/movie_screen.dart";
import "package:index/screens/tv_show_screen.dart";
import "package:index/services/tmdb_service.dart";
import "package:index/enums/media_type.dart";

class SearchScreen extends BaseScreen {
  const SearchScreen({
    super.key,
    required this.mediaType,
  }): super(shouldLogScreenView: false);

  final MediaType mediaType;

  @override
  BaseScreenState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends BaseScreenState<SearchScreen> {
  final TMDBService _tmdbService = TMDBService();
  bool _isSearched = false;
  final TextEditingController _searchController = TextEditingController();
  String _currentQuery = "";
  late final PagingController<int, dynamic> _searchPagingController = PagingController<int, dynamic>(
    getNextPageKey: (PagingState<int, dynamic> state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (int pageKey) async {
      if (_currentQuery.isEmpty) {
        return <dynamic>[];
      }

      final SearchResults result = widget.mediaType == MediaType.movies
          ? await _tmdbService.searchMovies(_currentQuery, pageKey)
          : await _tmdbService.searchTvShows(_currentQuery, pageKey);

      return widget.mediaType == MediaType.movies
          ? (result.movies ?? <Movie>[])
          : (result.tvShows ?? <TvShow>[]);
    },
  );

  void _submitSearch(String query) {
    if (query.trim().isEmpty) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    final String trimmedQuery = query.trim();

    setState(() {
      _searchController.text = trimmedQuery;
      _isSearched = true;
      _currentQuery = trimmedQuery;
    });

    context.read<AppBloc>().add(AddRecentSearch(trimmedQuery, widget.mediaType));

    _searchPagingController.refresh();
  }

  void _clearSearch() {
    setState(() {
      _isSearched = false;
      _currentQuery = "";
      _searchController.clear();
    });
    _searchPagingController.refresh();
  }

  //ignore: avoid_annotating_with_dynamic
  Future<void> _navigateToMediaScreen(dynamic media) async {
    if (widget.mediaType == MediaType.movies) {
      await navigate(MovieScreen(media as Movie));
    } else {
      await navigate(TvShowScreen(media as TvShow));
    }
  }

  AppBar _buildSearchAppBar() {
    List<Widget> actions = <Widget>[];
    
    if (_isSearched) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: _clearSearch,
        ),
      );
    }
    
    return AppBar(
      leading: BackButton(
        onPressed: () => Navigator.pop(context, "refresh"),
      ),
      title: TextField(
        controller: _searchController,
        readOnly: _isSearched,
        textInputAction: TextInputAction.search,
        cursorColor: Colors.white,
        style: Theme.of(context).textTheme.displayMedium,
        decoration: InputDecoration(
          hintText: "Type here...",
          hintStyle: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: Colors.white54,
          ),
          border: InputBorder.none,
        ),
        onTapOutside: (PointerDownEvent event) => FocusManager.instance.primaryFocus?.unfocus(),
        onSubmitted: (String query) => _submitSearch(query),
      ),
      actions: actions,
    );
  }

  Widget _buildRecentSearches(List<String>? recentSearches) {
    if (recentSearches == null || recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.search,
              size: 80,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            Text(
              "Search for ${widget.mediaType.toString()}",
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.white54,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: recentSearches.length,
      itemBuilder: (BuildContext context, int index) {
        final String query = recentSearches[index];
        return ListTile(
          leading: const Icon(
            Icons.history,
            color: Colors.white54,
          ),
          title: Text(
            query,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          trailing: IconButton(
            icon: const Icon(
              Icons.close,
              color: Colors.white54,
            ),
            onPressed: () => context.read<AppBloc>().add(RemoveRecentSearch(query, widget.mediaType)),
          ),
          onTap: () => _submitSearch(query),
        );
      },
    );
  }

  Widget _buildSearchResults() => VerticalMediaList<dynamic>(
    pagingController: _searchPagingController,
    //ignore: avoid_annotating_with_dynamic
    itemBuilder: (BuildContext context, dynamic media, int index) {
      if (widget.mediaType == MediaType.movies) {
        final Movie movie = media as Movie;
        return MediaCard(
          media: movie,
          mediaType: MediaType.movies,
          onTap: () => _navigateToMediaScreen(movie),
        );
      } else {
        final TvShow tvShow = media as TvShow;
        return MediaCard(
          media: tvShow,
          mediaType: MediaType.tvShows,
          onTap: () => _navigateToMediaScreen(tvShow),
        );
      }
    },
    crossAxisCount: 3,
    childAspectRatio: 0.5,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    emptyStateMessage: "No results found for $_currentQuery",
    errorMessage: "Failed to load search results",
    shrinkWrap: false,
    physics: const AlwaysScrollableScrollPhysics(),
  );

  @override
  String get screenName => "Search - ${widget.mediaType.toString()}";

  @override
  void handleDispose() {
    _searchController.dispose();
    _searchPagingController.dispose();
  }

  @override
  Widget buildContent(BuildContext context) => BlocConsumer<AppBloc, AppState>(
    listener: (BuildContext context, AppState state) {
      if (state.error != null) {
        showSnackBar(context, state.error!);
        context.read<AppBloc>().add(ClearError());
      }
    },
    builder: (BuildContext context, AppState state) {
      List<String>? recentSearches = widget.mediaType == MediaType.movies
          ? state.moviesRecentSearches
          : state.tvShowsRecentSearches;

      return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: _buildSearchAppBar(),
        body: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(18),
            child: _isSearched ? _buildSearchResults() : _buildRecentSearches(recentSearches),
          ),
        ),
      );
    },
  );
}