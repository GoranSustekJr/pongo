import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

backButton(context) {
  return kIsApple
      ? CupertinoButton(
          onPressed: () {
            Navigator.of(context).pop();
            showBottomNavBar.value = true;
            showSearchBar.value = true;
          },
          padding: EdgeInsets.zero,
          child: /* ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: */
              Container(
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
            /*  ),
            ), */
          ),
        )
      : Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(60),
            color: Col.primaryCard.withAlpha(150),
          ),
          child: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
              showBottomNavBar.value = true;
              showSearchBar.value = true;
            },
            icon: const Stack(
              children: [
                Positioned(
                  left: 2,
                  top: 3,
                  child: Icon(
                    CupertinoIcons.chevron_left,
                    size: 27.5,
                  ),
                ),
              ],
            ),
          ),
        );
}
