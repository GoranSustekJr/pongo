import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:provider/provider.dart';

import '../../../../../domain/models/catalog/track.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../app/view_models/app_settings_view_model.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/dimens.dart';
import '../../../../core/ui/app_blur.dart';
import '../../../../core/ui/blurhash/blurhash.dart';
import '../../../../core/ui/buttons/text_button.dart';
import '../../../../core/ui/phone/buttons/icon_button.dart';
import '../../../../core/ui/phone/liquid_glass_background.dart';
import '../../../../core/ui/phone/loading_scaffold.dart';
import '../../../../core/ui/phone/shimmer/song_shimmer.dart';
import '../../../../core/ui/phone/sticky_header_delegate.dart';
import '../../../../core/ui/space.dart';
import '../../../../player/widgets/phone/alerts/halt_alert.dart';
import '../../../../shell/view_models/shell_view_model.dart';
import '../../../view_models/online_playlist_view_model.dart';
import '../../../view_models/open_playlist.dart';
import '../pick_cover.dart';
import '../track_from_playlist_alert.dart';
import 'change_online_playlist_name_phone.dart';
import 'online_playlist_app_bar_phone.dart';
import 'online_playlist_body_phone.dart';
import 'play_shuffle_halt_online_playlist.dart';

class OnlinePlaylistPhone extends StatefulWidget {
  final int opid;
  final String title;
  final MemoryImage? cover;
  final String blurhash;
  final Function(MemoryImage) updateCover;
  final Function(String) updateTitle;
  const OnlinePlaylistPhone({
    super.key,
    required this.opid,
    required this.title,
    this.cover,
    required this.blurhash,
    required this.updateCover,
    required this.updateTitle,
  });

  @override
  State<OnlinePlaylistPhone> createState() => _OnlinePlaylistPhoneState();
}

class _OnlinePlaylistPhoneState extends State<OnlinePlaylistPhone> {
  late final OnlinePlaylistViewModel viewModel;

  // Scroll controller
  final scrollController = ScrollController();

  // Offset
  double scrollControllerOffset = 0;

  bool get showBody => viewModel.showBody;
  bool get edit => viewModel.edit;
  String get title => viewModel.title;
  String get blurhash => viewModel.blurhash;
  MemoryImage? get cover =>
      viewModel.cover == null ? widget.cover : MemoryImage(viewModel.cover!);
  List<Track> get tracks => viewModel.tracks;
  Map<String, bool> get hidden => viewModel.hidden;
  List<String> get selectedStids => viewModel.selectedStids;
  List<String> get missingTracks => viewModel.missingTracks;
  List<String> get loading => viewModel.loading;
  bool get loadingShuffle => viewModel.loadingShuffle;
  int get listLength => viewModel.listLength;

  @override
  void initState() {
    super.initState();
    viewModel = OnlinePlaylistViewModel(
      id: widget.opid,
      title: widget.title,
      cover: widget.cover?.bytes,
      blurhash: widget.blurhash,
      playlists: context.read(),
      player: context.read(),
      blurhashService: context.read(),
      catalog: context.read(),
      downloads: context.read(),
    );
    viewModel.addListener(_onViewModelChanged);
    scrollController.addListener(scrollControllerListener);
  }

  void _onViewModelChanged() => setState(() {});

  void scrollControllerListener() {
    setState(() {
      scrollControllerOffset = scrollController.offset < 0
          ? 0
          : scrollController.offset;
    });
  }

  Future<void> play({int index = 0}) => viewModel.play(index: index);

  Future<void> playShuffle() => viewModel.playShuffle();

  Future<void> showSelected() => viewModel.showSelected();

  Future<void> hideSelected() => viewModel.hideSelected();

  void changeTitle() {
    newPlaylistTitle(context, (newTitle) async {
      await viewModel.rename(newTitle);
      widget.updateTitle(newTitle);
    });
  }

