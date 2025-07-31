# التغييرات الرئيسية في مشروع INDEX

## 1. إزالة Firebase

### تم إزالة التبعيات التالية من pubspec.yaml:
```yaml
firebase_analytics: ^10.8.0
firebase_auth: ^4.17.0
firebase_core: ^2.25.0
firebase_crashlytics: ^3.4.9
cloud_firestore: ^4.15.0
firebase_remote_config: ^4.3.9
google_sign_in: ^6.2.1
```

### تم تعديل main.dart:
- إزالة استيراد Firebase
- إزالة كود تهيئة Firebase
- تبسيط عملية بدء التشغيل

## 2. استبدال تسجيل دخول Google بتسجيل دخول الضيف

### تم تعديل auth_service.dart:
- إزالة كود مصادقة Firebase
- إضافة نظام مصادقة بسيط للضيوف
- إضافة طرق لحفظ وتحميل بيانات المستخدم باستخدام SharedPreferences

### تم تعديل splash_screen.dart:
- تحديث لتحميل بيانات المستخدم من SharedPreferences

### تم تعديل landing_screen.dart:
- استبدال زر تسجيل الدخول بـ Google بزر تسجيل دخول الضيف
- تحديث تدفق المصادقة لاستخدام نظام المصادقة الجديد

## 3. إضافة مفاتيح API

### تم إنشاء ملف .env مع مفاتيح API لـ:
- TMDB: `eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJjYTc2MDk3MTlhNTYxYjM0MWM4MDYyYzMzN2FiZTM5NyIsIm5iZiI6MTc0NDI5MzUwOC4xMDQsInN1YiI6IjY3ZjdjZTg0MzE3NzUyNzZkNmQ5OTM4OCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.jB-LdCFKnX7xETXv3UgAHXffgoCOFK9wfyr6Z8y4AzI`
- SUBDL: `l0cgAb7VNM_KMN2KwkLCFNuRsk8q3tEg`

### تم إنشاء ملف env.g.dart:
```dart
// Generated file - do not modify
part of 'env.dart';

class _Env {
  static const String tmdbAccessToken = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJjYTc2MDk3MTlhNTYxYjM0MWM4MDYyYzMzN2FiZTM5NyIsIm5iZiI6MTc0NDI5MzUwOC4xMDQsInN1YiI6IjY3ZjdjZTg0MzE3NzUyNzZkNmQ5OTM4OCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.jB-LdCFKnX7xETXv3UgAHXffgoCOFK9wfyr6Z8y4AzI';
  static const String subdlApiKey = 'l0cgAb7VNM_KMN2KwkLCFNuRsk8q3tEg';
}
```

## 4. تغيير اسم المشروع

### تم تغيير اسم المشروع في pubspec.yaml:
```yaml
name: index
description: "A VOD streaming application"
```

### تم تحديث main.dart:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.init();
  runApp(const Index());
}

class Index extends StatelessWidget {
  const Index({super.key});
  // ...
}
```

### تم تحديث جميع مسارات الاستيراد:
- من `package:semo/...` إلى `package:index/...`

### تم إعادة تسمية المكونات:
- من `SemoPlayer` إلى `IndexPlayer`

## 5. إنشاء سكريبت البناء

### تم إنشاء build_apk.sh:
```bash
#!/bin/bash

# Generate env.g.dart file
echo "// Generated file - do not modify" > lib/utils/env/env.g.dart
echo "part of 'env.dart';" >> lib/utils/env/env.g.dart
echo "" >> lib/utils/env/env.g.dart
echo "class _Env {" >> lib/utils/env/env.g.dart
echo "  static const String tmdbAccessToken = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJjYTc2MDk3MTlhNTYxYjM0MWM4MDYyYzMzN2FiZTM5NyIsIm5iZiI6MTc0NDI5MzUwOC4xMDQsInN1YiI6IjY3ZjdjZTg0MzE3NzUyNzZkNmQ5OTM4OCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.jB-LdCFKnX7xETXv3UgAHXffgoCOFK9wfyr6Z8y4AzI';" >> lib/utils/env/env.g.dart
echo "  static const String subdlApiKey = 'l0cgAb7VNM_KMN2KwkLCFNuRsk8q3tEg';" >> lib/utils/env/env.g.dart
echo "}" >> lib/utils/env/env.g.dart

# Build APK with the name INDEX
flutter build apk --release --split-per-abi -v --no-tree-shake-icons --build-name=1.0.0 --build-number=1 --target-platform android-arm,android-arm64,android-x64 --obfuscate --split-debug-info=./symbols

# Rename the APK files to INDEX
mkdir -p build/app/outputs/apk/release/INDEX
cp build/app/outputs/apk/release/app-armeabi-v7a-release.apk build/app/outputs/apk/release/INDEX/INDEX-armeabi-v7a-release.apk
cp build/app/outputs/apk/release/app-arm64-v8a-release.apk build/app/outputs/apk/release/INDEX/INDEX-arm64-v8a-release.apk
cp build/app/outputs/apk/release/app-x86_64-release.apk build/app/outputs/apk/release/INDEX/INDEX-x86_64-release.apk

echo "APK files have been built and renamed to INDEX"
```