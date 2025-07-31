import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:semo/bloc/app_bloc.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/components/snack_bar.dart";
import "package:semo/gen/assets.gen.dart";
import "package:semo/screens/base_screen.dart";
import "package:semo/screens/fragments_screen.dart";
import "package:semo/services/auth_service.dart";
import "package:video_player/video_player.dart";

class LandingScreen extends BaseScreen {
  const LandingScreen({super.key}) : super(shouldListenToAuthStateChanges: false);

  @override
  BaseScreenState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends BaseScreenState<LandingScreen> {
  final AuthService _authService = AuthService();
  final VideoPlayerController _videoController = VideoPlayerController.asset(Assets.videos.coverPortrait);

  Future<void> _initPlayback() async {
    await _videoController.initialize();
    await _videoController.play();
    await _videoController.setLooping(true);
  }

  Future<void> _authenticateAsGuest() async {
    spinner.show();

    try {
      await _authService.signIn();

      if (mounted) {
        context.read<AppBloc>().add(LoadInitialData());

        await navigate(
          const FragmentsScreen(),
          replace: true,
        );
      }
    } catch (_) {
      if (mounted) {
        showSnackBar(context, "An error occurred");
      }
    }

    spinner.dismiss();
  }

  Widget _buildContinueAsGuestButton() => Container(
    width: double.infinity,
    height: 60,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        side: const BorderSide(
          width: 3,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      onPressed: () async {
        await _authenticateAsGuest();
      },
      child: Container(
        width: double.infinity,
        child: Stack(
          children: <Widget>[
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FaIcon(
                  FontAwesomeIcons.userAlt,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(
                right: 16,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Spacer(),
                    Text(
                      "Continue as Guest",
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const Spacer(),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildContent() => Column(
    children: <Widget>[
      const Spacer(),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 36),
              child: Container(
                width: double.infinity,
                child: Text(
                  "Welcome!",
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              child: Container(
                width: double.infinity,
                child: Text(
                  "Discover a vast library of entertainment, from blockbuster hits to indie gems, all tailored to your tastes. Enjoy unlimited streaming on any device, create your personalized watchlist, and get ready for an unparalleled viewing experience.",
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            SafeArea(
              top: false,
              left: false,
              right: false,
              bottom: true,
              child: Container(
                margin: const EdgeInsets.only(
                  bottom: 18,
                ),
                child: _buildContinueAsGuestButton(),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  @override
  String get screenName => "Landing";

  @override
  Future<void> initializeScreen() async {
    await _initPlayback();
  }

  @override
  void handleDispose() {
    _videoController.pause();
    _videoController.dispose();
  }

  @override
  Widget buildContent(BuildContext context) => Scaffold(
    body: Stack(
      children: <Widget>[
        Positioned.fill(
          child: AspectRatio(
            aspectRatio: _videoController.value.aspectRatio,
            child: VideoPlayer(_videoController),
          ),
        ),
        Container(
          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
        ),
        _buildContent(),
      ],
    ),
  );
}