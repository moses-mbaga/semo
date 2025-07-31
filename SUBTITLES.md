# تخصيص الترجمات في تطبيق INDEX

## نظرة عامة

يدعم تطبيق INDEX تخصيص الترجمات بشكل كامل، مما يتيح للمستخدمين تعديل حجم الخط ولون النص ولون الخلفية وموضع الترجمة وغيرها من الخيارات.

## تنسيقات الترجمة المدعومة

يدعم التطبيق تنسيق الترجمة التالي:

- **SRT (SubRip Text)**: التنسيق الأكثر شيوعًا للترجمات.

## الحصول على الترجمات

يستخدم التطبيق واجهة برمجة تطبيقات SUBDL للحصول على الترجمات. فيما يلي كيفية البحث عن الترجمات وتنزيلها:

```dart
import 'package:index/services/subtitle_service.dart';

// البحث عن الترجمات
final subtitles = await SubtitleService.searchSubtitles(imdbId, 'ar');

// تنزيل الترجمة
final subtitlePath = await SubtitleService.downloadSubtitle(fileId);
```

## تحميل ملف الترجمة

يمكن تحميل ملف الترجمة باستخدام الكود التالي:

```dart
import 'dart:io';
import 'package:flutter/services.dart';

Future<String> loadSubtitleContent(String path) async {
  if (path.startsWith('assets/')) {
    // تحميل من الأصول
    return await rootBundle.loadString(path);
  } else {
    // تحميل من الملف
    final file = File(path);
    return await file.readAsString();
  }
}
```

## تحليل ملف الترجمة

يتم تحليل ملف الترجمة لاستخراج توقيت وتنسيق الترجمة:

```dart
import 'package:subtitle/subtitle.dart';

Future<List<Subtitle>> parseSubtitle(String content) async {
  final subtitles = await SubtitleParser.fromSrt(content);
  return subtitles;
}
```

## عرض الترجمات

يتم عرض الترجمات على مشغل الفيديو باستخدام الكود التالي:

```dart
Widget buildSubtitleText(BuildContext context, Subtitle subtitle) {
  final subtitleStyle = TextStyle(
    fontSize: subtitleSize,
    color: Color(int.parse('0xFF$subtitleColor')),
    backgroundColor: Color(int.parse('0xFF$subtitleBackground')).withOpacity(subtitleOpacity),
    shadows: [
      Shadow(
        color: Colors.black,
        offset: const Offset(1, 1),
        blurRadius: 1,
      ),
    ],
  );

  return Text(
    subtitle.text,
    style: subtitleStyle,
    textAlign: TextAlign.center,
  );
}
```

## تخصيص الترجمات

### خيارات التخصيص

يمكن للمستخدمين تخصيص الخيارات التالية:

1. **تمكين/تعطيل الترجمات**: تشغيل أو إيقاف عرض الترجمات.
2. **لغة الترجمة**: اختيار لغة الترجمة المفضلة.
3. **حجم الخط**: تعديل حجم خط الترجمة.
4. **لون النص**: تغيير لون نص الترجمة.
5. **لون الخلفية**: تغيير لون خلفية الترجمة.
6. **شفافية الخلفية**: تعديل شفافية خلفية الترجمة.
7. **موضع الترجمة**: تحديد موضع الترجمة على الشاشة.
8. **تأخير الترجمة**: ضبط توقيت الترجمة للمزامنة مع الفيديو.

### واجهة المستخدم لتخصيص الترجمات

يمكن إنشاء شاشة لتخصيص الترجمات كما يلي:

```dart
class SubtitleSettingsScreen extends StatefulWidget {
  const SubtitleSettingsScreen({super.key});

  @override
  State<SubtitleSettingsScreen> createState() => _SubtitleSettingsScreenState();
}

class _SubtitleSettingsScreenState extends State<SubtitleSettingsScreen> {
  bool _subtitlesEnabled = true;
  String _subtitleLanguage = 'ar';
  double _subtitleSize = 16.0;
  String _subtitleColor = 'FFFFFF';
  String _subtitleBackground = '000000';
  double _subtitleOpacity = 0.8;
  String _subtitlePosition = 'bottom';
  double _subtitleDelay = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _subtitlesEnabled = prefs.getBool('subtitles_enabled') ?? true;
      _subtitleLanguage = prefs.getString('subtitle_language') ?? 'ar';
      _subtitleSize = prefs.getDouble('subtitle_size') ?? 16.0;
      _subtitleColor = prefs.getString('subtitle_color') ?? 'FFFFFF';
      _subtitleBackground = prefs.getString('subtitle_background') ?? '000000';
      _subtitleOpacity = prefs.getDouble('subtitle_opacity') ?? 0.8;
      _subtitlePosition = prefs.getString('subtitle_position') ?? 'bottom';
      _subtitleDelay = prefs.getDouble('subtitle_delay') ?? 0.0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('subtitles_enabled', _subtitlesEnabled);
    await prefs.setString('subtitle_language', _subtitleLanguage);
    await prefs.setDouble('subtitle_size', _subtitleSize);
    await prefs.setString('subtitle_color', _subtitleColor);
    await prefs.setString('subtitle_background', _subtitleBackground);
    await prefs.setDouble('subtitle_opacity', _subtitleOpacity);
    await prefs.setString('subtitle_position', _subtitlePosition);
    await prefs.setDouble('subtitle_delay', _subtitleDelay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الترجمة'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // تمكين/تعطيل الترجمات
          SwitchListTile(
            title: const Text('تمكين الترجمات'),
            value: _subtitlesEnabled,
            onChanged: (value) {
              setState(() {
                _subtitlesEnabled = value;
              });
              _saveSettings();
            },
          ),
          
          const Divider(),
          
          // لغة الترجمة
          ListTile(
            title: const Text('لغة الترجمة'),
            subtitle: Text(_getLanguageName(_subtitleLanguage)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showLanguageSelector();
            },
          ),
          
          const Divider(),
          
          // حجم الخط
          ListTile(
            title: const Text('حجم الخط'),
            subtitle: Slider(
              value: _subtitleSize,
              min: 10.0,
              max: 30.0,
              divisions: 20,
              label: _subtitleSize.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _subtitleSize = value;
                });
              },
              onChangeEnd: (value) {
                _saveSettings();
              },
            ),
          ),
          
          const Divider(),
          
          // لون النص
          ListTile(
            title: const Text('لون النص'),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Color(int.parse('0xFF$_subtitleColor')),
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onTap: () {
              _showColorPicker(true);
            },
          ),
          
          const Divider(),
          
          // لون الخلفية
          ListTile(
            title: const Text('لون الخلفية'),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Color(int.parse('0xFF$_subtitleBackground')),
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onTap: () {
              _showColorPicker(false);
            },
          ),
          
          const Divider(),
          
          // شفافية الخلفية
          ListTile(
            title: const Text('شفافية الخلفية'),
            subtitle: Slider(
              value: _subtitleOpacity,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: _subtitleOpacity.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _subtitleOpacity = value;
                });
              },
              onChangeEnd: (value) {
                _saveSettings();
              },
            ),
          ),
          
          const Divider(),
          
          // موضع الترجمة
          ListTile(
            title: const Text('موضع الترجمة'),
            subtitle: Text(_getPositionName(_subtitlePosition)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showPositionSelector();
            },
          ),
          
          const Divider(),
          
          // تأخير الترجمة
          ListTile(
            title: const Text('تأخير الترجمة'),
            subtitle: Slider(
              value: _subtitleDelay,
              min: -5.0,
              max: 5.0,
              divisions: 100,
              label: '${_subtitleDelay.toStringAsFixed(1)} ثانية',
              onChanged: (value) {
                setState(() {
                  _subtitleDelay = value;
                });
              },
              onChangeEnd: (value) {
                _saveSettings();
              },
            ),
          ),
          
          const Divider(),
          
          // معاينة الترجمة
          const ListTile(
            title: Text('معاينة الترجمة'),
          ),
          
          Container(
            padding: const EdgeInsets.all(16.0),
            alignment: Alignment.center,
            child: Text(
              'هذا نص تجريبي للترجمة',
              style: TextStyle(
                fontSize: _subtitleSize,
                color: Color(int.parse('0xFF$_subtitleColor')),
                backgroundColor: Color(int.parse('0xFF$_subtitleBackground')).withOpacity(_subtitleOpacity),
                shadows: [
                  Shadow(
                    color: Colors.black,
                    offset: const Offset(1, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // إعادة تعيين الإعدادات
          ElevatedButton(
            onPressed: () {
              _resetSettings();
            },
            child: const Text('إعادة تعيين الإعدادات'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اختر لغة الترجمة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('العربية'),
                selected: _subtitleLanguage == 'ar',
                onTap: () {
                  setState(() {
                    _subtitleLanguage = 'ar';
                  });
                  _saveSettings();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('الإنجليزية'),
                selected: _subtitleLanguage == 'en',
                onTap: () {
                  setState(() {
                    _subtitleLanguage = 'en';
                  });
                  _saveSettings();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('الفرنسية'),
                selected: _subtitleLanguage == 'fr',
                onTap: () {
                  setState(() {
                    _subtitleLanguage = 'fr';
                  });
                  _saveSettings();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPositionSelector() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اختر موضع الترجمة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('أعلى'),
                selected: _subtitlePosition == 'top',
                onTap: () {
                  setState(() {
                    _subtitlePosition = 'top';
                  });
                  _saveSettings();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('وسط'),
                selected: _subtitlePosition == 'middle',
                onTap: () {
                  setState(() {
                    _subtitlePosition = 'middle';
                  });
                  _saveSettings();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('أسفل'),
                selected: _subtitlePosition == 'bottom',
                onTap: () {
                  setState(() {
                    _subtitlePosition = 'bottom';
                  });
                  _saveSettings();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showColorPicker(bool isTextColor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isTextColor ? 'اختر لون النص' : 'اختر لون الخلفية'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: Color(int.parse('0xFF${isTextColor ? _subtitleColor : _subtitleBackground}')),
              onColorChanged: (color) {
                setState(() {
                  if (isTextColor) {
                    _subtitleColor = color.value.toRadixString(16).substring(2).toUpperCase();
                  } else {
                    _subtitleBackground = color.value.toRadixString(16).substring(2).toUpperCase();
                  }
                });
              },
              enableAlpha: false,
              labelTypes: const [],
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                _saveSettings();
                Navigator.pop(context);
              },
              child: const Text('موافق'),
            ),
          ],
        );
      },
    );
  }

  void _resetSettings() {
    setState(() {
      _subtitlesEnabled = true;
      _subtitleLanguage = 'ar';
      _subtitleSize = 16.0;
      _subtitleColor = 'FFFFFF';
      _subtitleBackground = '000000';
      _subtitleOpacity = 0.8;
      _subtitlePosition = 'bottom';
      _subtitleDelay = 0.0;
    });
    _saveSettings();
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'الإنجليزية';
      case 'fr':
        return 'الفرنسية';
      default:
        return code;
    }
  }

  String _getPositionName(String position) {
    switch (position) {
      case 'top':
        return 'أعلى';
      case 'middle':
        return 'وسط';
      case 'bottom':
        return 'أسفل';
      default:
        return position;
    }
  }
}
```

