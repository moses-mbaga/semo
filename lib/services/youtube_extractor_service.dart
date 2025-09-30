import "dart:io";
import "dart:math";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:logger/logger.dart";
import "package:pretty_dio_logger/pretty_dio_logger.dart";
import "package:semo/enums/stream_type.dart";
import "package:semo/models/cobalt_instance.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/models/stream_audio.dart";

class YoutubeExtractorService {
  factory YoutubeExtractorService() {
    if (!_instance._isDioLoggerInitialized) {
      _instance._dio.interceptors.add(_instance._dioLogger);
      _instance._isDioLoggerInitialized = true;
    }

    return _instance;
  }

  YoutubeExtractorService._internal();

  static final YoutubeExtractorService _instance = YoutubeExtractorService._internal();
  static const String _instancesUrl = "https://instances.cobalt.best/instances.json";
  static const List<String> _targetQualities = <String>["1080", "720", "480"];

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
  final Logger _logger = Logger();
  final Random _random = Random();

  Future<List<MediaStream>> getStreams(String youtubeUrl) async {
    final String trimmedUrl = youtubeUrl.trim();
    if (trimmedUrl.isEmpty) {
      return <MediaStream>[];
    }

    try {
      final List<CobaltInstance> instances = await _fetchInstances();
      if (instances.isEmpty) {
        return <MediaStream>[];
      }

      final List<MediaStream> streams = <MediaStream>[];

      for (final String quality in _targetQualities) {
        final CobaltInstance instance = _pickRandomInstance(instances);
        final MediaStream? stream = await _fetchStreamForQuality(
          instance: instance,
          youtubeUrl: trimmedUrl,
          quality: quality,
        );

        if (stream != null) {
          streams.add(stream);
        }
      }

      return streams;
    } catch (e, s) {
      _logger.e("Failed to retrieve YouTube streams", error: e, stackTrace: s);
    }

    return <MediaStream>[];
  }

  Future<List<CobaltInstance>> _fetchInstances() async {
    try {
      final Response<dynamic> response = await _dio.get(_instancesUrl);
      if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
        return <CobaltInstance>[];
      }

      if (response.data is! List<dynamic>) {
        return <CobaltInstance>[];
      }

      final List<dynamic> rawInstances = response.data as List<dynamic>;
      final List<CobaltInstance> instances = <CobaltInstance>[];

      for (final dynamic entry in rawInstances) {
        if (entry is! Map) {
          continue;
        }

        final CobaltInstance? instance = CobaltInstance.fromJson(entry.cast<String, dynamic>());
        if (instance != null) {
          instances.add(instance);
        }
      }

      return instances;
    } catch (e, s) {
      _logger.w("Failed to load cobalt instances", error: e, stackTrace: s);
    }

    return <CobaltInstance>[];
  }

  CobaltInstance _pickRandomInstance(List<CobaltInstance> instances) {
    if (instances.length == 1) {
      return instances.first;
    }

    final int index = _random.nextInt(instances.length);
    return instances[index];
  }

  Future<MediaStream?> _fetchStreamForQuality({
    required CobaltInstance instance,
    required String youtubeUrl,
    required String quality,
  }) async {
    final Uri endpoint = instance.endpoint;
    final Map<String, Object?> payload = <String, Object?>{
      "url": youtubeUrl,
      "videoQuality": quality,
      "disableMetadata": true,
      "localProcessing": "disabled",
      "youtubeHLS": true,
    };

    try {
      final Response<dynamic> response = await _dio.post(
        endpoint.toString(),
        data: payload,
        options: Options(
          headers: <String, String>{
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.contentTypeHeader: "application/json",
          },
        ),
      );

      if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
        return null;
      }

      if (response.data is! Map<String, dynamic>) {
        return null;
      }

      final Map<String, dynamic> data = (response.data as Map<dynamic, dynamic>).cast<String, dynamic>();

      return await _mapResponseToMediaStream(
        response: data,
        quality: quality,
      );
    } catch (e, s) {
      _logger.w("Failed to retrieve YouTube stream", error: e, stackTrace: s);
    }

    return null;
  }

  Future<MediaStream?> _mapResponseToMediaStream({required Map<String, dynamic> response, required String quality}) async {
    final String status = (response["status"] as String? ?? "").toLowerCase();
    if (status.isEmpty) {
      return null;
    }

    if (status == "tunnel" || status == "redirect") {
      final String url = (response["url"] as String? ?? "").trim();
      if (url.isEmpty) {
        return null;
      }

      // Delay a bit to allow remote processing to start
      await Future<void>.delayed(const Duration(seconds: 3));

      return MediaStream(
        type: StreamType.mp4,
        url: url,
        quality: "${quality}p",
      );
    }

    if (status == "local-processing") {
      final String type = (response["type"] as String? ?? "").toLowerCase();
      if (type != "merge") {
        return null;
      }

      final List<dynamic>? tunnels = response["tunnel"] as List<dynamic>?;
      if (tunnels == null || tunnels.length < 2) {
        return null;
      }

      final String videoUrl = (tunnels[0] as String? ?? "").trim();
      final String audioUrl = (tunnels[1] as String? ?? "").trim();
      if (videoUrl.isEmpty || audioUrl.isEmpty) {
        return null;
      }

      // Delay a bit to allow remote processing to start
      await Future<void>.delayed(const Duration(seconds: 3));

      return MediaStream(
        type: StreamType.mp4,
        url: videoUrl,
        quality: "${quality}p",
        audios: <StreamAudio>[
          StreamAudio(
            language: "Original",
            url: audioUrl,
            isDefault: false,
          ),
        ],
        hasDefaultAudio: false,
      );
    }

    return null;
  }
}
