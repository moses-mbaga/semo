import "dart:async";

import "package:firebase_analytics/firebase_analytics.dart";
import "package:firebase_remote_config/firebase_remote_config.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:internet_connection_checker_plus/internet_connection_checker_plus.dart";
import "package:logger/logger.dart";
import "package:semo/components/spinner.dart";
import "package:semo/screens/landing_screen.dart";
import "package:semo/utils/navigation_helper.dart";
import "package:url_launcher/url_launcher.dart";
import "package:semo/utils/urls.dart";

abstract class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key, this.shouldLogScreenView = true, this.shouldListenToAuthStateChanges = true});

  final bool shouldLogScreenView;
  final bool shouldListenToAuthStateChanges;
}

abstract class BaseScreenState<T extends BaseScreen> extends State<T> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final InternetConnection _internetConnection = InternetConnection();
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  late final StreamSubscription<InternetStatus> _connectionSubscription = _internetConnection.onStatusChange.listen((InternetStatus status) async {
    if (mounted) {
      switch (status) {
        case InternetStatus.connected:
          setState(() => _isConnectedToInternet = true);
        case InternetStatus.disconnected:
          setState(() => _isConnectedToInternet = false);
      }
    }
  });
  StreamSubscription<RemoteConfigUpdate>? _remoteConfigSubscription;
  StreamSubscription<User?>? _authSubscription;
  bool _isConnectedToInternet = true;
  bool _isAuthenticated = false;
  bool _isUpdateRequired = false;
  String? _remoteAppVersion;

  final Logger logger = Logger();
  late Spinner spinner;

  /// Override this method to provide the screen name for Firebase Analytics
  String get screenName;

  /// Optional screen parameters to be logged alongside the screen view
  Map<String, Object?> get screenParameters => <String, Object?>{};

  /// Override this method to handle initialization logic
  /// Called after initState and connectivity check
  Future<void> initializeScreen() async {}

  /// Override this method to provide the main content of the screen
  Widget buildContent(BuildContext context);

  /// Override this method to handle dispose logic
  /// Called after dispose
  void handleDispose() {}

  /// Override this method to customize the no internet widget
  Widget _buildNoInternetWidget() => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.wifi_off_sharp,
                color: Colors.white54,
                size: 80,
              ),
              Container(
                margin: const EdgeInsets.only(top: 10),
                child: Text(
                  "You have lost internet connection",
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white54,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await _checkConnectivity();
                },
                child: Text(
                  "Retry",
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white54,
                      ),
                ),
              ),
            ],
          ),
        ),
      );

  /// Update required widget
  Widget _buildUpdateRequiredWidget() => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.system_update,
                color: Colors.white54,
                size: 80,
              ),
              Container(
                margin: const EdgeInsets.only(top: 10),
                child: Text(
                  _remoteAppVersion == null ? "A new update is available" : "A new update is available (v$_remoteAppVersion)",
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white54,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await launchUrl(Uri.parse(Urls.github));
                },
                child: Text(
                  "Get Update",
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white54,
                      ),
                ),
              ),
            ],
          ),
        ),
      );

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final bool isConnected = await _internetConnection.hasInternetAccess;
      if (mounted) {
        setState(() => _isConnectedToInternet = isConnected);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnectedToInternet = false);
      }
    }
  }

  /// Log screen view to Firebase Analytics
  Future<void> _logScreenView() async {
    try {
      final Map<String, Object?> params = <String, Object?>{
        "screen_name": screenName,
        ...screenParameters,
      }..removeWhere((String key, Object? value) => value == null);

      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: widget.runtimeType.toString(),
        parameters: params.cast<String, Object>(),
      );
    } catch (e, s) {
      logger.e("Failed to log screen view", error: e, stackTrace: s);
    }
  }

  /// Log custom event to Firebase Analytics
  Future<void> logAnalyticsEvent(String eventName, Map<String, Object>? parameters) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
    } catch (e, s) {
      logger.e("Failed to log analytics event", error: e, stackTrace: s);
    }
  }

  void _initRemoteConfigListener() {
    _remoteConfigSubscription = _remoteConfig.onConfigUpdated.listen((RemoteConfigUpdate event) async {
      try {
        await _remoteConfig.activate();
        await _evaluateVersionRequirement();
      } catch (e, s) {
        logger.e("Failed to handle remote config update", error: e, stackTrace: s);
      }
    });
  }

  Future<void> _evaluateVersionRequirement() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String current = packageInfo.version;
      final String remote = _remoteConfig.getString("appVersion");
      final bool needsUpdate = _isVersionAGreaterThanB(remote, current);

      if (mounted) {
        setState(() {
          _remoteAppVersion = remote.isEmpty ? null : remote;
          _isUpdateRequired = needsUpdate;
        });
      }
    } catch (e, s) {
      logger.e("Failed to evaluate version requirement", error: e, stackTrace: s);
    }
  }

  bool _isVersionAGreaterThanB(String a, String b) {
    if (a.isEmpty || b.isEmpty) {
      return false;
    }

    List<int> pa = a.split(".").map((String x) => int.tryParse(x) ?? 0).toList();
    List<int> pb = b.split(".").map((String x) => int.tryParse(x) ?? 0).toList();
    final int len = pa.length > pb.length ? pa.length : pb.length;

    while (pa.length < len) {
      pa.add(0);
    }

    while (pb.length < len) {
      pb.add(0);
    }

    for (int i = 0; i < len; i++) {
      if (pa[i] > pb[i]) {
        return true;
      }

      if (pa[i] < pb[i]) {
        return false;
      }
    }

    return false;
  }

  /// Navigate to a screen
  Future<dynamic> navigate(Widget destination, {bool replace = false}) async => NavigationHelper.navigate(context, destination, replace: replace);

  void _initAuthStateListener() {
    _authSubscription = _auth.authStateChanges().listen((User? user) async {
      if (mounted) {
        setState(() => _isAuthenticated = user != null);
        if (user == null) {
          await navigate(
            const LandingScreen(),
            replace: true,
          );
        }
      }
    });
  }

  /// Get current connectivity status
  bool get isConnectedToInternet => _isConnectedToInternet;

  /// Get current auth status
  bool get isAuthenticated => _isAuthenticated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        spinner = Spinner(context);

        await _checkConnectivity();

        if (_isConnectedToInternet && widget.shouldLogScreenView) {
          await _logScreenView();
        }

        if (widget.shouldListenToAuthStateChanges) {
          _initAuthStateListener();
        }

        await _evaluateVersionRequirement();
        _initRemoteConfigListener();

        await initializeScreen();
      }
    });
  }

  @override
  void dispose() {
    handleDispose();
    _connectionSubscription.cancel();
    _remoteConfigSubscription?.cancel();
    if (widget.shouldListenToAuthStateChanges) {
      _authSubscription?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnectedToInternet) {
      return _buildNoInternetWidget();
    }

    if (_isUpdateRequired) {
      return _buildUpdateRequiredWidget();
    }

    return buildContent(context);
  }
}
