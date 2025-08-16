import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:lottie/lottie.dart";
import "package:semo/bloc/app_bloc.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/components/snack_bar.dart";
import "package:semo/gen/assets.gen.dart";
import "package:semo/screens/base_screen.dart";
import "package:semo/screens/fragments_screen.dart";
import "package:semo/services/auth_service.dart";

class LandingScreen extends BaseScreen {
  const LandingScreen({super.key}) : super(shouldListenToAuthStateChanges: false);

  @override
  BaseScreenState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends BaseScreenState<LandingScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late final AnimationController _lottieController = AnimationController(vsync: this);

  Future<void> _authenticateWithGoogle() async {
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

  Widget _buildContinueWithGoogleButton() => Container(
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
        await _authenticateWithGoogle();
      },
      child: Container(
        width: double.infinity,
        child: Stack(
          children: <Widget>[
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FaIcon(
                  FontAwesomeIcons.google,
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
                      "Continue with Google",
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

  Widget _buildAnimation() => Expanded(
    child: Lottie.asset(
      Assets.lottie.watchingTv,
      controller: _lottieController,
      fit: BoxFit.fill,
      onLoaded: (LottieComposition composition) async {
        _lottieController.duration = const Duration(milliseconds: 3500);
        await _lottieController.repeat(reverse: true);
      },
    ),
  );

  Widget _buildContent() => Column(
    children: <Widget>[
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
                child: _buildContinueWithGoogleButton(),
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
    await GoogleSignIn.instance.initialize();
  }

  @override
  void handleDispose() {
    _lottieController.dispose();
  }

  @override
  Widget buildContent(BuildContext context) => Scaffold(
    body: Column(
      children: <Widget>[
        _buildAnimation(),
        _buildContent(),
      ],
    ),
  );
}