import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

class QueueButtonPhone extends StatelessWidget {
  final bool showQueue;
  final bool lyricsOn;
  final Function() changeShowQueue;
  const QueueButtonPhone({
    super.key,
    required this.showQueue,
    required this.changeShowQueue,
    required this.lyricsOn,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.decelerate,
      top: showQueue && !lyricsOn
          ? MediaQuery.of(context).padding.top + 12.5
          : -50,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: 40,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    color: kIsDesktop
                        ? const MacosColor.fromRGBO(
                            40, 40, 40, 0.8) // Add transparency here
                        : Col.transp,
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: changeShowQueue,
                    child: Icon(
                      showQueue ? AppIcons.musicQueueFill : AppIcons.musicQueue,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
