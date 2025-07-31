import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:index/components/snack_bar.dart";
import "package:url_launcher/url_launcher.dart";
import "package:index/utils/urls.dart";

class MediaPoster extends StatelessWidget {
  const MediaPoster({
    super.key,
    required this.backdropPath,
    this.trailerUrl,
    this.playTrailerText = "Play trailer",
  });

  final String backdropPath;
  final String? trailerUrl;
  final String playTrailerText;

  @override
  Widget build(BuildContext context) => CachedNetworkImage(
    imageUrl: Urls.getResponsiveImageUrl(context) + backdropPath,
    placeholder: (BuildContext context, String url) => Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.width * 0.4,
      child: const Align(
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      ),
    ),
    imageBuilder: (BuildContext context, ImageProvider image) => Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.25,
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
    errorWidget: (BuildContext context, String url, Object error) => const Icon(Icons.error),
  );
}