import 'package:flutter/material.dart';

import '../../../app/view_models/app_settings_view_model.dart';
import '../../themes/colors.dart';

Widget inkWell(Widget child, Function() function) {
  return Builder(
    builder: (context) => Material(
      color: Col.transp,
      child: InkWell(
        highlightColor: context.readSettings.darkMode
            ? Colors.white.withAlpha(50)
            : Colors.black.withAlpha(25),
        splashColor: context.readSettings.darkMode
            ? Colors.white.withAlpha(75)
            : Colors.black.withAlpha(50),
        onTap: function,
        child: child,
      ),
    ),
  );
}
