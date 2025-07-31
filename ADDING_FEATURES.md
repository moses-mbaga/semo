# إضافة ميزات جديدة إلى تطبيق INDEX

## إضافة دعم اللغات المتعددة

### 1. إضافة حزمة الترجمة

أضف حزمة `flutter_localizations` إلى `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.18.0
```

### 2. إنشاء ملفات الترجمة

أنشئ مجلد `lib/l10n` وأضف ملفات الترجمة:

`lib/l10n/app_ar.arb` (العربية):
```json
{
  "appTitle": "INDEX",
  "homeTitle": "الرئيسية",
  "searchTitle": "بحث",
  "favoritesTitle": "المفضلة",
  "settingsTitle": "الإعدادات",
  "signInAsGuest": "تسجيل الدخول كضيف",
  "welcomeMessage": "مرحبًا بك في تطبيق INDEX"
}
```

`lib/l10n/app_en.arb` (الإنجليزية):
```json
{
  "appTitle": "INDEX",
  "homeTitle": "Home",
  "searchTitle": "Search",
  "favoritesTitle": "Favorites",
  "settingsTitle": "Settings",
  "signInAsGuest": "Sign in as Guest",
  "welcomeMessage": "Welcome to INDEX app"
}
```

### 3. تكوين الترجمة في `pubspec.yaml`

أضف تكوين الترجمة إلى `pubspec.yaml`:

```yaml
flutter:
  generate: true
  uses-material-design: true
  
flutter_intl:
  enabled: true
  class_name: AppLocalizations
  main_locale: ar
  arb_dir: lib/l10n
  output_dir: lib/generated
```

### 4. تكوين الترجمة في `main.dart`

قم بتحديث `main.dart` لدعم الترجمة:

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// ...

return MaterialApp(
  title: 'INDEX',
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('ar'), // العربية
    Locale('en'), // الإنجليزية
  ],
  locale: const Locale('ar'), // اللغة الافتراضية
  // ...
);
```

### 5. استخدام الترجمة في التطبيق

استخدم الترجمة في الشاشات:

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// ...

Text(AppLocalizations.of(context)!.welcomeMessage)
```

## إضافة وضع الظلام

### 1. إضافة مزود السمة

قم بتحديث `main.dart` لدعم وضع الظلام:

```dart
import 'package:provider/provider.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

// ...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.init();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const Index(),
    ),
  );
}

class Index extends StatelessWidget {
  const Index({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'INDEX',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        // ...
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        // ...
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      // ...
    );
  }
}
```

### 2. إضافة زر تبديل السمة

أضف زر تبديل السمة إلى شاشة الإعدادات:

```dart
SwitchListTile(
  title: const Text('الوضع الداكن'),
  value: Provider.of<ThemeProvider>(context).isDarkMode,
  onChanged: (value) {
    Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
  },
),
```

## إضافة ميزة التنزيل

### 1. إضافة التبعيات

أضف التبعيات اللازمة إلى `pubspec.yaml`:

```yaml
dependencies:
  flutter_downloader: ^1.11.1
  path_provider: ^2.1.1
  permission_handler: ^11.0.1
```

### 2. إنشاء خدمة التنزيل

أنشئ ملف `lib/services/download_service.dart`:

```dart
import 'dart:io';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadService {
  static Future<void> initialize() async {
    await FlutterDownloader.initialize();
  }

  static Future<String?> downloadVideo(String url, String fileName) async {
    final status = await Permission.storage.request();
    
    if (status.isGranted) {
      final directory = await getExternalStorageDirectory();
      final downloadsDir = Directory('${directory!.path}/Downloads');
      
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      
      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: downloadsDir.path,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: true,
      );
      
      return taskId;
    } else {
      return null;
    }
  }

  static Future<void> cancelDownload(String taskId) async {
    await FlutterDownloader.cancel(taskId: taskId);
  }

  static Future<void> pauseDownload(String taskId) async {
    await FlutterDownloader.pause(taskId: taskId);
  }

  static Future<void> resumeDownload(String taskId) async {
    await FlutterDownloader.resume(taskId: taskId);
  }
}
```

### 3. تهيئة خدمة التنزيل

قم بتحديث `main.dart` لتهيئة خدمة التنزيل:

```dart
import 'package:index/services/download_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.init();
  await DownloadService.initialize();
  
  // ...
}
```

### 4. إضافة زر التنزيل

أضف زر التنزيل إلى شاشة تفاصيل الفيلم أو المسلسل:

```dart
ElevatedButton.icon(
  icon: const Icon(Icons.download),
  label: const Text('تنزيل'),
  onPressed: () async {
    final taskId = await DownloadService.downloadVideo(
      movie.streamUrl,
      '${movie.title}.mp4',
    );
    
    if (taskId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('بدأ التنزيل')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل التنزيل')),
      );
    }
  },
),
```

## إضافة ميزة المشاركة

### 1. إضافة التبعية

أضف التبعية اللازمة إلى `pubspec.yaml`:

```yaml
dependencies:
  share_plus: ^7.2.1
```

### 2. إضافة زر المشاركة

أضف زر المشاركة إلى شاشة تفاصيل الفيلم أو المسلسل:

```dart
import 'package:share_plus/share_plus.dart';

// ...

IconButton(
  icon: const Icon(Icons.share),
  onPressed: () {
    Share.share(
      'شاهد ${movie.title} على تطبيق INDEX!\n'
      'https://example.com/movies/${movie.id}',
    );
  },
),
```

## إضافة ميزة الإشعارات

### 1. إضافة التبعيات

أضف التبعيات اللازمة إلى `pubspec.yaml`:

```yaml
dependencies:
  flutter_local_notifications: ^16.1.0
  timezone: ^0.9.2
```

### 2. إنشاء خدمة الإشعارات

أنشئ ملف `lib/services/notification_service.dart`:

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(initSettings);
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'index_channel',
      'INDEX Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(id, title, body, details);
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'index_channel',
      'INDEX Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
```

### 3. تهيئة خدمة الإشعارات

قم بتحديث `main.dart` لتهيئة خدمة الإشعارات:

```dart
import 'package:index/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.init();
  await NotificationService.initialize();
  
  // ...
}
```

### 4. إضافة زر التذكير

أضف زر التذكير إلى شاشة تفاصيل المسلسل:

```dart
ElevatedButton.icon(
  icon: const Icon(Icons.notifications),
  label: const Text('تذكير بالحلقة القادمة'),
  onPressed: () async {
    final now = DateTime.now();
    final scheduledDate = now.add(const Duration(days: 7));
    
    await NotificationService.scheduleNotification(
      id: tvShow.id,
      title: 'تذكير بالحلقة القادمة',
      body: 'الحلقة القادمة من ${tvShow.title} ستكون متاحة قريبًا!',
      scheduledDate: scheduledDate,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تعيين التذكير')),
    );
  },
),
```