import 'package:flutter/material.dart';

import 'package:pongo/shared/widgets/app_blur.dart';

appBarBlur() {
  return ClipRRect(
    child: BackdropFilter(
      filter: appBlur(10),
      child: Container(
        color: Colors.transparent,
      ),
    ),
  );
}
