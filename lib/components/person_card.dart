import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:semo/models/person.dart";
import "package:semo/utils/urls.dart";
import "package:semo/utils/aspect_ratios.dart";

class PersonCard extends StatelessWidget {
  const PersonCard({
    super.key,
    required this.person,
    this.onTap,
  });

  final Person person;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double totalHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height * 0.22; // fallback like lists
          final double reservedForName = (totalHeight * 0.16).clamp(28.0, 40.0).toDouble();
          final double imageHeight = (totalHeight - reservedForName).clamp(60.0, totalHeight).toDouble();
          final double width = imageHeight * AspectRatios.posterWidthOverHeight;

          return SizedBox(
            width: width,
            height: totalHeight,
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: imageHeight,
                  width: width,
                  child: _buildProfileImage(context, width, imageHeight),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: width,
                  child: Text(
                    person.name,
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

  Widget _buildProfileImage(BuildContext context, double width, double imageHeight) {
    final String? imageUrl = Urls.buildImageUrl(path: person.profilePath, width: width);

    Widget buildContainer({Widget? child}) => Container(
          width: width,
          height: imageHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: onTap,
            child: child ??
                const Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.white54,
                  ),
                ),
          ),
        );

    if (imageUrl == null) {
      return buildContainer();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      placeholder: (BuildContext context, String url) => buildContainer(
        const Align(
          alignment: Alignment.center,
          child: CircularProgressIndicator(),
        ),
      ),
      imageBuilder: (BuildContext context, ImageProvider<Object> image) => InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
        child: Container(
          width: width,
          height: imageHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: image,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      errorWidget: (BuildContext context, String url, Object error) => buildContainer(),
    );
  }
}
