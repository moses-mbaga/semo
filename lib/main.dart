import "dart:async";

import "package:audio_session/audio_session.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_crashlytics/firebase_crashlytics.dart";
import "package:firebase_remote_config/firebase_remote_config.dart";
import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:google_fonts/google_fonts.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:logger/logger.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:semo/bloc/app_bloc.dart";
import "package:semo/bloc/app_state.dart";
import "package:semo/firebase_options.dart";
import "package:semo/screens/splash_screen.dart";
import "package:semo/services/app_preferences_service.dart";
import "package:universal_back_gesture/back_gesture_config.dart";
import "package:universal_back_gesture/back_gesture_page_transitions_builder.dart";
import "package:media_kit/media_kit.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await _flagAsMediaApp();
  await _initializeFirebase();
  await AppPreferencesService.init();
  await GoogleSignIn.instance.initialize();
  runApp(const Semo());
}

Future<void> _flagAsMediaApp() async {
  final AudioSession session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  await session.setActive(true);
}

Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _initializeCrashlytics();
  await _initializeRemoteConfig();
}

Future<void> _initializeCrashlytics() async {
  if (!kIsWeb) {
    FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;
    await runZonedGuarded<Future<void>>(() async {
      await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
      FlutterError.onError = crashlytics.recordFlutterFatalError;
    }, (Object error, StackTrace stack) async {
      await crashlytics.recordError(error, stack, fatal: true);
    });
  }
}

Future<void> _initializeRemoteConfig() async {
  try {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(minutes: 15),
      ),
    );

    await remoteConfig.setDefaults(<String, dynamic>{
      "appVersion": packageInfo.version,
    });

    await remoteConfig.fetchAndActivate();
  } catch (e, s) {
    Logger().e("Failed to initialize remote config", error: e, stackTrace: s);
  }
}

class Semo extends StatelessWidget {
  const Semo({super.key});

  final Color _primary = const Color(0xFFAB261D);
  final Color _background = const Color(0xFF120201);
  final Color _surface = const Color(0xFF250604);
  final Color _onPrimary = Colors.white;
  final Color _onSurface = Colors.white54;

