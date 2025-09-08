import "package:diacritic/diacritic.dart";

String normalizeForComparison(String text) => removeDiacritics(text)
    .replaceAll(RegExp("[–—−]"), "-") // Replace various dash types
    .replaceAll(RegExp(r"\s+"), " ") // Normalize whitespace
    .toLowerCase()
    .trim();
