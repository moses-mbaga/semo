import "package:flutter/material.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:index/components/horizontal_media_list.dart";
import "package:index/components/media_card.dart";
import "package:index/enums/media_type.dart";
import "package:index/screens/view_all_screen.dart";
import "package:index/utils/navigation_helper.dart";

class MediaCardHorizontalList extends StatelessWidget {
  const MediaCardHorizontalList({
    super.key,
    required this.title,
    required this.pagingController,
    required this.mediaType,
    required this.onTap,
  });

  final String title;
  final PagingController<int, dynamic> pagingController;
  final MediaType mediaType;
  //ignore: avoid_annotating_with_dynamic
  final Function(dynamic media) onTap;

  @override
  Widget build(BuildContext context) => HorizontalMediaList<dynamic>(
    title: title,
    pagingController: pagingController,
    //ignore: avoid_annotating_with_dynamic
    itemBuilder: (BuildContext context, dynamic media, int index) => Padding(
      padding: EdgeInsets.only(
        right: index < (pagingController.items?.length ?? 0) - 1 ? 18 : 0,
      ),
      child: MediaCard(
        media: media,
        mediaType: mediaType,
        onTap: () => onTap(media),
      ),
    ),
    onViewAllTap: () => NavigationHelper.navigate(
      context,
      ViewAllScreen(
        title: title,
        pagingController: pagingController,
        mediaType: mediaType,
      ),
    ),
  );
}
