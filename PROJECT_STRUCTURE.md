# هيكل مشروع INDEX

## الملفات الرئيسية

- `lib/main.dart`: نقطة الدخول الرئيسية للتطبيق
- `lib/utils/env/env.dart`: ملف البيئة الذي يحتوي على مفاتيح API
- `lib/utils/env/env.g.dart`: ملف البيئة المولد تلقائيًا
- `pubspec.yaml`: ملف تكوين المشروع والتبعيات

## المجلدات الرئيسية

### lib/screens
يحتوي على جميع شاشات التطبيق:
- `splash_screen.dart`: شاشة البداية
- `landing_screen.dart`: شاشة تسجيل الدخول
- `fragments_screen.dart`: الشاشة الرئيسية مع علامات التبويب
- `movies_screen.dart`: شاشة الأفلام
- `tv_shows_screen.dart`: شاشة المسلسلات
- `search_screen.dart`: شاشة البحث
- `favorites_screen.dart`: شاشة المفضلة
- `settings_screen.dart`: شاشة الإعدادات
- `player_screen.dart`: شاشة مشغل الفيديو

### lib/components
يحتوي على المكونات القابلة لإعادة الاستخدام:
- `index_player.dart`: مكون مشغل الفيديو
- `media_card.dart`: بطاقة عرض الوسائط
- `carousel_slider.dart`: عارض الشرائح
- وغيرها من المكونات المستخدمة في واجهة المستخدم

### lib/models
يحتوي على نماذج البيانات:
- `movie.dart`: نموذج الفيلم
- `tv_show.dart`: نموذج المسلسل
- `episode.dart`: نموذج الحلقة
- `season.dart`: نموذج الموسم
- `person.dart`: نموذج الشخص
- `media_stream.dart`: نموذج بث الوسائط
- وغيرها من النماذج المستخدمة في التطبيق

### lib/services
يحتوي على خدمات التطبيق:
- `auth_service.dart`: خدمة المصادقة
- `tmdb_service.dart`: خدمة واجهة برمجة تطبيقات TMDB
- `subtitle_service.dart`: خدمة الترجمة
- `preferences.dart`: خدمة التفضيلات
- `stream_extractor/`: مجلد يحتوي على مستخرجات البث

### lib/bloc
يحتوي على منطق إدارة الحالة باستخدام نمط BLoC:
- `app_bloc.dart`: BLoC الرئيسي للتطبيق
- `app_event.dart`: أحداث التطبيق
- `app_state.dart`: حالة التطبيق
- `handlers/`: مجلد يحتوي على معالجات الأحداث

### lib/utils
يحتوي على الأدوات المساعدة:
- `urls.dart`: عناوين URL المستخدمة في التطبيق
- `secrets.dart`: الأسرار والمفاتيح
- `navigation_helper.dart`: مساعد التنقل
- `string_extension.dart`: امتدادات السلسلة النصية

### lib/enums
يحتوي على التعدادات المستخدمة في التطبيق:
- `media_type.dart`: أنواع الوسائط

## ملفات الموارد

### assets
يحتوي على موارد التطبيق:
- `images/`: الصور المستخدمة في التطبيق
- `fonts/`: الخطوط المستخدمة في التطبيق

## ملفات البناء

- `build_apk.sh`: سكريبت لبناء ملفات APK
- `update_imports.sh`: سكريبت لتحديث مسارات الاستيراد

## ملفات التوثيق

- `README_SETUP.md`: دليل الإعداد والبناء
- `CHANGES.md`: التغييرات الرئيسية في المشروع
- `USAGE.md`: دليل استخدام التطبيق
- `PROJECT_STRUCTURE.md`: هيكل المشروع