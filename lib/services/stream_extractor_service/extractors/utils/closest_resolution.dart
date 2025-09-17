String getClosestResolutionFromDimensions(int width, int height) {
  final Map<String, List<int>> resolutions = <String, List<int>>{
    "4K": <int>[3840, 2160],
    "2K": <int>[2560, 1440],
    "1080p": <int>[1920, 1080],
    "720p": <int>[1280, 720],
    "480p": <int>[854, 480],
    "360p": <int>[640, 360],
    "240p": <int>[426, 240],
  };

  String closestName = "";
  double closestDistance = double.infinity;

  for (MapEntry<String, List<int>> resolution in resolutions.entries) {
    int w = resolution.value[0];
    int h = resolution.value[1];

    // Euclidean distance between resolutions
    double distance = ((width - w) * (width - w) + (height - h) * (height - h)).toDouble();

    if (distance < closestDistance) {
      closestDistance = distance;
      closestName = resolution.key;
    }
  }

  return closestName;
}

String getClosestResolutionFromBandwidth(int bandwidth) {
  final Map<String, int> resolutionBandwidths = <String, int>{
    "4K": 15000000, // ~15 Mbps
    "2K": 8000000, // ~8 Mbps
    "1080p": 5000000, // ~5 Mbps
    "720p": 2500000, // ~2.5 Mbps
    "480p": 1000000, // ~1 Mbps
    "360p": 750000, // ~0.75 Mbps
    "240p": 400000, // ~0.4 Mbps
  };

  String closestName = "";
  int closestDiff = 1 << 62; // large initial number

  for (MapEntry<String, int> resolution in resolutionBandwidths.entries) {
    int diff = (bandwidth - resolution.value).abs();

    if (diff < closestDiff) {
      closestDiff = diff;
      closestName = resolution.key;
    }
  }

  return closestName;
}
