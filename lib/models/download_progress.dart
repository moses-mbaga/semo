import "package:semo/enums/download_status.dart";

class DownloadProgress {
  DownloadProgress({
    required this.id,
    required this.title,
    required this.percentage,
    required this.transferredBytes,
    required this.totalBytes,
    required this.speedBytesPerSecond,
    required this.status,
    required this.completedSegments,
    required this.totalSegments,
    required this.errorMessage,
    required this.estimatedTimeRemaining,
  });

  factory DownloadProgress.initial(String id, String title) => DownloadProgress(
        id: id,
        title: title,
        percentage: 0.0,
        transferredBytes: 0,
        totalBytes: 0,
        speedBytesPerSecond: 0,
        status: DownloadStatus.pending,
        completedSegments: 0,
        totalSegments: 0,
        errorMessage: null,
        estimatedTimeRemaining: null,
      );

  factory DownloadProgress.fromJson(Map<String, dynamic> json) => DownloadProgress(
        id: json["id"] as String,
        title: json["title"] as String,
        percentage: (json["percentage"] as num? ?? 0).toDouble(),
        transferredBytes: json["transferredBytes"] as int? ?? 0,
        totalBytes: json["totalBytes"] as int? ?? 0,
        speedBytesPerSecond: json["speedBytesPerSecond"] as int? ?? 0,
        status: DownloadStatus.values.firstWhere(
          (DownloadStatus element) => element.name == json["status"],
          orElse: () => DownloadStatus.pending,
        ),
        completedSegments: json["completedSegments"] as int? ?? 0,
        totalSegments: json["totalSegments"] as int? ?? 0,
        errorMessage: json["errorMessage"] as String?,
        estimatedTimeRemaining: json["estimatedTimeRemaining"] as int?,
      );

  final String id;
  final String title;
  final double percentage;
  final int transferredBytes;
  final int totalBytes;
  final int speedBytesPerSecond;
  final DownloadStatus status;
  final int completedSegments;
  final int totalSegments;
  final String? errorMessage;
  final int? estimatedTimeRemaining;

  DownloadProgress copyWith({
    double? percentage,
    int? transferredBytes,
    int? totalBytes,
    int? speedBytesPerSecond,
    DownloadStatus? status,
    int? completedSegments,
    int? totalSegments,
    String? errorMessage,
    int? estimatedTimeRemaining,
  }) =>
      DownloadProgress(
        id: id,
        title: title,
        percentage: percentage ?? this.percentage,
        transferredBytes: transferredBytes ?? this.transferredBytes,
        totalBytes: totalBytes ?? this.totalBytes,
        speedBytesPerSecond: speedBytesPerSecond ?? this.speedBytesPerSecond,
        status: status ?? this.status,
        completedSegments: completedSegments ?? this.completedSegments,
        totalSegments: totalSegments ?? this.totalSegments,
        errorMessage: errorMessage ?? this.errorMessage,
        estimatedTimeRemaining: estimatedTimeRemaining ?? this.estimatedTimeRemaining,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        "id": id,
        "title": title,
        "percentage": percentage,
        "transferredBytes": transferredBytes,
        "totalBytes": totalBytes,
        "speedBytesPerSecond": speedBytesPerSecond,
        "status": status.name,
        "completedSegments": completedSegments,
        "totalSegments": totalSegments,
        "errorMessage": errorMessage,
        "estimatedTimeRemaining": estimatedTimeRemaining,
      };
}
