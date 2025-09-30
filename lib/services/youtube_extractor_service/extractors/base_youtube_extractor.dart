import "package:semo/models/media_stream.dart";

abstract class BaseYoutubeExtractor {
  Future<List<MediaStream>> extractStreams(String youtubeUrl);
}
