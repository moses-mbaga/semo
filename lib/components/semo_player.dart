import "dart:async";

import "package:audio_video_progress_bar/audio_video_progress_bar.dart";
import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:just_audio/just_audio.dart";
import "package:logger/logger.dart";
import "package:semo/enums/subtitles_type.dart";
import "package:semo/models/media_progress.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/models/stream_audio.dart";
import "package:semo/enums/stream_type.dart";
import "package:semo/services/app_preferences_service.dart";
import "package:semo/models/stream_subtitles.dart";
import "package:semo/services/subtitles_service.dart";
import "package:semo/services/zip_to_vtt_service.dart";
import "package:semo/utils/string_extensions.dart";
import "package:video_player/video_player.dart";

typedef OnProgressCallback = void Function(Duration progress, Duration total);
typedef OnErrorCallback = void Function(Object? error);
typedef OnSeekCallback = Future<void> Function(Duration target);

class SemoPlayer extends StatefulWidget {
  const SemoPlayer({
    super.key,
    required this.streams,
    required this.title,
    this.subtitle,
    this.initialProgress = 0,
    this.onProgress,
    this.onError,
    this.onPlaybackComplete,
    this.onBack,
    this.showBackButton = true,
    this.autoPlay = true,
    this.autoHideControlsDelay = const Duration(seconds: 5),
  });

  final List<MediaStream> streams;
  final String title;
  final String? subtitle;
  final int initialProgress;
  final OnProgressCallback? onProgress;
  final OnErrorCallback? onError;
  final Function(int progressSeconds)? onPlaybackComplete;
  final Function(int progressSeconds)? onBack;
  final bool showBackButton;
  final bool autoPlay;
  final Duration autoHideControlsDelay;

  @override
  State<SemoPlayer> createState() => _SemoPlayerState();
}

