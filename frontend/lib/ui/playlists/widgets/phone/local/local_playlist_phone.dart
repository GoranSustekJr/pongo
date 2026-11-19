import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:provider/provider.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../app/view_models/app_settings_view_model.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/dimens.dart';
import '../../../../core/ui/app_blur.dart';
import '../../../../core/ui/blurhash/blurhash.dart';
import '../../../../core/ui/buttons/text_button.dart';
import '../../../../core/ui/phone/buttons/icon_button.dart';
import '../../../../core/ui/phone/shimmer/song_shimmer.dart';
import '../../../../core/ui/phone/sticky_header_delegate.dart';
import '../../../../core/ui/space.dart';
import '../../../../player/widgets/phone/alerts/halt_alert.dart';
import '../../../../shell/view_models/shell_view_model.dart';
import '../../../view_models/local_playlist_view_model.dart';
import '../../../view_models/open_playlist.dart';
import '../online/change_online_playlist_name_phone.dart';
import '../pick_cover.dart';
import '../track_from_playlist_alert.dart';
import 'local_playlist_app_bar_phone.dart';
import 'local_playlist_body_phone.dart';
import 'play_shuffle_halt_local_playlist.dart';

class LocalPlaylistPhone extends StatefulWidget {
  final int lpid;
  final String title;
  final MemoryImage? cover;
  final String blurhash;
  final Function(MemoryImage) updateCover;
  final Function(String) updateTitle;
  const LocalPlaylistPhone({
    super.key,
    required this.lpid,
    required this.title,
    this.cover,
    required this.blurhash,
    required this.updateCover,
    required this.updateTitle,
  });

  @override
  State<LocalPlaylistPhone> createState() => _LocalPlaylistPhoneState();
}