  Future<void> changeCover() async {
    if (edit) {
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

  void stopEdit() => viewModel.stopEdit();

  Future<void> remove() async {
    if (selectedStids.isEmpty) return;
    final CustomButton ok = await removeTrackFromPlaylistAlert(context);
    if (ok == CustomButton.positiveButton) await viewModel.removeSelected();
  }

  void addToPlaylist() {
    final handler = viewModel.addSelectedToPlaylist();
    if (handler != null) OpenPlaylist().show(context, handler);
  }

  void select(String stid) => viewModel.select(stid);

  Future<void> moveTrack(int oldIndex, int newIndex) =>
      viewModel.moveTrack(oldIndex, newIndex);

  void selectAll() => viewModel.selectAll();

  Future<void> download() async {
    final handler = await viewModel.downloadSelected();
    if (handler != null && mounted) OpenPlaylist().show(context, handler);
  }

  @override
  void dispose() {
    viewModel.removeListener(_onViewModelChanged);
    viewModel.dispose();
    scrollController.removeListener(scrollControllerListener);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: showBody
          ? Container(
              key: const ValueKey(true),
              width: size.width,
              height: size.height,
              decoration: context.colors.backgroundBoxDecoration,
              child: Stack(
                children: [
                  Blurhash(
                    blurhash: blurhash,
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
                        controller: scrollController,
                        child: CustomScrollView(
                          controller: scrollController,
                          slivers: [
                            OnlinePlaylistAppBarPhone(
                              title: title,
                              cover: cover,
                              edit: edit,
                              scrollControllerOffset: scrollControllerOffset,
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
                                  child: liquidGlassBackground(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(60),
                                        color: context.readSettings.useBlur
                                            ? Col.transp
                                            : context.colors.realBackground
                                                  .withAlpha(Dimens.noBlur),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(60),
                                        child: BackdropFilter(
                                          filter: nonAppleBlur(context, 10),
                                          child: PlayShuffleHaltOnlinePlaylist(
                                            opid: widget.opid,
                                            missingTracks: missingTracks,
                                            loadingShuffle: loadingShuffle,
                                            edit: edit,
                                            allSelected:
                                                selectedStids.length ==
                                                tracks.length,
                                            frontWidget: const SizedBox(),
                                            endWidget: const SizedBox(),
                                            play: () {
                                              play(index: 0);
                                            },
                                            shuffle: playShuffle,
                                            stopEdit: stopEdit,
                                            remove: remove,
                                            addToPlaylist: addToPlaylist,
                                            show: showSelected,
                                            hide: hideSelected,
                                            selectAll: selectAll,
                                            download: download,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: tracks.isNotEmpty || listLength < 1
                                    ? SizedBox(
                                        key: const ValueKey(true),
                                        child: tracks.isEmpty
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
                                                    edgeInsets: EdgeInsets.zero,
                                                  ),
                                                ],
                                              )
                                            : OnlinePlaylistBodyPhone(
                                                opid: widget.opid,
                                                tracks: tracks,
                                                missingTracks: missingTracks,
                                                loading: loading,
                                                numberOfSTIDS: tracks.length,
                                                hidden: hidden,
                                                edit: edit,
                                                play: (index) {
                                                  play(index: index);
                                                },
                                                selectedTracks: selectedStids,
                                                select: select,
                                                move: moveTrack,
                                              ),
                                      )
                                    : Column(
                                        key: const ValueKey(false),
                                        children: [
                                          ListView.builder(
                                            padding: EdgeInsets.only(
                                              top: 35,
                                              bottom:
                                                  MediaQuery.of(context)
                                                      .padding
                                                      .bottom +
                                                  15,
                                            ),
                                            itemCount: listLength,
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemBuilder: (context, index) {
                                              return songTileSchimmer(
                                                context,
                                                index == 0,
                                                index == listLength - 1,
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
                ],
              ),
            )
          : loadingScaffold(context, const ValueKey(false)),
    );
  }
}
