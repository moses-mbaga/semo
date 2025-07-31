import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:index/models/episode.dart";
import "package:index/utils/urls.dart";

class EpisodeCard extends StatelessWidget {
  const EpisodeCard({
    super.key,
    required this.episode,
    this.onTap,
    this.onMarkWatched,
    this.onRemove,
  });
  
  final Episode episode;
  final VoidCallback? onTap;
  final VoidCallback? onMarkWatched;
  final VoidCallback? onRemove;

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
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              CachedNetworkImage(
                imageUrl: Urls.getResponsiveImageUrl(context) + episode.stillPath,
                placeholder: (BuildContext context, String url) => Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Align(
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
                imageBuilder: (BuildContext context, ImageProvider<Object> image) => Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: image,
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: episode.isRecentlyWatched ? Column(
                          children: <Widget>[
                            const Spacer(),
                            LinearProgressIndicator(
                              value: episode.watchedProgress! / (episode.duration * 60),
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                              backgroundColor: Colors.transparent,
                            ),
                          ],
                        ) : Container(),
                      ),
                    ),
                  ),
                ),
                errorWidget: (BuildContext context, String url, Object error) => Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10),
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
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        episode.name,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                      ),
                      Text(
                        _formatDuration(Duration(minutes: episode.duration)),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white54,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (String value) {
                  switch (value) {
                    case "mark_watched":
                      onMarkWatched?.call();
                    case "delete_progress":
                      onRemove?.call();
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
                  if (episode.isRecentlyWatched)
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
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 18),
            child: Text(
              episode.overview,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white54,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}