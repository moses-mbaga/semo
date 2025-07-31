# تخصيص واجهة المستخدم في تطبيق INDEX

## نظرة عامة

يوفر تطبيق INDEX واجهة مستخدم قابلة للتخصيص بالكامل. يمكنك تعديل الألوان والخطوط والأيقونات والتخطيط وغيرها من عناصر واجهة المستخدم.

## تخصيص السمة

### تغيير الألوان الرئيسية

يمكنك تغيير الألوان الرئيسية للتطبيق في ملف `lib/utils/colors.dart`:

```dart
import 'package:flutter/material.dart';

class AppColors {
  // الألوان الرئيسية
  static const Color primary = Color(0xFF1E88E5); // أزرق
  static const Color secondary = Color(0xFFFF8F00); // برتقالي
  static const Color accent = Color(0xFF00C853); // أخضر
  
  // ألوان الخلفية
  static const Color background = Color(0xFF121212); // أسود
  static const Color surface = Color(0xFF1E1E1E); // رمادي داكن
  static const Color card = Color(0xFF2C2C2C); // رمادي
  
  // ألوان النص
  static const Color textPrimary = Color(0xFFFFFFFF); // أبيض
  static const Color textSecondary = Color(0xFFB0B0B0); // رمادي فاتح
  static const Color textHint = Color(0xFF808080); // رمادي متوسط
  
  // ألوان الحالة
  static const Color success = Color(0xFF00C853); // أخضر
  static const Color error = Color(0xFFD50000); // أحمر
  static const Color warning = Color(0xFFFFD600); // أصفر
  static const Color info = Color(0xFF2196F3); // أزرق فاتح
  
  // ألوان أخرى
  static const Color divider = Color(0xFF424242); // رمادي داكن
  static const Color shadow = Color(0x40000000); // أسود شفاف
}
```

### تطبيق السمة في التطبيق

يمكنك تطبيق السمة في ملف `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:index/utils/colors.dart';

class Index extends StatelessWidget {
  const Index({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'INDEX',
      theme: ThemeData(
        // الألوان الرئيسية
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          background: AppColors.background,
          error: AppColors.error,
        ),
        
        // ألوان الخلفية
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.card,
        dividerColor: AppColors.divider,
        
        // ألوان النص
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: AppColors.textPrimary),
          displayMedium: TextStyle(color: AppColors.textPrimary),
          displaySmall: TextStyle(color: AppColors.textPrimary),
          headlineLarge: TextStyle(color: AppColors.textPrimary),
          headlineMedium: TextStyle(color: AppColors.textPrimary),
          headlineSmall: TextStyle(color: AppColors.textPrimary),
          titleLarge: TextStyle(color: AppColors.textPrimary),
          titleMedium: TextStyle(color: AppColors.textPrimary),
          titleSmall: TextStyle(color: AppColors.textPrimary),
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textPrimary),
          bodySmall: TextStyle(color: AppColors.textSecondary),
          labelLarge: TextStyle(color: AppColors.textPrimary),
          labelMedium: TextStyle(color: AppColors.textSecondary),
          labelSmall: TextStyle(color: AppColors.textHint),
        ),
        
        // أنماط المكونات
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
        cardTheme: CardTheme(
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: AppColors.shadow,
        ),
        
        // إعدادات أخرى
        useMaterial3: true,
      ),
      // ...
    );
  }
}
```

### إضافة وضع الظلام

يمكنك إضافة وضع الظلام في ملف `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:index/utils/colors.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

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
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      // ...
    );
  }
  
  ThemeData _buildLightTheme() {
    return ThemeData(
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: Colors.white,
        background: Color(0xFFF5F5F5),
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      cardColor: Colors.white,
      dividerColor: Colors.grey.shade300,
      // ...
    );
  }
  
  ThemeData _buildDarkTheme() {
    return ThemeData(
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.card,
      dividerColor: AppColors.divider,
      // ...
    );
  }
}
```

## تخصيص الخطوط

### إضافة خطوط مخصصة

1. أضف ملفات الخطوط إلى مجلد `assets/fonts/`.

2. قم بتسجيل الخطوط في ملف `pubspec.yaml`:

```yaml
flutter:
  fonts:
    - family: Cairo
      fonts:
        - asset: assets/fonts/Cairo-Regular.ttf
        - asset: assets/fonts/Cairo-Bold.ttf
          weight: 700
        - asset: assets/fonts/Cairo-Light.ttf
          weight: 300
```

3. قم بتطبيق الخطوط في ملف `lib/main.dart`:

```dart
ThemeData _buildDarkTheme() {
  return ThemeData(
    // ...
    fontFamily: 'Cairo',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
    ),
    // ...
  );
}
```

