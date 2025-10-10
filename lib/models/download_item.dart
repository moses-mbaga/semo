import "package:semo/enums/download_status.dart";
import "package:semo/enums/download_type.dart";
import "package:semo/models/download_metadata.dart";

class DownloadItem {
  DownloadItem({
    required this.id,
    required this.title,
    required this.url,
    required this.type,
    required this.createdAt,
    required this.status,
    required this.localPath,
    required this.metadata,
    required this.segmentUrls,
    required this.completedSegments,
    required this.chunkSize,
    required this.completedChunks,
    required this.supportsResume,
  });

  factory DownloadItem.fromJson(Map<String, dynamic> json) => DownloadItem(
        id: json["id"] as String,
        title: json["title"] as String,
        url: json["url"] as String,
        type: DownloadType.values.firstWhere(
          (DownloadType element) => element.name == json["type"],
          orElse: () => DownloadType.directFile,
        ),
        createdAt: DateTime.parse(json["createdAt"] as String),
        status: DownloadStatus.values.firstWhere(
          (DownloadStatus element) => element.name == json["status"],
          orElse: () => DownloadStatus.pending,
        ),
        localPath: json["localPath"] as String,
        metadata: DownloadMetadata.fromJson(
          (json["metadata"] as Map<String, dynamic>?) ?? <String, dynamic>{},
        ),
        segmentUrls: List<String>.from(
          json["segmentUrls"] as List<dynamic>? ?? <dynamic>[],
        ),
        completedSegments: (json["completedSegments"] as List<dynamic>? ?? <dynamic>[])
            .map((Object? value) => value as int)
            .toSet(),
        chunkSize: json["chunkSize"] as int? ?? 0,
        completedChunks: (json["completedChunks"] as List<dynamic>? ?? <dynamic>[])
            .map((Object? value) => value as int)
            .toSet(),
        supportsResume: json["supportsResume"] as bool? ?? false,
      );

  final String id;
  final String title;
  final String url;
  final DownloadType type;
  final DateTime createdAt;
  final DownloadStatus status;
  final String localPath;
  final DownloadMetadata metadata;
  final List<String> segmentUrls;
  final Set<int> completedSegments;
  final int chunkSize;
  final Set<int> completedChunks;
  final bool supportsResume;

  DownloadItem copyWith({
    DownloadStatus? status,
    List<String>? segmentUrls,
    Set<int>? completedSegments,
    int? chunkSize,
    Set<int>? completedChunks,
    bool? supportsResume,
    DownloadMetadata? metadata,
    String? localPath,
  }) =>
      DownloadItem(
        id: id,
        title: title,
        url: url,
        type: type,
        createdAt: createdAt,
        status: status ?? this.status,
        localPath: localPath ?? this.localPath,
        metadata: metadata ?? this.metadata,
        segmentUrls: segmentUrls ?? this.segmentUrls,
        completedSegments: completedSegments ?? this.completedSegments,
        chunkSize: chunkSize ?? this.chunkSize,
        completedChunks: completedChunks ?? this.completedChunks,
        supportsResume: supportsResume ?? this.supportsResume,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        "id": id,
        "title": title,
        "url": url,
        "type": type.name,
        "createdAt": createdAt.toIso8601String(),
        "status": status.name,
        "localPath": localPath,
        "metadata": metadata.toJson(),
        "segmentUrls": segmentUrls,
        "completedSegments": completedSegments.toList(),
        "chunkSize": chunkSize,
        "completedChunks": completedChunks.toList(),
        "supportsResume": supportsResume,
      };
}
