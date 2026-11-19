import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../domain/models/catalog/track.dart';
import '../../../../../utils/platform.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/ui/phone/buttons/icon_button.dart';
import '../../../../core/ui/phone/trailing.dart';
import '../../../../library/widgets/phone/favourites/favourites_tile.dart';
import '../../../../player/view_models/player_view_model.dart';

class OnlinePlaylistBodyPhone extends StatelessWidget {
  final int opid;
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
  const OnlinePlaylistBodyPhone({
    super.key,
    required this.opid,
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
  Widget build(BuildContext context) {
    // Not hiddent tracks
    final List<Track> shownTracks = tracks
        .where((track) => hidden[track.id] != true || edit)
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
              if (edit) {}
              move(oldIndex, newIndex);
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
              return FavouritesTile(
                key: ValueKey(index),
                track: shownTracks[index],
                first: index == 0,
                forceWhite: true,
                last: shownTracks.length - 1 == index,
                exists: !missingTracks.contains(shownTracks[index].id),
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
                              show: !loading.contains(shownTracks[index].id),
                              showThis:
                                  id ==
                                      'online.playlist:$opid.${shownTracks[index].id}' &&
                                  player.currentIndex == index,
                              trailing: const Icon(
                                key: ValueKey(true),
                                AppIcons.loading,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (edit && hidden[shownTracks[index].id] == true)
                          const SizedBox(
                            height: 40,
                            width: 20,
                            child: Icon(AppIcons.hide, color: Colors.white),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: edit ? 40 : 0,
                          height: 40,
                          child: Padding(
                            padding: const EdgeInsets.only(),
                            child: iconButton(
                              selectedTracks.contains(shownTracks[index].id)
                                  ? AppIcons.checkmark
                                  : AppIcons.uncheckmark,
                              Colors.white,
                              () {
                                select(shownTracks[index].id);
                              },
                              edgeInsets: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                function: edit
                    ? () {
                        select(shownTracks[index].id);
                      }
                    : () async {
                        await context.player.playCollectionTrack(
                          collectionId: 'online.playlist:$opid',
                          stid: shownTracks[index].id,
                          index: index,
                          playCollection: () async => play(index),
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
