# تخصيص مشغل الفيديو في تطبيق INDEX

## نظرة عامة

يستخدم تطبيق INDEX مكون `IndexPlayer` لتشغيل الفيديو. يعتمد هذا المكون على حزمة `video_player` الأساسية مع إضافة واجهة مستخدم مخصصة وميزات إضافية مثل دعم الترجمة وتخزين تقدم المشاهدة.

## هيكل مشغل الفيديو

### المكونات الرئيسية

1. **IndexPlayer**: المكون الرئيسي الذي يدير تشغيل الفيديو.
2. **ControlsOverlay**: طبقة التحكم التي تظهر عند النقر على الفيديو.
3. **SubtitleView**: عرض الترجمة أسفل الفيديو.
4. **QualitySelector**: محدد جودة الفيديو.
5. **PlaybackSpeedSelector**: محدد سرعة التشغيل.

## تخصيص واجهة المستخدم

### تغيير مظهر أزرار التحكم

يمكنك تخصيص مظهر أزرار التحكم في ملف `lib/components/index_player.dart`:

```dart
Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
  return IconButton(
    icon: Icon(
      icon,
      color: Colors.white,
      size: 30, // تغيير حجم الأيقونة
    ),
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: Colors.black54, // تغيير لون خلفية الزر
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // تغيير شكل الزر
      ),
    ),
  );
}
```

### تخصيص شريط التقدم

يمكنك تخصيص شريط التقدم في ملف `lib/components/index_player.dart`:

```dart
Widget _buildProgressBar() {
  return SliderTheme(
    data: SliderThemeData(
      trackHeight: 5, // تغيير ارتفاع المسار
      activeTrackColor: Colors.red, // تغيير لون المسار النشط
      inactiveTrackColor: Colors.grey.withOpacity(0.5), // تغيير لون المسار غير النشط
      thumbColor: Colors.red, // تغيير لون المؤشر
      thumbShape: RoundSliderThumbShape(
        enabledThumbRadius: 8, // تغيير حجم المؤشر
      ),
      overlayColor: Colors.red.withOpacity(0.3), // تغيير لون التراكب
      overlayShape: RoundSliderOverlayShape(
        overlayRadius: 16, // تغيير حجم التراكب
      ),
    ),
    child: Slider(
      value: _position.inSeconds.toDouble(),
      min: 0.0,
      max: _duration.inSeconds.toDouble(),
      onChanged: (value) {
        _seekTo(Duration(seconds: value.toInt()));
      },
    ),
  );
}
```

### تخصيص عرض الوقت

يمكنك تخصيص عرض الوقت في ملف `lib/components/index_player.dart`:

```dart
Widget _buildTimeDisplay() {
  final position = _formatDuration(_position);
  final duration = _formatDuration(_duration);
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      '$position / $duration',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  
  if (duration.inHours > 0) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  } else {
    return '$minutes:$seconds';
  }
}
```

## تخصيص إعدادات الترجمة

### تغيير مظهر الترجمة

يمكنك تخصيص مظهر الترجمة في ملف `lib/components/subtitle_view.dart`:

```dart
class SubtitleView extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color backgroundColor;
  final double opacity;
  
  const SubtitleView({
    super.key,
    required this.text,
    this.style = const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    this.backgroundColor = Colors.black,
    this.opacity = 0.8,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(opacity),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }
}
```

### إضافة إعدادات الترجمة

يمكنك إضافة إعدادات الترجمة في ملف `lib/screens/settings_screen.dart`:

