import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

backLikeButton(context, IconData icon, Function() function) {
  return kIsApple
      ? CupertinoButton(
          onPressed: function,
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  color: Colors.black.withAlpha(20),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 9,
                      top: 11,
                      child: Icon(
                        icon,
                        size: 27.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
            onPressed: function,
            icon: Stack(
              children: [
                Positioned(
                  left: 2,
                  top: 3,
                  child: Icon(
                    icon,
                    size: 27.5,
                  ),
                ),
              ],
            ),
          ),
        );
}
