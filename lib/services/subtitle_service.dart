import "dart:io";

import "package:archive/archive.dart";
import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:logger/logger.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart";
import "package:pretty_dio_logger/pretty_dio_logger.dart";
import "package:semo/utils/secrets.dart";
import "package:semo/utils/urls.dart";

class SubtitleService {
  factory SubtitleService() {
    if (!_instance._isDioLoggerInitialized) {
      _dio.interceptors.add(_dioLogger);
      _instance._isDioLoggerInitialized = true;
    }

    return _instance;
  }

  SubtitleService._internal();

  static final SubtitleService _instance = SubtitleService._internal();

  final Logger _logger = Logger();
  static final Dio _dio = Dio();
  static final PrettyDioLogger _dioLogger = PrettyDioLogger(
    requestHeader: true,
    requestBody: true,
    responseBody: true,
    responseHeader: false,
    error: true,
    compact: true,
    enabled: kDebugMode,
  );
  bool _isDioLoggerInitialized = false;

  Future<List<File>> getSubtitles(int tmdbId, {int? seasonNumber, int? episodeNumber, String? locale = "EN"}) async {
    try {
      final List<File> srtFiles = <File>[];
      final Directory directory = await getTemporaryDirectory();
      String destinationDirectoryPath = "${directory.path}/d/$locale";

      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }

      if (seasonNumber != null && episodeNumber != null) {
        destinationDirectoryPath = "${directory.path}/$tmdbId/$locale/$seasonNumber/$episodeNumber";
      }

      Directory destinationDirectory = Directory(destinationDirectoryPath);

      if (destinationDirectory.existsSync()) {
        List<FileSystemEntity> destinationDirectoryEntities = destinationDirectory.listSync();

        for (FileSystemEntity entity in destinationDirectoryEntities) {
          if (entity is File) {
            String fileExtension = path.extension(entity.path);

            if (fileExtension == ".srt") {
              srtFiles.add(entity);
            }
          }
        }
      }

      if (srtFiles.isNotEmpty) {
        return srtFiles;
      }

      final Map<String, dynamic> parameters = <String, dynamic>{
        "api_key": Secrets.subdlApiKey,
        "tmdb_id": "$tmdbId",
        "languages": locale,
        "subs_per_page": "5",
      };

      if (seasonNumber != null && episodeNumber != null) {
        parameters["season_number"] = "$seasonNumber";
        parameters["episode_number"] = "$episodeNumber";
      }

      // Ensure the logger is added
      // It could've been removed in a previous call
      if (!_dio.interceptors.contains(_dioLogger)) {
        _dio.interceptors.add(_dioLogger);
      }

      final Response<dynamic> response = await _dio.get(
        Urls.subtitles,
        queryParameters: parameters,
      );

      if (response.statusCode == 200) {
        final dynamic subtitlesData = response.data;
        final List<dynamic> subtitles = subtitlesData["subtitles"] as List<dynamic>;

        for (final dynamic subtitle in subtitles) {
          final String zipUrl = subtitle["url"] as String;
          final String fullZipUrl = Urls.subdlDownloadBase + zipUrl;

          // Remove the logger temporarily
          // To avoid logging binary data
          _dio.interceptors.removeWhere((Interceptor interceptor) => interceptor == _dioLogger);

          final Response<dynamic> zipResponse = await _dio.get<List<int>>(
            fullZipUrl,
            options: Options(responseType: ResponseType.bytes),
          );

          if (zipResponse.statusCode == 200) {
            final Uint8List bytes = Uint8List.fromList(zipResponse.data);
            final Archive archive = ZipDecoder().decodeBytes(bytes);

            for (final dynamic file in archive) {
              if (file.isFile && file.content != null) {
                final String fileName = file.name;
                final String extension = path.extension(fileName);

                if (extension == ".srt") {
                  final List<int> data = file.content as List<int>;
                  final File srtFile = File("$destinationDirectoryPath/$fileName");

                  await srtFile.create(recursive: true);
                  await srtFile.writeAsBytes(data);

                  srtFiles.add(srtFile);
                }
              }
            }
          }
        }
      }

      return srtFiles;
    } catch (e, s) {
      _logger.w("Error getting subtitles", error: e, stackTrace: s);
    }

    return <File>[];
  }
}