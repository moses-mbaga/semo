import "package:flutter/material.dart";
import "package:semo/screens/base_screen.dart";
import "package:url_launcher/url_launcher.dart";

class OpenSourceLibrariesScreen extends BaseScreen {
  const OpenSourceLibrariesScreen({super.key});

  @override
  State<BaseScreen> createState() => _OpenSourceLibrariesScreenState();
}

class _OpenSourceLibrariesScreenState extends BaseScreenState<OpenSourceLibrariesScreen> {
  final List<String> _libraries = <String>[
    "archive",
    "audio_video_progress_bar",
    "cached_network_image",
    "carousel_slider",
    "cloud_firestore",
    "dio",
    "envied",
    "firebase_analytics",
    "firebase_auth",
    "firebase_core",
    "firebase_crashlytics",
    "firebase_remote_config",
    "flutter_bloc",
    "flutter_cache_manager",
    "flutter_settings_ui",
    "font_awesome_flutter",
    "google_fonts",
    "google_sign_in",
    "html",
    "infinite_scroll_pagination",
    "internet_connection_checker_plus",
    "logger",
    "lottie",
    "package_info_plus",
    "path",
    "path_provider",
    "pretty_dio_logger",
    "shared_preferences",
    "smooth_page_indicator",
    "subtitle_wrapper_package",
    "universal_back_gesture",
    "url_launcher",
    "wakelock_plus",
    "video_player",
  ];

  @override
  String get screenName => "Open Source Libraries";

  @override
  Widget buildContent(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("Open Source libraries"),
    ),
    body: ListView.builder(
      itemCount: _libraries.length,
      itemBuilder: (BuildContext context, int index) {
        String library = _libraries[index];
        return ListTile(
          title: Text(
            library,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          onTap: () async {
            await launchUrl(Uri.parse("https://pub.dev/packages/$library"));
          },
        );
      },
    ),
  );
}