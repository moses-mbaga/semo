import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:semo/components/snack_bar.dart";
import "package:url_launcher/url_launcher.dart";
import "package:semo/utils/urls.dart";
import "package:semo/utils/aspect_ratios.dart";

class MediaPoster extends StatelessWidget {
  const MediaPoster({
    super.key,
    required this.backdropPath,
    this.trailerUrl,
    this.playTrailerText = "Play trailer",
    this.onPlayTrailer,
  });

  final String backdropPath;
  final String? trailerUrl;
  final String playTrailerText;
  final Future<void> Function()? onPlayTrailer;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size screen = MediaQuery.of(context).size;
          final double width = constraints.maxWidth.isFinite ? constraints.maxWidth : screen.width;
          final double ratio = AspectRatios.backdropWidthOverHeight(context);
          final double desiredHeight = width / ratio;

          // Ensure clamp bounds are ordered (min <= max)
          final double minBound = (screen.height * 0.4) < 160.0 ? (screen.height * 0.4) : 160.0;
          final double maxBound = (screen.height * 0.4) < 160.0 ? 160.0 : (screen.height * 0.4);
          final double height = desiredHeight.clamp(minBound, maxBound).toDouble();

          final String base = Urls.getResponsiveImageUrlForWidth(width);

          return CachedNetworkImage(
            imageUrl: base + backdropPath,
            placeholder: (BuildContext context, String url) => SizedBox(
              width: width,
              height: height,
              child: const Center(child: CircularProgressIndicator()),
            ),
            imageBuilder: (BuildContext context, ImageProvider image) => SizedBox(
              width: width,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: image,
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.play_arrow),
                          color: Colors.white,
                          onPressed: () async {
                            if (onPlayTrailer != null) {
                              await onPlayTrailer!();
                              return;
                            }

                            if (trailerUrl != null) {
                              await launchUrl(
                                Uri.parse(trailerUrl!),
                                mode: LaunchMode.externalNonBrowserApplication,
                              );
                            } else {
                              showSnackBar(context, "No trailer found");
                            }
                          },
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        child: Text(
                          playTrailerText,
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            errorWidget: (BuildContext context, String url, Object error) => SizedBox(
              width: width,
              height: height,
              child: const Icon(Icons.error),
            ),
          );
        },
      );
}
