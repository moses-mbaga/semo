import "package:animated_read_more_text/animated_read_more_text.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:semo/models/episode.dart";
import "package:semo/utils/urls.dart";

class EpisodeCard extends StatelessWidget {
  const EpisodeCard({
    super.key,
    required this.episode,
    this.isRecentlyWatched = false,
    this.watchedProgress = 0,
    this.onTap,
    this.onMarkWatched,
    this.onRemoveFromWatched,
    this.isLoading = false,
    this.disabled = false,
  });

  final Episode episode;
  final bool isRecentlyWatched;
  final int watchedProgress;
  final VoidCallback? onTap;
  final VoidCallback? onMarkWatched;
  final VoidCallback? onRemoveFromWatched;
  final bool isLoading;
  final bool disabled;

  String _formatDuration(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return "$hours ${hours == 1 ? "hr" : "hrs"}${minutes > 0 ? " $minutes ${minutes == 1 ? "min" : "mins"}" : ''}";
    } else {
      return "$minutes ${minutes == 1 ? "min" : "mins"}";
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime airDate = DateTime.parse(episode.airDate ?? DateTime.now().toString());
    bool isAired = DateTime.now().isAfter(airDate);

    final double imageWidth = MediaQuery.of(context).size.width * 0.3;
    final BorderRadius borderRadius = BorderRadius.circular(10);
    final String? stillUrl = Urls.buildImageUrl(path: episode.stillPath, context: context);

    Widget buildPlaceholder(Widget child) => SizedBox(
          width: imageWidth,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Container(
                color: Theme.of(context).cardColor,
                child: child,
              ),
            ),
          ),
        );

    Widget buildLoadedImage(ImageProvider<Object> image) => SizedBox(
          width: imageWidth,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: image,
                    fit: BoxFit.cover,
                  ),
                ),
                child: isRecentlyWatched
                    ? Column(
                        children: <Widget>[
                          const Spacer(),
                          LinearProgressIndicator(
                            value: watchedProgress / (episode.duration * 60),
                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                            backgroundColor: Colors.transparent,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        );

    Widget buildErrorIcon() => buildPlaceholder(
          Align(
            alignment: Alignment.center,
            child: Icon(
              isAired ? Icons.image_not_supported : Icons.alarm,
              color: Colors.white54,
            ),
          ),
        );

    final Widget imageWidget = stillUrl == null
        ? buildErrorIcon()
        : CachedNetworkImage(
            imageUrl: stillUrl,
            placeholder: (BuildContext context, String url) => buildPlaceholder(
              const Align(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              ),
            ),
            imageBuilder: (BuildContext context, ImageProvider<Object> image) => buildLoadedImage(image),
            errorWidget: (BuildContext context, String url, Object error) => buildErrorIcon(),
          );

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: InkWell(
        onTap: (!isAired || disabled) ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  imageWidget,
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(left: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  episode.name,
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                  maxLines: 2,
                                ),
                              ),
                              if (isLoading)
                                Container(
                                  width: 18,
                                  height: 18,
                                  margin: const EdgeInsets.only(left: 8),
                                  child: const CircularProgressIndicator(strokeWidth: 2),
                                ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                          ),
                          if (episode.airDate != null)
                            Text(
                              episode.airDate!,
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white54, fontSize: 12),
                              maxLines: 1,
                            ),
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                          ),
                          Text(
                            isAired ? _formatDuration(Duration(minutes: episode.duration)) : "TBD",
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white54, fontSize: 12),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isAired)
                    PopupMenuButton<String>(
                      onSelected: (String value) {
                        switch (value) {
                          case "mark_watched":
                            onMarkWatched?.call();
                          case "delete_progress":
                            onRemoveFromWatched?.call();
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: "mark_watched",
                          child: Text(
                            "Mark as watched",
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                        ),
                        if (isRecentlyWatched)
                          PopupMenuItem<String>(
                            value: "delete_progress",
                            child: Text(
                              "Delete progress",
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              if (episode.overview.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10),
                  child: AnimatedReadMoreText(
                    episode.overview,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                    maxLines: 3,
                    trimExpandedText: " show less",
                    trimCollapsedText: " show more",
                    moreStyle: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                        ),
                    lessStyle: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                        ),
                  ),
                ),
              if (isAired)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: <Widget>[
                      ElevatedButton.icon(
                        onPressed: isLoading ? null : onMarkWatched,
                        icon: const Icon(Icons.check),
                        label: const Text("Mark watched"),
                      ),
                      if (isRecentlyWatched)
                        Container(
                          margin: const EdgeInsets.only(left: 10),
                          child: ElevatedButton.icon(
                            onPressed: isLoading ? null : onRemoveFromWatched,
                            icon: const Icon(Icons.delete),
                            label: const Text("Delete progress"),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
