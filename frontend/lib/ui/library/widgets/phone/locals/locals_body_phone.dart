import 'package:flutter/material.dart';

import '../../../../../utils/platform.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/ui/phone/buttons/icon_button.dart';
import '../../../../core/ui/phone/trailing.dart';
import '../../../../player/view_models/player_view_model.dart';
import '../../../view_models/locals_view_model.dart';
import 'locals_tile.dart';

class LocalsBodyPhone extends StatefulWidget {
  final LocalsViewModel localsDataManager;

  const LocalsBodyPhone({super.key, required this.localsDataManager});

  @override
  State<LocalsBodyPhone> createState() => _LocalsBodyPhoneState();
}

class _LocalsBodyPhoneState extends State<LocalsBodyPhone> {
  // Scroll controller
  ScrollController controller = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.player;

    return Padding(
      padding: const EdgeInsets.only(),
      child: StreamBuilder(
        key: const ValueKey(false),
        stream: player.currentItemStream,
        builder: (context, snapshot) {
          final String id = snapshot.data != null ? snapshot.data!.id : '';
          return ListView.builder(
            controller: controller,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.localsDataManager.tracks.length,
            itemBuilder: (context, index) {
              return LocalsTile(
                track: widget.localsDataManager.tracks[index],
                first: index == 0,
                forceWhite: false,
                last: widget.localsDataManager.tracks.length - 1 == index,
                trailing: Padding(
                  padding: EdgeInsets.only(right: kIsApple ? 0 : 5),
                  child: SizedBox(
                    child: Row(
                      children: [
                        SizedBox(
                          height: 40,
                          width: 25,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Trailing(
                              forceWhite: false,
                              show:
                                  id ==
                                      'library.locals.${widget.localsDataManager.tracks[index].id}' &&
                                  player.currentIndex == index,
                              showThis:
                                  id ==
                                      'library.locals.${widget.localsDataManager.tracks[index].id}' &&
                                  player.currentIndex == index,
                              trailing: const SizedBox(key: ValueKey(true)),
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: widget.localsDataManager.edit ? 40 : 0,
                          height: 40,
                          child: Padding(
                            padding: const EdgeInsets.only(),
                            child: iconButton(
                              widget.localsDataManager.selectedTracks.contains(
                                    widget.localsDataManager.tracks[index].id,
                                  )
                                  ? AppIcons.checkmark
                                  : AppIcons.uncheckmark,
                              context.colors.icon,
                              () {
                                widget.localsDataManager.select(
                                  widget.localsDataManager.tracks[index].id,
                                );
                              },
                              edgeInsets: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                function: widget.localsDataManager.edit
                    ? () {
                        widget.localsDataManager.select(
                          widget.localsDataManager.tracks[index].id,
                        );
                      }
                    : () async {
                        await context.player.playCollectionTrack(
                          collectionId: LocalsViewModel.collectionId,
                          stid: widget.localsDataManager.tracks[index].id,
                          index: index,
                          playCollection: () =>
                              widget.localsDataManager.play(index: index),
                        );
                      },
              );
            },
          );
        },
      ),
    );
  }
}
