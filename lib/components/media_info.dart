import "package:animated_read_more_text/animated_read_more_text.dart";
import "package:flutter/material.dart";

class MediaInfo extends StatelessWidget {
  const MediaInfo({
    super.key,
    required this.title,
    required this.subtitle,
    this.overview,
    this.progressIndicator,
  });

  final String title;
  final String subtitle;
  final String? overview;
  final Widget? progressIndicator;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: double.infinity,
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white54,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          if (progressIndicator != null) progressIndicator!,
          if (overview != null && overview!.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 20),
              child: AnimatedReadMoreText(
                overview!,
                maxLines: 3,
                readMoreText: "Read more",
                readLessText: "Read less",
                textStyle: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white54,
                    ),
                buttonTextStyle: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
        ],
      );
}
