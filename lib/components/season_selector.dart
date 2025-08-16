import "package:flutter/material.dart";
import "package:semo/models/season.dart";

class SeasonSelector extends StatelessWidget {
  const SeasonSelector({
    super.key,
    required this.seasons,
    required this.selectedSeason,
    required this.onSeasonChanged,
    required this.enabled,
  });

  final List<Season> seasons;
  final Season selectedSeason;
  final Function(List<Season>, Season) onSeasonChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !enabled,
    child: DropdownMenu<Season>(
      initialSelection: selectedSeason,
      requestFocusOnTap: false,
      enableFilter: false,
      enableSearch: false,
      textStyle: Theme.of(context).textTheme.displayLarge,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onSelected: (Season? season) {
        if (season != null) {
          onSeasonChanged(seasons, season);
        }
      },
      dropdownMenuEntries: seasons.map<DropdownMenuEntry<Season>>((Season season) => DropdownMenuEntry<Season>(
        value: season,
        label: season.name,
        style: MenuItemButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Theme.of(context).cardColor,
        ),
      )).toList(),
    ),
  );
}