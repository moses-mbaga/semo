# إعداد بيئة Flutter

## تثبيت Flutter

1. قم بتنزيل Flutter SDK من [الموقع الرسمي](https://flutter.dev/docs/get-started/install).

2. قم بفك ضغط الملف في المجلد الذي تريده، على سبيل المثال:
   - Windows: `C:\flutter`
   - macOS/Linux: `~/flutter`

3. أضف مجلد `flutter/bin` إلى متغير PATH الخاص بك.

4. تحقق من تثبيت Flutter:
   ```bash
   flutter doctor
   ```

5. قم بإصلاح أي مشاكل يشير إليها الأمر `flutter doctor`.

## إعداد Android Studio

1. قم بتنزيل وتثبيت [Android Studio](https://developer.android.com/studio).

2. قم بتشغيل Android Studio وإكمال معالج الإعداد.

3. قم بتثبيت إضافة Flutter:
   - افتح Android Studio
   - انتقل إلى File > Settings > Plugins
   - ابحث عن "Flutter" وقم بتثبيته
   - أعد تشغيل Android Studio

## إعداد VS Code (اختياري)

1. قم بتنزيل وتثبيت [VS Code](https://code.visualstudio.com/).

2. قم بتثبيت إضافة Flutter:
   - افتح VS Code
   - انتقل إلى Extensions (Ctrl+Shift+X)
   - ابحث عن "Flutter" وقم بتثبيته

## إعداد المشروع

1. استنسخ المشروع:
   ```bash
   git clone https://github.com/htrdjyfjy/semo.git
   cd semo
   git checkout remove-firebase-add-guest-auth
   ```

2. قم بتثبيت التبعيات:
   ```bash
   flutter pub get
   ```

3. قم بإنشاء ملف env.g.dart:
   ```bash
   chmod +x build_apk.sh
   ./build_apk.sh
   ```

4. قم بتشغيل التطبيق:
   ```bash
   flutter run
   ```

## استكشاف الأخطاء وإصلاحها

### مشاكل التبعيات

إذا واجهت مشاكل في التبعيات، جرب:
```bash
flutter clean
flutter pub get
```

### مشاكل الجهاز

تأكد من أن جهازك متصل ويمكن اكتشافه:
```bash
flutter devices
```

### مشاكل البناء

إذا واجهت مشاكل في البناء، جرب:
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### مشاكل Gradle

إذا واجهت مشاكل في Gradle، جرب:
```bash
cd android
./gradlew clean
cd ..
flutter run
```

## بناء التطبيق للإنتاج

### بناء APK

```bash
./build_apk.sh
```

أو

```bash
flutter build apk --release --split-per-abi -v --no-tree-shake-icons --build-name=1.0.0 --build-number=1 --target-platform android-arm,android-arm64,android-x64 --obfuscate --split-debug-info=./symbols
```

### بناء App Bundle

```bash
flutter build appbundle --release -v --no-tree-shake-icons --build-name=1.0.0 --build-number=1 --obfuscate --split-debug-info=./symbols
```

### بناء IPA (iOS)

```bash
flutter build ipa --release -v --no-tree-shake-icons --build-name=1.0.0 --build-number=1 --obfuscate --split-debug-info=./symbols
```