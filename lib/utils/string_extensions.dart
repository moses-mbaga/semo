import "package:diacritic/diacritic.dart";

extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) {
      return this;
    }

    return this[0].toUpperCase() + substring(1);
  }

  String normalize() => removeDiacritics(this)
      .replaceAll(RegExp("[–—−]"), "-") // Replace various dash types
      .replaceAll(RegExp(r"\s+"), " ") // Normalize whitespace
      .toLowerCase()
      .trim();

  String removeSpecialChars() {
    if (isEmpty) {
      return this;
    }

    final String ascii = removeDiacritics(this);
    return ascii.replaceAll(RegExp("[^a-zA-Z0-9 ]"), "");
  }
}
