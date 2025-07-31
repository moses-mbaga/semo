import "dart:io";

import "package:cached_network_image/cached_network_image.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:index/bloc/app_bloc.dart";
import "package:index/bloc/app_event.dart";
import "package:index/components/snack_bar.dart";
import "package:index/gen/assets.gen.dart";
import "package:index/screens/base_screen.dart";
import "package:index/screens/landing_screen.dart";
import "package:index/models/streaming_server.dart";
import "package:index/screens/open_source_libraries_screen.dart";
import "package:index/screens/subtitles_preferences_screen.dart";
import "package:index/services/auth_service.dart";
import "package:index/services/stream_extractor/extractor.dart";
import "package:index/services/preferences.dart";
import "package:index/utils/urls.dart";
import "package:url_launcher/url_launcher.dart";

class SettingsScreen extends BaseScreen {
  const SettingsScreen({super.key});

  @override
  BaseScreenState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends BaseScreenState<SettingsScreen> {
  final AppPreferences _appPreferences = AppPreferences();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  Future<void> _openServerSelector() async {
    String savedServerName = _appPreferences.getStreamingServer();
    List<StreamingServer> servers = StreamExtractor.streamingServers;

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        String serverName = savedServerName;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => ListView.builder(
            shrinkWrap: true,
            itemCount: servers.length,
            itemBuilder: (BuildContext context, int index) {
              StreamingServer server = servers[index];
              bool isSelected = server.name == serverName;

              return ListTile(
                selected: isSelected,
                selectedColor: Theme.of(context).primaryColor,
                selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                titleTextStyle: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                title: Text(server.name),
                leading: isSelected ? const Icon(Icons.check) : null,
                onTap: () async {
                  await _appPreferences.setStreamingServer(server);
                  setState(() => serverName = server.name);
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openSeekDurationSelector() async {
    int savedSeekDuration = _appPreferences.getSeekDuration();
    List<int> seekDurations = <int>[5, 15, 30, 45, 60];

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        int seekDuration = savedSeekDuration;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => ListView.builder(
              shrinkWrap: true,
              itemCount: seekDurations.length,
              itemBuilder: (BuildContext context, int index) {
                bool isSelected = seekDurations[index] == seekDuration;

                return ListTile(
                  selected: isSelected,
                  selectedColor: Theme.of(context).primaryColor,
                  selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  titleTextStyle: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  title: Text(seekDurations[index] != 60 ? "${seekDurations[index]} s" : "1 m"),
                  leading: isSelected ? const Icon(Icons.check) : null,
                  onTap: () async {
                    await _appPreferences.setSeekDuration(seekDurations[index]);
                    setState(() => seekDuration = seekDurations[index]);
                  },
                );
              },
            ),
        );
      },
    );
  }

  Future<void> _openAbout() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;

    if (mounted) {
      await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) => Container(
          width: double.infinity,
          margin: const EdgeInsets.all(18),
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            bottom: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Assets.images.appIcon.image(
                  width: 125,
                  height: 125,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 25),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: Theme.of(context).textTheme.displayMedium,
                      children: <TextSpan>[
                        const TextSpan(text: "Developed by "),
                        TextSpan(
                          text: "Moses Mbaga",
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()..onTap = () async {
                            await launchUrl(Uri.parse(Urls.mosesGithub));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        version,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      Text(
                        " · ",
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      GestureDetector(
                        onTap: () async {
                          await launchUrl(Uri.parse(Urls.github));
                        },
                        child: Text(
                          "GitHub",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Future<void> _showDeleteAccountConfirmation() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Delete account"),
        content: const Text("Are you sure that you want to close your account? Your account will be delete your account, along with all the saved data.\nYou can create a new account at any time.\n\nFor security reasons, you will be asked to re-authenticate first"),
        actions: <Widget>[
          TextButton(
            child: Text(
              "Cancel",
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.white54,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(
              "Delete",
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Theme.of(context).primaryColor,
              ),
            ),
            onPressed: () async {
              await _reAuthenticate();
              await _deleteAccount();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _reAuthenticate() async {
    spinner.show();

    try {
      UserCredential? credential = await _authService.reAuthenticate();

      if (credential == null) {
        throw Exception("Credential is null");
      }
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "Failed to re-authenticate");
      }
    }

    spinner.dismiss();
  }

  Future<void> _deleteAccount() async {
    try {
      spinner.show();

      await Future.wait(<Future<void>>[
        _clearRecentSearches(showResponse: false),
        _clearFavorites(showResponse: false),
        _clearRecentlyWatched(showResponse: false),
        _appPreferences.clear(),
        _authService.deleteAccount(),
      ]);

      spinner.dismiss();

      if (mounted) {
        showSnackBar(context, "Account deleted");
      }

      await navigate(
        const LandingScreen(),
        replace: true,
      );
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "Failed to delete account");
      }
    }
  }

  Future<void> _clearRecentSearches({bool showResponse = true}) async {
    if (mounted) {
      context.read<AppBloc>().add(ClearRecentSearches());
    }
  }

  Future<void> _clearFavorites({bool showResponse = true}) async {
    if (mounted) {
      context.read<AppBloc>().add(ClearFavorites());
    }
  }

  Future<void> _clearRecentlyWatched({bool showResponse = true}) async {
    if (mounted) {
      context.read<AppBloc>().add(ClearRecentlyWatched());
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      await navigate(
        const LandingScreen(),
        replace: true,
      );
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "Failed to sign out");
      }
    }
  }

  Widget _buildUserCard() {
    String photoUrl = _auth.currentUser?.photoURL ?? "";
    String name = _auth.currentUser?.displayName ?? "User";
    String email = _auth.currentUser?.email ?? "user@email.com";

    return Container(
      margin: const EdgeInsets.only(
        top: 18,
        left: 18,
        right: 18,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.2,
            height: MediaQuery.of(context).size.width * 0.2,
            child: CircleAvatar(
              backgroundColor: Theme.of(context).cardColor,
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                placeholder: (BuildContext context, String url) => const Align(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(),
                ),
                imageBuilder: (BuildContext context, ImageProvider image) => Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1000),
                    image: DecorationImage(
                      image: image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                errorWidget: (BuildContext context, String url, Object? error) => Container(
                  width: double.infinity,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(1000)),
                  child: Icon(
                    Icons.account_circle,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 2.5),
                  ),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white54,
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

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      fontSize: 20,
      color: Theme.of(context).primaryColor,
    ),
  );

  SettingsTile _buildSectionTile({
    required String title,
    String? description,
    required IconData icon,
    Widget? trailing,
    required Function(BuildContext context) onPressed,
  }) => SettingsTile(
    title: Text(
      title,
      style: Theme.of(context).textTheme.displayMedium,
    ),
    description: description != null ? Text(
      description,
      style: Theme.of(context).textTheme.displaySmall?.copyWith(
        color: Colors.white54,
      ),
    ) : null,
    leading: Icon(icon),
    trailing: trailing,
    backgroundColor: Platform.isIOS ? Theme.of(context).cardColor: Colors.transparent,
    onPressed: onPressed,
  );

  Widget _buildSettingsList() {
    SettingsThemeData settingsThemeData = SettingsThemeData(
      titleTextColor: Theme.of(context).primaryColor,
      settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
    );

    return SettingsList(
      lightTheme: settingsThemeData,
      darkTheme: settingsThemeData,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      sections: <SettingsSection>[
        SettingsSection(
          title: _buildSectionTitle("Playback"),
          tiles: <SettingsTile>[
            _buildSectionTile(
              title: "Server",
              description: "Select a server that works best for you",
              icon: Icons.dns_outlined,
              trailing: Platform.isIOS ? const Icon(Icons.keyboard_arrow_right_outlined) : null,
              onPressed: (BuildContext context) => _openServerSelector(),
            ),
            _buildSectionTile(
              title: "Subtitles",
              description: "Customize the subtitles style to fit your preference",
              icon: Icons.subtitles_outlined,
              trailing: Platform.isIOS ? const Icon(Icons.keyboard_arrow_right_outlined) : null,
              onPressed: (BuildContext context) => navigate(const SubtitlesPreferencesScreen()),
            ),
            _buildSectionTile(
              title: "Seek duration",
              description: "Adjust how long the seek forward/backward duration is",
              icon: Icons.update,
              trailing: Platform.isIOS ? const Icon(Icons.keyboard_arrow_right_outlined) : null,
              onPressed: (BuildContext context) => _openSeekDurationSelector(),
            ),
          ],
        ),
        SettingsSection(
          title: _buildSectionTitle("App"),
          tiles: <SettingsTile>[
            _buildSectionTile(
              title: "About",
              icon: Icons.info_outline_rounded,
              trailing: Platform.isIOS ? const Icon(Icons.keyboard_arrow_right_outlined) : null,
              onPressed: (BuildContext context) => _openAbout(),
            ),
            _buildSectionTile(
              title: "Open Source libraries",
              icon: Icons.description_outlined,
              trailing: Platform.isIOS ? const Icon(Icons.keyboard_arrow_right_outlined) : null,
              onPressed: (BuildContext context) => navigate(const OpenSourceLibrariesScreen()),
            ),
          ],
        ),
        SettingsSection(
          title: _buildSectionTitle("Other"),
          tiles: <SettingsTile>[
            _buildSectionTile(
              title: "Clear recent searches",
              description: "Deletes all the recent search queries",
              icon: Icons.search_off,
              trailing: Platform.isIOS ? const Icon(Icons.keyboard_arrow_right_outlined) : null,
              onPressed: (BuildContext context) => _clearRecentSearches(),
            ),
            _buildSectionTile(
              title: "Clear favorites",
              description: "Deletes all your favorites",
              icon: Icons.favorite_border,
              trailing: Platform.isIOS ? const Icon(Icons.keyboard_arrow_right_outlined) : null,
              onPressed: (BuildContext context) => _clearFavorites(),
            ),
            _buildSectionTile(
              title: "Clear recently watched",
              description: "Deletes all the progress of recently watched movies and TV shows",
              icon: Icons.video_library_outlined,
              trailing: Platform.isIOS ? const Icon(Icons.keyboard_arrow_right_outlined) : null,
              onPressed: (BuildContext context) => _clearRecentlyWatched(),
            ),
            _buildSectionTile(
              title: "Delete account",
              description: "Delete your account, along with all the saved data. You can create a new account at any time",
              icon: Icons.no_accounts_rounded,
              trailing: Platform.isIOS ? const Icon(Icons.keyboard_arrow_right_outlined) : null,
              onPressed: (BuildContext context) => _showDeleteAccountConfirmation(),
            ),
            _buildSectionTile(
              title: "Sign out",
              icon: Icons.exit_to_app,
              trailing: Platform.isIOS ? const Icon(Icons.keyboard_arrow_right_outlined) : null,
              onPressed: (BuildContext context) => _signOut(),
            ),
          ],
        ),
      ],
    );
  }

  @override
  String get screenName => "Settings";

  @override
  Widget buildContent(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _buildUserCard(),
            _buildSettingsList(),
          ],
        ),
      ),
    ),
  );
}