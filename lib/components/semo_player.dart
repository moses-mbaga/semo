import "dart:async";

import "package:audio_video_progress_bar/audio_video_progress_bar.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:logger/logger.dart";
import "package:semo/models/media_progress.dart";
import "package:semo/models/media_stream.dart";
import "package:semo/enums/stream_type.dart";
import "package:semo/services/app_preferences_service.dart";
import "package:semo/models/subtitle_style.dart" as local;
import "package:semo/models/stream_subtitles.dart";
import "package:semo/services/secrets_service.dart";
import "package:subtitle_wrapper_package/subtitle_wrapper_package.dart";
import "package:video_player/video_player.dart";

typedef OnProgressCallback = void Function(Duration progress, Duration total);
typedef OnErrorCallback = void Function(Object? error);
typedef OnSeekCallback = Future<void> Function(Duration target);

class SemoPlayer extends StatefulWidget {
  const SemoPlayer({
    super.key,
    required this.stream,
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

  final MediaStream stream;
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
  late final VideoPlayerController _videoPlayerController;
  final SubtitleController _subtitleController = SubtitleController(
    subtitleType: SubtitleType.webvtt,
    showSubtitles: true,
  );
  final AppPreferencesService _appPreferences = AppPreferencesService();
  final Dio _dio = Dio();
  SubtitleStyle _subtitleStyle = const SubtitleStyle();
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

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.stream.url),
      httpHeaders: widget.stream.headers ?? <String, String>{},
      formatHint: widget.stream.type == StreamType.hls ? VideoFormat.hls : VideoFormat.other,
    );
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
    _initializePlayer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _progressTimer?.cancel();
    _videoPlayerController.removeListener(_playerListener);
    _videoPlayerController.dispose();
    _scaleVideoAnimationController.dispose();
    _leftRippleController.dispose();
    _rightRippleController.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      // Initialize subtitle style
      local.SubtitleStyle localSubtitlesStyle = _appPreferences.getSubtitlesStyle();
      SubtitleStyle subtitleStyle = SubtitleStyle(
        fontSize: localSubtitlesStyle.fontSize,
        textColor: local.SubtitleStyle.getColors()[localSubtitlesStyle.color] ?? Colors.white,
        hasBorder: localSubtitlesStyle.hasBorder,
        borderStyle: SubtitleBorderStyle(
          strokeWidth: localSubtitlesStyle.borderStyle.strokeWidth,
          style: localSubtitlesStyle.borderStyle.style,
          color: local.SubtitleStyle.getColors()[localSubtitlesStyle.borderStyle.color] ?? Colors.white,
        ),
      );

      setState(() => _subtitleStyle = subtitleStyle);

      // Initialize video player
      await _videoPlayerController.initialize().catchError((Object? e) {
        widget.onError?.call(e);
        return;
      });