```dart
class SubtitleSettings extends StatefulWidget {
  const SubtitleSettings({super.key});

  @override
  State<SubtitleSettings> createState() => _SubtitleSettingsState();
}

class _SubtitleSettingsState extends State<SubtitleSettings> {
  double _fontSize = 16.0;
  Color _textColor = Colors.white;
  Color _backgroundColor = Colors.black;
  double _opacity = 0.8;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('subtitle_size') ?? 16.0;
      _textColor = Color(int.parse(prefs.getString('subtitle_color') ?? 'FFFFFF', radix: 16) | 0xFF000000);
      _backgroundColor = Color(int.parse(prefs.getString('subtitle_background') ?? '000000', radix: 16) | 0xFF000000);
      _opacity = prefs.getDouble('subtitle_opacity') ?? 0.8;
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('subtitle_size', _fontSize);
    await prefs.setString('subtitle_color', _textColor.value.toRadixString(16).substring(2));
    await prefs.setString('subtitle_background', _backgroundColor.value.toRadixString(16).substring(2));
    await prefs.setDouble('subtitle_opacity', _opacity);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الترجمة'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('حجم الخط: ${_fontSize.toStringAsFixed(1)}', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _fontSize,
            min: 12.0,
            max: 30.0,
            divisions: 18,
            onChanged: (value) {
              setState(() {
                _fontSize = value;
              });
            },
            onChangeEnd: (value) {
              _saveSettings();
            },
          ),
          
          const SizedBox(height: 16),
          
          Text('لون النص', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildColorOption(Colors.white, _textColor == Colors.white),
              _buildColorOption(Colors.yellow, _textColor == Colors.yellow),
              _buildColorOption(Colors.green, _textColor == Colors.green),
              _buildColorOption(Colors.cyan, _textColor == Colors.cyan),
              _buildColorOption(Colors.pink, _textColor == Colors.pink),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Text('لون الخلفية', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildColorOption(Colors.black, _backgroundColor == Colors.black),
              _buildColorOption(Colors.grey.shade800, _backgroundColor == Colors.grey.shade800),
              _buildColorOption(Colors.blue.shade900, _backgroundColor == Colors.blue.shade900),
              _buildColorOption(Colors.brown.shade900, _backgroundColor == Colors.brown.shade900),
              _buildColorOption(Colors.transparent, _backgroundColor == Colors.transparent),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Text('شفافية الخلفية: ${(_opacity * 100).toInt()}%', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _opacity,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (value) {
              setState(() {
                _opacity = value;
              });
            },
            onChangeEnd: (value) {
              _saveSettings();
            },
          ),
          
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _backgroundColor.withOpacity(_opacity),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'معاينة الترجمة',
              style: TextStyle(
                color: _textColor,
                fontSize: _fontSize,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildColorOption(Color color, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (color == _textColor || color == _backgroundColor) return;
          
          if (_textColor == Colors.white || _textColor == Colors.yellow || _textColor == Colors.green || _textColor == Colors.cyan || _textColor == Colors.pink) {
            _textColor = color;
          } else {
            _backgroundColor = color;
          }
          
          _saveSettings();
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
```

## إضافة ميزات متقدمة

### إضافة دعم تشغيل الفيديو في الخلفية

يمكنك إضافة دعم تشغيل الفيديو في الخلفية باستخدام حزمة `audio_service`:

```dart
import 'package:audio_service/audio_service.dart';

class BackgroundPlaybackHandler extends BaseAudioHandler {
  final VideoPlayerController _controller;
  
  BackgroundPlaybackHandler(this._controller) {
    _controller.addListener(_updatePlaybackState);
  }
  
  void _updatePlaybackState() {
    final playing = _controller.value.isPlaying;
    final position = _controller.value.position;
    final duration = _controller.value.duration;
    
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.rewind,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _controller.value.isBuffering
          ? AudioProcessingState.buffering
          : AudioProcessingState.ready,
      playing: playing,
      updatePosition: position,
      bufferedPosition: position,
      speed: _controller.value.playbackSpeed,
      queueIndex: 0,
    ));
  }
  
  @override
  Future<void> play() async {
    await _controller.play();
  }
  
  @override
  Future<void> pause() async {
    await _controller.pause();
  }
  
  @override
  Future<void> seek(Duration position) async {
    await _controller.seekTo(position);
  }
  
  @override
  Future<void> stop() async {
    await _controller.pause();
    await _controller.seekTo(Duration.zero);
  }
}
```

### إضافة دعم تشغيل الفيديو في نافذة عائمة

يمكنك إضافة دعم تشغيل الفيديو في نافذة عائمة باستخدام حزمة `pip_view`:

```dart
import 'package:pip_view/pip_view.dart';

class PipPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  
  const PipPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
  });
  
  @override
  State<PipPlayerScreen> createState() => _PipPlayerScreenState();
}

class _PipPlayerScreenState extends State<PipPlayerScreen> {
  late VideoPlayerController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return PIPView(
      builder: (context, isFloating) {
        return Scaffold(
          appBar: isFloating ? null : AppBar(
            title: Text(widget.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_in_picture),
                onPressed: () {
                  PIPView.of(context)?.presentBelow(const HomeScreen());
                },
              ),
            ],
          ),
          body: IndexPlayer(
            controller: _controller,
            showControls: !isFloating,
          ),
        );
      },
    );
  }
}
```

### إضافة دعم تنزيل الفيديو للمشاهدة دون اتصال

يمكنك إضافة دعم تنزيل الفيديو للمشاهدة دون اتصال باستخدام حزمة `flutter_downloader`:

```dart
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoDownloadManager {
  static Future<void> initialize() async {
    await FlutterDownloader.initialize();
  }
  
  static Future<String?> downloadVideo(String url, String fileName) async {
    final status = await Permission.storage.request();
    
    if (status.isGranted) {
      final directory = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${directory.path}/Videos');
      
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }
      
      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: videosDir.path,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: true,
      );
      
      return taskId;
    } else {
      return null;
    }
  }
  
  static Future<List<DownloadTask>> getDownloadedVideos() async {
    return await FlutterDownloader.loadTasks() ?? [];
  }
  
  static Future<String?> getLocalVideoPath(String taskId) async {
    final tasks = await FlutterDownloader.loadTasks();
    final task = tasks?.firstWhere((task) => task.taskId == taskId);
    
    if (task != null && task.status == DownloadTaskStatus.complete) {
      return '${task.savedDir}/${task.filename}';
    }
    
    return null;
  }
}
```

## تحسين أداء مشغل الفيديو

### تحسين تحميل الفيديو

يمكنك تحسين تحميل الفيديو باستخدام التخزين المؤقت:

```dart
Future<void> _initializePlayer() async {
  // تحديد حجم التخزين المؤقت
  await VideoPlayerController.setMaxCacheSize(100 * 1024 * 1024); // 100 ميجابايت
  
  _controller = VideoPlayerController.network(
    widget.videoUrl,
    videoPlayerOptions: VideoPlayerOptions(
      mixWithOthers: false,
      allowBackgroundPlayback: true,
    ),
  );
  
  await _controller.initialize();
  
  // تحميل مسبق للفيديو
  await _controller.seekTo(const Duration(milliseconds: 100));
  await _controller.seekTo(Duration.zero);
  
  setState(() {
    _isInitialized = true;
  });
  
  _controller.play();
}
```

### تحسين استهلاك الذاكرة

يمكنك تحسين استهلاك الذاكرة عن طريق التخلص من الموارد بشكل صحيح:

```dart
@override
void dispose() {
  _controller.removeListener(_onControllerUpdate);
  _hideTimer?.cancel();
  _initTimer?.cancel();
  _subtitleSubscription?.cancel();
  
  // التخلص من المشغل بشكل صحيح
  _controller.pause().then((_) {
    _controller.dispose();
  });
  
  super.dispose();
}
```

## استخدام مشغل الفيديو في التطبيق

### استخدام المشغل في شاشة تفاصيل الفيلم

```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(
          videoUrl: movie.streamUrl,
          title: movie.title,
          posterUrl: movie.posterPath,
          subtitleUrl: movie.subtitleUrl,
        ),
      ),
    );
  },
  child: const Text('مشاهدة'),
),
```

### استخدام المشغل في شاشة تفاصيل الحلقة

```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(
          videoUrl: episode.streamUrl,
          title: '${tvShow.name} - S${season.seasonNumber}E${episode.episodeNumber}',
          posterUrl: episode.stillPath ?? tvShow.posterPath,
          subtitleUrl: episode.subtitleUrl,
        ),
      ),
    );
  },
  child: const Text('مشاهدة'),
),
```