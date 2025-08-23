import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:logger/logger.dart";
import "package:pretty_dio_logger/pretty_dio_logger.dart";

class StreamingServerBaseUrlExtractor {
  factory StreamingServerBaseUrlExtractor() {
    if (!_instance._isDioLoggerInitialized) {
      _instance._dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          enabled: kDebugMode,
        ),
      );

      _instance._isDioLoggerInitialized = true;
    }

    return _instance;
  }

  StreamingServerBaseUrlExtractor._internal();

  static final StreamingServerBaseUrlExtractor _instance = StreamingServerBaseUrlExtractor._internal();

  final String _configUrl = "https://himanshu8443.github.io/providers/modflix.json";
  final Duration _cacheExpireTime = const Duration(hours: 1);

  final Map<String, String> _cachedBaseUrls = <String, String>{};
  final Map<String, DateTime> _cacheTimestamps = <String, DateTime>{};

  final Logger _logger = Logger();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  bool _isDioLoggerInitialized = false;

  Future<String?> getBaseUrl(String serverKey) async {
    if (isCached(serverKey)) {
      return _cachedBaseUrls[serverKey]!;
    }

    try {
      final Response<dynamic> response = await _dio.get(_configUrl);

      if (response.statusCode != 200) {
        throw Exception("Failed to fetch base URL config: ${response.statusCode}");
      }

      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      final Map<String, dynamic>? serverData = data[serverKey] as Map<String, dynamic>?;

      if (serverData == null) {
        throw Exception("Provider data not found for: $serverKey");
      }

      final String? baseUrl = serverData["url"] as String?;

      if (baseUrl == null || baseUrl.isEmpty) {
        throw Exception("Base URL is empty for server: $serverKey");
      }

      // Cache the result
      _cachedBaseUrls[serverKey] = baseUrl;
      _cacheTimestamps[serverKey] = DateTime.now();

      return baseUrl;
    } catch (e, s) {
      _logger.e("Error fetching base URL for $serverKey", error: e, stackTrace: s);
    }

    return null;
  }

  void clearCache(String serverKey) {
    _cachedBaseUrls.remove(serverKey);
    _cacheTimestamps.remove(serverKey);
  }

  void clearAllCache() {
    _cachedBaseUrls.clear();
    _cacheTimestamps.clear();
  }

  bool isCached(String serverKey) => _cachedBaseUrls.containsKey(serverKey) &&
        _cacheTimestamps.containsKey(serverKey) &&
        DateTime.now().difference(_cacheTimestamps[serverKey]!).compareTo(_cacheExpireTime) < 0;

  Future<List<String>> getAvailableProviders() async {
    try {
      final Response<dynamic> response = await _dio.get(_configUrl);

      if (response.statusCode != 200) {
        throw Exception("Failed to fetch base URL config: ${response.statusCode}");
      }

      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      return data.keys.toList();
    } catch (e, s) {
      _logger.e("Error fetching available servers", error: e, stackTrace: s);
    }

    return <String>[];
  }
}