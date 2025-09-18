import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:logger/logger.dart";
import "package:pretty_dio_logger/pretty_dio_logger.dart";
import "package:semo/enums/subtitles_type.dart";
import "package:semo/models/stream_subtitles.dart";
import "package:semo/utils/urls.dart";

class SubtitlesService {
  factory SubtitlesService() {
    if (!_instance._isDioLoggerInitialized) {
      _instance._dio.interceptors.add(_instance._dioLogger);
      _instance._isDioLoggerInitialized = true;
    }

    return _instance;
  }

  SubtitlesService._internal();

  static final SubtitlesService _instance = SubtitlesService._internal();

  final Logger _logger = Logger();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  final PrettyDioLogger _dioLogger = PrettyDioLogger(
    requestHeader: true,
    requestBody: true,
    responseBody: false,
    responseHeader: false,
    error: true,
    compact: true,
    enabled: kDebugMode,
  );
  bool _isDioLoggerInitialized = false;

  Future<List<StreamSubtitles>> getSubtitles({
    required String imdbId,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    try {
      final List<StreamSubtitles> results = <StreamSubtitles>[];
      String sanitizedImdbId = imdbId.trim();
      if (sanitizedImdbId.isEmpty) {
        return results;
      }
      if (sanitizedImdbId.toLowerCase().startsWith("tt")) {
        sanitizedImdbId = sanitizedImdbId.substring(2);
      }
      if (sanitizedImdbId.isEmpty) {
        return results;
      }

      final Set<String> allowedLanguages = <String>{
        "EN",
        "FI",
        "ES",
        "FR",
        "DE",
        "PT",
        "IT",
        "RU",
        "AR",
        "TR",
        "HI",
        "ZH",
        "JA",
        "KO",
      };

      final String requestUrl = seasonNumber != null && episodeNumber != null
          ? Urls.getOpenSubtitlesEpisodeSearch(
              sanitizedImdbId,
              seasonNumber,
              episodeNumber,
            )
          : Urls.getOpenSubtitlesMovieSearch(sanitizedImdbId);

      if (!_dio.interceptors.contains(_dioLogger)) {
        _dio.interceptors.add(_dioLogger);
      }

      final Response<dynamic> response = await _dio.get(requestUrl);

      if (response.statusCode == 200 && response.data is List<dynamic>) {
        final List<dynamic> subtitles = response.data as List<dynamic>;
        final List<Map<String, dynamic>> filtered = <Map<String, dynamic>>[];

        for (final dynamic subtitle in subtitles) {
          if (subtitle is! Map<String, dynamic>) {
            continue;
          }

          final dynamic formatValue = subtitle["SubFormat"];
          final String format = formatValue == null ? "" : formatValue.toString().toLowerCase();
          if (format != "srt") {
            continue;
          }

          final String language = (subtitle["ISO639"] ?? "").toString().toUpperCase();
          if (language.isEmpty || !allowedLanguages.contains(language)) {
            continue;
          }

          final String zipUrl = (subtitle["ZipDownloadLink"] ?? "").toString();
          if (zipUrl.isEmpty) {
            continue;
          }

          final double score = subtitle["Score"] is num ? (subtitle["Score"] as num).toDouble() : double.tryParse(subtitle["Score"]?.toString() ?? "") ?? 0;

          filtered.add(<String, dynamic>{
            "language": language,
            "zipUrl": zipUrl,
            "score": score,
          });
        }

        filtered.sort(
          (Map<String, dynamic> a, Map<String, dynamic> b) => (b["score"] as double).compareTo(a["score"] as double),
        );

        for (int index = 0; index < filtered.length; index++) {
          final Map<String, dynamic> subtitle = filtered[index];
          final String zipUrl = subtitle["zipUrl"] as String;

          results.add(
            StreamSubtitles(
              name: "${index + 1}",
              language: subtitle["language"] as String,
              url: zipUrl,
              type: SubtitlesType.zip,
            ),
          );
        }
      }

      return results;
    } catch (e, s) {
      _logger.w("Error getting subtitles", error: e, stackTrace: s);
    }

    return <StreamSubtitles>[];
  }

  String srtToVtt(String srt) {
    final String normalized = srt.replaceAll("\r\n", "\n");
    final List<String> lines = normalized.split("\n");
    final RegExp timestampPattern = RegExp(
      r"^(\d{2}:\d{2}:\d{2}),(\d{3})\s-->\s(\d{2}:\d{2}:\d{2}),(\d{3})(.*)$",
    );
    final RegExp numericPattern = RegExp(r"^\d+$");

    final StringBuffer buffer = StringBuffer("WEBVTT\n\n");

    for (int index = 0; index < lines.length; index++) {
      String line = lines[index];

      if (numericPattern.hasMatch(line.trim())) {
        final bool nextIsTimestamp = index + 1 < lines.length && timestampPattern.hasMatch(lines[index + 1]);
        if (nextIsTimestamp) {
          continue;
        }
      }

      final RegExpMatch? match = timestampPattern.firstMatch(line);
      if (match != null) {
        final String tail = match.group(5) ?? "";
        line = "${match.group(1)}.${match.group(2)} --> ${match.group(3)}.${match.group(4)}$tail";
      }

      buffer.writeln(line);
    }

    return buffer.toString();
  }
}
