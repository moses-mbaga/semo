import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:logger/logger.dart";
import "package:pretty_dio_logger/pretty_dio_logger.dart";
import "package:semo/services/secrets_service.dart";

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
  DateTime? _cacheTimestamp;

  static final Map<String, String> _manualBaseUrls = <String, String>{
    "semo_cinepro": SecretsService.cineProBaseUrl,
    "semo_vidfast": "https://vidfast.pro",
    "semo_vidlink": "https://vidlink.pro",
  };

  final Logger _logger = Logger();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  bool _isDioLoggerInitialized = false;

  Future<String?> getBaseUrl(String serverKey) async {
    await _ensureCache();
    if (_cachedBaseUrls.containsKey(serverKey)) {
      return _cachedBaseUrls[serverKey];
    }
    return null;
  }

  void clearAllCache() {
    _cachedBaseUrls.clear();
    _cacheTimestamp = null;
  }

  bool _isCacheValid() => _cachedBaseUrls.isNotEmpty && _cacheTimestamp != null && DateTime.now().difference(_cacheTimestamp!).compareTo(_cacheExpireTime) < 0;

  Future<void> _ensureCache() async {
    if (_isCacheValid()) {
      return;
    } else {
      clearAllCache();
    }

    try {
      final Response<dynamic> response = await _dio.get(_configUrl);
      if (response.statusCode != 200) {
        throw Exception("Failed to fetch base URL config: ${response.statusCode}");
      }

      final Map<String, dynamic> data = response.data as Map<String, dynamic>;

      // ignore: avoid_annotating_with_dynamic
      data.forEach((String key, dynamic value) {
        final String? url = value["url"] as String?;
        if (url != null && url.isNotEmpty) {
          _cachedBaseUrls[key] = url;
        }
      });

      _cachedBaseUrls.addAll(_manualBaseUrls);

      _cacheTimestamp = DateTime.now();
    } catch (e, s) {
      _logger.e("Error building base URL cache", error: e, stackTrace: s);
    }
  }
}
