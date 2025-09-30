Uri? _parseUri(String rawUrl) {
  final String trimmedUrl = rawUrl.trim();
  if (trimmedUrl.isEmpty) {
    return null;
  }

  try {
    Uri parsed = Uri.parse(trimmedUrl);
    if (parsed.scheme.isEmpty) {
      parsed = Uri.parse("https://$trimmedUrl");
    }

    return parsed;
  } catch (_) {
    return null;
  }
}

Uri? normalizeYouTubeUri(String youtubeUrl) {
  final Uri? parsedUri = _parseUri(youtubeUrl);
  if (parsedUri == null) {
    return null;
  }

  final String host = parsedUri.host.toLowerCase();
  final Map<String, String> queryParameters = Map<String, String>.from(parsedUri.queryParameters);

  if (host.contains("youtu.be")) {
    final String videoId = parsedUri.pathSegments.isNotEmpty ? parsedUri.pathSegments.first : "";
    if (videoId.isEmpty) {
      return null;
    }

    queryParameters.putIfAbsent("v", () => videoId);

    return Uri(
      scheme: "https",
      host: "www.youtube.com",
      path: "/watch",
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  if (parsedUri.pathSegments.isNotEmpty) {
    final String firstSegment = parsedUri.pathSegments.first;

    if (firstSegment == "embed" && parsedUri.pathSegments.length >= 2) {
      final String videoId = parsedUri.pathSegments[1];
      if (videoId.isEmpty) {
        return null;
      }

      queryParameters.putIfAbsent("v", () => videoId);

      return Uri(
        scheme: "https",
        host: "www.youtube.com",
        path: "/watch",
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );
    }

    if (firstSegment == "shorts" && parsedUri.pathSegments.length >= 2) {
      final String videoId = parsedUri.pathSegments[1];
      if (videoId.isEmpty) {
        return null;
      }

      queryParameters.putIfAbsent("v", () => videoId);

      return Uri(
        scheme: "https",
        host: "www.youtube.com",
        path: "/watch",
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );
    }
  }

  if (host.contains("youtube")) {
    final String path = parsedUri.path.isEmpty ? "/watch" : parsedUri.path;

    return Uri(
      scheme: "https",
      host: "www.youtube.com",
      path: path,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  return null;
}

String? extractYouTubeVideoId(Uri normalizedUri) {
  final String? id = normalizedUri.queryParameters["v"];
  if (id != null && id.isNotEmpty) {
    return id;
  }

  if (normalizedUri.pathSegments.isNotEmpty) {
    return normalizedUri.pathSegments.last;
  }

  return null;
}