## تطبيق إعدادات الترجمة على مشغل الفيديو

يمكن تطبيق إعدادات الترجمة على مشغل الفيديو كما يلي:

```dart
Widget buildSubtitleWidget(BuildContext context, Subtitle subtitle) {
  // تحميل إعدادات الترجمة
  final prefs = await SharedPreferences.getInstance();
  final subtitlesEnabled = prefs.getBool('subtitles_enabled') ?? true;
  
  if (!subtitlesEnabled) {
    return const SizedBox.shrink();
  }
  
  final subtitleSize = prefs.getDouble('subtitle_size') ?? 16.0;
  final subtitleColor = prefs.getString('subtitle_color') ?? 'FFFFFF';
  final subtitleBackground = prefs.getString('subtitle_background') ?? '000000';
  final subtitleOpacity = prefs.getDouble('subtitle_opacity') ?? 0.8;
  final subtitlePosition = prefs.getString('subtitle_position') ?? 'bottom';
  final subtitleDelay = prefs.getDouble('subtitle_delay') ?? 0.0;
  
  // تطبيق تأخير الترجمة
  final delayInMilliseconds = (subtitleDelay * 1000).toInt();
  final adjustedStartTime = subtitle.start.add(Duration(milliseconds: delayInMilliseconds));
  final adjustedEndTime = subtitle.end.add(Duration(milliseconds: delayInMilliseconds));
  
  // التحقق من وقت الترجمة
  final currentPosition = _controller.value.position;
  if (currentPosition < adjustedStartTime || currentPosition > adjustedEndTime) {
    return const SizedBox.shrink();
  }
  
  // إنشاء نمط الترجمة
  final textStyle = TextStyle(
    fontSize: subtitleSize,
    color: Color(int.parse('0xFF$subtitleColor')),
    backgroundColor: Color(int.parse('0xFF$subtitleBackground')).withOpacity(subtitleOpacity),
    shadows: [
      Shadow(
        color: Colors.black,
        offset: const Offset(1, 1),
        blurRadius: 1,
      ),
    ],
  );
  
  // تحديد موضع الترجمة
  Alignment alignment;
  switch (subtitlePosition) {
    case 'top':
      alignment = Alignment.topCenter;
      break;
    case 'middle':
      alignment = Alignment.center;
      break;
    case 'bottom':
    default:
      alignment = Alignment.bottomCenter;
      break;
  }
  
  return Align(
    alignment: alignment,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      margin: const EdgeInsets.all(16.0),
      child: Text(
        subtitle.text,
        style: textStyle,
        textAlign: TextAlign.center,
      ),
    ),
  );
}
```

## تحميل الترجمات تلقائيًا

يمكن تحميل الترجمات تلقائيًا عند تشغيل الفيديو:

```dart
Future<void> _loadSubtitles() async {
  final prefs = await SharedPreferences.getInstance();
  final subtitlesEnabled = prefs.getBool('subtitles_enabled') ?? true;
  
  if (!subtitlesEnabled) {
    return;
  }
  
  final subtitleLanguage = prefs.getString('subtitle_language') ?? 'ar';
  
  try {
    // البحث عن الترجمات
    final subtitles = await SubtitleService.searchSubtitles(widget.movie.imdbId, subtitleLanguage);
    
    if (subtitles.isNotEmpty) {
      // تنزيل الترجمة الأولى
      final subtitlePath = await SubtitleService.downloadSubtitle(subtitles.first.fileId);
      
      // تحميل محتوى الترجمة
      final subtitleContent = await loadSubtitleContent(subtitlePath);
      
      // تحليل الترجمة
      final parsedSubtitles = await parseSubtitle(subtitleContent);
      
      setState(() {
        _subtitles = parsedSubtitles;
      });
    }
  } catch (e) {
    print('Error loading subtitles: $e');
  }
}
```