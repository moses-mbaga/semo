import "dart:convert";

import "package:flutter/material.dart";
import "package:semo/gen/assets.gen.dart";
import "package:semo/screens/base_screen.dart";
import "package:url_launcher/url_launcher.dart";

class OpenSourceLibrariesScreen extends BaseScreen {
  const OpenSourceLibrariesScreen({super.key});

  @override
  State<BaseScreen> createState() => _OpenSourceLibrariesScreenState();
}

class _OpenSourceLibrariesScreenState extends BaseScreenState<OpenSourceLibrariesScreen> {
  List<String> _libraries = <String>[];

  Future<void> loadPubPackages() async {
    String data = await DefaultAssetBundle.of(context).loadString(Assets.gen.pubPackages);
    setState(() => _libraries = jsonDecode(data).cast<String>());
  }

  @override
  String get screenName => "Open Source Libraries";

  @override
  Future<void> initializeScreen() async {
    await loadPubPackages();
  }

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