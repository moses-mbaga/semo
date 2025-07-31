import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:index/gen/assets.gen.dart";
import "package:index/models/subtitle_style.dart";
import "package:index/screens/base_screen.dart";
import "package:index/services/preferences.dart";
import "package:index/utils/string_extension.dart";

class SubtitlesPreferencesScreen extends BaseScreen {
  const SubtitlesPreferencesScreen({super.key});

  @override
  BaseScreenState<SubtitlesPreferencesScreen> createState() => _SubtitlesPreferencesScreenState();
}

class _SubtitlesPreferencesScreenState extends BaseScreenState<SubtitlesPreferencesScreen> {
  final AppPreferences _appPreferences = AppPreferences();
  //ignore: prefer_final_fields
  late SubtitleStyle _subtitleStyle = _appPreferences.getSubtitlesStyle();

  Widget _buildVisualExample() {
    String subtitle = "Just like everything else in this place. [Chair scrapes floor]\nThe coordinates point to the old lighthouse.";
    Paint foreground  = Paint()
      ..style = _subtitleStyle.borderStyle.style
      ..strokeWidth = _subtitleStyle.borderStyle.strokeWidth
      ..color = SubtitleStyle.getColors()[_subtitleStyle.borderStyle.color]!;

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.25,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: Assets.images.subtitlesPoster.provider(),
          fit: BoxFit.cover,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Center(
        child: Stack(
          children: <Widget>[
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _subtitleStyle.fontSize,
                foreground: _subtitleStyle.hasBorder ? foreground : null,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _subtitleStyle.fontSize,
                color: SubtitleStyle.getColors()[_subtitleStyle.color],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Text _buildSectionTitle(String title) => Text(
    title,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      fontSize: 20,
      color: Theme.of(context).primaryColor,
    ),
  );

  SettingsTile _buildSectionTile({
    required String title,
    required Widget trailing,
    bool enabled = true,
    Function(BuildContext context)? onPressed,
  }) => SettingsTile(
    title: Text(
      title,
      style: Theme.of(context).textTheme.displayMedium,
    ),
    leading: null,
    trailing: trailing,
    backgroundColor: Platform.isIOS ? Theme.of(context).cardColor: Colors.transparent,
    onPressed: onPressed,
  );

  SettingsList _buildCustomizations() {
    SettingsThemeData settingsThemeData = SettingsThemeData(
      settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
    );

    InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
      filled: true,
      fillColor: Theme.of(context).cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );

    return SettingsList(
      lightTheme: settingsThemeData,
      darkTheme: settingsThemeData,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      sections: <SettingsSection>[
        SettingsSection(
          title: _buildSectionTitle("Font"),
          tiles: <SettingsTile>[
            _buildSectionTile(
              title: "Size",
              trailing: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: DropdownMenu<double>(
                  initialSelection: _subtitleStyle.fontSize,
                  requestFocusOnTap: false,
                  enableFilter: false,
                  enableSearch: false,
                  textStyle: Theme.of(context).textTheme.displayLarge,
                  inputDecorationTheme: inputDecorationTheme,
                  onSelected: (double? size) async {
                    if (size != null) {
                      setState(() => _subtitleStyle.fontSize = size);
                      await _appPreferences.setSubtitlesStyle(_subtitleStyle);
                    }
                  },
                  dropdownMenuEntries: SubtitleStyle.getFontSizes()
                      .map<DropdownMenuEntry<double>>((double size) => DropdownMenuEntry<double>(
                    value: size,
                    label: "$size".replaceAll(".0", ""),
                  )).toList(),
                ),
              ),
            ),
            _buildSectionTile(
              title: "Color",
              trailing: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: DropdownMenu<String>(
                  initialSelection: _subtitleStyle.color,
                  requestFocusOnTap: false,
                  enableFilter: false,
                  enableSearch: false,
                  textStyle: Theme.of(context).textTheme.displayLarge,
                  inputDecorationTheme: inputDecorationTheme,
                  onSelected: (String? color) async {
                    if (color != null) {
                      setState(() => _subtitleStyle.color = color);
                      await _appPreferences.setSubtitlesStyle(_subtitleStyle);
                    }
                  },
                  dropdownMenuEntries: SubtitleStyle.getColors().keys
                      .map<DropdownMenuEntry<String>>((String color) => DropdownMenuEntry<String>(
                    value: color,
                    label: color,
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: _buildSectionTitle("Border"),
          tiles: <SettingsTile>[
            _buildSectionTile(
              title: "Has border",
              trailing: Switch(
                value: _subtitleStyle.hasBorder,
                onChanged: (bool isSelected) async {
                  setState(() => _subtitleStyle.hasBorder = isSelected);
                  await _appPreferences.setSubtitlesStyle(_subtitleStyle);
                },
                activeColor: Theme.of(context).primaryColor,
              ),
              onPressed: (BuildContext context) async {
                setState(() => _subtitleStyle.hasBorder = !_subtitleStyle.hasBorder);
                await _appPreferences.setSubtitlesStyle(_subtitleStyle);
              },
            ),
            _buildSectionTile(
              title: "Width",
              enabled: _subtitleStyle.hasBorder,
              trailing: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: DropdownMenu<double>(
                  initialSelection: _subtitleStyle.borderStyle.strokeWidth,
                  requestFocusOnTap: false,
                  enableFilter: false,
                  enableSearch: false,
                  textStyle: Theme.of(context).textTheme.displayLarge,
                  inputDecorationTheme: inputDecorationTheme,
                  onSelected: (double? size) async {
                    if (size != null) {
                      setState(() => _subtitleStyle.borderStyle.strokeWidth = size);
                      await _appPreferences.setSubtitlesStyle(_subtitleStyle);
                    }
                  },
                  dropdownMenuEntries: SubtitleStyle.getBorderWidths()
                      .map<DropdownMenuEntry<double>>((double size) => DropdownMenuEntry<double>(
                    value: size,
                    label: "$size".replaceAll(".0", ""),
                  )).toList(),
                ),
              ),
            ),
            _buildSectionTile(
              title: "Color",
              enabled: _subtitleStyle.hasBorder,
              trailing: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: DropdownMenu<String>(
                  initialSelection: _subtitleStyle.borderStyle.color,
                  requestFocusOnTap: false,
                  enableFilter: false,
                  enableSearch: false,
                  textStyle: Theme.of(context).textTheme.displayLarge,
                  inputDecorationTheme: inputDecorationTheme,
                  onSelected: (String? color) async {
                    if (color != null) {
                      setState(() => _subtitleStyle.borderStyle.color = color);
                      await _appPreferences.setSubtitlesStyle(_subtitleStyle);
                    }
                  },
                  dropdownMenuEntries: SubtitleStyle.getColors().keys
                      .map<DropdownMenuEntry<String>>((String color) => DropdownMenuEntry<String>(
                    value: color,
                    label: color,
                  )).toList(),
                ),
              ),
            ),
            _buildSectionTile(
              title: "Style",
              enabled: _subtitleStyle.hasBorder,
              trailing: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: DropdownMenu<String>(
                  initialSelection: _subtitleStyle.borderStyle.style.name,
                  requestFocusOnTap: false,
                  enableFilter: false,
                  enableSearch: false,
                  textStyle: Theme.of(context).textTheme.displayLarge,
                  inputDecorationTheme: inputDecorationTheme,
                  onSelected: (String? style) async {
                    if (style != null) {
                      setState(() => _subtitleStyle.borderStyle.style = PaintingStyle.values.byName(style));
                      await _appPreferences.setSubtitlesStyle(_subtitleStyle);
                    }
                  },
                  dropdownMenuEntries: PaintingStyle.values
                      .map((PaintingStyle style) => style.name).toList().map<DropdownMenuEntry<String>>((String style) => DropdownMenuEntry<String>(
                    value: style,
                    label: style.capitalize(),
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  @override
  String get screenName => "Subtitles Preferences";

  @override
  Widget buildContent(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("Subtitles"),
    ),
    body: SingleChildScrollView(
      child: Column(
        children: <Widget>[
          _buildVisualExample(),
          _buildCustomizations(),
        ],
      ),
    ),
  );
}