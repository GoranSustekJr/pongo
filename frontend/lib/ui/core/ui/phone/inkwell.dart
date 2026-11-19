import 'package:flutter/material.dart';

import 'package:pongo/app/theme/colors.dart';
import 'package:pongo/core/state/globals.dart';

Widget inkWell(
  Widget child,
  Function() function,
) {
  return Material(
    color: Col.transp,
    child: InkWell(
      highlightColor: darkMode.value
          ? Colors.white.withAlpha(50)
          : Colors.black.withAlpha(25),
      splashColor: darkMode.value
          ? Colors.white.withAlpha(75)
          : Colors.black.withAlpha(50),
      onTap: function,
      child: child,
    ),
  );
}
