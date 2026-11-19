import 'package:flutter/material.dart';

import '../app_blur.dart';

Widget appBarBlur() {
  return ClipRRect(
    child: Builder(
      builder: (context) => BackdropFilter(
        filter: appBlur(context, 10),
        child: Container(color: Colors.transparent),
      ),
    ),
  );
}
