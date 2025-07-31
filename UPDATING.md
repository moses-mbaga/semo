# تحديث تطبيق INDEX

## تحديث التبعيات

### تحديث تبعيات Flutter

لتحديث تبعيات Flutter إلى أحدث إصدار متوافق:

```bash
flutter pub upgrade
```

لتحديث تبعيات Flutter إلى أحدث إصدار (قد يتطلب تغييرات في الكود):

```bash
flutter pub upgrade --major-versions
```

### تحديث إصدار Flutter

لتحديث إصدار Flutter نفسه:

```bash
flutter upgrade
```

## تحديث مفاتيح API

### تحديث مفتاح TMDB

1. قم بتحديث مفتاح TMDB في ملف `.env`:
   ```
   TMDB_ACCESS_TOKEN=your_new_tmdb_access_token
   ```

2. قم بتحديث مفتاح TMDB في ملف `lib/utils/env/env.g.dart`:
   ```dart
   static const String tmdbAccessToken = 'your_new_tmdb_access_token';
   ```

3. أو قم بتشغيل سكريبت البناء لتحديث الملف تلقائيًا:
   ```bash
   ./build_apk.sh
   ```

### تحديث مفتاح SUBDL

1. قم بتحديث مفتاح SUBDL في ملف `.env`:
   ```
   SUBDL_API_KEY=your_new_subdl_api_key
   ```

2. قم بتحديث مفتاح SUBDL في ملف `lib/utils/env/env.g.dart`:
   ```dart
   static const String subdlApiKey = 'your_new_subdl_api_key';
   ```

3. أو قم بتشغيل سكريبت البناء لتحديث الملف تلقائيًا:
   ```bash
   ./build_apk.sh
   ```

## تحديث إصدار التطبيق

### تحديث رقم الإصدار

قم بتحديث رقم الإصدار في ملف `pubspec.yaml`:

```yaml
version: 1.0.1+2  # تنسيق: version_name+version_code
```

حيث:
- `version_name` هو الإصدار المرئي للمستخدم (مثل 1.0.1)
- `version_code` هو رقم الإصدار الداخلي المستخدم للتحديثات (مثل 2)

### تحديث سكريبت البناء

قم بتحديث سكريبت البناء `build_apk.sh` لاستخدام رقم الإصدار الجديد:

```bash
flutter build apk --release --split-per-abi -v --no-tree-shake-icons --build-name=1.0.1 --build-number=2 --target-platform android-arm,android-arm64,android-x64 --obfuscate --split-debug-info=./symbols
```

## إضافة ميزات جديدة

### إضافة شاشة جديدة

1. أنشئ ملف الشاشة الجديدة في مجلد `lib/screens/`:
   ```dart
   import 'package:flutter/material.dart';

   class NewScreen extends StatefulWidget {
     const NewScreen({super.key});

     @override
     State<NewScreen> createState() => _NewScreenState();
   }

   class _NewScreenState extends State<NewScreen> {
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(
           title: const Text('شاشة جديدة'),
         ),
         body: const Center(
           child: Text('محتوى الشاشة الجديدة'),
         ),
       );
     }
   }
   ```

2. أضف الشاشة إلى نظام التنقل في التطبيق.

### إضافة خدمة جديدة

1. أنشئ ملف الخدمة الجديدة في مجلد `lib/services/`:
   ```dart
   class NewService {
     static Future<void> someFunction() async {
       // تنفيذ الوظيفة
     }
   }
   ```

2. استخدم الخدمة في التطبيق.

### إضافة نموذج جديد

1. أنشئ ملف النموذج الجديد في مجلد `lib/models/`:
   ```dart
   class NewModel {
     final int id;
     final String name;

     NewModel({
       required this.id,
       required this.name,
     });

     factory NewModel.fromJson(Map<String, dynamic> json) {
       return NewModel(
         id: json['id'],
         name: json['name'],
       );
     }

     Map<String, dynamic> toJson() {
       return {
         'id': id,
         'name': name,
       };
     }
   }
   ```

2. استخدم النموذج في التطبيق.

## تحديث واجهة المستخدم

### تحديث السمة

قم بتحديث سمة التطبيق في ملف `lib/main.dart`:

```dart
return MaterialApp(
  title: 'INDEX',
  theme: ThemeData(
    primaryColor: Colors.blue,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      secondary: Colors.orange,
    ),
    useMaterial3: true,
  ),
  // ...
);
```

### تحديث الشعار

1. استبدل ملفات الشعار في المجلدات المناسبة.
2. قم بتحديث ملف `pubspec.yaml` إذا لزم الأمر.

## بناء التطبيق المحدث

بعد إجراء التحديثات، قم ببناء التطبيق:

```bash
./build_apk.sh
```

أو

```bash
flutter build apk --release --split-per-abi -v --no-tree-shake-icons --build-name=1.0.1 --build-number=2 --target-platform android-arm,android-arm64,android-x64 --obfuscate --split-debug-info=./symbols
```

## نشر التحديث

### نشر التحديث على GitHub

1. قم بإنشاء إصدار جديد على GitHub:
   ```bash
   git tag -a v1.0.1 -m "إصدار 1.0.1"
   git push origin v1.0.1
   ```

2. قم بإنشاء إصدار جديد على صفحة الإصدارات في GitHub وقم بتحميل ملفات APK.

### نشر التحديث على متاجر التطبيقات

1. قم بتحضير ملفات APK أو App Bundle.
2. قم بتحميل الملفات إلى متجر Google Play أو متاجر التطبيقات الأخرى.
3. قم بتحديث وصف التطبيق وصور الشاشة إذا لزم الأمر.
4. قم بنشر التحديث.