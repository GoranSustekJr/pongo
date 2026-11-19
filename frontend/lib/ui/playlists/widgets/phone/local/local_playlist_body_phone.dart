import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../domain/models/catalog/track.dart';
import '../../../../../utils/platform.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/ui/phone/buttons/icon_button.dart';
import '../../../../core/ui/phone/trailing.dart';
import '../../../../library/widgets/phone/locals/locals_tile.dart';
import '../../../../player/view_models/player_view_model.dart';

class LocalPlaylistBodyPhone extends StatefulWidget {
  final int lpid;
  final List<Track> tracks;
  final List missingTracks;
  final List<String> loading;
  final int numberOfSTIDS;
  final bool edit;
  final List<String> selectedTracks;
  final Map<String, bool> hidden;
  final Function(int) play;
  final Function(String) select;
  final Function(int, int) move;
  const LocalPlaylistBodyPhone({
    super.key,
    required this.lpid,
    required this.tracks,
    required this.missingTracks,
    required this.loading,
    required this.numberOfSTIDS,
    required this.edit,
    required this.selectedTracks,
    required this.play,
    required this.select,
    required this.move,
    required this.hidden,
  });

  @override
  State<LocalPlaylistBodyPhone> createState() => _LocalPlaylistBodyPhoneState();
}

class _LocalPlaylistBodyPhoneState extends State<LocalPlaylistBodyPhone> {
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
    // Not hiddent tracks
    final List<Track> shownTracks = widget.tracks
        .where((track) => widget.hidden[track.id] != true || widget.edit)
        .toList();

    final player = context.player;

    return Padding(
      padding: const EdgeInsets.only(),
      child: StreamBuilder(
        key: const ValueKey(false),
        stream: player.currentItemStream,
        builder: (context, snapshot) {
          final String id = snapshot.data != null ? snapshot.data!.id : '';

          return ReorderableListView.builder(
            padding: EdgeInsets.only(
              top: 35,
              bottom: MediaQuery.of(context).padding.bottom + 15,
            ),
            itemCount: shownTracks.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorderItem: (oldIndex, newIndex) {
              // The handlers below expect the index from before the item is
              // removed
              if (newIndex > oldIndex) newIndex += 1;
              if (widget.edit) {}
              widget.move(oldIndex, newIndex);
            },
            proxyDecorator: (child, index, animation) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: context.colors.primaryCard.withAlpha(175),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: child,
                ),
              ),
            ),
            itemBuilder: (context, index) {
              return LocalsTile(
                key: ValueKey(index),
                forceWhite: true,
                track: shownTracks[index],
                first: index == 0,
                last: shownTracks.length - 1 == index,
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
                              forceWhite: true,
                              show: !widget.loading.contains(
                                shownTracks[index].id,
                              ),
                              showThis:
                                  id ==
                                      'local.playlist:${widget.lpid}.${shownTracks[index].id}' &&
                                  player.currentIndex == index,
                              trailing: const Icon(
                                key: ValueKey(true),
                                AppIcons.loading,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (widget.edit &&
                            widget.hidden[shownTracks[index].id] == true)
                          const SizedBox(
                            height: 40,
                            width: 20,
                            child: Icon(AppIcons.hide, color: Colors.white),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: widget.edit ? 40 : 0,
                          height: 40,
                          child: Padding(
                            padding: const EdgeInsets.only(),
                            child: iconButton(
                              widget.selectedTracks.contains(
                                    shownTracks[index].id,
                                  )
                                  ? AppIcons.checkmark
                                  : AppIcons.uncheckmark,
                              Colors.white,
                              () {
                                widget.select(shownTracks[index].id);
                              },
                              edgeInsets: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                function: widget.edit
                    ? () {
                        widget.select(shownTracks[index].id);
                      }
                    : () async {
                        await context.player.playCollectionTrack(
                          collectionId: 'local.playlist:${widget.lpid}',
                          stid: shownTracks[index].id,
                          index: index,
                          playCollection: () async => widget.play(index),
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
