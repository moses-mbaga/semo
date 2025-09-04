import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/models/genre.dart";
import "package:semo/services/tmdb_service.dart";
import "package:semo/utils/urls.dart";
import "package:semo/utils/aspect_ratios.dart";

class GenreCard extends StatefulWidget {
  const GenreCard({
    super.key,
    required this.genre,
    required this.mediaType,
    this.onTap,
  });

  final Genre genre;
  final MediaType mediaType;
  final VoidCallback? onTap;

  @override
  State<GenreCard> createState() => _GenreCardState();
}

class _GenreCardState extends State<GenreCard> {
  final TMDBService _tmdbService = TMDBService();

  late Genre _genre;
  Future<String?>? _backdropFuture;

  @override
  void initState() {
    super.initState();
    _genre = widget.genre;
    if (_genre.backdropPath == null || _genre.backdropPath!.isEmpty) {
      _backdropFuture = _tmdbService.getGenreBackdrop(widget.mediaType, _genre);
    }
  }

  Widget _buildCardContent(BuildContext context, {ImageProvider? imageProvider}) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final double totalHeight = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : MediaQuery.of(context).size.height * 0.22;
      final double reservedForName = (totalHeight * 0.16).clamp(28.0, 40.0).toDouble();
      final double imageHeight = (totalHeight - reservedForName).clamp(60.0, totalHeight).toDouble();
      final double width = imageHeight * AspectRatios.genreCardWidthOverHeight;

      return SizedBox(
        width: width,
        height: totalHeight,
        child: Column(
          children: <Widget>[
            Container(
              height: imageHeight,
              width: width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: imageProvider == null ? Theme.of(context).cardColor : null,
                image: imageProvider != null
                    ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                    : null,
              ),
              child: InkWell(
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: widget.onTap,
                child: imageProvider == null
                    ? const Center(
                        child: Icon(
                          Icons.image,
                          color: Colors.white54,
                          size: 48,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: width,
              child: Text(
                _genre.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _buildFallback(BuildContext context, {required Widget child}) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final double totalHeight = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : MediaQuery.of(context).size.height * 0.22;
      final double reservedForName = (totalHeight * 0.16).clamp(28.0, 40.0).toDouble();
      final double imageHeight = (totalHeight - reservedForName).clamp(60.0, totalHeight).toDouble();
      final double width = imageHeight * AspectRatios.genreCardWidthOverHeight;

      return SizedBox(
        width: width,
        height: totalHeight,
        child: Column(
          children: <Widget>[
            Container(
              height: imageHeight,
              width: width,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: widget.onTap,
                child: Center(child: child),
              ),
            ),
            const SizedBox(height: 6),
            const SizedBox(width: double.infinity),
          ],
        ),
      );
    },
  );

  Widget _buildImage(String url) => CachedNetworkImage(
    imageUrl: url,
    placeholder: (BuildContext context, String url) => _buildFallback(
      context,
      child: const CircularProgressIndicator(),
    ),
    imageBuilder: (BuildContext context, ImageProvider imageProvider) => _buildCardContent(
      context,
      imageProvider: imageProvider,
    ),
    errorWidget: (BuildContext context, String url, Object error) => _buildFallback(
      context,
      child: const Icon(Icons.error, color: Colors.white54),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_backdropFuture != null) {
      return FutureBuilder<String?>(
        future: _backdropFuture,
        builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildFallback(
              context,
              child: const CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
            return _buildFallback(
              context,
              child: const Icon(Icons.error, color: Colors.white54),
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _genre.backdropPath = snapshot.data;
                _backdropFuture = null;
              });
            }
          });

          return _buildImage("${Urls.getResponsiveImageUrl(context)}${snapshot.data}");
        },
      );
    }

    return _buildImage("${Urls.getResponsiveImageUrl(context)}${_genre.backdropPath}");
  }
}
