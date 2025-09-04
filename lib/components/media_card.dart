import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:semo/utils/urls.dart";
import "package:semo/utils/aspect_ratios.dart";

class MediaCard extends StatelessWidget {
  const MediaCard({
    super.key,
    required this.posterPath,
    required this.voteAverage,
    this.onTap,
    this.showRemoveOption = false,
    this.onRemove,
    this.showHideOption = false,
    this.onHide,
  });

  final String posterPath;
  final double voteAverage;
  final VoidCallback? onTap;
  final bool showRemoveOption;
  final VoidCallback? onRemove;
  final bool showHideOption;
  final VoidCallback? onHide;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double height = constraints.maxHeight.isFinite ? constraints.maxHeight : MediaQuery.of(context).size.height * 0.22; // sensible fallback
          final double width = height * AspectRatios.posterWidthOverHeight;

          return SizedBox(
            width: width,
            height: height,
        child: CachedNetworkImage(
          imageUrl: "${Urls.getResponsiveImageUrlForWidth(width)}$posterPath",
              placeholder: (BuildContext context, String url) => Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Align(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(),
                ),
              ),
              imageBuilder: (BuildContext context, ImageProvider image) => Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: image,
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: InkWell(
                        customBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: onTap,
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 5,
                                    horizontal: 8,
                                  ),
                                  margin: const EdgeInsets.only(
                                    top: 5,
                                    right: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  child: Text(
                                    "$voteAverage",
                                    style: Theme.of(context).textTheme.displaySmall,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                    if ((showRemoveOption && onRemove != null) || (showHideOption && onHide != null))
                      Positioned(
                        top: 5,
                        left: 5,
                        child: PopupMenuButton<String>(
                          onSelected: (String action) {
                            if (action == "remove") {
                              onRemove!();
                            } else if (action == "hide") {
                              onHide!();
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            if (showHideOption && onHide != null)
                              PopupMenuItem<String>(
                                value: "hide",
                                child: Text(
                                  "Hide",
                                  style: Theme.of(context).textTheme.displaySmall,
                                ),
                              ),
                            if (showRemoveOption && onRemove != null)
                              PopupMenuItem<String>(
                                value: "remove",
                                child: Text(
                                  "Remove",
                                  style: Theme.of(context).textTheme.displaySmall,
                                ),
                              ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              errorWidget: (BuildContext context, String url, Object error) => Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.error,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          );
        },
      );
}
