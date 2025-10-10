import "dart:convert";

import "package:archive/archive.dart";
import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:logger/logger.dart";
import "package:path/path.dart" as path;
import "package:semo/services/subtitles_service.dart";

class ZipToVttService {
  factory ZipToVttService() => _instance;

  ZipToVttService._internal();

  static final ZipToVttService _instance = ZipToVttService._internal();

  final Logger _logger = Logger();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  final SubtitlesService _subtitlesService = SubtitlesService();
  static const Duration _cacheTtl = Duration(hours: 24);
  final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};

  Future<String?> extract(String zipUrl) async {
    final _CacheEntry? cached = _cache[zipUrl];
    if (cached != null && !_isExpired(cached.timestamp)) {
      return cached.value;
    }

    try {
      final Uint8List zipBytes = await _getZipBytes(zipUrl);
      final Archive archive = ZipDecoder().decodeBytes(zipBytes, verify: true);

      if (archive.files.isEmpty) {
        throw Exception("ZIP has no entries");
      }

      final ArchiveFile? vttFile = _findFirstByExtension(archive, ".vtt");
      final ArchiveFile? srtFile = _findFirstByExtension(archive, ".srt");

      final ArchiveFile? chosen = vttFile ?? srtFile;
      if (chosen == null) {
        throw Exception("No .srt or .vtt found in ZIP");
      }

      final String text = _decodeText(chosen);
      if (path.extension(chosen.name) == ".vtt") {
        _cache[zipUrl] = _CacheEntry(value: text, timestamp: DateTime.now());
        return text;
      }

      final String converted = _subtitlesService.srtToVtt(text);
      _cache[zipUrl] = _CacheEntry(value: converted, timestamp: DateTime.now());
      return converted;
    } catch (e, s) {
      _logger.w("Failed to extract WebVTT from ZIP", error: e, stackTrace: s);
    }

    _cache.remove(zipUrl);
    return null;
  }

  bool _isExpired(DateTime timestamp) => DateTime.now().difference(timestamp) > _cacheTtl;

  Future<Uint8List> _getZipBytes(String zipUrl) async {
    final Response<dynamic> zipResponse = await _dio.get<List<int>>(
      zipUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    if (zipResponse.statusCode == 200) {
      return Uint8List.fromList(zipResponse.data);
    }

    throw Exception("Failed to get ZIP bytes");
  }

  ArchiveFile? _findFirstByExtension(Archive archive, String extension) {
    for (final ArchiveFile file in archive) {
      if (file.isFile) {
        final String fileName = file.name;
        final String fileExtension = path.extension(fileName);

        if (fileExtension == extension) {
          return file;
        }
      }
    }

    return null;
  }

  String _decodeText(ArchiveFile file) {
    final List<int> data = _readFileBytes(file);
    try {
      return utf8.decode(data);
    } on FormatException {
      return latin1.decode(data);
    }
  }

  List<int> _readFileBytes(ArchiveFile file) {
    final Object initialContent = file.content;
    if (initialContent is List<int>) {
      return List<int>.from(initialContent);
    }

    if (initialContent is String) {
      return utf8.encode(initialContent);
    }

    file.decompress();
    final Object decompressed = file.content;
    if (decompressed is List<int>) {
      return List<int>.from(decompressed);
    }

    if (decompressed is String) {
      return utf8.encode(decompressed);
    }

    throw Exception("Unsupported archive entry encoding");
  }
}

class _CacheEntry {
  _CacheEntry({required this.value, required this.timestamp});

  final String value;
  final DateTime timestamp;
}
