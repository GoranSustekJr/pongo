import 'package:flutter/material.dart';

import '../../../../../domain/models/catalog/track.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/ui/phone/buttons/icon_button.dart';
import '../../../../core/ui/phone/trailing.dart';
import '../../../../player/view_models/player_view_model.dart';
import 'favourites_tile.dart';

class FavouritesBodyPhone extends StatefulWidget {
  final List<Track> favourites;
  final List missingTracks;
  final List<String> loading;
  final int numberOfSTIDS;
  final bool edit;
  final List<String> selectedTracks;
  final Function(int) play;
  final Function(String) select;
  const FavouritesBodyPhone({
    super.key,
    required this.favourites,
    required this.missingTracks,
    required this.loading,
    required this.play,
    required this.numberOfSTIDS,
    required this.edit,
    required this.select,
    required this.selectedTracks,
  });

  @override
  State<FavouritesBodyPhone> createState() => _FavouritesBodyPhoneState();
}

class _FavouritesBodyPhoneState extends State<FavouritesBodyPhone> {
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
      padding: const EdgeInsets.only(left: 0),
      child: StreamBuilder(
        key: const ValueKey(false),
        stream: player.currentItemStream,
        builder: (context, snapshot) {
          final String id = snapshot.data != null ? snapshot.data!.id : '';
          return ListView.builder(
            controller: controller,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.favourites.length + 1,
            itemBuilder: (context, index) {
              if (index == widget.favourites.length) {
                return widget.numberOfSTIDS != index
                    ? const CircularProgressIndicator.adaptive()
                    : const SizedBox();
              }
              return FavouritesTile(
                track: widget.favourites[index],
                first: index == 0,
                forceWhite: false,
                last: widget.favourites.length - 1 == index,
                exists: !widget.missingTracks.contains(
                  widget.favourites[index].id,
                ),
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 0),
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
                              show: !widget.loading.contains(
                                widget.favourites[index].id,
                              ),
                              showThis:
                                  id ==
                                      'library.favourites.${widget.favourites[index].id}' &&
                                  player.currentIndex == index,
                              trailing:
                                  const CircularProgressIndicator.adaptive(
                                    key: ValueKey(true),
                                  ),
                            ),
                          ) /* AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: widget.loading.contains(widget.favourites[index].id)
                                  ? const CircularProgressIndicator.adaptive(
                                      key: ValueKey(true),
                                    )
                                  : const SizedBox()), */,
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: widget.edit ? 40 : 0,
                          height: 40,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 0),
                            child: iconButton(
                              widget.selectedTracks.contains(
                                    widget.favourites[index].id,
                                  )
                                  ? AppIcons.checkmark
                                  : AppIcons.uncheckmark,
                              context.colors.icon,
                              () {
                                widget.select(widget.favourites[index].id);
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
                        widget.select(widget.favourites[index].id);
                      }
                    : () async {
                        await context.player.playCollectionTrack(
                          collectionId: 'library.favourites',
                          stid: widget.favourites[index].id,
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
