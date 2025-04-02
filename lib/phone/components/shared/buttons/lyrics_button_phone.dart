import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

class LyricsButtonPhone extends StatelessWidget {
  final String stid;
  final int syncTimeDelay;
  final bool lyricsOn;
  final bool useSynced;
  final Function() changeLyricsOn;
  final Function() changeUseSynced;
  final Function() plus;
  final Function() minus;
  final Function() resetSyncTimeDelay;
  const LyricsButtonPhone({
    super.key,
    required this.stid,
    required this.syncTimeDelay,
    required this.plus,
    required this.minus,
    required this.lyricsOn,
    required this.changeLyricsOn,
    required this.useSynced,
    required this.changeUseSynced,
    required this.resetSyncTimeDelay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.decelerate,
      top: lyricsOn ? MediaQuery.of(context).padding.top + 12.5 : -50,
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
                filter: ImageFilter.blur(
                  sigmaX: useBlur.value ? 10 : 0,
                  sigmaY: useBlur.value ? 10 : 0,
                ),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    color: kIsDesktop
                        ? const MacosColor.fromRGBO(
                            40, 40, 40, 0.8) // Add transparency here
                        : useBlur.value
                            ? Col.transp
                            : Col.realBackground
                                .withAlpha(AppConstants().noBlur),
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: changeLyricsOn,
                    child: Icon(
                      lyricsOn ? AppIcons.lyricsFill : AppIcons.lyrics,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: useBlur.value ? 10 : 0,
                  sigmaY: useBlur.value ? 10 : 0,
                ),
                child: Container(
                  height: 40,
                  width: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    color: kIsDesktop
                        ? const MacosColor.fromRGBO(
                            40, 40, 40, 0.8) // Add transparency here
                        : useBlur.value
                            ? Col.transp
                            : Col.realBackground
                                .withAlpha(AppConstants().noBlur),
                  ),
                  child: Row(
                    children: [
                      if (kIsApple)
                        GestureDetector(
                          child: CupertinoButton(
                            padding: const EdgeInsets.only(),
                            child: const Icon(
                              CupertinoIcons.minus,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              minus();
                            },
                          ),
                        ),
                      if (!kIsApple)
                        IconButton(
                          onPressed: () {
                            minus();
                          },
                          icon: const Icon(CupertinoIcons.minus),
                        ),
                      Expanded(child: Container()),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: GestureDetector(
                          onLongPress: () async {
                            await DatabaseHelper()
                                .insertSyncTimeDelay(stid, syncTimeDelay);
                            Notifications().showSpecialNotification(
                              context,
                              AppLocalizations.of(context).successful,
                              AppLocalizations.of(context)
                                  .successfullysavedsynctimedelay,
                              CupertinoIcons.time,
                            );
                          },
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: resetSyncTimeDelay,
                            child: Text(
                              "${syncTimeDelay / 1000} s",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.fade,
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: Container()),
                      if (!kIsApple)
                        IconButton(
                          onPressed: () {
                            plus();
                          },
                          icon: const Icon(CupertinoIcons.plus),
                        ),
                      if (kIsApple)
                        CupertinoButton(
                          padding: const EdgeInsets.only(),
                          child: const Icon(
                            CupertinoIcons.plus,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            plus();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: useBlur.value ? 10 : 0,
                  sigmaY: useBlur.value ? 10 : 0,
                ),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    color: kIsDesktop
                        ? const MacosColor.fromRGBO(
                            40, 40, 40, 0.8) // Add transparency here
                        : useBlur.value
                            ? Col.transp
                            : Col.realBackground
                                .withAlpha(AppConstants().noBlur),
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: changeUseSynced,
                    child: Icon(
                      useSynced
                          ? CupertinoIcons.hourglass_tophalf_fill
                          : CupertinoIcons.hourglass_bottomhalf_fill,
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
