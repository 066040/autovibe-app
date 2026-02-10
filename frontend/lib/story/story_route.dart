import 'package:flutter/material.dart';

Route<T> storyCameraRoute<T>(Widget child) {
  return MaterialPageRoute<T>(
    builder: (_) => child,
    fullscreenDialog: true,
    settings: const RouteSettings(name: 'story_camera'),
  );
}
