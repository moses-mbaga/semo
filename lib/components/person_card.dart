import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:index/models/person.dart";
import "package:index/utils/urls.dart";

class PersonCard extends StatelessWidget {
  const PersonCard({
    super.key,
    required this.person,
    this.onTap,
  });

  final Person person;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Expanded(
        child: CachedNetworkImage(
          imageUrl: "${Urls.image300}${person.profilePath}",
          placeholder: (BuildContext context, String url) => Container(
            width: MediaQuery.of(context).size.width * 0.4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Align(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            ),
          ),
          imageBuilder: (BuildContext context, ImageProvider image) => InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: onTap,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: image,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          errorWidget: (BuildContext context, String url, Object error) => Container(
            width: MediaQuery.of(context).size.width * 0.4,
            height: double.infinity,
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
      ),
      Container(
        width: MediaQuery.of(context).size.width * 0.4,
        margin: const EdgeInsets.only(top: 10),
        child: Text(
          person.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );
}