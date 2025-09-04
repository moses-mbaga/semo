import "package:flutter/material.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:semo/components/genre_card.dart";
import "package:semo/components/horizontal_media_list.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/genre.dart";
import "package:semo/screens/view_all_screen.dart";
import "package:semo/utils/navigation_helper.dart";

class GenresList extends StatelessWidget {
  const GenresList({
    super.key,
    required this.genres,
    required this.mediaPagingControllers,
    required this.mediaType,
  });

  final List<Genre> genres;
  final Map<String, PagingController<int, dynamic>> mediaPagingControllers;
  final MediaType mediaType;

  @override
  Widget build(BuildContext context) => HorizontalMediaList<Genre>(
    title: "Genres",
    items: genres,
    itemBuilder: (BuildContext context, Genre genre, int index) => Container(
      margin: EdgeInsets.only(
        right: index < genres.length - 1 ? 18 : 0,
      ),
      child: GenreCard(
        genre: genre,
        mediaType: mediaType,
        onTap: () => NavigationHelper.navigate(
          context,
          ViewAllScreen(
            title: genre.name,
            pagingController: mediaPagingControllers[genre.id.toString()]!,
            mediaType: mediaType,
          ),
        ),
      ),
    ),
  );
}
