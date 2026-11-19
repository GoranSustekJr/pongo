import 'package:flutter/material.dart';

import '../../../../core/themes/colors.dart';

Widget settingsText(String text) {
  return Builder(
    builder: (context) => Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 5),
          child: Text(
            text,
            style: TextStyle(color: context.colors.text.withAlpha(150)),
          ),
        ),
      ],
    ),
  );
}
