import "package:flutter/material.dart";

class AspectRatios {
  static const double posterWidthOverHeight = 2 / 3;
  static const double genreCardWidthOverHeight = 16 / 10;
  static const double platformCardWidthOverHeight = 3 / 2;

  static double backdropWidthOverHeight(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isLandscape = size.width > size.height;

    return isLandscape ? (21 / 9) : (16 / 9);
  }
}
