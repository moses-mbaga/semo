class DownloadMetadata {
  DownloadMetadata({
    required this.contentLength,
    required this.contentType,
    required this.acceptRanges,
    required this.eTag,
    required this.lastModified,
    required this.qualityLabel,
  });

  factory DownloadMetadata.fromJson(Map<String, dynamic> json) => DownloadMetadata(
        contentLength: json["contentLength"] as int?,
        contentType: json["contentType"] as String?,
        acceptRanges: json["acceptRanges"] as bool? ?? false,
        eTag: json["eTag"] as String?,
        lastModified: json["lastModified"] as String?,
        qualityLabel: json["qualityLabel"] as String?,
      );

  final int? contentLength;
  final String? contentType;
  final bool acceptRanges;
  final String? eTag;
  final String? lastModified;
  final String? qualityLabel;

  Map<String, dynamic> toJson() => <String, dynamic>{
        "contentLength": contentLength,
        "contentType": contentType,
        "acceptRanges": acceptRanges,
        "eTag": eTag,
        "lastModified": lastModified,
        "qualityLabel": qualityLabel,
      };
}
