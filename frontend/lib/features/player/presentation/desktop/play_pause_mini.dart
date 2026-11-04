import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

playPauseMini(bool playing, Function() function) {
  return Theme(
    data: ThemeData(
      splashColor: Col.transp,
      hoverColor: Col.transp,
      highlightColor: Col.transp,
      focusColor: Col.transp,
    ),
    child: IconButton(
      onPressed: function,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation,
              child: child,
            ),
          );
        },
        child: playing
            ? const Icon(
                CupertinoIcons.pause_fill,
                key: ValueKey(true),
                size: 30,
                color: Colors.white,
              )
            : const Icon(
                CupertinoIcons.play_fill,
                key: ValueKey(false),
                size: 30,
                color: Colors.white,
              ),
      ),
    ),
  );
}
