# تطبيق INDEX - دليل الإعداد والبناء

## نظرة عامة
تم تعديل هذا المشروع لإزالة ربط Firebase بالكامل واستبدال تسجيل الدخول بـ Google بتسجيل دخول الضيف. تم أيضًا تغيير اسم المشروع من "semo" إلى "INDEX".

## مفاتيح API
تم إضافة مفاتيح API التالية:

### TMDB
```
eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJjYTc2MDk3MTlhNTYxYjM0MWM4MDYyYzMzN2FiZTM5NyIsIm5iZiI6MTc0NDI5MzUwOC4xMDQsInN1YiI6IjY3ZjdjZTg0MzE3NzUyNzZkNmQ5OTM4OCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.jB-LdCFKnX7xETXv3UgAHXffgoCOFK9wfyr6Z8y4AzI
```

### SUBDL
```
l0cgAb7VNM_KMN2KwkLCFNuRsk8q3tEg
```

## خطوات الإعداد

### 1. تثبيت Flutter
تأكد من تثبيت Flutter على جهازك. يمكنك اتباع التعليمات في [الموقع الرسمي لـ Flutter](https://flutter.dev/docs/get-started/install).

### 2. استنساخ المشروع
```bash
git clone https://github.com/htrdjyfjy/semo.git
cd semo
git checkout remove-firebase-add-guest-auth
```

### 3. تثبيت التبعيات
```bash
flutter pub get
```

### 4. إنشاء ملف env.g.dart
قم بإنشاء ملف `lib/utils/env/env.g.dart` بالمحتوى التالي:

```dart
// Generated file - do not modify
part of 'env.dart';

class _Env {
  static const String tmdbAccessToken = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJjYTc2MDk3MTlhNTYxYjM0MWM4MDYyYzMzN2FiZTM5NyIsIm5iZiI6MTc0NDI5MzUwOC4xMDQsInN1YiI6IjY3ZjdjZTg0MzE3NzUyNzZkNmQ5OTM4OCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.jB-LdCFKnX7xETXv3UgAHXffgoCOFK9wfyr6Z8y4AzI';
  static const String subdlApiKey = 'l0cgAb7VNM_KMN2KwkLCFNuRsk8q3tEg';
}
```

أو يمكنك استخدام السكريبت المرفق:
```bash
chmod +x build_apk.sh
./build_apk.sh
```

## بناء التطبيق

### بناء APK
```bash
flutter build apk --release --split-per-abi -v --no-tree-shake-icons --build-name=1.0.0 --build-number=1 --target-platform android-arm,android-arm64,android-x64 --obfuscate --split-debug-info=./symbols
```

### إعادة تسمية ملفات APK
بعد بناء التطبيق، يمكنك إعادة تسمية ملفات APK:
```bash
mkdir -p build/app/outputs/apk/release/INDEX
cp build/app/outputs/apk/release/app-armeabi-v7a-release.apk build/app/outputs/apk/release/INDEX/INDEX-armeabi-v7a-release.apk
cp build/app/outputs/apk/release/app-arm64-v8a-release.apk build/app/outputs/apk/release/INDEX/INDEX-arm64-v8a-release.apk
cp build/app/outputs/apk/release/app-x86_64-release.apk build/app/outputs/apk/release/INDEX/INDEX-x86_64-release.apk
```

## التغييرات الرئيسية

1. **إزالة Firebase**:
   - تمت إزالة جميع تبعيات Firebase من ملف pubspec.yaml
   - تمت إزالة كود تهيئة Firebase من main.dart

2. **تسجيل دخول الضيف**:
   - تم استبدال تسجيل الدخول بـ Google بتسجيل دخول الضيف
   - تم تعديل خدمة المصادقة لاستخدام SharedPreferences لتخزين بيانات المستخدم

3. **تغيير اسم المشروع**:
   - تم تغيير اسم المشروع من "semo" إلى "index" في pubspec.yaml
   - تم تحديث جميع مسارات الاستيراد
   - تم تغيير اسم المكونات ذات الصلة

## ملاحظات إضافية

- تم تبسيط عملية المصادقة لتعمل بدون الاتصال بالإنترنت
- تم الاحتفاظ بجميع الوظائف الأخرى كما هي
- يمكن استخدام التطبيق بدون الحاجة إلى حساب Google

## استكشاف الأخطاء وإصلاحها

إذا واجهت أي مشاكل أثناء البناء، تأكد من:
1. تثبيت أحدث إصدار من Flutter
2. تشغيل `flutter doctor` للتحقق من وجود أي مشاكل في الإعداد
3. التأكد من وجود ملف env.g.dart في المسار الصحيح
4. تنظيف مجلد البناء باستخدام `flutter clean` ثم إعادة تثبيت التبعيات باستخدام `flutter pub get`