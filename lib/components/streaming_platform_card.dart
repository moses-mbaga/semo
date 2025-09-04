import "package:flutter/material.dart";
import "package:semo/models/streaming_platform.dart";
import "package:semo/utils/aspect_ratios.dart";

class StreamingPlatformCard extends StatelessWidget {
  const StreamingPlatformCard({
    super.key,
    required this.platform,
    this.onTap,
  });

  final StreamingPlatform platform;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final double height = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : MediaQuery.of(context).size.height * 0.18;
      final double width = height * AspectRatios.platformCardWidthOverHeight;

      return SizedBox(
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Center(
                child: Image.asset(
                  platform.logoPath,
                  fit: BoxFit.contain,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
