import "dart:async";
import "dart:collection";
import "dart:convert";
import "dart:io";
import "dart:math" as math;

import "package:background_fetch/background_fetch.dart";
import "package:device_info_plus/device_info_plus.dart";
import "package:dio/dio.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:logger/logger.dart";
import "package:mime/mime.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart";
import "package:permission_handler/permission_handler.dart";
import "package:semo/enums/download_status.dart";
import "package:semo/enums/download_type.dart";
import "package:semo/models/download_item.dart";
import "package:semo/models/download_metadata.dart";
import "package:semo/models/download_progress.dart";
import "package:shared_preferences/shared_preferences.dart";

class StreamDownloaderService {
  factory StreamDownloaderService() => _instance;

  StreamDownloaderService._internal();

  static final StreamDownloaderService _instance = StreamDownloaderService._internal();

  static const String _storageKey = "stream_downloader_items";
  static const String _progressKey = "stream_downloader_progress";
  static const int _maxConcurrentDownloads = 2;
  static const int _segmentConcurrency = 3;
  static const Duration _progressThrottle = Duration(seconds: 1);

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 1),
      sendTimeout: const Duration(minutes: 1),
      followRedirects: true,
      validateStatus: (int? status) => status != null && status < 500,
    ),
  );

  final Logger _logger = Logger();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final StreamController<DownloadProgress> _progressController = StreamController<DownloadProgress>.broadcast();
  final StreamController<List<DownloadItem>> _itemsController = StreamController<List<DownloadItem>>.broadcast();

  final Map<String, DownloadItem> _downloads = <String, DownloadItem>{};
  final Map<String, DownloadProgress> _progress = <String, DownloadProgress>{};
  final Map<String, DownloadMetadata> _metadataCache = <String, DownloadMetadata>{};
  final Map<String, DateTime> _metadataCacheExpiry = <String, DateTime>{};
  final Map<String, CancelToken> _cancelTokens = <String, CancelToken>{};
  final Set<String> _pausedDownloads = <String>{};
  final Queue<String> _queue = Queue<String>();

  SharedPreferences? _preferences;
  bool _initialized = false;
  bool _processingQueue = false;
  int _activeDownloadCount = 0;
  DateTime _lastProgressEmit = DateTime.fromMillisecondsSinceEpoch(0);

  Stream<DownloadProgress> get progressStream => _progressController.stream;

  Stream<List<DownloadItem>> get downloadsStream => _itemsController.stream;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _preferences = await SharedPreferences.getInstance();
    await _restoreState();
    await _configureNotifications();
    await _configureBackgroundFetch();
    await _requestInitialPermissions();

    _initialized = true;
  }

  Future<void> dispose() async {
    await _progressController.close();
    await _itemsController.close();
    _processingQueue = false;
  }

  Future<String> enqueueDownload({
    required String url,
    required String title,
    DownloadType? overrideType,
  }) async {
    await initialize();

    final DownloadMetadata metadata = await _inspectUrl(url);
    final DownloadType type = overrideType ?? _resolveDownloadType(url, metadata);
    final Directory downloadsDirectory = await _downloadsDirectory(type);

    final String id = _generateId(url, metadata);
    final String sanitizedTitle = _sanitizeFileName(title.isEmpty ? id : title);
    final String extension = _resolveFileExtension(type, metadata, url);
    final String outputPath = path.join(downloadsDirectory.path, "$sanitizedTitle$extension");

    final DownloadItem item = DownloadItem(
      id: id,
      title: title,
      url: url,
      type: type,
      createdAt: DateTime.now(),
      status: DownloadStatus.pending,
      localPath: outputPath,
      metadata: metadata,
      segmentUrls: <String>[],
      completedSegments: <int>{},
      chunkSize: 0,
      completedChunks: <int>{},
      supportsResume: metadata.acceptRanges,
    );

    final DownloadProgress progress = DownloadProgress.initial(id, title);

    _downloads[id] = item;
    _progress[id] = progress;
    _queue.add(id);

    await _persistState();
    _emitState();

    unawaited(_processQueue());
    return id;
  }

  Future<void> pauseDownload(String id) async {
    if (!_downloads.containsKey(id)) {
      return;
    }

    _pausedDownloads.add(id);
    final CancelToken? token = _cancelTokens[id];
    if (token != null && !token.isCancelled) {
      token.cancel("paused");
    }

    final DownloadItem item = _downloads[id]!;
    _downloads[id] = item.copyWith(status: DownloadStatus.paused);
    _progress[id] = _progress[id]!.copyWith(status: DownloadStatus.paused);
    await _persistState();
    _emitState(force: true);
  }

  Future<void> resumeDownload(String id) async {
    if (!_downloads.containsKey(id)) {
      return;
    }

    _pausedDownloads.remove(id);
    _downloads[id] = _downloads[id]!.copyWith(status: DownloadStatus.pending);
    _progress[id] = _progress[id]!.copyWith(status: DownloadStatus.pending);
    if (!_queue.contains(id)) {
      _queue.addFirst(id);
    }

    await _persistState();
    _emitState(force: true);
    unawaited(_processQueue());
  }

  Future<void> cancelDownload(String id) async {
    final DownloadItem? item = _downloads.remove(id);
    final DownloadProgress? progress = _progress.remove(id);
    _queue.remove(id);
    _pausedDownloads.remove(id);

    final CancelToken? token = _cancelTokens.remove(id);
    if (token != null && !token.isCancelled) {
      token.cancel("cancelled");
    }

    if (item != null) {
      await _cleanupDownloadArtifacts(item);
    }

    if (progress != null) {
      await _showFinalNotification(progress.copyWith(status: DownloadStatus.cancelled));
    }

    await _persistState();
    _emitState(force: true);
  }

  Future<void> retryDownload(String id) async {
    final DownloadItem? item = _downloads[id];
    if (item == null) {
      return;
    }

    _downloads[id] = item.copyWith(
      status: DownloadStatus.pending,
      completedSegments: <int>{},
      completedChunks: <int>{},
    );
    _progress[id] = DownloadProgress.initial(item.id, item.title);
    _queue.addFirst(id);

    await _cleanupDownloadArtifacts(item);
    await _persistState();
    _emitState(force: true);
    unawaited(_processQueue());
  }

  Future<void> registerBackgroundTask() async {
    await BackgroundFetch.scheduleTask(
      TaskConfig(
        taskId: "stream_downloader_refresh",
        delay: 15 * 60 * 1000,
        periodic: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        startOnBoot: true,
        enableHeadless: true,
        requiresNetworkConnectivity: true,
      ),
    );
  }

  Future<void> _processQueue() async {
    if (_processingQueue) {
      return;
    }
    _processingQueue = true;

    try {
      while (_queue.isNotEmpty) {
        if (_activeDownloadCount >= _maxConcurrentDownloads) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          continue;
        }

        final String id = _queue.removeFirst();
        if (!_downloads.containsKey(id)) {
          continue;
        }

        if (_pausedDownloads.contains(id)) {
          continue;
        }

        final DownloadItem item = _downloads[id]!;
        if (item.status == DownloadStatus.completed) {
          continue;
        }

        _activeDownloadCount++;
        unawaited(_startDownload(item).whenComplete(() {
          _activeDownloadCount = math.max(0, _activeDownloadCount - 1);
        }));
      }
    } finally {
      _processingQueue = false;
    }
  }

  Future<void> _startDownload(DownloadItem item) async {
    try {
      _downloads[item.id] = item.copyWith(status: DownloadStatus.downloading);
      _progress[item.id] = _progress[item.id]!.copyWith(status: DownloadStatus.downloading);
      _emitState();

      if (item.type == DownloadType.hlsStream || item.type == DownloadType.adaptiveStream) {
        await _handleHlsDownload(item);
      } else {
        await _handleDirectDownload(item);
      }

      if (_downloads[item.id]?.status == DownloadStatus.completed) {
        await _showFinalNotification(_progress[item.id]!);
      }
    } catch (error, stackTrace) {
      final DownloadItem? currentItem = _downloads[item.id];
      final bool isCancelledError = error is DioException && CancelToken.isCancel(error);
      final bool isCancelledType = error is DioException && error.type == DioExceptionType.cancel;
      final bool intentionalInterruption = isCancelledError || isCancelledType || currentItem == null || currentItem.status == DownloadStatus.paused || currentItem.status == DownloadStatus.cancelled || _pausedDownloads.contains(item.id);

      if (intentionalInterruption) {
        _logger.i(
          "Download interrupted",
          error: error,
          stackTrace: stackTrace,
        );
        return;
      }

      _logger.e("Failed download", error: error, stackTrace: stackTrace);
      _downloads[item.id] = item.copyWith(status: DownloadStatus.error);
      final DownloadProgress? currentProgress = _progress[item.id];
      if (currentProgress != null) {
        _progress[item.id] = currentProgress.copyWith(
          status: DownloadStatus.error,
          errorMessage: error.toString(),
        );
      }
      if (!_queue.contains(item.id)) {
        _queue.add(item.id);
      }
      if (_progress[item.id] != null) {
        await _showFinalNotification(_progress[item.id]!);
      }
    } finally {
      await _persistState();
      _emitState(force: true);
    }
  }

  Future<void> _handleHlsDownload(DownloadItem item) async {
    final CancelToken cancelToken = CancelToken();
    _cancelTokens[item.id] = cancelToken;

    final List<String> segments = item.segmentUrls.isNotEmpty ? item.segmentUrls : await _loadPlaylistSegments(item.url, item.metadata);
    final Directory tempDirectory = await _temporaryDirectory(item.id);

    final List<String> updatedSegments = List<String>.from(segments);
    _downloads[item.id] = item.copyWith(
      segmentUrls: updatedSegments,
      status: DownloadStatus.downloading,
    );

    int completedSegments = item.completedSegments.length;
    final int totalSegments = updatedSegments.length;
    int transferredBytes = _progress[item.id]?.transferredBytes ?? 0;

    for (int i = 0; i < updatedSegments.length; i += _segmentConcurrency) {
      if (cancelToken.isCancelled) {
        throw Exception("Download cancelled");
      }

      final int end = math.min(i + _segmentConcurrency, updatedSegments.length);
      final List<Future<int>> batch = <Future<int>>[];
      for (int j = i; j < end; j++) {
        if (_downloads[item.id]!.completedSegments.contains(j)) {
          continue;
        }
        batch.add(_downloadSegment(
          itemId: item.id,
          segmentUrl: updatedSegments[j],
          segmentIndex: j,
          tempDirectory: tempDirectory,
          cancelToken: cancelToken,
        ));
      }

      if (batch.isEmpty) {
        continue;
      }

      final List<int> results = await Future.wait(batch);
      for (final int bytes in results) {
        transferredBytes += bytes;
        completedSegments++;
        _progress[item.id] = _progress[item.id]!.copyWith(
          transferredBytes: transferredBytes,
          completedSegments: completedSegments,
          totalSegments: totalSegments,
          percentage: totalSegments == 0 ? 0 : (completedSegments / totalSegments) * 100,
        );
        _throttledProgressEmit(item.id);
      }
    }

    await _mergeSegments(item, tempDirectory, updatedSegments);

    _downloads[item.id] = _downloads[item.id]!.copyWith(status: DownloadStatus.completed);
    _progress[item.id] = _progress[item.id]!.copyWith(
      status: DownloadStatus.completed,
      percentage: 100,
      completedSegments: totalSegments,
      totalSegments: totalSegments,
    );

    _cancelTokens.remove(item.id);
  }

  Future<void> _handleDirectDownload(DownloadItem item) async {
    final CancelToken cancelToken = CancelToken();
    _cancelTokens[item.id] = cancelToken;

    final DownloadMetadata metadata = item.metadata;
    final int? contentLength = metadata.contentLength;

    if (contentLength != null && metadata.acceptRanges && contentLength > 0) {
      await _downloadInChunks(item, cancelToken, contentLength);
    } else {
      await _singleStreamDownload(item, cancelToken);
    }

    if (_downloads[item.id]?.status == DownloadStatus.downloading) {
      _downloads[item.id] = _downloads[item.id]!.copyWith(status: DownloadStatus.completed);
      _progress[item.id] = _progress[item.id]!.copyWith(
        status: DownloadStatus.completed,
        percentage: 100,
      );
    }

    _cancelTokens.remove(item.id);
  }

  Future<int> _downloadSegment({
    required String itemId,
    required String segmentUrl,
    required int segmentIndex,
    required Directory tempDirectory,
    required CancelToken cancelToken,
  }) async {
    final String fileName = "segment_$segmentIndex";
    final File file = File(path.join(tempDirectory.path, fileName));

    if (await file.exists()) {
      final int fileLength = await file.length();
      _downloads[itemId] = _downloads[itemId]!.copyWith(
        completedSegments: <int>{..._downloads[itemId]!.completedSegments, segmentIndex},
      );
      return fileLength;
    }

    final Response<ResponseBody> response = await _dio.get<ResponseBody>(
      segmentUrl,
      options: Options(responseType: ResponseType.stream),
      cancelToken: cancelToken,
    );

    final IOSink sink = file.openWrite();
    int received = 0;
    try {
      await for (final List<int> chunk in response.data!.stream) {
        received += chunk.length;
        sink.add(chunk);
      }
      await sink.flush();
    } catch (error) {
      await sink.close();
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }

    await sink.close();

    _downloads[itemId] = _downloads[itemId]!.copyWith(
      completedSegments: <int>{..._downloads[itemId]!.completedSegments, segmentIndex},
    );
    return received;
  }

  Future<void> _mergeSegments(DownloadItem item, Directory tempDirectory, List<String> segments) async {
    final File outputFile = File(item.localPath);
    if (await outputFile.exists()) {
      await outputFile.delete();
    }
    await outputFile.create(recursive: true);

    final IOSink outputSink = outputFile.openWrite(mode: FileMode.write);

    for (int i = 0; i < segments.length; i++) {
      final File segmentFile = File(path.join(tempDirectory.path, "segment_$i"));
      if (!await segmentFile.exists()) {
        throw Exception("Missing segment $i for ${item.id}");
      }

      await outputSink.addStream(segmentFile.openRead());
    }

    await outputSink.flush();
    await outputSink.close();

    await _cleanupTemporaryDirectory(tempDirectory);
  }

  Future<void> _downloadInChunks(DownloadItem item, CancelToken cancelToken, int contentLength) async {
    final File outputFile = File(item.localPath);
    if (!await outputFile.exists()) {
      await outputFile.create(recursive: true);
    }

    final int chunkSize = _determineChunkSize(contentLength);
    final int totalChunks = (contentLength / chunkSize).ceil();
    final Set<int> completedChunks = Set<int>.from(item.completedChunks);
    int downloadedBytes = _progress[item.id]?.transferredBytes ?? 0;

    final RandomAccessFile raf = await outputFile.open(mode: FileMode.write);

    try {
      for (int chunkIndex = 0; chunkIndex < totalChunks; chunkIndex += _segmentConcurrency) {
        final int end = math.min(chunkIndex + _segmentConcurrency, totalChunks);
        final List<Future<_ChunkResult>> batch = <Future<_ChunkResult>>[];
        for (int i = chunkIndex; i < end; i++) {
          if (completedChunks.contains(i)) {
            continue;
          }
          final int startByte = i * chunkSize;
          final int endByte = (i + 1) * chunkSize - 1;
          batch.add(_downloadChunk(
            item: item,
            cancelToken: cancelToken,
            start: startByte,
            end: endByte >= contentLength ? null : endByte,
            chunkIndex: i,
          ));
        }

        if (batch.isEmpty) {
          continue;
        }

        final List<_ChunkResult> results = await Future.wait(batch);
        for (final _ChunkResult result in results) {
          await raf.setPosition(result.start);
          await raf.writeFrom(result.bytes);
          completedChunks.add(result.index);
          downloadedBytes += result.bytes.length;
          if (contentLength > 0) {
            downloadedBytes = math.min(downloadedBytes, contentLength);
          }

          final double percentage = contentLength == 0 ? 0 : (downloadedBytes / contentLength) * 100;
          _progress[item.id] = _progress[item.id]!.copyWith(
            transferredBytes: downloadedBytes,
            totalBytes: contentLength,
            percentage: percentage > 100 ? 100 : percentage,
            completedSegments: completedChunks.length,
            totalSegments: totalChunks,
          );
          _downloads[item.id] = _downloads[item.id]!.copyWith(
            completedChunks: Set<int>.from(completedChunks),
            chunkSize: chunkSize,
          );
          _throttledProgressEmit(item.id);
        }
      }
    } finally {
      await raf.close();
    }
  }

  Future<_ChunkResult> _downloadChunk({
    required DownloadItem item,
    required CancelToken cancelToken,
    required int start,
    required int? end,
    required int chunkIndex,
  }) async {
    final Response<ResponseBody> response = await _dio.get<ResponseBody>(
      item.url,
      options: Options(
        responseType: ResponseType.stream,
        headers: <String, String>{
          "Range": end == null ? "bytes=$start-" : "bytes=$start-$end",
        },
      ),
      cancelToken: cancelToken,
    );

    final List<int> bytes = <int>[];
    int received = 0;
    final Stopwatch stopwatch = Stopwatch()..start();
    await for (final List<int> chunk in response.data!.stream) {
      received += chunk.length;
      bytes.addAll(chunk);
    }
    stopwatch.stop();

    final int elapsed = stopwatch.elapsedMilliseconds == 0 ? 1 : stopwatch.elapsedMilliseconds;
    final int speed = (received * 1000) ~/ elapsed;
    _progress[item.id] = _progress[item.id]!.copyWith(speedBytesPerSecond: speed);

    return _ChunkResult(index: chunkIndex, start: start, bytes: bytes);
  }

  Future<void> _singleStreamDownload(DownloadItem item, CancelToken cancelToken) async {
    final File outputFile = File(item.localPath);
    final IOSink sink = outputFile.openWrite(mode: FileMode.writeOnlyAppend);
    int received = await outputFile.exists() ? await outputFile.length() : 0;

    final Response<ResponseBody> response = await _dio.get<ResponseBody>(
      item.url,
      options: Options(responseType: ResponseType.stream),
      cancelToken: cancelToken,
    );

    final Stopwatch stopwatch = Stopwatch()..start();
    int lastEmitBytes = 0;
    try {
      await for (final List<int> chunk in response.data!.stream) {
        received += chunk.length;
        sink.add(chunk);
        final int elapsed = stopwatch.elapsedMilliseconds == 0 ? 1 : stopwatch.elapsedMilliseconds;
        final int speed = (received * 1000) ~/ elapsed;
        if (received - lastEmitBytes >= 512 * 1024) {
          _progress[item.id] = _progress[item.id]!.copyWith(
            transferredBytes: received,
            speedBytesPerSecond: speed,
          );
          _throttledProgressEmit(item.id);
          lastEmitBytes = received;
        }
      }
      await sink.flush();
      _progress[item.id] = _progress[item.id]!.copyWith(
        transferredBytes: received,
        totalBytes: received,
        percentage: 100,
      );
    } catch (error) {
      await sink.close();
      rethrow;
    }
    await sink.close();
  }

  Future<List<String>> _loadPlaylistSegments(String url, DownloadMetadata metadata) async {
    final Response<String> response = await _dio.get<String>(url);
    final String body = response.data ?? "";
    final List<String> lines = body.split(RegExp(r"\r?\n"));
    final bool isMaster = lines.any((String line) => line.startsWith("#EXT-X-STREAM-INF"));

    if (isMaster) {
      final Map<int, String> variants = <int, String>{};
      for (int i = 0; i < lines.length; i++) {
        final String line = lines[i];
        if (line.startsWith("#EXT-X-STREAM-INF")) {
          final String bandwidthValue = line.split(",").map((String entry) => entry.trim()).firstWhere(
                (String entry) => entry.startsWith("BANDWIDTH"),
                orElse: () => "",
              );
          final int bandwidth = int.tryParse(bandwidthValue.split("=").last) ?? 0;
          if (i + 1 < lines.length) {
            variants[bandwidth] = lines[i + 1];
          }
        }
      }

      final List<int> sortedBandwidths = variants.keys.toList()..sort();
      final int selectedBandwidth = sortedBandwidths.isNotEmpty ? sortedBandwidths.last : 0;
      final String? playlistPath = variants[selectedBandwidth];
      if (playlistPath == null) {
        throw Exception("Unable to resolve variant playlist");
      }
      final Uri resolved = Uri.parse(url).resolve(playlistPath.trim());
      final DownloadMetadata variantMetadata = DownloadMetadata(
        contentLength: metadata.contentLength,
        contentType: metadata.contentType,
        acceptRanges: metadata.acceptRanges,
        eTag: metadata.eTag,
        lastModified: metadata.lastModified,
        qualityLabel: selectedBandwidth.toString(),
      );
      return _loadPlaylistSegments(resolved.toString(), variantMetadata);
    }

    final List<String> segments = <String>[];
    for (final String line in lines) {
      final String trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith("#")) {
        continue;
      }
      final Uri resolved = Uri.parse(url).resolve(trimmed);
      segments.add(resolved.toString());
    }
    return segments;
  }

  DownloadType _resolveDownloadType(String url, DownloadMetadata metadata) {
    final String? mimeType = metadata.contentType ?? lookupMimeType(url);
    if (mimeType != null && mimeType.contains("mpegurl")) {
      return DownloadType.hlsStream;
    }
    if (url.toLowerCase().contains("m3u8")) {
      return DownloadType.hlsStream;
    }
    if (mimeType != null && mimeType.contains("mpd")) {
      return DownloadType.adaptiveStream;
    }
    return DownloadType.directFile;
  }

  Future<DownloadMetadata> _inspectUrl(String url) async {
    if (_metadataCache.containsKey(url)) {
      final DateTime? expiry = _metadataCacheExpiry[url];
      if (expiry != null && expiry.isAfter(DateTime.now())) {
        return _metadataCache[url]!;
      }
    }

    Response<void>? response;
    try {
      response = await _dio.head<void>(url);
    } catch (error) {
      _logger.w("HEAD request failed, fallback to GET metadata", error: error);
    }

    int? contentLength;
    String? contentType;
    bool acceptRanges = false;
    String? eTag;
    String? lastModified;

    if (response != null) {
      contentLength = int.tryParse(response.headers.value("content-length") ?? "");
      contentType = response.headers.value("content-type");
      acceptRanges = response.headers.value("accept-ranges") == "bytes";
      eTag = response.headers.value("etag");
      lastModified = response.headers.value("last-modified");
    }

    final DownloadMetadata metadata = DownloadMetadata(
      contentLength: contentLength,
      contentType: contentType,
      acceptRanges: acceptRanges,
      eTag: eTag,
      lastModified: lastModified,
      qualityLabel: null,
    );

    _metadataCache[url] = metadata;
    _metadataCacheExpiry[url] = DateTime.now().add(const Duration(minutes: 10));
    return metadata;
  }

  Future<void> _configureNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings("app_icon");
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notifications.initialize(settings);

    const AndroidNotificationChannel activeChannel = AndroidNotificationChannel(
      "downloads_active",
      "Active Downloads",
      description: "Notifications for ongoing downloads",
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    const AndroidNotificationChannel completeChannel = AndroidNotificationChannel(
      "downloads_complete",
      "Completed Downloads",
      description: "Notifications for completed downloads",
      importance: Importance.high,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(activeChannel);
      await androidPlugin.createNotificationChannel(completeChannel);
    }
  }

  Future<void> _configureBackgroundFetch() async {
    await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: true,
        startOnBoot: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiredNetworkType: NetworkType.ANY,
      ),
      (String taskId) async {
        await _processQueue();
        await BackgroundFetch.finish(taskId);
      },
      (String taskId) async {
        await BackgroundFetch.finish(taskId);
      },
    );
  }

  Future<void> _requestInitialPermissions() async {
    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        await Permission.notification.request();
      }
    }

    if (Platform.isIOS) {
      await Permission.notification.request();
    }

    if (Platform.isAndroid) {
      await Permission.storage.request();
    }
  }

  Future<void> _showFinalNotification(DownloadProgress progress) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      progress.status == DownloadStatus.completed ? "downloads_complete" : "downloads_active",
      progress.status == DownloadStatus.completed ? "Completed Downloads" : "Active Downloads",
      importance: Importance.high,
      priority: Priority.high,
      showProgress: false,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      progress.id.hashCode,
      progress.title,
      progress.status == DownloadStatus.completed ? "Download completed" : progress.errorMessage ?? "Download updated",
      details,
    );
  }

  Future<void> _emitProgressNotification(DownloadProgress progress) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      "downloads_active",
      "Active Downloads",
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      showProgress: true,
      maxProgress: 100,
      progress: math.max(0, math.min(100, progress.percentage.round())),
      channelShowBadge: false,
      playSound: false,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);
    final double kilobytesPerSecond = progress.speedBytesPerSecond / 1024;
    await _notifications.show(
      progress.id.hashCode,
      progress.title,
      "${progress.percentage.toStringAsFixed(1)}% • ${kilobytesPerSecond.toStringAsFixed(1)} KB/s",
      details,
    );
  }

  Future<void> _restoreState() async {
    final String? itemsJson = _preferences?.getString(_storageKey);
    final String? progressJson = _preferences?.getString(_progressKey);

    if (itemsJson != null) {
      final List<Object?> decoded = jsonDecode(itemsJson) as List<Object?>;
      for (final Object? entry in decoded) {
        if (entry is! Map<String, dynamic>) {
          continue;
        }
        final DownloadItem item = DownloadItem.fromJson(entry);
        _downloads[item.id] = item;
        if (item.status == DownloadStatus.downloading) {
          _downloads[item.id] = item.copyWith(status: DownloadStatus.paused);
          _queue.add(item.id);
        }
      }
    }

    if (progressJson != null) {
      final List<Object?> decoded = jsonDecode(progressJson) as List<Object?>;
      for (final Object? entry in decoded) {
        if (entry is! Map<String, dynamic>) {
          continue;
        }
        final DownloadProgress progress = DownloadProgress.fromJson(entry);
        if (_downloads.containsKey(progress.id)) {
          _progress[progress.id] = progress;
        }
      }
    }

    for (final String id in _downloads.keys) {
      _progress.putIfAbsent(id, () => DownloadProgress.initial(id, _downloads[id]!.title));
    }

    _emitState(force: true);
  }

  Future<void> _persistState() async {
    if (_preferences == null) {
      return;
    }

    final List<Map<String, dynamic>> items = _downloads.values.map((DownloadItem item) => item.toJson()).toList()
      ..sort(
        (Map<String, dynamic> a, Map<String, dynamic> b) => DateTime.parse(b["createdAt"] as String).compareTo(DateTime.parse(a["createdAt"] as String)),
      );

    final List<Map<String, dynamic>> progress = _progress.values.map((DownloadProgress element) => element.toJson()).toList();

    await _preferences!.setString(_storageKey, jsonEncode(items));
    await _preferences!.setString(_progressKey, jsonEncode(progress));
  }

  void _emitState({bool force = false}) {
    final DateTime now = DateTime.now();
    if (!force && now.difference(_lastProgressEmit) < _progressThrottle) {
      return;
    }
    _lastProgressEmit = now;
    _itemsController.add(_downloads.values.toList()..sort((DownloadItem a, DownloadItem b) => b.createdAt.compareTo(a.createdAt)));
    for (final DownloadProgress progress in _progress.values) {
      _progressController.add(progress);
    }
  }

  void _throttledProgressEmit(String id) {
    final DownloadProgress? progress = _progress[id];
    if (progress == null) {
      return;
    }
    unawaited(_emitProgressNotification(progress));
    _emitState();
    unawaited(_persistState());
  }

  Future<void> _cleanupDownloadArtifacts(DownloadItem item) async {
    final File file = File(item.localPath);
    if (await file.exists()) {
      await file.delete();
    }

    final Directory tempDir = await _temporaryDirectory(item.id);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }

  Future<void> _cleanupTemporaryDirectory(Directory directory) async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<Directory> _downloadsDirectory(DownloadType type) async {
    final Directory baseDirectory = await getApplicationDocumentsDirectory();
    final String folderName = type == DownloadType.hlsStream ? "hls" : "files";
    final Directory directory = Directory(path.join(baseDirectory.path, "downloads", folderName));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<Directory> _temporaryDirectory(String id) async {
    final Directory cacheDir = await getTemporaryDirectory();
    final Directory directory = Directory(path.join(cacheDir.path, "downloader", id));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  int _determineChunkSize(int length) {
    const int minChunk = 5 * 1024 * 1024;
    const int maxChunk = 15 * 1024 * 1024;
    final int suggested = length ~/ 8;
    final int normalized = suggested <= 0 ? minChunk : suggested;
    return math.max(minChunk, math.min(maxChunk, normalized));
  }

  String _generateId(String url, DownloadMetadata metadata) {
    final String base = base64Url.encode(utf8.encode(url));
    final int prefixLength = math.min(base.length, 12);
    final String suffix = metadata.eTag ?? metadata.lastModified ?? DateTime.now().millisecondsSinceEpoch.toString();
    return "dl_${base.substring(0, prefixLength)}_$suffix";
  }

  String _sanitizeFileName(String input) {
    final String sanitized = input.replaceAll(RegExp(r"[^a-zA-Z0-9_\- ]"), "_");
    return sanitized.trim().replaceAll(" ", "_");
  }

  String _resolveFileExtension(DownloadType type, DownloadMetadata metadata, String url) {
    if (type == DownloadType.hlsStream || type == DownloadType.adaptiveStream) {
      return ".mp4";
    }
    final String? mimeType = metadata.contentType ?? lookupMimeType(url);
    if (mimeType == null) {
      return ".mp4";
    }
    final String extension = extensionFromMime(mimeType);
    if (extension.isEmpty) {
      return ".mp4";
    }
    return ".${extension.toLowerCase()}";
  }
}

class _ChunkResult {
  _ChunkResult({
    required this.index,
    required this.start,
    required this.bytes,
  });

  final int index;
  final int start;
  final List<int> bytes;
}