class _LocalPlaylistPhoneState extends State<LocalPlaylistPhone> {
  late final LocalPlaylistViewModel viewModel;
  final scrollController = ScrollController();
  double scrollControllerOffset = 0;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      setState(() {
        scrollControllerOffset = scrollController.offset < 0
            ? 0
            : scrollController.offset;
      });
    });
    viewModel = LocalPlaylistViewModel(
      id: widget.lpid,
      title: widget.title,
      cover: widget.cover?.bytes,
      blurhash: widget.blurhash,
      playlists: context.read(),
      player: context.read(),
      blurhashService: context.read(),
    );
  }

  @override
  void dispose() {
    viewModel.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void changeTitle() {
    newPlaylistTitle(context, (newTitle) async {
      await viewModel.rename(newTitle);
      widget.updateTitle(newTitle);
    });
  }

  Future<void> changeCover() async {
    if (viewModel.edit) {
      final bytes = await pickSquareCover(context);
      if (bytes == null || bytes.isEmpty) return;
      await viewModel.setCover(bytes);
      widget.updateCover(MemoryImage(bytes));
      return;
    }
    var halt = false;
    if (viewModel.isPlaying) {
      final CustomButton ok = await haltAlert(context);
      if (ok != CustomButton.positiveButton || !mounted) return;
      context.shell.currentTrackHeight.value = 0;
      halt = true;
    }
    await viewModel.startEdit(haltPlayback: halt);
  }

  Future<void> remove() async {
    if (viewModel.selectedStids.isEmpty) return;
    final CustomButton ok = await removeTrackFromPlaylistAlert(context);
    if (ok == CustomButton.positiveButton) await viewModel.removeSelected();
  }

  void addToPlaylist() {
    final handler = viewModel.addSelectedToPlaylist();
    if (handler != null) OpenPlaylist().show(context, handler);
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final localPlaylistDataManager = viewModel;
        return AnimatedSwitcher(
          key: ValueKey(localPlaylistDataManager),
          duration: const Duration(milliseconds: 400),
          child: localPlaylistDataManager.showBody
              ? Container(
                  key: const ValueKey(true),
                  width: size.width,
                  height: size.height,
                  decoration: context.colors.backgroundBoxDecoration,
                  child: Stack(
                    children: [
                      Blurhash(
                        blurhash: localPlaylistDataManager.blurhash,
                        sigmaX: 0,
                        sigmaY: 0,
                        child: Container(),
                      ),
                      Container(
                        width: size.width,
                        height: size.height,
                        color: Colors.black.withAlpha(50),
                        child: Scaffold(
                          extendBodyBehindAppBar: true,
                          extendBody: true,
                          body: Scrollbar(
                            child: Scrollbar(
                              child: CustomScrollView(
                                controller: scrollController,
                                slivers: [
                                  LocalPlaylistAppBarPhone(
                                    title: localPlaylistDataManager.title,
                                    cover:
                                        localPlaylistDataManager.cover == null
                                        ? null
                                        : MemoryImage(
                                            localPlaylistDataManager.cover!,
                                          ),
                                    edit: localPlaylistDataManager.edit,
                                    scrollControllerOffset:
                                        scrollControllerOffset,
                                    changeCover: changeCover,
                                    changeTitle: changeTitle,
                                  ),
                                  SliverPersistentHeader(
                                    pinned: true,
                                    delegate: StickyHeaderDelegate(
                                      minHeight: 40,
                                      maxHeight: 40,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 15,
                                          right: 15,
                                          top: 5,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              60,
                                            ),
                                            color: context.readSettings.useBlur
                                                ? Col.transp
                                                : context.colors.realBackground
                                                      .withAlpha(Dimens.noBlur),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              60,
                                            ),
                                            child: BackdropFilter(
                                              filter: appBlur(context, 10),
                                              child:
                                                  PlayShuffleHaltLocalPlaylist(
                                                    lpid: widget.lpid,
                                                    allSelected:
                                                        localPlaylistDataManager
                                                            .selectedStids
                                                            .length ==
                                                        localPlaylistDataManager
                                                            .tracks
                                                            .length,
                                                    missingTracks:
                                                        const <String>[],
                                                    loadingShuffle: false,
                                                    edit:
                                                        localPlaylistDataManager
                                                            .edit,
                                                    frontWidget:
                                                        const SizedBox(),
                                                    endWidget: const SizedBox(),
                                                    play: () {
                                                      localPlaylistDataManager
                                                          .play(index: 0);
                                                    },
                                                    shuffle:
                                                        localPlaylistDataManager
                                                            .playShuffle,
                                                    stopEdit:
                                                        localPlaylistDataManager
                                                            .stopEdit,
                                                    remove: remove,
                                                    addToPlaylist:
                                                        addToPlaylist,
                                                    show:
                                                        localPlaylistDataManager
                                                            .showSelected,
                                                    hide:
                                                        localPlaylistDataManager
                                                            .hideSelected,
                                                    selectAll:
                                                        localPlaylistDataManager
                                                            .selectAll,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child:
                                          localPlaylistDataManager
                                                  .tracks
                                                  .isNotEmpty ||
                                              localPlaylistDataManager
                                                      .listLength <
                                                  1
                                          ? SizedBox(
                                              key: const ValueKey(true),
                                              child:
                                                  localPlaylistDataManager
                                                      .tracks
                                                      .isEmpty
                                                  ? Column(
                                                      children: [
                                                        razh(50),
                                                        iconButton(
                                                          AppIcons.blankTrack,
                                                          Colors.white,
                                                          () {
                                                            context
                                                                    .shell
                                                                    .navigationBarIndex
                                                                    .value =
                                                                0;
                                                            context
                                                                .shell
                                                                .searchFocusNode
                                                                .requestFocus();
                                                          },
                                                          size: 60,
                                                        ),
                                                        textButton(
                                                          AppLocalizations.of(
                                                            context,
                                                          ).addtrackstoyoutplaylist,
                                                          () {
                                                            context
                                                                    .shell
                                                                    .navigationBarIndex
                                                                    .value =
                                                                0;
                                                            context
                                                                .shell
                                                                .searchFocusNode
                                                                .requestFocus();
                                                          },
                                                          const TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                          edgeInsets:
                                                              EdgeInsets.zero,
                                                        ),
                                                      ],
                                                    )
                                                  : LocalPlaylistBodyPhone(
                                                      lpid: widget.lpid,
                                                      tracks:
                                                          localPlaylistDataManager
                                                              .tracks,
                                                      missingTracks:
                                                          const <String>[],
                                                      loading: const <String>[],
                                                      numberOfSTIDS:
                                                          localPlaylistDataManager
                                                              .tracks
                                                              .length,
                                                      hidden:
                                                          localPlaylistDataManager
                                                              .hidden,
                                                      edit:
                                                          localPlaylistDataManager
                                                              .edit,
                                                      play: (index) {
                                                        localPlaylistDataManager
                                                            .play(index: index);
                                                      },
                                                      selectedTracks:
                                                          localPlaylistDataManager
                                                              .selectedStids,
                                                      select:
                                                          localPlaylistDataManager
                                                              .select,
                                                      move:
                                                          localPlaylistDataManager
                                                              .moveTrack,
                                                    ),
                                            )
                                          : Column(
                                              key: const ValueKey(false),
                                              children: [
                                                ListView.builder(
                                                  itemCount:
                                                      localPlaylistDataManager
                                                          .listLength,
                                                  padding: EdgeInsets.only(
                                                    top: 35,
                                                    bottom:
                                                        MediaQuery.of(context)
                                                            .padding
                                                            .bottom +
                                                        15,
                                                  ),
                                                  shrinkWrap: true,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  itemBuilder: (context, index) {
                                                    return songTileSchimmer(
                                                      context,
                                                      index == 0,
                                                      index ==
                                                          localPlaylistDataManager
                                                                  .listLength -
                                                              1,
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const Text('ddddd'),
        );
      },
    );
  }
}
