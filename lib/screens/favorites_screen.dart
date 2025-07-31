import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:index/bloc/app_bloc.dart";
import "package:index/bloc/app_event.dart";
import "package:index/bloc/app_state.dart";
import "package:index/components/media_card.dart";
import "package:index/components/snack_bar.dart";
import "package:index/components/vertical_media_list.dart";
import "package:index/models/movie.dart";
import "package:index/models/tv_show.dart";
import "package:index/screens/base_screen.dart";
import "package:index/screens/movie_screen.dart";
import "package:index/screens/tv_show_screen.dart";
import "package:index/enums/media_type.dart";

class FavoritesScreen extends BaseScreen {
  const FavoritesScreen({
    super.key,
    required this.mediaType,
  });

  final MediaType mediaType;

  @override
  BaseScreenState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends BaseScreenState<FavoritesScreen> {
  //ignore: avoid_annotating_with_dynamic
  Widget _buildMediaCard(dynamic media, int index) {
    VoidCallback onTap;

    if (widget.mediaType == MediaType.movies) {
      onTap = () => navigate(MovieScreen(media as Movie));
    } else {
      onTap = () => navigate(TvShowScreen(media as TvShow));
    }

    return MediaCard(
      media: media,
      mediaType: widget.mediaType,
      onTap: onTap,
      showRemoveOption: true,
      onRemove: () {
        // Delay the removal to escape dispose error
        Timer(const Duration(milliseconds: 500), () {
          context.read<AppBloc>().add(
            RemoveFavorite(media, widget.mediaType),
          );
        });
      },
    );
  }

  @override
  String get screenName => "Favorites";

  @override
  Widget buildContent(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Container(
        margin: const EdgeInsets.all(18),
        child: BlocConsumer<AppBloc, AppState>(
          listener: (BuildContext context, AppState state) {
            if (state.error != null) {
              showSnackBar(context, state.error!);
              context.read<AppBloc>().add(ClearError());
            }
          },
          builder: (BuildContext context, AppState state) {
            List<dynamic> favorites = <dynamic>[];

            if (widget.mediaType == MediaType.movies) {
              favorites = state.favoriteMovies ?? <Movie>[];
            } else if (widget.mediaType == MediaType.tvShows) {
              favorites = state.favoriteTvShows ?? <TvShow>[];
            }

            return VerticalMediaList<dynamic>(
              isLoading: state.isLoadingFavorites,
              items: favorites,
              //ignore: avoid_annotating_with_dynamic
              itemBuilder: (BuildContext context, dynamic media, int index) => _buildMediaCard(media, index),
              crossAxisCount: 3,
              childAspectRatio: 0.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              emptyStateMessage: "You don't have any favorite ${widget.mediaType.toString()}",
              errorMessage: "Failed to load favorite ${widget.mediaType.toString()}",
              shrinkWrap: false,
              physics: const AlwaysScrollableScrollPhysics(),
            );
          },
        ),
      ),
    ),
  );
}