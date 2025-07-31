import "dart:async";

import "package:firebase_analytics/firebase_analytics.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:internet_connection_checker_plus/internet_connection_checker_plus.dart";
import "package:logger/logger.dart";
import "package:index/components/spinner.dart";
import "package:index/screens/landing_screen.dart";
import "package:index/utils/navigation_helper.dart";

abstract class BaseScreen extends StatefulWidget {
  const BaseScreen({
    super.key,
    this.shouldLogScreenView = true,
    this.shouldListenToAuthStateChanges = true
  });

  final bool shouldLogScreenView;
  final bool shouldListenToAuthStateChanges;
}

abstract class BaseScreenState<T extends BaseScreen> extends State<T> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final InternetConnection _internetConnection = InternetConnection();
  late final StreamSubscription<InternetStatus> _connectionSubscription = _internetConnection.onStatusChange
      .listen((InternetStatus status) async {
    if (mounted) {
      switch (status) {
        case InternetStatus.connected:
          setState(() => _isConnectedToInternet = true);
        case InternetStatus.disconnected:
          setState(() => _isConnectedToInternet = false);
      }
    }
  });
  StreamSubscription<User?>? _authSubscription;
  bool _isConnectedToInternet = true;
  bool _isAuthenticated = false;

  final Logger logger = Logger();
  late Spinner spinner;

  /// Override this method to provide the screen name for Firebase Analytics
  String get screenName;

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
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: widget.runtimeType.toString(),
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

        await initializeScreen();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _connectionSubscription.cancel();
    if (widget.shouldListenToAuthStateChanges) {
      _authSubscription?.cancel();
    }
    handleDispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnectedToInternet) {
      return _buildNoInternetWidget();
    }

    return buildContent(context);
  }
}