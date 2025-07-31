# تغيير اسم التطبيق

إذا كنت ترغب في تغيير اسم التطبيق من "INDEX" إلى اسم آخر، اتبع الخطوات التالية:

## 1. تغيير اسم المشروع في pubspec.yaml

افتح ملف `pubspec.yaml` وقم بتغيير السطر الأول:

```yaml
name: your_app_name
description: "A VOD streaming application"
```

## 2. تحديث اسم التطبيق في main.dart

افتح ملف `lib/main.dart` وقم بتغيير اسم الفئة الرئيسية:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.init();
  runApp(const YourAppName());
}

class YourAppName extends StatelessWidget {
  const YourAppName({super.key});
  // ...
}
```

## 3. تحديث اسم التطبيق في Android

### android/app/src/main/AndroidManifest.xml

افتح ملف `android/app/src/main/AndroidManifest.xml` وقم بتغيير اسم التطبيق:

```xml
<application
    android:label="Your App Name"
    ...>
```

### android/app/build.gradle

افتح ملف `android/app/build.gradle` وقم بتغيير applicationId:

```gradle
defaultConfig {
    applicationId "com.example.yourappname"
    ...
}
```

## 4. تحديث اسم التطبيق في iOS

### ios/Runner/Info.plist

افتح ملف `ios/Runner/Info.plist` وقم بتغيير اسم التطبيق:

```xml
<key>CFBundleName</key>
<string>Your App Name</string>
<key>CFBundleDisplayName</key>
<string>Your App Name</string>
```

## 5. تحديث مسارات الاستيراد

قم بتشغيل السكريبت التالي لتحديث جميع مسارات الاستيراد:

```bash
chmod +x update_imports.sh
./update_imports.sh index your_app_name
```

## 6. إعادة تسمية المكونات

قم بإعادة تسمية المكونات التي تحتوي على اسم التطبيق:

- `lib/components/index_player.dart` إلى `lib/components/your_app_name_player.dart`

وقم بتحديث جميع الاستيرادات والاستخدامات ذات الصلة.

## 7. تحديث سكريبت البناء

افتح ملف `build_apk.sh` وقم بتغيير اسم التطبيق:

```bash
# Rename the APK files
mkdir -p build/app/outputs/apk/release/YOUR_APP_NAME
cp build/app/outputs/apk/release/app-armeabi-v7a-release.apk build/app/outputs/apk/release/YOUR_APP_NAME/YOUR_APP_NAME-armeabi-v7a-release.apk
cp build/app/outputs/apk/release/app-arm64-v8a-release.apk build/app/outputs/apk/release/YOUR_APP_NAME/YOUR_APP_NAME-arm64-v8a-release.apk
cp build/app/outputs/apk/release/app-x86_64-release.apk build/app/outputs/apk/release/YOUR_APP_NAME/YOUR_APP_NAME-x86_64-release.apk
```

## 8. إعادة تثبيت التبعيات

بعد إجراء جميع التغييرات، قم بتنظيف المشروع وإعادة تثبيت التبعيات:

```bash
flutter clean
flutter pub get
```

## 9. اختبار التطبيق

قم بتشغيل التطبيق للتأكد من أن جميع التغييرات تعمل بشكل صحيح:

```bash
flutter run
```

## 10. بناء التطبيق

قم ببناء التطبيق باستخدام الاسم الجديد:

```bash
./build_apk.sh
```