## تخصيص الأيقونات

### استخدام أيقونات مخصصة

1. أضف حزمة أيقونات مخصصة:

```yaml
dependencies:
  flutter_icons: ^1.1.0
```

2. استخدم الأيقونات في التطبيق:

```dart
import 'package:flutter_icons/flutter_icons.dart';

// ...

Icon(Feather.home),
Icon(Feather.search),
Icon(Feather.heart),
Icon(Feather.settings),
```

### إنشاء أيقونات مخصصة

يمكنك إنشاء أيقونات مخصصة باستخدام حزمة `flutter_svg`:

```dart
import 'package:flutter_svg/flutter_svg.dart';

// ...

SvgPicture.asset(
  'assets/icons/custom_icon.svg',
  width: 24,
  height: 24,
  color: AppColors.primary,
),
```

## تخصيص التخطيط

### تخصيص شريط التنقل السفلي

يمكنك تخصيص شريط التنقل السفلي في ملف `lib/screens/fragments_screen.dart`:

```dart
BottomNavigationBar(
  currentIndex: _currentIndex,
  onTap: (index) => setState(() => _currentIndex = index),
  selectedItemColor: AppColors.primary,
  unselectedItemColor: AppColors.textSecondary,
  backgroundColor: AppColors.surface,
  type: BottomNavigationBarType.fixed,
  showSelectedLabels: true,
  showUnselectedLabels: true,
  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
  elevation: 8,
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
```

### تخصيص شريط التطبيق

يمكنك تخصيص شريط التطبيق في ملف `lib/screens/movies_screen.dart`:

```dart
AppBar(
  title: const Text('الأفلام'),
  backgroundColor: AppColors.surface,
  elevation: 0,
  centerTitle: true,
  leading: IconButton(
    icon: const Icon(Icons.menu),
    onPressed: () {
      // فتح القائمة الجانبية
    },
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.filter_list),
      onPressed: () {
        // فتح شاشة التصفية
      },
    ),
    IconButton(
      icon: const Icon(Icons.sort),
      onPressed: () {
        // فتح شاشة الترتيب
      },
    ),
  ],
),
```

### تخصيص القائمة الجانبية

يمكنك إضافة قائمة جانبية مخصصة:

```dart
Drawer(
  child: Container(
    color: AppColors.surface,
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(
            color: AppColors.primary,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 30,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'مرحبًا، ضيف',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'إصدار التطبيق: 1.0.0',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.home, color: AppColors.primary),
          title: const Text('الرئيسية'),
          onTap: () {
            Navigator.pop(context);
            // الانتقال إلى الشاشة الرئيسية
          },
        ),
        ListTile(
          leading: const Icon(Icons.movie, color: AppColors.primary),
          title: const Text('الأفلام'),
          onTap: () {
            Navigator.pop(context);
            // الانتقال إلى شاشة الأفلام
          },
        ),
        ListTile(
          leading: const Icon(Icons.tv, color: AppColors.primary),
          title: const Text('المسلسلات'),
          onTap: () {
            Navigator.pop(context);
            // الانتقال إلى شاشة المسلسلات
          },
        ),
        const Divider(color: AppColors.divider),
        ListTile(
          leading: const Icon(Icons.favorite, color: AppColors.primary),
          title: const Text('المفضلة'),
          onTap: () {
            Navigator.pop(context);
            // الانتقال إلى شاشة المفضلة
          },
        ),
        ListTile(
          leading: const Icon(Icons.history, color: AppColors.primary),
          title: const Text('سجل المشاهدة'),
          onTap: () {
            Navigator.pop(context);
            // الانتقال إلى شاشة سجل المشاهدة
          },
        ),
        const Divider(color: AppColors.divider),
        ListTile(
          leading: const Icon(Icons.settings, color: AppColors.primary),
          title: const Text('الإعدادات'),
          onTap: () {
            Navigator.pop(context);
            // الانتقال إلى شاشة الإعدادات
          },
        ),
        ListTile(
          leading: const Icon(Icons.info, color: AppColors.primary),
          title: const Text('حول التطبيق'),
          onTap: () {
            Navigator.pop(context);
            // الانتقال إلى شاشة حول التطبيق
          },
        ),
      ],
    ),
  ),
),
```

## تخصيص بطاقات العرض

### تخصيص بطاقة الفيلم

يمكنك تخصيص بطاقة الفيلم في ملف `lib/components/media_card.dart`:

