# تطبيق INDEX

تطبيق INDEX هو تطبيق لمشاهدة الأفلام والمسلسلات، تم تعديله لإزالة ربط Firebase واستبدال تسجيل الدخول بـ Google بتسجيل دخول الضيف.

## الوثائق الإضافية

- [دليل الإعداد والبناء](README_SETUP.md)
- [التغييرات الرئيسية](CHANGES.md)
- [دليل الاستخدام](USAGE.md)
- [هيكل المشروع](PROJECT_STRUCTURE.md)

## الميزات

🗂 مكتبة شاملة

- الوصول إلى معظم الأفلام والمسلسلات.
- استكشاف مكتبة واسعة للعثور على شيء للجميع.

🎥 تشغيل البث

- تشغيل الأفلام والمسلسلات مباشرة باستخدام بث HLS عالي الجودة.
- خوادم بث متعددة لضمان المشاهدة دون انقطاع.

⏳ مزامنة تقدم المشاهدة

- مزامنة تلقائية لتقدم التشغيل للأفلام والحلقات.
- لن تفقد مكانك أبدًا، حتى إذا قمت بتبديل الأجهزة أو إعادة زيارة المحتوى لاحقًا.

🔠 ترجمات قابلة للتخصيص

- دعم لملفات الترجمة بتنسيق .srt.
- خيارات قابلة للتخصيص بالكامل.

## مفاتيح API

### TMDB
```
eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJjYTc2MDk3MTlhNTYxYjM0MWM4MDYyYzMzN2FiZTM5NyIsIm5iZiI6MTc0NDI5MzUwOC4xMDQsInN1YiI6IjY3ZjdjZTg0MzE3NzUyNzZkNmQ5OTM4OCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.jB-LdCFKnX7xETXv3UgAHXffgoCOFK9wfyr6Z8y4AzI
```

### SUBDL
```
l0cgAb7VNM_KMN2KwkLCFNuRsk8q3tEg
```

## التكنولوجيا المستخدمة

**العميل:** Flutter

**التخزين المحلي:** SharedPreferences

## التثبيت

المتطلبات الأساسية:
- [Flutter SDK](https://flutter.dev/) (أحدث إصدار مستقر).
- محرر التعليمات البرمجية (مثل [Android Studio](https://developer.android.com/studio) أو [VSCode](https://code.visualstudio.com/)).

التعليمات:

- استنسخ المستودع
```bash
git clone https://github.com/htrdjyfjy/semo.git
cd semo
git checkout remove-firebase-add-guest-auth
```

- قم بتثبيت التبعيات:
```bash
flutter pub get
```

- قم بإنشاء ملف env.g.dart:
```bash
chmod +x build_apk.sh
./build_apk.sh
```

- قم بتشغيل التطبيق:
```bash
flutter run
```

## بناء التطبيق

لبناء ملف APK:
```bash
./build_apk.sh
```

ستجد ملفات APK في المجلد:
```
build/app/outputs/apk/release/INDEX/
```

## الدعم

إذا واجهت أي مشاكل أو كان لديك اقتراحات، يرجى فتح مشكلة في قسم [GitHub Issues](https://github.com/htrdjyfjy/semo/issues).

استمتع بالمشاهدة مع INDEX! 🌟
