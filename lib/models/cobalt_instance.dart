class CobaltInstance {
  const CobaltInstance({
    required this.protocol,
    required this.apiHost,
  });

  final String protocol;
  final String apiHost;

  Uri get endpoint => Uri(
        scheme: protocol,
        host: apiHost,
        path: "/",
      );

  static CobaltInstance? fromJson(Map<String, dynamic> json) {
    final String? statusValue = json["status"] as String?;
    final String normalizedStatus = statusValue?.toLowerCase() ?? "";
    if (normalizedStatus != "good" && normalizedStatus != "perfect") {
      return null;
    }

    final Map<String, dynamic>? info = json["info"] as Map<String, dynamic>?;
    if (info != null && info["auth"] == true) {
      return null;
    }

    final Map<String, dynamic>? services = json["services"] as Map<String, dynamic>?;
    final Object? youtubeService = services != null ? services["youtube"] : null;
    if (youtubeService is! bool || !youtubeService) {
      return null;
    }

    final bool isOnline = json["online"] == true;
    if (!isOnline) {
      return null;
    }

    final String? protocol = json["protocol"] as String?;
    final String? api = json["api"] as String?;
    if (protocol == null || protocol.isEmpty || api == null || api.isEmpty) {
      return null;
    }

    return CobaltInstance(
      protocol: protocol,
      apiHost: api,
    );
  }
}