```dart
class MediaCard extends StatelessWidget {
  final String title;
  final String? posterPath;
  final double voteAverage;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  
  const MediaCard({
    super.key,
    required this.title,
    this.posterPath,
    required this.voteAverage,
    required this.onTap,
    this.isFavorite = false,
    required this.onFavoriteToggle,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة الملصق
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: posterPath != null
                      ? CachedNetworkImage(
                          imageUrl: 'https://image.tmdb.org/t/p/w500$posterPath',
                          width: 150,
                          height: 225,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 150,
                            height: 225,
                            color: Colors.grey.shade800,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 150,
                            height: 225,
                            color: Colors.grey.shade800,
                            child: const Center(
                              child: Icon(Icons.error),
                            ),
                          ),
                        )
                      : Container(
                          width: 150,
                          height: 225,
                          color: Colors.grey.shade800,
                          child: const Center(
                            child: Icon(
                              Icons.movie,
                              size: 50,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                ),
                // زر المفضلة
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // تقييم الفيلم
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          voteAverage.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // عنوان الفيلم
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### تخصيص بطاقة الحلقة

يمكنك تخصيص بطاقة الحلقة:

```dart
class EpisodeCard extends StatelessWidget {
  final int episodeNumber;
  final String title;
  final String? stillPath;
  final String overview;
  final VoidCallback onTap;
  final double progress;
  
  const EpisodeCard({
    super.key,
    required this.episodeNumber,
    required this.title,
    this.stillPath,
    required this.overview,
    required this.onTap,
    this.progress = 0.0,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة الحلقة
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  stillPath != null
                      ? CachedNetworkImage(
                          imageUrl: 'https://image.tmdb.org/t/p/w500$stillPath',
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: double.infinity,
                            height: 180,
                            color: Colors.grey.shade800,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: double.infinity,
                            height: 180,
                            color: Colors.grey.shade800,
                            child: const Center(
                              child: Icon(Icons.error),
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          height: 180,
                          color: Colors.grey.shade800,
                          child: const Center(
                            child: Icon(
                              Icons.movie,
                              size: 50,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                  // رقم الحلقة
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'الحلقة $episodeNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // زر التشغيل
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  // شريط التقدم
                  if (progress > 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade800.withOpacity(0.5),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 4,
                      ),
                    ),
                ],
              ),
            ),
            // معلومات الحلقة
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    overview,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## تخصيص الرسوم المتحركة

### إضافة رسوم متحركة للانتقال بين الشاشات

يمكنك إضافة رسوم متحركة للانتقال بين الشاشات:

```dart
Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const DetailsScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;
      
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);
      
      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  ),
);
```

### إضافة رسوم متحركة للتحميل

يمكنك إضافة رسوم متحركة للتحميل:

```dart
import 'package:lottie/lottie.dart';

// ...

Center(
  child: Lottie.asset(
    'assets/animations/loading.json',
    width: 200,
    height: 200,
    fit: BoxFit.contain,
  ),
),
```

## تخصيص الشاشات الرئيسية

### تخصيص الشاشة الرئيسية

يمكنك تخصيص الشاشة الرئيسية في ملف `lib/screens/home_screen.dart`:

```dart
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // شريط التطبيق
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('INDEX'),
              background: Image.asset(
                'assets/images/banner.jpg',
                fit: BoxFit.cover,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // الانتقال إلى شاشة البحث
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  // الانتقال إلى شاشة الإشعارات
                },
              ),
            ],
          ),
          
          // محتوى الشاشة
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // قسم الأفلام الشائعة
                  _buildSectionHeader('الأفلام الشائعة', () {
                    // الانتقال إلى شاشة الأفلام الشائعة
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return const MediaCard(
                          title: 'عنوان الفيلم',
                          posterPath: null,
                          voteAverage: 8.5,
                          onTap: null,
                          onFavoriteToggle: null,
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // قسم المسلسلات الشائعة
                  _buildSectionHeader('المسلسلات الشائعة', () {
                    // الانتقال إلى شاشة المسلسلات الشائعة
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return const MediaCard(
                          title: 'عنوان المسلسل',
                          posterPath: null,
                          voteAverage: 8.5,
                          onTap: null,
                          onFavoriteToggle: null,
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // قسم الأفلام الجديدة
                  _buildSectionHeader('الأفلام الجديدة', () {
                    // الانتقال إلى شاشة الأفلام الجديدة
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return const MediaCard(
                          title: 'عنوان الفيلم',
                          posterPath: null,
                          voteAverage: 8.5,
                          onTap: null,
                          onFavoriteToggle: null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, VoidCallback? onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onTap != null)
          TextButton(
            onPressed: onTap,
            child: const Text('عرض المزيد'),
          ),
      ],
    );
  }
}
```