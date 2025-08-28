import "dart:async";

import "package:flutter/material.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:semo/components/media_card.dart";
import "package:semo/components/vertical_media_list.dart";
import "package:semo/models/movie.dart";
import "package:semo/models/tv_show.dart";
import "package:semo/screens/base_screen.dart";
import "package:semo/screens/movie_screen.dart";
import "package:semo/screens/tv_show_screen.dart";
import "package:semo/enums/media_type.dart";

class ViewAllScreen extends BaseScreen {
  const ViewAllScreen({
    super.key,
    required this.mediaType,
    required this.title,
    this.pagingController,
    this.items,
  }) : assert(
    (pagingController == null && items != null) || (pagingController != null && items == null),
    "Either pagingController or items must be provided.",
  );
  
  final MediaType mediaType;
  final String title;
  final PagingController<int, dynamic>? pagingController;
  final List<dynamic>? items;

  @override
  BaseScreenState<ViewAllScreen> createState() => _ViewAllScreenState();
}

class _ViewAllScreenState extends BaseScreenState<ViewAllScreen> {
  //ignore: avoid_annotating_with_dynamic
  Future<void> _navigateToMedia(dynamic media) async {
    if (widget.mediaType == MediaType.movies) {
      await navigate(MovieScreen(media as Movie));
    } else {
      await navigate(TvShowScreen(media as TvShow));
    }
  }

  Widget _buildGrid() => VerticalMediaList<dynamic>(
    pagingController: widget.pagingController,
    items: widget.items,
    //ignore: avoid_annotating_with_dynamic
    itemBuilder: (BuildContext context, dynamic media, int index) => MediaCard(
      media: media,
      mediaType: widget.mediaType,
      onTap: () => _navigateToMedia(media),
    ),
    crossAxisCount: 3,
    childAspectRatio: 0.5,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    padding: EdgeInsets.zero,
    emptyStateMessage: "No ${widget.mediaType.toString()} found",
    errorMessage: "Failed to load ${widget.mediaType.toString()}",
  );

  @override
  String get screenName => "View All - ${widget.title}";

  @override
  Widget buildContent(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: false,
    appBar: AppBar(
      title: Text(widget.title),
    ),
    body: SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 18,
        ),
        child: _buildGrid(),
      ),
    ),
  );
}