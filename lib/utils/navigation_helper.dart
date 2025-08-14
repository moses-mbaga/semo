import "package:flutter/material.dart";

class NavigationHelper {
  static Future<dynamic> navigate(BuildContext context, Widget destination, {bool replace = false}) {
    final MaterialPageRoute<dynamic> route = MaterialPageRoute<dynamic>(builder: (BuildContext context) => destination);

    if (replace) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }
}