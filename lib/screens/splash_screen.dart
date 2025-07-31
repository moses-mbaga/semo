import "dart:async";

import "package:flutter/material.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:semo/gen/assets.gen.dart";
import "package:semo/screens/base_screen.dart";
import "package:semo/screens/fragments_screen.dart";
import "package:semo/screens/landing_screen.dart";
import "package:semo/services/auth_service.dart";

class SplashScreen extends BaseScreen {
  const SplashScreen({super.key}) : super(shouldListenToAuthStateChanges: false);

  @override
  BaseScreenState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends BaseScreenState<SplashScreen> {
  String _appVersion = "1.0.0";

  Future<void> _getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() => _appVersion = packageInfo.version);
  }

  Future<void> _checkAuthState() async {
    await AuthService().loadUserFromPrefs();
    
    Widget destination;
    
    if (AuthService().isAuthenticated()) {
      destination = const FragmentsScreen();
    } else {
      destination = const LandingScreen();
    }

    Future<void>.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        await navigate(destination, replace: true);
      }
    });
  }
  
  @override
  String get screenName => "Splash";

  @override
  Future<void> initializeScreen() async {
    await _getAppVersion();
    _checkAuthState();
  }

  @override
  Widget buildContent(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: SafeArea(
      child: Center(
        child: Column(
          children: <Widget>[
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Assets.images.appIcon.image(
                  width: 200,
                  height: 200,
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 10,
                    right: 16,
                    left: 16,
                  ),
                  child: Text(
                    "Version $_appVersion",
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}