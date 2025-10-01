import "package:dio/dio.dart";

class StreamProbeResult {
  StreamProbeResult({
    required this.isSuccessful,
    required this.matchedMime,
    required this.usedFallbackMime,
    this.statusCode,
    this.contentType,
    this.failureReason,
  });

  final bool isSuccessful;
  final bool matchedMime;
  final bool usedFallbackMime;
  final int? statusCode;
  final String? contentType;
  final String? failureReason;
}

class StreamProbe {
  StreamProbe({Dio? dio}) : _dio = dio ?? _createDefaultClient();

  final Dio _dio;

  static Dio _createDefaultClient() => Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

  Future<StreamProbeResult> probe(
    String url, {
    required List<String> expectedMimeTypePrefixes,
    bool allowOctetStreamFallback = true,
  }) async {
    Response<dynamic>? response = await _attemptHead(url);

    response ??= await _attemptRangeGet(url);

    if (response == null) {
      return StreamProbeResult(
        isSuccessful: false,
        matchedMime: false,
        usedFallbackMime: false,
        failureReason: "No response received",
      );
    }

    final int? statusCode = response.statusCode;
    if (statusCode == null || statusCode < 200 || statusCode >= 400) {
      return StreamProbeResult(
        isSuccessful: false,
        matchedMime: false,
        usedFallbackMime: false,
        statusCode: statusCode,
        contentType: response.headers.value(Headers.contentTypeHeader),
        failureReason: "Unexpected status code",
      );
    }

    final String? contentType = response.headers.value(Headers.contentTypeHeader);
    final bool mimeMatches = _matchesMime(contentType, expectedMimeTypePrefixes);
    final bool fallbackMatches = allowOctetStreamFallback && _isOctetStream(contentType);

    final bool isSuccessful = mimeMatches || fallbackMatches;

    return StreamProbeResult(
      isSuccessful: isSuccessful,
      matchedMime: mimeMatches,
      usedFallbackMime: fallbackMatches && !mimeMatches,
      statusCode: statusCode,
      contentType: contentType,
      failureReason: isSuccessful ? null : "Content type mismatch",
    );
  }

  Future<Response<dynamic>?> _attemptHead(String url) async {
    try {
      final Response<dynamic> response = await _dio.head<dynamic>(
        url,
        options: Options(
          followRedirects: true,
          validateStatus: (int? status) => status != null && status < 400,
        ),
      );
      return response;
    } on DioException catch (error) {
      if (error.response != null) {
        return error.response;
      }
    } catch (_) {
      // Ignore unexpected exceptions and fall back to range GET.
    }

    return null;
  }

  Future<Response<dynamic>?> _attemptRangeGet(String url) async {
    try {
      final Response<List<int>> response = await _dio.get<List<int>>(
        url,
        options: Options(
          followRedirects: true,
          responseType: ResponseType.bytes,
          headers: <String, String>{"Range": "bytes=0-0"},
          validateStatus: (int? status) => status != null && status < 400,
        ),
      );
      return response;
    } on DioException catch (error) {
      if (error.response != null) {
        return error.response;
      }
    } catch (_) {
      // Ignore unexpected exceptions.
    }

    return null;
  }

  bool _matchesMime(String? contentType, List<String> expectedPrefixes) {
    if (contentType == null || contentType.isEmpty) {
      return false;
    }

    final String lowerContentType = contentType.toLowerCase();
    for (final String prefix in expectedPrefixes) {
      if (lowerContentType.startsWith(prefix.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  bool _isOctetStream(String? contentType) {
    if (contentType == null) {
      return false;
    }

    return contentType.toLowerCase().startsWith("application/octet-stream");
  }
}
