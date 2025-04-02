import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

backButton(context) {
  Widget child = Container(
    height: 50,
    width: 50,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(60),
      color: Colors.black.withAlpha(100),
    ),
    child: const Stack(
      children: [
        Positioned(
          left: 9,
          top: 11,
          child: Icon(
            CupertinoIcons.chevron_left,
            size: 27.5,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
  return kIsApple
      ? CupertinoButton(
          onPressed: () {
            Navigator.of(context).pop();
            showBottomNavBar.value = true;
            showSearchBar.value = true;
          },
          padding: EdgeInsets.zero,
          child: child,
        )
      : ClipRRect(
          borderRadius: BorderRadius.circular(360),
          child: Material(
            color: Col.transp,
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
                showBottomNavBar.value = true;
                showSearchBar.value = true;
              },
              child: child,
            ),
          ),
        );
}
