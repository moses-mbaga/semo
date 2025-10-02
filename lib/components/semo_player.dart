import "dart:async";
import "dart:math";

import "package:audio_video_progress_bar/audio_video_progress_bar.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:logger/logger.dart";
import "package:semo/enums/stream_type.dart";
import "package:semo/enums/subtitles_type.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/models/stream_audio.dart";
import "package:semo/services/app_preferences_service.dart";
import "package:semo/models/stream_subtitles.dart";
import "package:semo/services/streams_extractor_service/extractors/utils/closest_resolution.dart";
import "package:semo/services/subtitles_service.dart";
import "package:semo/services/zip_to_vtt_service.dart";
import "package:media_kit/media_kit.dart";
import "package:media_kit_video/media_kit_video.dart";

typedef OnProgressCallback = void Function(Duration progress, Duration total);
typedef OnErrorCallback = void Function(Object? error);

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
  late final Player _player;
  late final VideoController _videoController;
  final AppPreferencesService _appPreferences = AppPreferencesService();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );
  final SubtitlesService _subtitlesService = SubtitlesService();
  final ZipToVttService _zipToVttService = ZipToVttService();
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
  Timer? _stallMonitorTimer;
  static const double _eps = 1e-3;
  static const int _seekCompletionToleranceMs = 500;
  final Logger _logger = Logger();
  late List<MediaStream> _streams;
  int _activeStreamIndex = 0;
  bool _playerInitialized = false;
  bool _isHandlingFailure = false;
  final List<StreamSubscription<dynamic>> _subscriptions = <StreamSubscription<dynamic>>[];
  List<VideoTrack> _availableVideoTracks = <VideoTrack>[];
  VideoTrack? _selectedVideoTrack;
  List<AudioTrack> _availableAudioTracks = <AudioTrack>[];
  AudioTrack? _selectedAudioTrack;
  List<AudioTrack> _manualAudioTracks = <AudioTrack>[];
  final Map<String, StreamAudio> _manualAudioMetadata = <String, StreamAudio>{};
  Object? _pendingStreamFailure;
  Duration? _pendingSeekTarget;
  int? _pendingSeekDirection;
  bool _shouldResumeAfterSeek = false;
  DateTime? _lastSeekRetryTime;
  static const Duration _seekRetryInterval = Duration(milliseconds: 500);
  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;
  Duration _currentBuffered = Duration.zero;
  bool _isBuffering = false;
  DateTime? _playStartedAt;
  static const Duration _stallTimeout = Duration(seconds: 5);

  MediaStream get _currentStream => _streams[_activeStreamIndex];
  bool get _isCurrentStreamAdaptive => _streams.isNotEmpty && (_currentStream.type == StreamType.hls || _currentStream.type == StreamType.dash);
  bool get _hasMultipleQualityOptions => _isCurrentStreamAdaptive ? _availableVideoTracks.length > 1 : _streams.length > 1;
  bool get _requiresManualAudio => _manualAudioTracks.isNotEmpty && !_currentStream.hasDefaultAudio;
  bool get _supportsSeeking => _streams.isNotEmpty && _currentStream.type != StreamType.dash;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _streams = List<MediaStream>.from(widget.streams);
    _scaleVideoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 125),
      vsync: this,
    );
    _leftRippleController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _rightRippleController = AnimationController(
      duration: const Duration(seconds: 1),
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

    _attachPlayerListeners();
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
          resumePosition: _currentPosition,
          autoPlayOverride: _isPlaying,
        ),
      );
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _progressTimer?.cancel();
    _stallMonitorTimer?.cancel();
    for (final StreamSubscription<dynamic> subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_player.dispose());
    _scaleVideoAnimationController.dispose();
    _leftRippleController.dispose();
    _rightRippleController.dispose();
    super.dispose();
  }

  void _attachPlayerListeners() {
    _subscriptions.add(_player.stream.playing.listen(_handlePlayingChanged));
    _subscriptions.add(_player.stream.completed.listen((bool completed) {
      if (completed) {
        widget.onPlaybackComplete?.call(_currentPosition.inSeconds);
      }
    }));
    _subscriptions.add(_player.stream.position.listen(_handlePositionChanged));
    _subscriptions.add(_player.stream.duration.listen(_handleDurationChanged));
    _subscriptions.add(_player.stream.buffer.listen(_handleBufferChanged));
    _subscriptions.add(_player.stream.buffering.listen(_handleBufferingChanged));
    _subscriptions.add(_player.stream.tracks.listen(_handleTracksChanged));
    _subscriptions.add(_player.stream.track.listen(_handleTrackSelectionChanged));
    _subscriptions.add(_player.stream.error.listen((String error) {
      if (error.isNotEmpty) {
        unawaited(_handleStreamFailure(error));
      }
    }));
  }

  void _handlePlayingChanged(bool playing) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isPlaying = playing;
      if (!playing) {
        _showControls = true;
      }
    });

    if (playing) {
      _playStartedAt = DateTime.now();
      _startStallMonitor();
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
      _cancelStallMonitor();
    }
  }

  void _handlePositionChanged(Duration position) {
    _currentPosition = position;

    if (position > Duration.zero) {
      _cancelStallMonitor();
    }

    if (_pendingSeekTarget != null) {
      final Duration target = _pendingSeekTarget!;
      final int deltaMs = (position - target).inMilliseconds;
      final int? direction = _pendingSeekDirection;
      final bool hasReachedTarget = deltaMs.abs() <= _seekCompletionToleranceMs || (direction == 1 && deltaMs >= 0) || (direction == -1 && deltaMs <= 0);

      if (hasReachedTarget) {
        _clearPendingSeek();
      } else if (!_isBuffering) {
        final bool needsRetry;
        if (direction == -1) {
          needsRetry = deltaMs > _seekCompletionToleranceMs;
        } else {
          needsRetry = deltaMs < -_seekCompletionToleranceMs;
        }

        if (needsRetry) {
          final DateTime now = DateTime.now();
          if (_lastSeekRetryTime == null || now.difference(_lastSeekRetryTime!) >= _seekRetryInterval) {
            _lastSeekRetryTime = now;
            unawaited(_player.seek(target));
          }
        }
      }
    }

    _emitProgressUpdate();
  }

  void _handleDurationChanged(Duration duration) {
    _currentDuration = duration;
    _emitProgressUpdate();
  }

  void _handleBufferChanged(Duration buffered) {
    _currentBuffered = buffered;
    _emitProgressUpdate();
  }

  void _handleBufferingChanged(bool buffering) {
    if (!mounted) {
      _isBuffering = buffering;

      if (buffering) {
        _hideControlsTimer?.cancel();
        _showControls = true;
      }

      return;
    }

    setState(() {
      _isBuffering = buffering;

      if (buffering) {
        _hideControlsTimer?.cancel();
        _showControls = true;
      } else if (_isPlaying) {
        _startHideControlsTimer();
        if (_currentPosition <= Duration.zero) {
          _startStallMonitor();
        }
      }
    });

    _emitProgressUpdate();
  }

  void _handleTracksChanged(Tracks tracks) {
    final List<AudioTrack> audioTracks = tracks.audio.where((AudioTrack track) {
      if (track.uri) {
        return _manualAudioMetadata.containsKey(_audioTrackKey(track));
      }
      return track.id == "auto" || (track.title != null && track.title!.isNotEmpty) || (track.language != null && track.language!.isNotEmpty);
    }).toList();
    final Set<String> seenAudioTrackKeys = audioTracks.map(_audioTrackKey).toSet();

    for (final AudioTrack manualTrack in _manualAudioTracks) {
      final String key = _audioTrackKey(manualTrack);
      if (seenAudioTrackKeys.add(key)) {
        audioTracks.add(manualTrack);
      }
    }
    final bool isAdaptive = _isCurrentStreamAdaptive;
    final List<VideoTrack> videoTracks = isAdaptive ? _collectAdaptiveVideoTracks(tracks.video) : <VideoTrack>[];
    final VideoTrack currentVideoTrack = _player.state.track.video;

    if (!mounted) {
      return;
    }

    setState(() {
      _availableAudioTracks = audioTracks;
      if (!_availableAudioTracks.contains(_selectedAudioTrack)) {
        final AudioTrack currentAudioTrack = _player.state.track.audio;
        if (_availableAudioTracks.contains(currentAudioTrack)) {
          _selectedAudioTrack = currentAudioTrack;
        } else {
          final AudioTrack? defaultManualTrack = _defaultManualAudioTrack();
          if (defaultManualTrack != null) {
            _selectedAudioTrack = defaultManualTrack;
          } else if (_availableAudioTracks.isNotEmpty) {
            _selectedAudioTrack = _availableAudioTracks.first;
          } else {
            _selectedAudioTrack = currentAudioTrack;
          }
        }
      }

      if (isAdaptive) {
        _availableVideoTracks = videoTracks;
        if (videoTracks.contains(currentVideoTrack)) {
          _selectedVideoTrack = currentVideoTrack;
        } else if (_availableVideoTracks.isNotEmpty) {
          _selectedVideoTrack = _availableVideoTracks.first;
        } else {
          _selectedVideoTrack = currentVideoTrack;
        }
      } else {
        _availableVideoTracks = <VideoTrack>[];
        _selectedVideoTrack = null;
      }
    });
  }

  void _handleTrackSelectionChanged(Track track) {
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedAudioTrack = track.audio;
      if (_isCurrentStreamAdaptive) {
        _selectedVideoTrack = track.video;
      } else {
        _selectedVideoTrack = null;
      }
    });
  }

  List<VideoTrack> _collectAdaptiveVideoTracks(List<VideoTrack> tracks) {
    final VideoTrack autoTrack = tracks.firstWhere(
      (VideoTrack track) => track.id == "auto",
      orElse: VideoTrack.auto,
    );
    final List<VideoTrack> variants = tracks
        .where(
          (VideoTrack track) => track.id != "auto" && track.w != null && track.h != null && track.w! > 0 && track.h! > 0,
        )
        .toList()
      ..sort((VideoTrack a, VideoTrack b) => (b.h ?? 0).compareTo(a.h ?? 0));

    final List<VideoTrack> ordered = <VideoTrack>[];
    final Set<String> seen = <String>{};

    if (seen.add(autoTrack.id)) {
      ordered.add(autoTrack);
    }

    for (final VideoTrack track in variants) {
      if (seen.add(track.id)) {
        ordered.add(track);
      }
    }

    return ordered;
  }

  void _prepareManualAudioTracks(MediaStream stream) {
    _manualAudioTracks = <AudioTrack>[];
    _manualAudioMetadata.clear();

    final List<StreamAudio>? audios = stream.audios;
    if (audios == null || audios.isEmpty || stream.hasDefaultAudio) {
      return;
    }

    for (final StreamAudio audio in audios) {
      final AudioTrack track = _createAudioTrackForStreamAudio(audio);
      _manualAudioTracks.add(track);
      _manualAudioMetadata[_audioTrackKey(track)] = audio;
    }
  }

  AudioTrack _createAudioTrackForStreamAudio(StreamAudio audio) {
    final String trimmedLanguage = audio.language.trim();
    final String title;
    if (trimmedLanguage.isEmpty) {
      title = audio.isDefault ? "External (Default)" : "External";
    } else {
      title = audio.isDefault ? "$trimmedLanguage (Default)" : trimmedLanguage;
    }

    return AudioTrack.uri(
      audio.url,
      title: title,
      language: trimmedLanguage.isEmpty ? null : trimmedLanguage,
    );
  }

  AudioTrack? _defaultManualAudioTrack() {
    if (_manualAudioTracks.isEmpty) {
      return null;
    }

    for (final AudioTrack track in _manualAudioTracks) {
      final StreamAudio? audio = _manualAudioMetadata[_audioTrackKey(track)];
      if (audio?.isDefault == true) {
        return track;
      }
    }

    return _manualAudioTracks.first;
  }

  String _audioTrackKey(AudioTrack track) => "${track.id}|${track.uri ? 1 : 0}";

  void _clearPendingSeek() {
    _pendingSeekTarget = null;
    _pendingSeekDirection = null;
    _lastSeekRetryTime = null;
    final bool shouldResume = _shouldResumeAfterSeek;
    _shouldResumeAfterSeek = false;

    if (shouldResume) {
      unawaited(
        _player.play().catchError((Object error, StackTrace stackTrace) {
          _logger.w(
            "Failed to resume after seek",
            error: error,
            stackTrace: stackTrace,
          );
        }),
      );
    }
  }

  void _emitProgressUpdate() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _initializePlayer({Duration? resumePosition, bool? autoPlayOverride}) async {
    if (_streams.isEmpty) {
      return;
    }

    try {
      _cancelStallMonitor();
      try {
        await _videoController.platform.future;
      } catch (e, s) {
        _logger.w("Video controller failed to initialize", error: e, stackTrace: s);
        rethrow;
      }

      final MediaStream stream = _currentStream;
      _prepareManualAudioTracks(stream);
      final bool shouldPlay = autoPlayOverride ?? (_playerInitialized ? _isPlaying : widget.autoPlay);

      Duration? targetSeek;
      if (!_isSeekedToInitialProgress && widget.initialProgress > 0 && (resumePosition == null || resumePosition == Duration.zero)) {
        targetSeek = Duration(seconds: widget.initialProgress);
        _isSeekedToInitialProgress = true;
      } else if (resumePosition != null) {
        targetSeek = resumePosition;
      }

      _pendingSeekTarget = targetSeek;
      _pendingSeekDirection = targetSeek == null || targetSeek == Duration.zero ? null : 1;
      _lastSeekRetryTime = null;

      if (mounted) {
        _hideControlsTimer?.cancel();
        setState(() {
          _currentPosition = targetSeek ?? Duration.zero;
          _currentBuffered = targetSeek ?? Duration.zero;
          _currentDuration = Duration.zero;
          _isBuffering = true;
          _showControls = true;
          _availableVideoTracks = <VideoTrack>[];
          _selectedVideoTrack = null;
          _availableAudioTracks = <AudioTrack>[];
          _selectedAudioTrack = null;
          _showSubtitles = false;
          _selectedSubtitleLanguageGroup = null;
          _selectedSubtitleIndex = 0;
        });
      }

      await _player.open(
        Media(
          stream.url,
          httpHeaders: stream.headers ?? <String, String>{},
        ),
        play: false,
      );

      if (targetSeek != null && targetSeek > Duration.zero) {
        await _player.seek(targetSeek);
        _lastSeekRetryTime = DateTime.now();
      }

      if (_requiresManualAudio) {
        final AudioTrack? manualDefaultTrack = _defaultManualAudioTrack();
        if (manualDefaultTrack != null) {
          try {
            await _player.setAudioTrack(manualDefaultTrack);
            _selectedAudioTrack = manualDefaultTrack;
          } on Object catch (error, stackTrace) {
            _logger.w(
              "Failed to attach external audio track",
              error: error,
              stackTrace: stackTrace,
            );
          }
        }
      }

      if (shouldPlay) {
        await _player.play();
      }

      if (!shouldPlay) {
        await _player.pause();
      }

      if (mounted) {
        setState(() {
          _playerInitialized = true;
          _isPlaying = shouldPlay;
        });
      }

      final double targetScale = _computeZoomInScale();
      _setTargetNativeScale(targetScale);
      _startHideControlsTimer();
      _ensureProgressTimer();
      if (shouldPlay && (_currentPosition <= Duration.zero)) {
        _startStallMonitor();
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
    if (!_playerInitialized) {
      return 1.0;
    }
    final Size screenSize = MediaQuery.of(context).size;
    final int? width = _player.state.width;
    final int? height = _player.state.height;

    if (screenSize.height == 0 || width == null || height == null || width == 0 || height == 0) {
      return 1.0;
    }

    final double videoAR = width / height;

    if (!videoAR.isFinite || videoAR <= 0) {
      return 1.0;
    }

    final double screenAR = screenSize.width / screenSize.height;
    final double widthScale = screenAR / videoAR;
    final double heightScale = videoAR / screenAR;

    if (!widthScale.isFinite || !heightScale.isFinite) {
      return 1.0;
    }

    return max(1.0, max(widthScale, heightScale));
  }

  Future<void> _handleStreamFailure(Object? error) async {
    if (_isHandlingFailure) {
      _pendingStreamFailure = error;
      return;
    }

    _isHandlingFailure = true;
    try {
      _clearPendingSeek();
      _cancelStallMonitor();
      final bool wasPlaying = _isPlaying;
      _availableVideoTracks = <VideoTrack>[];
      _selectedVideoTrack = null;
      _availableAudioTracks = <AudioTrack>[];
      _selectedAudioTrack = null;

      try {
        await _player.stop();
      } catch (e, s) {
        _logger.w("Failed to stop media player after error", error: e, stackTrace: s);
      }

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
          _availableVideoTracks = <VideoTrack>[];
          _selectedVideoTrack = null;
          _selectedSubtitleLanguageGroup = null;
          _selectedSubtitleIndex = 0;
          _showSubtitles = false;
          _playerInitialized = false;
        });
      }

      await _initializePlayer(
        resumePosition: _currentPosition,
        autoPlayOverride: wasPlaying,
      );
    } finally {
      _isHandlingFailure = false;

      if (_pendingStreamFailure != null) {
        final Object? pendingError = _pendingStreamFailure;
        _pendingStreamFailure = null;
        await _handleStreamFailure(pendingError);
      }
    }
  }

  void _startStallMonitor() {
    if (!_isPlaying || _isBuffering) {
      return;
    }

    _stallMonitorTimer?.cancel();
    _stallMonitorTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPlaying || _isBuffering) {
        _cancelStallMonitor();
        return;
      }

      if (_currentPosition > Duration.zero) {
        _cancelStallMonitor();
        return;
      }

      final DateTime? startedAt = _playStartedAt;
      if (startedAt == null) {
        return;
      }

      final Duration elapsed = DateTime.now().difference(startedAt);
      if (elapsed >= _stallTimeout) {
        _cancelStallMonitor();
        _logger.w("Playback stalled after ${elapsed.inMilliseconds}ms; attempting fallback stream");
        unawaited(_handleStreamFailure(Exception("Playback stalled")));
      }
    });
  }

  void _cancelStallMonitor() {
    _stallMonitorTimer?.cancel();
    _stallMonitorTimer = null;
    _playStartedAt = null;
  }

  Future<void> _prepareForStreamSwitch({required bool wasPlaying}) async {
    if (!_playerInitialized) {
      if (mounted) {
        _hideControlsTimer?.cancel();
        setState(() {
          _showControls = true;
          _isPlaying = false;
          _currentBuffered = _currentPosition;
          _isBuffering = true;
        });
      }
      return;
    }

    if (wasPlaying || _player.state.playing) {
      try {
        await _player.pause();
      } catch (e, s) {
        _logger.w("Failed to pause player before stream switch", error: e, stackTrace: s);
      }
    }

    if (mounted) {
      _hideControlsTimer?.cancel();
      setState(() {
        _showControls = true;
        _isPlaying = false;
        _currentPosition = _player.state.position;
        _currentDuration = _player.state.duration;
        _currentBuffered = _player.state.position;
        _isBuffering = true;
      });
    }
  }

  Future<void> _showQualitySelector() async {
    if (_isCurrentStreamAdaptive) {
      if (_availableVideoTracks.length <= 1) {
        return;
      }

      final int? selectedIndex = await showDialog<int>(
        context: context,
        builder: (BuildContext context) => SimpleDialog(
          title: Text(
            "Select quality",
            style: Theme.of(context).textTheme.titleSmall,
          ),
          children: _availableVideoTracks.asMap().entries.map((MapEntry<int, VideoTrack> entry) {
            final VideoTrack track = entry.value;
            final bool isActive = track == _selectedVideoTrack;
            return ListTile(
              title: Text(
                _describeVideoTrack(track),
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

      final VideoTrack selectedTrack = _availableVideoTracks[selectedIndex];

      if (_selectedVideoTrack == selectedTrack) {
        return;
      }

      await _changeVideoTrack(selectedTrack);
      return;
    }

    if (_streams.length <= 1) {
      return;
    }

    final int? selectedIndex = await showDialog<int>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: Text(
          "Select quality",
          style: Theme.of(context).textTheme.titleSmall,
        ),
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

    final Duration resumePosition = _currentPosition;
    final bool wasPlaying = _player.state.playing;

    await _prepareForStreamSwitch(wasPlaying: wasPlaying);

    if (mounted) {
      setState(() => _activeStreamIndex = selectedIndex);
    }

    await _initializePlayer(
      resumePosition: resumePosition,
      autoPlayOverride: wasPlaying,
    );
  }

  Future<void> _showAudioSelector() async {
    if (_availableAudioTracks.length <= 1) {
      return;
    }

    final int? selectedIndex = await showDialog<int>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: Text(
          "Select audio",
          style: Theme.of(context).textTheme.titleSmall,
        ),
        children: _availableAudioTracks.asMap().entries.map((MapEntry<int, AudioTrack> entry) {
          final AudioTrack track = entry.value;
          final bool isActive = _selectedAudioTrack == track;

          return ListTile(
            title: Text(
              _describeAudioTrack(track),
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

    final AudioTrack selected = _availableAudioTracks[selectedIndex];

    if (_selectedAudioTrack == selected) {
      return;
    }

    await _changeAudioTrack(selected);
  }

  Future<void> _changeAudioTrack(AudioTrack track) async {
    final bool wasPlaying = _player.state.playing;

    try {
      if (wasPlaying) {
        await _player.pause();
      }

      await _player.setAudioTrack(track);

      if (mounted) {
        setState(() {
          _selectedAudioTrack = track;
        });
      }

      if (wasPlaying) {
        await _player.play();
      }
    } catch (e, s) {
      _logger.w("Failed to switch audio track", error: e, stackTrace: s);
      widget.onError?.call(e);
    }
  }

  Future<void> _changeVideoTrack(VideoTrack track) async {
    final bool wasPlaying = _player.state.playing;

    try {
      if (wasPlaying) {
        await _player.pause();
      }

      await _player.setVideoTrack(track);

      if (mounted) {
        setState(() {
          _selectedVideoTrack = track;
        });
      }

      if (wasPlaying) {
        await _player.play();
      }
    } catch (e, s) {
      _logger.w("Failed to switch video track", error: e, stackTrace: s);
      widget.onError?.call(e);
    }
  }

  String _describeAudioTrack(AudioTrack track) {
    if (track.id == "auto") {
      return "Default";
    }

    if (track.title != null && track.title!.isNotEmpty) {
      return track.title!;
    }

    if (track.language != null && track.language!.isNotEmpty) {
      return track.language!.toUpperCase();
    }

    return track.id;
  }

  String _describeVideoTrack(VideoTrack track) {
    if (track.id == "auto") {
      return "Auto";
    }

    String? description;

    if (track.w != null && track.h != null && track.w! > 0 && track.h! > 0) {
      final String resolution = getClosestResolutionFromDimensions(track.w!, track.h!);
      if (resolution.isNotEmpty) {
        description = resolution;
      } else {
        description = "${track.h}p";
      }
    }

    if ((description == null || description.isEmpty) && track.title != null && track.title!.isNotEmpty) {
      description = track.title!;
    }

    if (description == null || description.isEmpty) {
      description = track.id;
    }

    return description;
  }

  void _updateProgress() {
    final Duration progress = _player.state.position;
    final Duration total = _player.state.duration;
    widget.onProgress?.call(progress, total);
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (!_isPlaying || _isBuffering) {
      return;
    }
    _hideControlsTimer = Timer(widget.autoHideControlsDelay, () {
      if (mounted && _isPlaying && !_isBuffering) {
        setState(() => _showControls = false);
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() => _showControls = true);
    _startHideControlsTimer();
  }

  Future<void> playPause() async {
    if (!_playerInitialized) {
      return;
    }

    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } catch (e, s) {
      _logger.w("Failed to toggle playback", error: e, stackTrace: s);
      widget.onError?.call(e);
    }
  }

  Future<void> seekForward() async {
    if (!_playerInitialized) {
      return;
    }
    if (!_supportsSeeking) {
      return;
    }
    try {
      final Duration currentPosition = _player.state.position;
      final Duration targetPosition = currentPosition + Duration(seconds: _seekDuration);
      await seek(targetPosition);
    } catch (e, s) {
      _logger.w("Failed to seek forward", error: e, stackTrace: s);
      widget.onError?.call(e);
    }
  }

  Future<void> seekBack() async {
    if (!_playerInitialized) {
      return;
    }
    if (!_supportsSeeking) {
      return;
    }

    try {
      final Duration currentPosition = _player.state.position;
      final int seekBackSeconds = currentPosition.inSeconds < _seekDuration ? currentPosition.inSeconds : _seekDuration;
      final Duration targetPosition = currentPosition - Duration(seconds: seekBackSeconds);
      await seek(targetPosition);
    } catch (e, s) {
      _logger.w("Failed to seek back", error: e, stackTrace: s);
      widget.onError?.call(e);
    }
  }

  Duration _clampSeekTarget(Duration target) {
    Duration clamped = target;

    if (clamped < Duration.zero) {
      clamped = Duration.zero;
    }

    final Duration total = _player.state.duration;
    if (total > Duration.zero && clamped > total) {
      clamped = total;
    }

    return clamped;
  }

  Future<void> seek(Duration target) async {
    if (!_playerInitialized) {
      return;
    }
    if (!_supportsSeeking) {
      return;
    }

    final Duration clampedTarget = _clampSeekTarget(target);
    final Duration currentPosition = _player.state.position;
    final bool wasPlaying = _player.state.playing;
    _shouldResumeAfterSeek = wasPlaying;

    if (wasPlaying) {
      try {
        await _player.pause();
      } on Object catch (error, stackTrace) {
        _logger.w(
          "Failed to pause before seek",
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    final int direction;
    if (clampedTarget > currentPosition) {
      direction = 1;
    } else if (clampedTarget < currentPosition) {
      direction = -1;
    } else {
      direction = 0;
    }

    _pendingSeekTarget = clampedTarget;
    _pendingSeekDirection = direction == 0 ? null : direction;
    _lastSeekRetryTime = null;

    if (mounted) {
      _hideControlsTimer?.cancel();
      setState(() {
        _currentPosition = clampedTarget;
        _currentBuffered = clampedTarget;
        _currentDuration = _player.state.duration;
        _isBuffering = true;
        _showControls = true;
      });
    }

    try {
      await _player.seek(clampedTarget);
      _lastSeekRetryTime = DateTime.now();
    } catch (e, s) {
      _clearPendingSeek();
      _logger.w("Failed to seek", error: e, stackTrace: s);
      widget.onError?.call(e);
    }
  }

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
        await _player.setSubtitleTrack(
          SubtitleTrack.data(
            content,
            title: subtitles.name,
            language: language.toLowerCase(),
          ),
        );

        if (mounted) {
          setState(() {
            _selectedSubtitleLanguageGroup = language;
            _selectedSubtitleIndex = indexInLanguage;
            _showSubtitles = true;
          });
        }
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
    if (_currentDuration.inSeconds <= 0) {
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
    if (_currentDuration.inSeconds <= 0) {
      return;
    }

    final double targetScale = _computeZoomInScale();
    if (_lastZoomGestureScale < 1.0 - _eps) {
      if (_isZoomedIn) {
        _scaleVideoAnimationController.reverse();
        setState(() {
          _isZoomedIn = false;
        });
      }
    } else if (_lastZoomGestureScale > 1.0 + _eps) {
      if (!_isZoomedIn && targetScale > 1.0 + _eps) {
        _setTargetNativeScale(targetScale);
        _scaleVideoAnimationController.forward(from: 0);
        setState(() {
          _isZoomedIn = true;
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
    if (!_supportsSeeking) {
      return;
    }

    if (_currentDuration.inSeconds > 0) {
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

  double? _videoAspectRatio() {
    final int? width = _player.state.width;
    final int? height = _player.state.height;

    if (width == null || height == null || width == 0 || height == 0) {
      return null;
    }

    return width / height;
  }

  Widget _buildPlayer() {
    if (!_playerInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final double aspectRatio = _videoAspectRatio() ?? (16 / 9);

    return ScaleTransition(
      scale: _scaleVideoAnimation,
      child: Center(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Video(
            controller: _videoController,
            controls: (_) => const SizedBox.shrink(),
            subtitleViewConfiguration: const SubtitleViewConfiguration(visible: false),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitles() {
    if (!_playerInitialized) {
      return const SizedBox.shrink();
    }

    return SubtitleView(
      controller: _videoController,
      configuration: SubtitleViewConfiguration(
        visible: _showSubtitles,
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: MediaQuery.of(context).size.width * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                ) ??
            const TextStyle(),
        textAlign: TextAlign.center,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
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
                                widget.onBack?.call(_currentPosition.inSeconds);
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
                        if (_hasMultipleQualityOptions)
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
                        if (_availableAudioTracks.length > 1)
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
                                  await _player.pause();
                                }

                                await _showSubtitleSelector();
                                await _player.play();
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
                              unawaited(_player.setSubtitleTrack(SubtitleTrack.no()));
                              if (mounted) {
                                setState(() => _showSubtitles = false);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(_showSubtitles ? Icons.closed_caption_rounded : Icons.closed_caption_off),
                            ),
                          ),
                        Builder(
                          builder: (BuildContext context) {
                            final bool canOperate = _currentDuration.inSeconds > 0;
                            final double targetScale = _computeZoomInScale();
                            final bool canZoomIn = targetScale > 1.0 + _eps;
                            final VoidCallback? onPressed = !_isZoomedIn
                                ? (canOperate && canZoomIn
                                    ? () {
                                        _setTargetNativeScale(targetScale);
                                        _scaleVideoAnimationController.forward(from: 0);
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
                        icon: FaIcon(
                          FontAwesomeIcons.rotateLeft,
                          color: _supportsSeeking && _currentDuration.inSeconds > 0 ? Colors.white : Colors.grey.withValues(alpha: 0.5),
                          size: 25,
                        ),
                        onPressed: !_supportsSeeking || _currentDuration.inSeconds <= 0 ? null : () => seekBack(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: !_isBuffering
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
                        icon: FaIcon(
                          FontAwesomeIcons.rotateRight,
                          color: _supportsSeeking && _currentDuration.inSeconds > 0 ? Colors.white : Colors.grey.withValues(alpha: 0.5),
                          size: 25,
                        ),
                        onPressed: !_supportsSeeking || _currentDuration.inSeconds <= 0 ? null : () => seekForward(),
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
                        progress: _currentPosition,
                        buffered: _currentBuffered,
                        total: _currentDuration,
                        progressBarColor: Theme.of(context).primaryColor,
                        baseBarColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                        bufferedBarColor: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                        thumbColor: Theme.of(context).primaryColor,
                        timeLabelTextStyle: Theme.of(context).textTheme.displaySmall,
                        timeLabelPadding: 10,
                        onSeek: _supportsSeeking ? (Duration target) => seek(target) : null,
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
          _buildSubtitles(),
          _buildControls(),
          _buildDoubleTapFeedback(),
        ],
      ),
    );
  }
}
