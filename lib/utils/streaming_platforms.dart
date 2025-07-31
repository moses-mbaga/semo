import "package:index/gen/assets.gen.dart";
import "package:index/models/streaming_platform.dart";

final List<StreamingPlatform> streamingPlatforms = <StreamingPlatform>[
  StreamingPlatform(
    id: 8,
    logoPath: Assets.images.netflixLogo.path,
    name: "Netflix",
  ),
  StreamingPlatform(
    id: 9,
    logoPath: Assets.images.amazonPrimeVideoLogo.path,
    name: "Amazon Prime Video",
  ),
  StreamingPlatform(
    id: 2,
    logoPath: Assets.images.appleTvLogo.path,
    name: "Apple TV",
  ),
  StreamingPlatform(
    id: 337,
    logoPath: Assets.images.disneyPlusLogo.path,
    name: "Disney+",
  ),
  StreamingPlatform(
    id: 15,
    logoPath: Assets.images.huluLogo.path,
    name: "Hulu",
  ),
];