import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:pongo/core/state/globals.dart';

appBarBlur() {
  return ClipRRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(
          sigmaX: useBlur.value ? 10 : 0, sigmaY: useBlur.value ? 10 : 0),
      child: Container(
        color: Colors.transparent,
      ),
    ),
  );
}
