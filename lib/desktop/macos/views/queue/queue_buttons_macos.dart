import 'package:flutter/cupertino.dart';
import 'package:pongo/phone/components/shared/playing%20details/controls.dart';

class QueueButtonsMacos extends StatelessWidget {
  final bool edit;
  final Function(bool) changeEditQueue;
  final Function() removeItemsFromQueue;
  final Function() clearSelectedQueueIndexes;
  final Function() closeQueue;
  const QueueButtonsMacos(
      {super.key,
      required this.edit,
      required this.changeEditQueue,
      required this.removeItemsFromQueue,
      required this.clearSelectedQueueIndexes,
      required this.closeQueue});

  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Tooltip(
            message: AppLocalizations.of(context).shuffle,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                color: kIsDesktop && !kIsMacOS
                    ? const MacosColor.fromRGBO(
                        40, 40, 40, 0.8) // Add transparency here
                    : Col.transp,
              ),
              child: ValueListenableBuilder(
                  valueListenable: queueAllowShuffle,
                  builder: (context, _, __) {
                    return CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        if (queueAllowShuffle.value) {
                          if (audioServiceHandler
                              .audioPlayer.shuffleModeEnabled) {
                            await audioServiceHandler
                                .setShuffleMode(AudioServiceShuffleMode.none);
                          } else {
                            await audioServiceHandler
                                .setShuffleMode(AudioServiceShuffleMode.all);
                          }
                        }
                      },
                      child: StreamBuilder(
                          stream: audioServiceHandler
                              .audioPlayer.shuffleModeEnabledStream,
                          builder: (context, snapshot) {
                            bool enabled = snapshot.data ?? false;
                            return Icon(
                              AppIcons.shuffle,
                              color: enabled
                                  ? Colors.white
                                  : Colors.white.withAlpha(150),
                            );
                          }),
                    );
                  }),
            ),
          ),
          dividerVertical(30, 1, 7.5),
          Tooltip(
            message: edit
                ? AppLocalizations.of(context).cancel
                : AppLocalizations.of(context).edit,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                color: kIsDesktop && !kIsMacOS
                    ? const MacosColor.fromRGBO(
                        40, 40, 40, 0.8) // Add transparency here
                    : Col.transp,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: edit
                    ? iconButton(AppIcons.x, Colors.white, () {
                        changeEditQueue(false);
                        clearSelectedQueueIndexes();
                      }, edgeInsets: EdgeInsets.zero)
                    : iconButton(AppIcons.edit, Colors.white, () {
                        changeEditQueue(true);
                      }, edgeInsets: EdgeInsets.zero),
              ),
            ),
          ),
          dividerVertical(30, 1, 7.5),
          Tooltip(
            message: edit
                ? AppLocalizations.of(context).delete
                : AppLocalizations.of(context).addtrackstoyoutplaylist,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                color: kIsDesktop && !kIsMacOS
                    ? const MacosColor.fromRGBO(
                        40, 40, 40, 0.8) // Add transparency here
                    : Col.transp,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: edit
                    ? iconButton(AppIcons.trash, Colors.white, () {
                        removeItemsFromQueue();
                      }, edgeInsets: EdgeInsets.zero)
                    : iconButton(AppIcons.musicAlbums, Colors.white, () async {
                        // TODO: Add to playlist
                      }, edgeInsets: EdgeInsets.zero),
              ),
            ),
          ),
          dividerVertical(30, 1, 7.5),
          Tooltip(
            message: AppLocalizations.of(context).download,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                color: kIsDesktop && !kIsMacOS
                    ? const MacosColor.fromRGBO(
                        40, 40, 40, 0.8) // Add transparency here
                    : Col.transp,
              ),
              child: iconButton(AppIcons.download, Colors.white, () async {
                // TODO: Download
              }, edgeInsets: EdgeInsets.zero),
            ),
          ),
          dividerVertical(30, 1, 7.5),
          Tooltip(
            message: AppLocalizations.of(context).halt,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                color: kIsDesktop && !kIsMacOS
                    ? const MacosColor.fromRGBO(
                        40, 40, 40, 0.8) // Add transparency here
                    : Col.transp,
              ),
              child: iconButton(AppIcons.halt, Colors.white, () async {
                CustomButton ok = await haltAlert(context);

                if (ok == CustomButton.positiveButton) {
                  currentTrackHeight.value = 0;
                  final audioServiceHandler =
                      Provider.of<AudioHandler>(context, listen: false)
                          as AudioServiceHandler;

                  closeQueue();

                  await audioServiceHandler.halt();
                }
              }, edgeInsets: EdgeInsets.zero),
            ),
          ),
        ],
      ),
    );
  }
}
