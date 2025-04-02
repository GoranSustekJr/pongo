import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

backLikeButton(context, IconData icon, Function() function) {
  Widget child = Container(
    height: 50,
    width: 50,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(60),
      color: Colors.black.withAlpha(100),
    ),
    child: Stack(
      children: [
        Center(
          child: Icon(
            icon,
            size: 27.5,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
  return kIsApple
      ? CupertinoButton(
          onPressed: function,
          padding: EdgeInsets.zero,
          child: child,
        )
      : ClipRRect(
          borderRadius: BorderRadius.circular(360),
          child: Material(
            color: Col.transp,
            child: InkWell(
              onTap: function,
              child: child,
            ),
          ),
        );
}