  ThemeData _buildTheme() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: _primary,
        scaffoldBackgroundColor: _background,
        cardColor: _surface,
        pageTransitionsTheme: PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            for (final TargetPlatform platform in TargetPlatform.values)
              platform: const BackGesturePageTransitionsBuilder(
                parentTransitionBuilder: PredictiveBackPageTransitionsBuilder(),
                config: BackGestureConfig(
                  cancelAnimationDuration: Duration(milliseconds: 300),
                ),
              ),
          },
        ),
        appBarTheme: AppBarTheme(
          scrolledUnderElevation: 0,
          backgroundColor: _background,
          titleTextStyle: GoogleFonts.freckleFace(
            textStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: _onPrimary,
            ),
          ),
          iconTheme: IconThemeData(color: _onPrimary),
          centerTitle: false,
        ),
        bottomAppBarTheme: BottomAppBarThemeData(
          color: _surface,
          elevation: 0,
          height: 72,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _primary,
          foregroundColor: _onPrimary,
          elevation: 0,
          shape: const CircleBorder(),
        ),
        textTheme: TextTheme(
          titleLarge: GoogleFonts.freckleFace(
            textStyle: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: _onPrimary,
            ),
          ),
          titleMedium: GoogleFonts.freckleFace(
            textStyle: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: _onPrimary,
            ),
          ),
          titleSmall: GoogleFonts.freckleFace(
            textStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: _onPrimary,
            ),
          ),
          displayLarge: GoogleFonts.lexend(
            textStyle: TextStyle(
              fontSize: 18,
              color: _onPrimary,
            ),
          ),
          displayMedium: GoogleFonts.lexend(
            textStyle: TextStyle(
              fontSize: 15,
              color: _onPrimary,
            ),
          ),
          displaySmall: GoogleFonts.lexend(
            textStyle: TextStyle(
              fontSize: 14,
              color: _onPrimary,
            ),
          ),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: _primary,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: _surface,
        ),
        tabBarTheme: TabBarThemeData(
          indicatorColor: _primary,
          labelColor: _primary,
          dividerColor: _surface,
          unselectedLabelColor: _onSurface,
        ),
        menuTheme: MenuThemeData(
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(_surface),
          ),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          showDragHandle: true,
          backgroundColor: _surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _surface,
        ),
      );

  TextStyle? _scaleTextStyle(TextStyle? style, double scale) {
    if (style == null) {
      return null;
    }

    if (scale == 1.0) {
      return style;
    }

    final double? originalSize = style.fontSize;
    if (originalSize == null) {
      return style;
    }

    return style.copyWith(fontSize: originalSize * scale);
  }

  TextTheme _scaleTextTheme(TextTheme textTheme, double scale) {
    if (scale == 1.0) {
      return textTheme;
    }

    return textTheme.copyWith(
      displayLarge: _scaleTextStyle(textTheme.displayLarge, scale),
      displayMedium: _scaleTextStyle(textTheme.displayMedium, scale),
      displaySmall: _scaleTextStyle(textTheme.displaySmall, scale),
      headlineLarge: _scaleTextStyle(textTheme.headlineLarge, scale),
      headlineMedium: _scaleTextStyle(textTheme.headlineMedium, scale),
      headlineSmall: _scaleTextStyle(textTheme.headlineSmall, scale),
      titleLarge: _scaleTextStyle(textTheme.titleLarge, scale),
      titleMedium: _scaleTextStyle(textTheme.titleMedium, scale),
      titleSmall: _scaleTextStyle(textTheme.titleSmall, scale),
      bodyLarge: _scaleTextStyle(textTheme.bodyLarge, scale),
      bodyMedium: _scaleTextStyle(textTheme.bodyMedium, scale),
      bodySmall: _scaleTextStyle(textTheme.bodySmall, scale),
      labelLarge: _scaleTextStyle(textTheme.labelLarge, scale),
      labelMedium: _scaleTextStyle(textTheme.labelMedium, scale),
      labelSmall: _scaleTextStyle(textTheme.labelSmall, scale),
    );
  }

  ThemeData _applyFontScale(ThemeData baseTheme, double scale) {
    final TextTheme scaledTextTheme = _scaleTextTheme(baseTheme.textTheme, scale);
    final AppBarThemeData appBarTheme = baseTheme.appBarTheme;

    return baseTheme.copyWith(
      textTheme: scaledTextTheme,
      appBarTheme: appBarTheme.copyWith(
        titleTextStyle: _scaleTextStyle(appBarTheme.titleTextStyle, scale),
      ),
    );
  }

  double _resolveFontScale(double width) {
    double scale = width / 375;
    if (scale < 0.85) {
      scale = 0.85;
    } else if (scale > 1.25) {
      scale = 1.25;
    }
    return scale;
  }

  @override
  Widget build(BuildContext context) => BlocProvider<AppBloc>(
        create: (BuildContext context) => AppBloc()..init(),
        child: BlocBuilder<AppBloc, AppState>(
          builder: (BuildContext context, AppState state) {
            ThemeData baseTheme = _buildTheme();
            return MaterialApp(
              title: "Semo",
              debugShowCheckedModeBanner: false,
              theme: baseTheme,
              builder: (BuildContext context, Widget? child) {
                MediaQueryData mediaQuery = MediaQuery.of(context);
                double scale = _resolveFontScale(mediaQuery.size.width);
                ThemeData scaledTheme = _applyFontScale(baseTheme, scale);
                return Theme(
                  data: scaledTheme,
                  child: child ?? const SizedBox.shrink(),
                );
              },
              home: const SplashScreen(),
            );
          },
        ),
      );
}
