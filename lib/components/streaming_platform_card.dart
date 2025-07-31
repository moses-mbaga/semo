import "package:flutter/material.dart";
import "package:index/models/streaming_platform.dart";

class StreamingPlatformCard extends StatelessWidget {
  const StreamingPlatformCard({
    super.key,
    required this.platform,
    this.onTap,
  });

  final StreamingPlatform platform;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Container(
    height: double.infinity,
    decoration: BoxDecoration(
      color: Theme.of(context).primaryColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: InkWell(
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        child: Image.asset(
          platform.logoPath,
          width: MediaQuery.of(context).size.width * 0.4,
          color: Colors.white,
        ),
      ),
    ),
  );
}