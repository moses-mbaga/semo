import "dart:io";
import "dart:typed_data";

import "package:archive/archive.dart";
import "package:dio/dio.dart";
import "package:logger/logger.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart";
import "package:index/utils/secrets.dart";
import "package:index/utils/urls.dart";

class SubtitleService {
  factory SubtitleService() => _instance;
  SubtitleService._internal();

  static final SubtitleService _instance = SubtitleService._internal();

  final Logger _logger = Logger();

  Future<List<File>> getSubtitles(int tmdbId, {int? seasonNumber, int? episodeNumber}) async {
    try {
      final List<File> srtFiles = <File>[];

      final Map<String, dynamic> parameters = <String, dynamic>{
        "api_key": Secrets.subdlApiKey,
        "tmdb_id": "$tmdbId",
        "languages": "EN",
        "subs_per_page": "5",
      };

      if (seasonNumber != null) {
        parameters["season_number"] = "$seasonNumber";
      }
      if (episodeNumber != null) {
        parameters["episode_number"] = "$episodeNumber";
      }

      Dio dio = Dio();
      final Response<dynamic> response = await dio.get(Urls.subtitles, queryParameters: parameters);

      if (response.statusCode == 200) {
        final dynamic subtitlesData = response.data;
        final List<dynamic> subtitles = subtitlesData["subtitles"] as List<dynamic>;

        final Directory directory = await getTemporaryDirectory();
        final String destinationDirectory = directory.path;

        for (final dynamic subtitle in subtitles) {
          final String zipUrl = subtitle["url"] as String;
          final String fullZipUrl = Urls.subdlDownloadBase + zipUrl;

          final Response<dynamic> zipResponse = await dio.get<List<int>>(
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
                  final File srtFile = File("$destinationDirectory/$fileName");
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