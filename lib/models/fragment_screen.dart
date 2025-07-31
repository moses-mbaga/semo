import "package:flutter/material.dart";
import "package:index/enums/media_type.dart";

class FragmentScreen {
  const FragmentScreen({
    required this.icon,
    required this.title,
    required this.widget,
    this.mediaType = MediaType.none,
  });

  final IconData icon;
  final String title;
  final Widget widget;
  final MediaType mediaType;
}
