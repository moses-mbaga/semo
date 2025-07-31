# تشغيل تطبيق INDEX في بيئات مختلفة

## تشغيل التطبيق في وضع التطوير

### تشغيل التطبيق على جهاز Android

1. قم بتوصيل جهاز Android بجهاز الكمبيوتر وتمكين وضع المطور وتصحيح USB.
2. تأكد من أن الجهاز معترف به:
   ```bash
   flutter devices
   ```
3. قم بتشغيل التطبيق:
   ```bash
   flutter run
   ```

### تشغيل التطبيق على محاكي Android

1. قم بتشغيل محاكي Android.
2. تأكد من أن المحاكي معترف به:
   ```bash
   flutter devices
   ```
3. قم بتشغيل التطبيق:
   ```bash
   flutter run
   ```

### تشغيل التطبيق على جهاز iOS

1. قم بتوصيل جهاز iOS بجهاز Mac.
2. تأكد من أن الجهاز معترف به:
   ```bash
   flutter devices
   ```
3. قم بتشغيل التطبيق:
   ```bash
   flutter run
   ```

### تشغيل التطبيق على محاكي iOS

1. قم بتشغيل محاكي iOS.
2. تأكد من أن المحاكي معترف به:
   ```bash
   flutter devices
   ```
3. قم بتشغيل التطبيق:
   ```bash
   flutter run
   ```

### تشغيل التطبيق على الويب

1. قم بتشغيل التطبيق على الويب:
   ```bash
   flutter run -d chrome
   ```

## تشغيل التطبيق في وضع الإصدار

### تشغيل التطبيق على جهاز Android في وضع الإصدار

```bash
flutter run --release
```

### تشغيل التطبيق على جهاز iOS في وضع الإصدار

```bash
flutter run --release
```

## تشغيل التطبيق مع خيارات مختلفة

### تشغيل التطبيق مع Hot Reload

Hot Reload يسمح لك بتطبيق التغييرات على التطبيق دون إعادة تشغيله بالكامل:

1. قم بتشغيل التطبيق:
   ```bash
   flutter run
   ```
2. بعد إجراء تغييرات على الكود، اضغط على `r` في نافذة الطرفية لتطبيق التغييرات.

### تشغيل التطبيق مع Hot Restart

Hot Restart يعيد تشغيل التطبيق بالكامل مع الاحتفاظ بحالة التطبيق:

1. قم بتشغيل التطبيق:
   ```bash
   flutter run
   ```
2. بعد إجراء تغييرات على الكود، اضغط على `R` في نافذة الطرفية لإعادة تشغيل التطبيق.

### تشغيل التطبيق مع تصحيح الأخطاء

```bash
flutter run --debug
```

### تشغيل التطبيق مع ملف تكوين مختلف

```bash
flutter run --flavor development
```

## تشغيل التطبيق مع بيئات مختلفة

### تشغيل التطبيق في بيئة التطوير

1. قم بإنشاء ملف `.env.development`:
   ```
   TMDB_ACCESS_TOKEN=your_development_tmdb_access_token
   SUBDL_API_KEY=your_development_subdl_api_key
   ```

2. قم بتشغيل التطبيق مع البيئة المحددة:
   ```bash
   flutter run --dart-define=ENV=development
   ```

### تشغيل التطبيق في بيئة الإنتاج

1. قم بإنشاء ملف `.env.production`:
   ```
   TMDB_ACCESS_TOKEN=your_production_tmdb_access_token
   SUBDL_API_KEY=your_production_subdl_api_key
   ```

2. قم بتشغيل التطبيق مع البيئة المحددة:
   ```bash
   flutter run --dart-define=ENV=production
   ```

## تشغيل التطبيق مع خيارات إضافية

### تشغيل التطبيق مع تسجيل الدخول التلقائي

```bash
flutter run --dart-define=AUTO_LOGIN=true
```

### تشغيل التطبيق مع وضع التصحيح المفصل

```bash
flutter run --verbose
```

### تشغيل التطبيق مع تعطيل تحسين الشجرة

```bash
flutter run --no-tree-shake-icons
```

## تشغيل التطبيق من ملف APK

بعد بناء التطبيق، يمكنك تثبيته وتشغيله على جهاز Android:

```bash
adb install build/app/outputs/apk/release/INDEX/INDEX-arm64-v8a-release.apk
```

## تشغيل التطبيق من ملف IPA

بعد بناء التطبيق، يمكنك تثبيته وتشغيله على جهاز iOS باستخدام Xcode أو Apple Configurator.

## تشغيل اختبارات التطبيق

### تشغيل اختبارات الوحدة

```bash
flutter test
```

### تشغيل اختبارات التكامل

```bash
flutter test integration_test
```

### تشغيل اختبارات محددة

```bash
flutter test test/specific_test.dart
```

## تشغيل التطبيق مع أدوات التطوير

### تشغيل التطبيق مع DevTools

1. قم بتشغيل التطبيق:
   ```bash
   flutter run
   ```
2. اضغط على `d` في نافذة الطرفية لفتح DevTools.

### تشغيل التطبيق مع Performance Overlay

```bash
flutter run --profile --trace-skia
```

### تشغيل التطبيق مع تحليل الأداء

```bash
flutter run --profile
```