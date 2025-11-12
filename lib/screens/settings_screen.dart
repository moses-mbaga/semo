import "dart:async";
import "dart:io";

import "package:cached_network_image/cached_network_image.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_cache_manager/flutter_cache_manager.dart";
import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:semo/bloc/app_bloc.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/components/snack_bar.dart";
import "package:semo/gen/assets.gen.dart";
import "package:semo/screens/base_screen.dart";
import "package:semo/screens/landing_screen.dart";
import "package:semo/models/streaming_server.dart";
import "package:semo/screens/open_source_libraries_screen.dart";
import "package:semo/services/auth_service.dart";
import "package:semo/services/streams_extractor_service/streams_extractor_service.dart";
import "package:semo/services/app_preferences_service.dart";
import "package:semo/utils/urls.dart";
import "package:url_launcher/url_launcher.dart";

class SettingsScreen extends BaseScreen {
  const SettingsScreen({super.key});

  @override
  BaseScreenState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends BaseScreenState<SettingsScreen> {
  final AppPreferencesService _appPreferences = AppPreferencesService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  Future<void> _openServerSelector() async {
    if (mounted) {
      await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          List<StreamingServer> servers = StreamsExtractorService().getStreamingServers();
          String savedServerName = _appPreferences.getStreamingServer();

          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) => ListView.builder(
              shrinkWrap: true,
              itemCount: servers.length,
              itemBuilder: (BuildContext context, int index) {
                StreamingServer server = servers[index];
                bool isSelected = server.name == savedServerName;

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
                    setState(() => savedServerName = server.name);
                  },
                );
              },
            ),
          );
        },
      );
    }
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
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
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

  Future<void> _showConfirmationDialog({
    required String title,
    required String content,
    String cancelLabel = "Cancel",
    required String confirmLabel,
    required Future<void> Function() onConfirm,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: Text(
              cancelLabel,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white54,
                  ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: Text(
              confirmLabel,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await onConfirm();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    unawaited(logEvent("settings_delete_account_start"));
    spinner.show();

    // Re-authenticate the user
    try {
      UserCredential? credential = await _authService.reAuthenticate();

      if (credential == null) {
        throw Exception("Credential is null");
      }
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "Failed to re-authenticate");
      }
      spinner.dismiss();
      return;
    }

    // Delete user data and account
    try {
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

      unawaited(logEvent("settings_delete_account_success"));

      await navigate(
        const LandingScreen(),
        replace: true,
      );
    } catch (_) {
      unawaited(logEvent("settings_delete_account_failure"));
      if (mounted) {
        showSnackBar(context, "Failed to delete account");
      }
      spinner.dismiss();
    }
  }

  Future<void> _clearCache() async {
    unawaited(logEvent("settings_clear_cache"));

    if (mounted) {
      context.read<AppBloc>().add(InvalidateCache());
    }

    try {
      DefaultCacheManager manager = DefaultCacheManager();
      await manager.emptyCache();
    } catch (_) {}
  }

  Future<void> _clearRecentSearches({bool showResponse = true}) async {
    unawaited(logEvent("settings_clear_recent_searches"));

    if (mounted) {
      context.read<AppBloc>().add(ClearRecentSearches());
    }
  }

  Future<void> _clearFavorites({bool showResponse = true}) async {
    unawaited(logEvent("settings_clear_favorites"));

    if (mounted) {
      context.read<AppBloc>().add(ClearFavorites());
    }
  }

  Future<void> _clearRecentlyWatched({bool showResponse = true}) async {
    unawaited(logEvent("settings_clear_recently_watched"));

    if (mounted) {
      context.read<AppBloc>().add(ClearRecentlyWatched());
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      unawaited(logEvent("settings_sign_out_success"));
      await navigate(
        const LandingScreen(),
        replace: true,
      );
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "Failed to sign out");
      }
      unawaited(logEvent("settings_sign_out_failure"));
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
              child: photoUrl.isEmpty
                  ? Icon(
                      Icons.account_circle,
                      color: Theme.of(context).primaryColor,
                    )
                  : CachedNetworkImage(
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
  }) =>
      SettingsTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        description: description != null
            ? Text(
                description,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white54,
                    ),
              )
            : null,
        leading: Icon(icon),
        trailing: trailing,
        backgroundColor: Platform.isIOS ? Theme.of(context).cardColor : Colors.transparent,
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
              onPressed: (BuildContext context) async {
                await _openAbout();
              },
            ),
            _buildSectionTile(
              title: "Open Source libraries",
              icon: Icons.description_outlined,
              trailing: Platform.isIOS ? const Icon(Icons.keyboard_arrow_right_outlined) : null,
              onPressed: (BuildContext context) async {
                await navigate(const OpenSourceLibrariesScreen());
              },
            ),
          ],
        ),
        SettingsSection(
          title: _buildSectionTitle("Other"),
          tiles: <SettingsTile>[
            _buildSectionTile(
              title: "Clear cache",
              description: "Deletes all cached data",
              icon: Icons.cached,
              trailing: Platform.isIOS ? const Icon(Icons.keyboard_arrow_right_outlined) : null,
              onPressed: (BuildContext context) => _showConfirmationDialog(
                title: "Clear cache",
                content: "Are you sure that you want to clear cached data? This will delete all cached images and subtitles.",
                confirmLabel: "Clear",
                onConfirm: () => _clearCache(),
              ),
            ),
            _buildSectionTile(
              title: "Clear recent searches",
              description: "Deletes all the recent search queries",
              icon: Icons.search_off,
              trailing: Platform.isIOS ? const Icon(Icons.keyboard_arrow_right_outlined) : null,
              onPressed: (BuildContext context) => _showConfirmationDialog(
                title: "Clear recent searches",
                content: "Are you sure that you want to clear recent searches? This will delete all the recent search queries.",
                confirmLabel: "Clear",
                onConfirm: () => _clearRecentSearches(),
              ),
            ),
            _buildSectionTile(
              title: "Clear favorites",
              description: "Deletes all your favorites",
              icon: Icons.favorite_border,
              trailing: Platform.isIOS ? const Icon(Icons.keyboard_arrow_right_outlined) : null,
              onPressed: (BuildContext context) => _showConfirmationDialog(
                title: "Clear favorites",
                content: "Are you sure that you want to clear favorites? This will delete all your favorites.",
                confirmLabel: "Clear",
                onConfirm: () => _clearFavorites(),
              ),
            ),
            _buildSectionTile(
              title: "Clear recently watched",
              description: "Deletes all the progress of recently watched movies and TV shows",
              icon: Icons.video_library_outlined,
              trailing: Platform.isIOS ? const Icon(Icons.keyboard_arrow_right_outlined) : null,
              onPressed: (BuildContext context) => _showConfirmationDialog(
                title: "Clear recently watched",
                content: "Are you sure that you want to clear recently watched? This will delete all the progress of recently watched movies and TV shows.",
                confirmLabel: "Clear",
                onConfirm: () => _clearRecentlyWatched(),
              ),
            ),
            _buildSectionTile(
              title: "Delete account",
              description: "Delete your account, along with all the saved data. You can create a new account at any time",
              icon: Icons.no_accounts_rounded,
              trailing: Platform.isIOS ? const Icon(Icons.keyboard_arrow_right_outlined) : null,
              onPressed: (BuildContext context) => _showConfirmationDialog(
                title: "Delete account",
                content: "Are you sure that you want to close your account? Your account will be deleted, along with all the saved data.\nYou can create a new account at any time.\n\nFor security reasons, you will be asked to re-authenticate first.",
                confirmLabel: "Delete",
                onConfirm: () async {
                  await _deleteAccount();
                },
              ),
            ),
            _buildSectionTile(
              title: "Sign out",
              icon: Icons.exit_to_app,
              trailing: Platform.isIOS ? const Icon(Icons.keyboard_arrow_right_outlined) : null,
              onPressed: (BuildContext context) => _showConfirmationDialog(
                title: "Sign out",
                content: "Are you sure that you want to sign out? You can always sign in again later.",
                confirmLabel: "Sign out",
                onConfirm: () => _signOut(),
              ),
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