class _SemoPlayerState extends State<SemoPlayer> with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  final AppPreferencesService _appPreferences = AppPreferencesService();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );
  final SubtitlesService _subtitlesService = SubtitlesService();
  final ZipToVttService _zipToVttService = ZipToVttService();
  MediaProgress _mediaProgress = const MediaProgress();
  late final int _seekDuration = _appPreferences.getSeekDuration();
  bool _isSeekedToInitialProgress = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _showSubtitles = false;
  String? _selectedSubtitleLanguageGroup;
  int _selectedSubtitleIndex = 0;
  late final AnimationController _scaleVideoAnimationController;
  Animation<double> _scaleVideoAnimation = const AlwaysStoppedAnimation<double>(1.0);
  late final AnimationController _leftRippleController;
  late final AnimationController _rightRippleController;
  late final Animation<double> _leftRippleScale;
  late final Animation<double> _rightRippleScale;
  late final Animation<double> _leftRippleOpacity;
  late final Animation<double> _rightRippleOpacity;
  bool _isZoomedIn = false;
  double _lastZoomGestureScale = 1.0;
  Timer? _hideControlsTimer;
  Timer? _progressTimer;
  static const double _eps = 1e-3;
  final Logger _logger = Logger();
  late List<MediaStream> _streams;
  int _activeStreamIndex = 0;
  bool _videoControllerInitialized = false;
  bool _isHandlingFailure = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<StreamAudio> _availableAudios = <StreamAudio>[];
  StreamAudio? _selectedAudio;
  bool _isSynchronizingAudio = false;
  bool _audioPlayerHasSource = false;

  MediaStream get _currentStream => _streams[_activeStreamIndex];

  @override
  void initState() {
    super.initState();
    _streams = List<MediaStream>.from(widget.streams);
    _scaleVideoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 125),
      vsync: this,
    );
    _leftRippleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _rightRippleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _leftRippleScale = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(
        parent: _leftRippleController,
        curve: Curves.easeOut,
      ),
    );
    _rightRippleScale = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(
        parent: _rightRippleController,
        curve: Curves.easeOut,
      ),
    );
    _leftRippleOpacity = Tween<double>(begin: 0.6, end: 0).animate(
      CurvedAnimation(
        parent: _leftRippleController,
        curve: Curves.easeOut,
      ),
    );
    _rightRippleOpacity = Tween<double>(begin: 0.6, end: 0).animate(
      CurvedAnimation(
        parent: _rightRippleController,
        curve: Curves.easeOut,
      ),
    );
    _leftRippleController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _leftRippleController.reset();
      }
    });
    _rightRippleController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _rightRippleController.reset();
      }
    });
    if (_streams.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onError?.call(Exception("No streams available")));
      return;
    }

    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant SemoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.streams, widget.streams)) {
      final List<MediaStream> updated = List<MediaStream>.from(widget.streams);

      if (updated.isEmpty) {
        _streams = updated;
        widget.onError?.call(Exception("No streams available"));
        return;
      }

      _streams = updated;

      if (_activeStreamIndex >= _streams.length) {
        _activeStreamIndex = 0;
      }

      if (mounted) {
        setState(() {});
      }

      unawaited(
        _initializePlayer(
          resumePosition: _mediaProgress.progress,
          autoPlayOverride: _isPlaying,
        ),
      );
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _progressTimer?.cancel();
    if (_videoControllerInitialized) {
      _videoController.removeListener(_playerListener);
      unawaited(_videoController.dispose());
    }
    _scaleVideoAnimationController.dispose();
    _leftRippleController.dispose();
    _rightRippleController.dispose();
    unawaited(_audioPlayer.dispose());
    super.dispose();
  }

  Future<void> _initializePlayer({Duration? resumePosition, bool? autoPlayOverride}) async {
    try {
      final MediaStream stream = _currentStream;
      final List<StreamAudio> streamAudios = List<StreamAudio>.from(stream.audios ?? <StreamAudio>[]);
      final StreamAudio? resolvedAudio = _resolveAudioSelection(streamAudios);
      final VideoPlayerController newController = VideoPlayerController.networkUrl(
        Uri.parse(stream.url),
        httpHeaders: stream.headers ?? <String, String>{},
        formatHint: stream.type == StreamType.hls ? VideoFormat.hls : VideoFormat.other,
        closedCaptionFile: null,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      try {
        await newController.initialize();
      } catch (e, s) {
        _logger.w("Failed to initialize stream", error: e, stackTrace: s);
        await newController.dispose();
        await _handleStreamFailure(errorTextConfiguration);
        return;
      }

      Duration? targetSeek;
      if (!_isSeekedToInitialProgress && widget.initialProgress > 0 && (resumePosition == null || resumePosition == Duration.zero)) {
        targetSeek = Duration(seconds: widget.initialProgress);
        _isSeekedToInitialProgress = true;
      } else if (resumePosition != null) {
        targetSeek = resumePosition;
      }

      if (targetSeek != null && targetSeek > Duration.zero) {
        await newController.seekTo(targetSeek);
      }

      final Duration targetAudioPosition = targetSeek ?? newController.value.position;

      await _prepareAudioForStream(
        stream: stream,
        audios: streamAudios,
        selection: resolvedAudio,
        targetPosition: targetAudioPosition,
      );

      await newController.setVolume(_audioPlayerHasSource ? 0 : 1);

      final bool shouldPlay = autoPlayOverride ?? (_videoControllerInitialized ? _isPlaying : widget.autoPlay);

      newController.addListener(_playerListener);

      final VideoPlayerController? oldController = _videoControllerInitialized ? _videoController : null;

      if (mounted) {
        setState(() {
          _videoController = newController;
          _videoControllerInitialized = true;
          _isPlaying = shouldPlay;
        });

        final double targetScale = _computeZoomInScale();
        _setTargetNativeScale(targetScale);
        _startHideControlsTimer();
        _ensureProgressTimer();
      }

      if (shouldPlay) {
        await _startPlayback();
      } else if (_audioPlayerHasSource) {
        await _audioPlayer.pause().catchError((_) {});
      }

      if (oldController != null) {
        oldController.removeListener(_playerListener);
        await oldController.pause().catchError((_) {});
        await oldController.dispose();
      }
    } catch (e, s) {
      _logger.w("Failed to initialize player", error: e, stackTrace: s);
      await _handleStreamFailure(e);
    }
  }

  void _ensureProgressTimer() {
    _progressTimer ??= Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _updateProgress();
      }
    });
  }

  Future<void> _prepareAudioForStream({
    required MediaStream stream,
    required List<StreamAudio> audios,
    required StreamAudio? selection,
    required Duration targetPosition,
  }) async {
    _availableAudios = audios;

    if (selection == null) {
      if (_audioPlayerHasSource) {
        try {
          await _audioPlayer.stop();
        } catch (e, s) {
          _logger.w("Failed to stop audio player", error: e, stackTrace: s);
        }
      }

      _audioPlayerHasSource = false;
      _selectedAudio = null;

      return;
    }

    final bool requiresNewSource = !_audioPlayerHasSource || _selectedAudio == null || _selectedAudio!.url != selection.url;

    try {
      if (requiresNewSource) {
        await _audioPlayer.setAudioSource(
          AudioSource.uri(
            Uri.parse(selection.url),
            headers: stream.headers,
          ),
        );
      }

      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      }

      await _audioPlayer.seek(targetPosition > Duration.zero ? targetPosition : Duration.zero);

      _selectedAudio = selection;
      _audioPlayerHasSource = true;
    } catch (e, s) {
      _logger.w("Failed to prepare audio stream", error: e, stackTrace: s);
      widget.onError?.call(e);
      _selectedAudio = null;
      _audioPlayerHasSource = false;

      try {
        await _audioPlayer.stop();
      } catch (_) {}
    }
  }

  Future<void> _startPlayback() async {
    try {
      if (_audioPlayerHasSource && _audioPlayer.playing) {
        await _audioPlayer.pause();
      }

      await _videoController.play();
    } catch (e, s) {
      _logger.w("Failed to start playback", error: e, stackTrace: s);
      widget.onError?.call(e);
    }
  }

  StreamAudio? _resolveAudioSelection(List<StreamAudio> audios) {
    if (audios.isEmpty) {
      return null;
    }

    if (_selectedAudio != null) {
      final StreamAudio? matched = _matchAudio(audios, _selectedAudio!);
      if (matched != null) {
        return matched;
      }
    }

    return _chooseInitialAudio(audios);
  }

  StreamAudio? _chooseInitialAudio(List<StreamAudio> audios) {
    if (audios.isEmpty) {
      return null;
    }

    final List<StreamAudio> defaultAudios = audios.where((StreamAudio audio) => audio.isDefault).toList();
    StreamAudio? englishAudio;

    for (final StreamAudio audio in audios) {
      if (_languageIsEnglish(audio.language)) {
        englishAudio = audio;
        break;
      }
    }
    final bool allNotDefaults = audios.every((StreamAudio audio) => !audio.isDefault);
    final bool hasEnglishDefault = defaultAudios.any((StreamAudio audio) => _languageIsEnglish(audio.language));

    if (englishAudio != null && (allNotDefaults || (defaultAudios.isNotEmpty && !hasEnglishDefault))) {
      return englishAudio;
    }

    if (englishAudio != null) {
      return englishAudio;
    }

    if (defaultAudios.isNotEmpty) {
      return defaultAudios.first;
    }

    return audios.first;
  }

  StreamAudio? _matchAudio(List<StreamAudio> audios, StreamAudio reference) {
    for (final StreamAudio candidate in audios) {
      if (candidate.url == reference.url) {
        return candidate;
      }
    }

    final String referenceLanguage = reference.language.normalize();

    for (final StreamAudio candidate in audios) {
      if (candidate.language.normalize() == referenceLanguage) {
        return candidate;
      }
    }

    return null;
  }

  bool _languageIsEnglish(String language) {
    final String normalized = language.normalize();
    if (normalized.isEmpty) {
      return false;
    }

    if (normalized == "en" || normalized == "eng" || normalized == "english") {
      return true;
    }

    if (normalized.startsWith("en-")) {
      return true;
    }

    return normalized.contains("english");
  }

  Future<void> _syncAudio(
    Duration videoPosition, {
    required bool isPlaying,
    required bool isBuffering,
  }) async {
    if (!_audioPlayerHasSource || _isSynchronizingAudio) {
      return;
    }

    _isSynchronizingAudio = true;
    try {
      final Duration audioPosition = _audioPlayer.position;
      final int positionDelta = (audioPosition.inMilliseconds - videoPosition.inMilliseconds).abs();

      if (positionDelta > 350) {
        await _audioPlayer.seek(videoPosition);
      }

      final bool shouldPlayAudio = isPlaying && !isBuffering;

      if (shouldPlayAudio && !_audioPlayer.playing) {
        await _audioPlayer.play();
      } else if (!shouldPlayAudio && _audioPlayer.playing) {
        await _audioPlayer.pause();
      }
    } catch (e, s) {
      _logger.w("Failed to synchronize audio", error: e, stackTrace: s);
    } finally {
      _isSynchronizingAudio = false;
    }
  }

  void _setTargetNativeScale(double newValue) {
    if (!newValue.isFinite) {
      return;
    }

    setState(() {
      _scaleVideoAnimation = Tween<double>(begin: 1.0, end: newValue).animate(
        CurvedAnimation(
          parent: _scaleVideoAnimationController,
          curve: Curves.easeInOut,
        ),
      );
    });
  }

  double _computeZoomInScale() {
    if (!_videoControllerInitialized) {
      return 1.0;
    }
    final Size screenSize = MediaQuery.of(context).size;
    final double videoAR = _videoController.value.aspectRatio;

    if (screenSize.height == 0 || videoAR <= 0 || !videoAR.isFinite) {
      return 1.0;
    }

    final double screenAR = screenSize.width / screenSize.height;
    return screenAR / videoAR;
  }

  Future<void> _playerListener() async {
    if (!_videoControllerInitialized) {
      return;
    }

    try {
      final VideoPlayerValue value = _videoController.value;
      final bool isPlaying = value.isPlaying;
      if (mounted) {
        setState(() => _isPlaying = isPlaying);
      }

      if (value.hasError) {
        await _handleStreamFailure(value.errorDescription);
        return;
      }

      Duration progress = value.position;
      Duration total = value.duration;
      Duration buffered = Duration.zero;
      final List<DurationRange> ranges = value.buffered;

      if (ranges.isNotEmpty) {
        // Find the range that contains the current position
        int activeRangeIndex = -1;

        for (int i = 0; i < ranges.length; i++) {
          final DurationRange range = ranges[i];

          if (progress >= range.start && progress <= range.end) {
            activeRangeIndex = i;
            break;
          }
        }

        if (activeRangeIndex == -1) {
          // No buffered range contains the playhead
          // Treat as no buffer ahead
          buffered = progress;
        } else {
          // Merge adjacent forward ranges so buffered reflects the full contiguous end
          Duration end = ranges[activeRangeIndex].end;
          const Duration epsilon = Duration(milliseconds: 200);

          for (int j = activeRangeIndex + 1; j < ranges.length; j++) {
            final DurationRange next = ranges[j];

            if (next.start <= end + epsilon) {
              if (next.end > end) {
                end = next.end;
              }
            } else {
              break;
            }
          }

          buffered = end;
        }

        // Clamp buffered within [progress, total]
        if (buffered < progress) {
          buffered = progress;
        }

        if (total > Duration.zero && buffered > total) {
          buffered = total;
        }
      }

      bool isBuffering = false;
      if (isPlaying && value.isBuffering && (progress == _mediaProgress.progress)) {
        isBuffering = true;
      }

      await _syncAudio(
        progress,
        isPlaying: isPlaying,
        isBuffering: value.isBuffering,
      );

      // Seek to initial progress if not done yet
      if (!_isSeekedToInitialProgress && total.inSeconds != 0 && progress.inSeconds < widget.initialProgress) {
        Duration initialProgress = Duration(seconds: widget.initialProgress);
        await seek(initialProgress);
        if (mounted) {
          setState(() => _isSeekedToInitialProgress = true);
        }
      }

      if (mounted) {
        setState(() {
          _mediaProgress = MediaProgress(
            progress: progress,
            total: total,
            buffered: buffered,
            isBuffering: isBuffering,
          );
        });
      }

      // Check if playback is complete
      if (total.inSeconds != 0 && progress == total) {
        widget.onPlaybackComplete?.call(progress.inSeconds);
      }
    } catch (e) {
      widget.onError?.call(e);
    }
  }

  Future<void> _handleStreamFailure(Object? error) async {
    if (_isHandlingFailure) {
      return;
    }

    _isHandlingFailure = true;
    try {
      final bool wasPlaying = _isPlaying;

      if (_videoControllerInitialized) {
        _videoController.removeListener(_playerListener);
        await _videoController.pause().catchError((_) {});
        await _videoController.dispose().catchError((_) {});
        _videoControllerInitialized = false;
      }

      if (_audioPlayerHasSource) {
        await _audioPlayer.stop().catchError((_) {});
        _audioPlayerHasSource = false;
        _selectedAudio = null;
      }

      _availableAudios = <StreamAudio>[];

      if (_streams.isNotEmpty) {
        _streams.removeAt(_activeStreamIndex);
      }

      if (_streams.isEmpty) {
        if (mounted) {
          setState(() {});
        }
        widget.onError?.call(error);
        return;
      }

      if (_activeStreamIndex >= _streams.length) {
        _activeStreamIndex = 0;
      }

      if (mounted) {
        setState(() {
          _selectedSubtitleLanguageGroup = null;
          _selectedSubtitleIndex = 0;
          _showSubtitles = false;
        });
      }

      await _initializePlayer(
        resumePosition: _mediaProgress.progress,
        autoPlayOverride: wasPlaying,
      );
    } finally {
      _isHandlingFailure = false;
    }
  }

  Future<void> _showQualitySelector() async {
    if (_streams.length <= 1) {
      return;
    }

    final int? selectedIndex = await showDialog<int>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: const Text("Select quality"),
        children: _streams.asMap().entries.map((MapEntry<int, MediaStream> entry) {
          final bool isActive = entry.key == _activeStreamIndex;
          return ListTile(
            title: Text(
              entry.value.quality,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: isActive ? Theme.of(context).primaryColor : Colors.white,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
            trailing: isActive
                ? Icon(
                    Icons.check,
                    color: Theme.of(context).primaryColor,
                  )
                : null,
            onTap: () => Navigator.pop(context, entry.key),
          );
        }).toList(),
      ),
    );

    if (selectedIndex == null || selectedIndex == _activeStreamIndex) {
      return;
    }

    final Duration resumePosition = _mediaProgress.progress;
    final bool wasPlaying = _videoControllerInitialized && _videoController.value.isPlaying;

    setState(() => _activeStreamIndex = selectedIndex);

    await _initializePlayer(
      resumePosition: resumePosition,
      autoPlayOverride: wasPlaying,
    );
  }

  Future<void> _showAudioSelector() async {
    if (_availableAudios.length <= 1) {
      return;
    }

    final int? selectedIndex = await showDialog<int>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: const Text("Select audio"),
        children: _availableAudios.asMap().entries.map((MapEntry<int, StreamAudio> entry) {
          final StreamAudio audio = entry.value;
          final bool isActive = _selectedAudio != null && audio.url == _selectedAudio!.url;

          return ListTile(
            title: Text(
              audio.language.toUpperCase(),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: isActive ? Theme.of(context).primaryColor : Colors.white,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
            trailing: isActive
                ? Icon(
                    Icons.check,
                    color: Theme.of(context).primaryColor,
                  )
                : null,
            onTap: () => Navigator.pop(context, entry.key),
          );
        }).toList(),
      ),
    );

    if (selectedIndex == null) {
      return;
    }

    final StreamAudio selected = _availableAudios[selectedIndex];

    if (_selectedAudio != null && selected.url == _selectedAudio!.url) {
      return;
    }

    await _changeAudioTrack(selected);
  }

  Future<void> _changeAudioTrack(StreamAudio audio) async {
    if (!_videoControllerInitialized) {
      return;
    }

    final bool wasPlaying = _isPlaying;
    final Duration currentPosition = _videoController.value.position;

    try {
      await _videoController.pause();

      if (_audioPlayerHasSource) {
        await _audioPlayer.pause();
      }

      await _prepareAudioForStream(
        stream: _currentStream,
        audios: _availableAudios,
        selection: audio,
        targetPosition: currentPosition,
      );

      await _videoController.setVolume(_audioPlayerHasSource ? 0 : 1);

      if (mounted) {
        setState(() {});
      }

      if (wasPlaying) {
        await _startPlayback();
      }
    } catch (e, s) {
      _logger.w("Failed to switch audio track", error: e, stackTrace: s);
      widget.onError?.call(e);
    }
  }

  void _updateProgress() {
    if (_videoController.value.isInitialized) {
      final Duration progress = _videoController.value.position;
      final Duration total = _videoController.value.duration;
      widget.onProgress?.call(progress, total);
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(widget.autoHideControlsDelay, () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() => _showControls = true);
    _startHideControlsTimer();
  }

  Future<void> playPause() async {
    if (!_videoControllerInitialized) {
      return;
    }
    try {
      if (_isPlaying) {
        final List<Future<void>> operations = <Future<void>>[_videoController.pause(), if (_audioPlayerHasSource) _audioPlayer.pause()];

        await Future.wait(operations);
      } else {
        if (_audioPlayerHasSource) {
          await _audioPlayer.seek(_videoController.value.position);
        }

        await _startPlayback();
      }
    } catch (e) {
      widget.onError?.call(e);
    }
  }

  Future<void> seekForward() async {
    if (!_videoControllerInitialized) {
      return;
    }
    try {
      Duration currentPosition = _videoController.value.position;
      Duration targetPosition = Duration(seconds: currentPosition.inSeconds + _seekDuration);
      await seek(targetPosition);
    } catch (e) {
      widget.onError?.call(e);
    }
  }

  Future<void> seekBack() async {
    if (!_videoControllerInitialized) {
      return;
    }
    try {
      Duration currentPosition = _videoController.value.position;
      int seekBackSeconds = currentPosition.inSeconds < _seekDuration ? currentPosition.inSeconds : _seekDuration;
      Duration targetPosition = Duration(
        seconds: currentPosition.inSeconds - seekBackSeconds,
      );
      await seek(targetPosition);
    } catch (e) {
      widget.onError?.call(e);
    }
  }

  Future<void> seek(Duration target) async {
    if (!_videoControllerInitialized) {
      return;
    }
    try {
      final List<Future<void>> operations = <Future<void>>[
        // Pause
        if (_isPlaying) _videoController.pause(),
        if (_audioPlayerHasSource && _audioPlayer.playing) _audioPlayer.pause(),

        // Seek
        _videoController.seekTo(target),
        if (_audioPlayerHasSource) _audioPlayer.seek(target)
      ];

      await Future.wait(operations);
      await _startPlayback();
    } catch (e) {
      widget.onError?.call(e);
    }
  }

  Future<ClosedCaptionFile> _createCaptionFile(String content) async => WebVTTCaptionFile(content);

  Future<void> _applySubtitle(StreamSubtitles subtitles, {required int indexInLanguage, required String language}) async {
    try {
      String? content;

      if (subtitles.type == SubtitlesType.webVtt || subtitles.type == SubtitlesType.srt) {
        final Response<String> response = await _dio.get<String>(
          subtitles.url,
          options: Options(responseType: ResponseType.plain),
        );

        if (response.statusCode == 200) {
          if (response.data != null && response.data!.isNotEmpty) {
            content = subtitles.type == SubtitlesType.webVtt ? response.data : _subtitlesService.srtToVtt(response.data!);
          }
        }
      } else if (subtitles.type == SubtitlesType.zip) {
        content = await _zipToVttService.extract(subtitles.url);
      }

      if (content != null) {
        await _videoController.setClosedCaptionFile(_createCaptionFile(content));

        setState(() {
          _selectedSubtitleLanguageGroup = language;
          _selectedSubtitleIndex = indexInLanguage;
          _showSubtitles = true;
        });
      }
    } catch (e, s) {
      _logger.w("Failed to apply subtitles", error: e, stackTrace: s);
    }
  }

  Map<String, List<StreamSubtitles>> _groupSubtitlesByLanguage(List<StreamSubtitles> subtitles) {
    final Map<String, List<StreamSubtitles>> grouped = <String, List<StreamSubtitles>>{};
    for (final StreamSubtitles t in subtitles) {
      final String key = t.language.toUpperCase();
      grouped.putIfAbsent(key, () => <StreamSubtitles>[]).add(t);
    }
    return grouped;
  }

  Future<void> _showSubtitleSelector() async {
    final List<StreamSubtitles> subtitles = _currentStream.subtitles ?? <StreamSubtitles>[];
    if (subtitles.isEmpty) {
      return;
    }

    final Map<String, List<StreamSubtitles>> byLanguage = _groupSubtitlesByLanguage(subtitles);
    final List<String> languages = byLanguage.keys.toList()..sort();

    // First: language selection
    final String? selectedLanguage = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: const Text("Select subtitle language"),
        children: languages.map((String language) {
          final bool selected = language == _selectedSubtitleLanguageGroup;

          return ListTile(
            onTap: () => Navigator.pop(context, language),
            title: Text(
              language,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: selected ? Theme.of(context).primaryColor : Colors.white,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          );
        }).toList(),
      ),
    );

    if (selectedLanguage == null || !mounted) {
      return;
    }

    // Second: subtitles selection within language
    final List<StreamSubtitles> languageSubtitles = byLanguage[selectedLanguage] ?? <StreamSubtitles>[];
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: Text("$selectedLanguage subtitles"),
        children: languageSubtitles.asMap().entries.map((MapEntry<int, StreamSubtitles> entry) {
          final int index = entry.key;
          final StreamSubtitles subtitles = entry.value;
          final bool isSelected = selectedLanguage == _selectedSubtitleLanguageGroup && index == _selectedSubtitleIndex;

          return ListTile(
            onTap: () async {
              await _applySubtitle(subtitles, indexInLanguage: index, language: selectedLanguage);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            title: Text(
              subtitles.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _handleTap() {
    if (_mediaProgress.total.inSeconds <= 0) {
      return;
    }

    if (_showControls) {
      setState(() => _showControls = false);
    } else {
      _showControlsTemporarily();
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (mounted) {
      _lastZoomGestureScale = details.scale;
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (_mediaProgress.total.inSeconds <= 0) {
      return;
    }

    final double targetScale = _computeZoomInScale();
    // Pinch in (<1.0) => zoom out (reverse) if currently zoomed-in
    if (_lastZoomGestureScale < 1.0 - _eps) {
      if (_isZoomedIn) {
        setState(() {
          _isZoomedIn = false;
          _scaleVideoAnimationController.reverse();
        });
      }
    }
    // Pinch out (>1.0) => zoom in (forward) only if zooming-in makes sense
    else if (_lastZoomGestureScale > 1.0 + _eps) {
      if (!_isZoomedIn && targetScale > 1.0 + _eps) {
        setState(() {
          _isZoomedIn = true;
          _scaleVideoAnimationController.forward();
        });
      }
    }

    _lastZoomGestureScale = 1.0;
  }

  void _triggerDoubleTapFeedback({required bool isLeftTap}) {
    if (isLeftTap) {
      _leftRippleController.forward(from: 0);
    } else {
      _rightRippleController.forward(from: 0);
    }
  }

  Future<void> _handleDoubleTap(TapDownDetails details) async {
    if (_mediaProgress.total.inSeconds > 0) {
      setState(() => _showControls = true);
      Timer(const Duration(seconds: 3), () {
        if (context.mounted && _isPlaying) {
          setState(() => _showControls = false);
        }
      });

      final Size? widgetSize = context.size;
      final double width = widgetSize?.width ?? MediaQuery.of(context).size.width;
      final bool isLeftTap = details.localPosition.dx < width / 2;
      _triggerDoubleTapFeedback(isLeftTap: isLeftTap);

      Timer(const Duration(milliseconds: 500), () async {
        if (context.mounted) {
          if (isLeftTap) {
            await seekBack();
          } else {
            await seekForward();
          }
        }
      });
    }
  }

  Widget _buildPlayer() {
    if (!_videoControllerInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return ScaleTransition(
      scale: _scaleVideoAnimation,
      child: Center(
        child: AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: <Widget>[
                VideoPlayer(_videoController),
                ClosedCaption(
                  text: _videoController.value.caption.text,
                  textStyle: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * .02,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() => AnimatedOpacity(
        opacity: _showControls ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
          child: Stack(
            children: <Widget>[
              // Top controls
              Positioned.fill(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: AppBar(
                      backgroundColor: Colors.transparent,
                      leading: widget.showBackButton
                          ? BackButton(
                              onPressed: () {
                                widget.onBack?.call(_mediaProgress.progress.inSeconds);
                              },
                            )
                          : null,
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontSize: 20,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.subtitle ?? "",
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        if (_streams.length > 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: IconButton(
                              onPressed: _showQualitySelector,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.hd_outlined, size: 20),
                            ),
                          ),
                        if (_availableAudios.length > 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: IconButton(
                              onPressed: _showAudioSelector,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.translate, size: 20),
                            ),
                          ),
                        if (_currentStream.subtitles?.isNotEmpty ?? false)
                          InkWell(
                            borderRadius: BorderRadius.circular(1000),
                            onTap: () async {
                              if (_showSubtitles) {
                                if (_isPlaying) {
                                  await _videoController.pause();
                                }

                                await _showSubtitleSelector();
                                await _videoController.play();
                              } else {
                                // Auto-pick EN if available otherwise first available
                                final List<StreamSubtitles> streamSubtitles = _currentStream.subtitles ?? <StreamSubtitles>[];
                                if (streamSubtitles.isNotEmpty) {
                                  final Map<String, List<StreamSubtitles>> grouped = _groupSubtitlesByLanguage(streamSubtitles);
                                  String language = grouped.containsKey("EN") ? "EN" : grouped.keys.first;
                                  final StreamSubtitles subtitles = grouped[language]!.first;
                                  await _applySubtitle(subtitles, indexInLanguage: 0, language: language);
                                }
                              }
                            },
                            onLongPress: () {
                              _videoController.setClosedCaptionFile(null);
                              setState(() => _showSubtitles = false);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(_showSubtitles ? Icons.closed_caption_rounded : Icons.closed_caption_off),
                            ),
                          ),
                        Builder(
                          builder: (BuildContext context) {
                            final bool canOperate = _mediaProgress.total.inSeconds > 0;
                            final double targetScale = _computeZoomInScale();
                            final bool canZoomIn = targetScale > 1.0 + _eps;
                            final VoidCallback? onPressed = !_isZoomedIn
                                ? (canOperate && canZoomIn
                                    ? () {
                                        // Only zoom in if targetScale would enlarge the video
                                        _scaleVideoAnimationController.forward();
                                        setState(() {
                                          _isZoomedIn = true;
                                          _lastZoomGestureScale = 1.0;
                                        });
                                      }
                                    : null)
                                : (canOperate
                                    ? () {
                                        _scaleVideoAnimationController.reverse();
                                        setState(() {
                                          _isZoomedIn = false;
                                          _lastZoomGestureScale = 1.0;
                                        });
                                      }
                                    : null);

                            return IconButton(
                              icon: Icon(!_isZoomedIn ? Icons.zoom_out_map : Icons.zoom_in_map),
                              onPressed: onPressed,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Center controls
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.rotateLeft,
                          color: Colors.white,
                          size: 25,
                        ),
                        onPressed: () => _mediaProgress.total.inSeconds > 0 ? seekBack() : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: !_mediaProgress.isBuffering
                            ? IconButton(
                                icon: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 42,
                                ),
                                onPressed: () => playPause(),
                              )
                            : const CircularProgressIndicator(),
                      ),
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.rotateRight,
                          color: Colors.white,
                          size: 25,
                        ),
                        onPressed: () => _mediaProgress.total.inSeconds > 0 ? seekForward() : null,
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom progress bar
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18).copyWith(top: 0),
                    child: SafeArea(
                      top: false,
                      bottom: false,
                      child: ProgressBar(
                        progress: _mediaProgress.progress,
                        buffered: _mediaProgress.buffered,
                        total: _mediaProgress.total,
                        progressBarColor: Theme.of(context).primaryColor,
                        baseBarColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                        bufferedBarColor: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                        thumbColor: Theme.of(context).primaryColor,
                        timeLabelTextStyle: Theme.of(context).textTheme.displaySmall,
                        timeLabelPadding: 10,
                        onSeek: (Duration target) => seek(target),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildDoubleTapFeedback() => Positioned.fill(
        child: IgnorePointer(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: _buildDoubleTapRipple(isLeft: true),
                ),
              ),
              Expanded(
                child: Center(
                  child: _buildDoubleTapRipple(isLeft: false),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildDoubleTapRipple({required bool isLeft}) {
    final AnimationController controller = isLeft ? _leftRippleController : _rightRippleController;
    final Animation<double> scaleAnimation = isLeft ? _leftRippleScale : _rightRippleScale;
    final Animation<double> opacityAnimation = isLeft ? _leftRippleOpacity : _rightRippleOpacity;

    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        if (controller.isDismissed) {
          return const SizedBox.shrink();
        }

        final double opacity = opacityAnimation.value.clamp(0.0, 1.0).toDouble();

        return Transform.scale(
          scale: scaleAnimation.value,
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: _buildDoubleTapIndicator(isLeft: isLeft),
    );
  }

  Widget _buildDoubleTapIndicator({required bool isLeft}) {
    final String label = "${isLeft ? "-" : "+"}${_seekDuration.abs()} s";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            isLeft ? Icons.fast_rewind_rounded : Icons.fast_forward_rounded,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_streams.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _handleTap,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      onDoubleTapDown: _handleDoubleTap,
      child: Stack(
        children: <Widget>[
          Container(color: Colors.black),
          _buildPlayer(),
          _buildControls(),
          _buildDoubleTapFeedback(),
        ],
      ),
    );
  }
}
