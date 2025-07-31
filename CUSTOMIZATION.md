# تخصيص تطبيق INDEX

## تخصيص الألوان

### تغيير الألوان الرئيسية

افتح ملف `lib/utils/colors.dart` وقم بتغيير الألوان الرئيسية:

```dart
class AppColors {
  static const Color primary = Color(0xFFYOUR_COLOR);
  static const Color secondary = Color(0xFFYOUR_COLOR);
  static const Color accent = Color(0xFFYOUR_COLOR);
  // ...
}
```

### تغيير سمة التطبيق

افتح ملف `lib/main.dart` وقم بتغيير سمة التطبيق:

```dart
return MaterialApp(
  title: 'INDEX',
  theme: ThemeData(
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      secondary: AppColors.secondary,
    ),
    // ...
  ),
  // ...
);
```

## تخصيص الشعار والأيقونات

### تغيير شعار التطبيق

1. استبدل ملفات الشعار في المجلدات التالية:
   - `android/app/src/main/res/mipmap-*`
   - `ios/Runner/Assets.xcassets/AppIcon.appiconset`

2. يمكنك استخدام أدوات مثل [Flutter Launcher Icons](https://pub.dev/packages/flutter_launcher_icons) لتوليد الأيقونات تلقائيًا:

   أضف التبعية إلى `pubspec.yaml`:
   ```yaml
   dev_dependencies:
     flutter_launcher_icons: ^0.13.1
   ```

   أضف التكوين إلى `pubspec.yaml`:
   ```yaml
   flutter_launcher_icons:
     android: true
     ios: true
     image_path: "assets/images/logo.png"
     adaptive_icon_background: "#FFFFFF"
     adaptive_icon_foreground: "assets/images/logo_foreground.png"
   ```

   ثم قم بتشغيل:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

### تغيير شاشة البداية

1. استبدل ملفات شاشة البداية في المجلدات التالية:
   - `android/app/src/main/res/drawable/launch_background.xml`
   - `android/app/src/main/res/drawable-v21/launch_background.xml`
   - `ios/Runner/Assets.xcassets/LaunchImage.imageset`

2. يمكنك استخدام أدوات مثل [Flutter Native Splash](https://pub.dev/packages/flutter_native_splash) لتوليد شاشة البداية تلقائيًا:

   أضف التبعية إلى `pubspec.yaml`:
   ```yaml
   dev_dependencies:
     flutter_native_splash: ^2.3.6
   ```

   أضف التكوين إلى `pubspec.yaml`:
   ```yaml
   flutter_native_splash:
     color: "#FFFFFF"
     image: "assets/images/splash.png"
     android: true
     ios: true
   ```

   ثم قم بتشغيل:
   ```bash
   flutter pub get
   flutter pub run flutter_native_splash:create
   ```

## تخصيص الخطوط

1. أضف ملفات الخطوط إلى مجلد `assets/fonts/`.

2. قم بتسجيل الخطوط في `pubspec.yaml`:
   ```yaml
   flutter:
     fonts:
       - family: YourFont
         fonts:
           - asset: assets/fonts/YourFont-Regular.ttf
           - asset: assets/fonts/YourFont-Bold.ttf
             weight: 700
           - asset: assets/fonts/YourFont-Italic.ttf
             style: italic
   ```

3. استخدم الخط في سمة التطبيق:
   ```dart
   return MaterialApp(
     theme: ThemeData(
       fontFamily: 'YourFont',
       // ...
     ),
     // ...
   );
   ```

## تخصيص واجهة المستخدم

### تغيير شاشة تسجيل الدخول

افتح ملف `lib/screens/landing_screen.dart` وقم بتخصيص واجهة المستخدم:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      decoration: BoxDecoration(
        // تغيير خلفية الشاشة
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue, Colors.purple],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // تغيير شعار الشاشة
            Image.asset(
              'assets/images/your_logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 30),
            // تغيير نص الترحيب
            const Text(
              'مرحبًا بك في تطبيقك',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 50),
            // تخصيص زر تسجيل الدخول
            ElevatedButton(
              onPressed: () => _signInAsGuest(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'تسجيل الدخول كضيف',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

### تخصيص الشاشة الرئيسية

افتح ملف `lib/screens/fragments_screen.dart` وقم بتخصيص شريط التنقل:

```dart
return Scaffold(
  body: _screens[_currentIndex],
  bottomNavigationBar: BottomNavigationBar(
    currentIndex: _currentIndex,
    onTap: (index) => setState(() => _currentIndex = index),
    selectedItemColor: AppColors.primary,
    unselectedItemColor: Colors.grey,
    type: BottomNavigationBarType.fixed,
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'الرئيسية',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.search),
        label: 'بحث',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.favorite),
        label: 'المفضلة',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'الإعدادات',
      ),
    ],
  ),
);
```

## تخصيص مشغل الفيديو

افتح ملف `lib/components/index_player.dart` وقم بتخصيص مشغل الفيديو:

```dart
// تخصيص أزرار التحكم
IconButton(
  icon: Icon(
    _controller.value.isPlaying
        ? Icons.pause_circle_filled
        : Icons.play_circle_filled,
    color: Colors.white,
    size: 50,
  ),
  onPressed: _togglePlayPause,
),

// تخصيص شريط التقدم
Slider(
  value: _position.inSeconds.toDouble(),
  min: 0.0,
  max: _duration.inSeconds.toDouble(),
  activeColor: AppColors.primary,
  inactiveColor: Colors.white30,
  onChanged: (value) {
    _seekTo(Duration(seconds: value.toInt()));
  },
),
```

## تخصيص إعدادات التطبيق

افتح ملف `lib/screens/settings_screen.dart` وقم بإضافة خيارات إعدادات جديدة:

```dart
ListTile(
  leading: const Icon(Icons.color_lens),
  title: const Text('سمة التطبيق'),
  subtitle: const Text('اختر سمة التطبيق المفضلة لديك'),
  onTap: () {
    // افتح شاشة اختيار السمة
  },
),

ListTile(
  leading: const Icon(Icons.language),
  title: const Text('اللغة'),
  subtitle: const Text('اختر لغة التطبيق'),
  onTap: () {
    // افتح شاشة اختيار اللغة
  },
),
```