      if (mounted) {
        // Compute zoom-in target scale (screen AR / video AR)
        final double targetScale = _computeZoomInScale();
        _setTargetNativeScale(targetScale);

        if (widget.autoPlay) {
          await _videoPlayerController.play();
        }

        _startHideControlsTimer();

        // Start progress update timer
        _progressTimer = Timer.periodic(const Duration(seconds: 10), (_) {
          if (mounted) {
            _updateProgress();
          }
        });

        _videoPlayerController.addListener(_playerListener);
      }
    } catch (e) {
      widget.onError?.call(e);
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
    final Size screenSize = MediaQuery.of(context).size;
    final double videoAR = _videoPlayerController.value.aspectRatio;

    if (screenSize.height == 0 || videoAR <= 0 || !videoAR.isFinite) {
      return 1.0;
    }

    final double screenAR = screenSize.width / screenSize.height;
    return screenAR / videoAR;
  }

  Future<void> _playerListener() async {
    try {
      bool isPlaying = _videoPlayerController.value.isPlaying;
      if (mounted) {
        setState(() => _isPlaying = isPlaying);
      }

      await Future<void>.delayed(const Duration(milliseconds: 500));

      if (_videoPlayerController.value.hasError) {
        widget.onError?.call(_videoPlayerController.value.errorDescription);
        return;
      }

      Duration progress = _videoPlayerController.value.position;
      Duration total = _videoPlayerController.value.duration;
      Duration buffered = Duration.zero;
      final List<DurationRange> ranges = _videoPlayerController.value.buffered;

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
      if (isPlaying && _videoPlayerController.value.isBuffering && (progress == _mediaProgress.progress)) {
        isBuffering = true;
      }

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

  void _updateProgress() {
    if (_videoPlayerController.value.isInitialized) {
      final Duration progress = _videoPlayerController.value.position;
      final Duration total = _videoPlayerController.value.duration;
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
    try {
      if (_isPlaying) {
        await _videoPlayerController.pause();
      } else {
        await _videoPlayerController.play();
      }
    } catch (e) {
      widget.onError?.call(e);
    }
  }

  Future<void> seekForward() async {
    try {
      Duration currentPosition = _videoPlayerController.value.position;
      Duration targetPosition = Duration(seconds: currentPosition.inSeconds + _seekDuration);
      await _videoPlayerController.seekTo(targetPosition);
    } catch (e) {
      widget.onError?.call(e);
    }
  }

  Future<void> seekBack() async {
    try {
      Duration currentPosition = _videoPlayerController.value.position;
      int seekBackSeconds = currentPosition.inSeconds < _seekDuration ? currentPosition.inSeconds : _seekDuration;
      Duration targetPosition = Duration(
        seconds: currentPosition.inSeconds - seekBackSeconds,
      );
      await _videoPlayerController.seekTo(targetPosition);
    } catch (e) {
      widget.onError?.call(e);
    }
  }

  Future<void> seek(Duration target) async {
    try {
      await _videoPlayerController.seekTo(target);
    } catch (e) {
      widget.onError?.call(e);
    }
  }

  Future<void> _applySubtitle(StreamSubtitles track, {required int indexInLanguage, required String language}) async {
    try {
      // Currently throwing 403 errors on OpenSubtitles urls with proxy
      // To be investigated
      final Response<String> response = await _dio.get<String>(
        track.url,
        options: Options(
          responseType: ResponseType.plain,
          headers: <String, String>{
            "Authorization": "Bearer ${SecretsService.cfWorkersApiKey}",
          },
        ),
      );

      final String content = response.data ?? "";
      _subtitleController.updateSubtitleContent(content: content);

      setState(() {
        _selectedSubtitleLanguageGroup = language;
        _selectedSubtitleIndex = indexInLanguage;
        _showSubtitles = true;
      });
    } catch (e, s) {
      _logger.w("Failed to apply subtitles", error: e, stackTrace: s);
    }
  }

  Map<String, List<StreamSubtitles>> _groupSubtitlesByLanguage(List<StreamSubtitles> tracks) {
    final Map<String, List<StreamSubtitles>> grouped = <String, List<StreamSubtitles>>{};
    for (final StreamSubtitles t in tracks) {
      final String key = t.language.toUpperCase();
      grouped.putIfAbsent(key, () => <StreamSubtitles>[]).add(t);
    }
    return grouped;
  }

  Future<void> _showSubtitleSelector() async {
    final List<StreamSubtitles> tracks = widget.stream.subtitles ?? <StreamSubtitles>[];
    if (tracks.isEmpty) {
      return;
    }

    final Map<String, List<StreamSubtitles>> byLang = _groupSubtitlesByLanguage(tracks);
    final List<String> languages = byLang.keys.toList()..sort();

    // First: language selection
    final String? selectedLang = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Select subtitle language"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (BuildContext context, int index) {
              final String lang = languages[index];
              final bool selected = lang == _selectedSubtitleLanguageGroup;
              return ListTile(
                title: Text(
                  lang,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: selected ? Theme.of(context).primaryColor : Colors.white,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                ),
                trailing: Text("${byLang[lang]?.length ?? 0}", style: Theme.of(context).textTheme.displaySmall),
                onTap: () => Navigator.pop(context, lang),
              );
            },
          ),
        ),
      ),
    );

    if (selectedLang == null || !mounted) {
      return;
    }

    // Second: track selection within language
    final List<StreamSubtitles> langTracks = byLang[selectedLang] ?? <StreamSubtitles>[];
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text("$selectedLang subtitles"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: langTracks.length,
            itemBuilder: (BuildContext context, int idx) {
              final bool isSelected = selectedLang == _selectedSubtitleLanguageGroup && idx == _selectedSubtitleIndex;
              final StreamSubtitles track = langTracks[idx];
              return ListTile(
                title: Text(
                  track.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                ),
                onTap: () async {
                  await _applySubtitle(track, indexInLanguage: idx, language: selectedLang);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
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

  Widget _buildPlayer() => SubtitleWrapper(
        subtitleController: _subtitleController,
        videoPlayerController: _videoPlayerController,
        subtitleStyle: _subtitleStyle,
        videoChild: ScaleTransition(
          scale: _scaleVideoAnimation,
          child: Center(
            child: AspectRatio(
              aspectRatio: _videoPlayerController.value.aspectRatio,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: VideoPlayer(_videoPlayerController),
              ),
            ),
          ),
        ),
      );

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
                        if (widget.stream.subtitles?.isNotEmpty ?? false)
                          InkWell(
                            borderRadius: BorderRadius.circular(1000),
                            onTap: () async {
                              if (_showSubtitles) {
                                if (_isPlaying) {
                                  await _videoPlayerController.pause();
                                }

                                await _showSubtitleSelector();
                                await _videoPlayerController.play();
                              } else {
                                // Auto-pick EN if available otherwise first available
                                final List<StreamSubtitles> tracks = widget.stream.subtitles ?? <StreamSubtitles>[];
                                if (tracks.isNotEmpty) {
                                  final Map<String, List<StreamSubtitles>> grouped = _groupSubtitlesByLanguage(tracks);
                                  String lang = grouped.containsKey("EN") ? "EN" : grouped.keys.first;
                                  final StreamSubtitles track = grouped[lang]!.first;
                                  await _applySubtitle(track, indexInLanguage: 0, language: lang);
                                }
                              }
                            },
                            onLongPress: () {
                              _subtitleController.updateSubtitleContent(content: "");
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
    final TextStyle textStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ) ??
        const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        );

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
          Text(label, style: textStyle),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
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
