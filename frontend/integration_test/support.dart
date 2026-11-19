import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Saves what is on screen, shader glass included.
Future<void> saveScreenshot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 300));
  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  // The root layer is in physical pixels
  final dpr = tester.view.devicePixelRatio;
  final image = await layer.toImage(
    Offset.zero & (view.size * dpr),
    pixelRatio: 1.5 / dpr,
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  // flutter test removes the app afterwards, so the file can't be fetched from
  // the phone. Print it instead when asked: --dart-
  // define=PRINT_SCREENSHOTS=true
  final encoded = base64Encode(data!.buffer.asUint8List());
  if (const bool.fromEnvironment('PRINT_SCREENSHOTS')) {
    for (var i = 0; i < encoded.length; i += 900) {
      debugPrintSynchronously(
        'SHOT $name ${encoded.substring(i, min(i + 900, encoded.length))}',
      );
    }
  }
}

/// Pumps frames in real time until [condition] holds.
Future<bool> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 25),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) return true;
  }
  return false;
}
