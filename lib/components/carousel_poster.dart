import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:index/utils/urls.dart";

class CarouselPoster extends StatelessWidget {
  const CarouselPoster({
    super.key,
    required this.backdropPath,
    required this.title,
    this.onTap,
  });
  
  final String backdropPath;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Stack(
      children: <Widget>[
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: "${Urls.getResponsiveImageUrl(context)}$backdropPath",
            fit: BoxFit.cover,
            placeholder: (BuildContext context, String url) => Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor),
              child: const Align(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (BuildContext context, String url, Object error) => Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor),
              child: const Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.error,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          top: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Theme.of(context).primaryColor,
                  Colors.transparent,
                  Theme.of(context).primaryColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            child: Column(
              children: <Widget>[
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    left: 14,
                    bottom: 8,
                  ),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(onTap: onTap),
          ),
        ),
      ],
    ),
  );
}