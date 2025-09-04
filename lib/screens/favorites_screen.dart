import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:semo/bloc/app_bloc.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/bloc/app_state.dart";
import "package:semo/components/media_card.dart";
import "package:semo/components/snack_bar.dart";
import "package:semo/components/vertical_media_list.dart";
import "package:semo/models/movie.dart";
import "package:semo/models/tv_show.dart";
import "package:semo/screens/base_screen.dart";
import "package:semo/screens/movie_screen.dart";
import "package:semo/screens/tv_show_screen.dart";
import "package:semo/enums/media_type.dart";

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

    String posterPath = media.posterPath ?? "";
    double voteAverage = media.voteAverage ?? 0;

    return MediaCard(
      posterPath: posterPath,
      voteAverage: voteAverage,
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
            margin: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 18,
            ),
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
