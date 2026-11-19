import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:kr_pull_down_button/pull_down_button.dart';
import 'package:provider/provider.dart';

import '../../../../../domain/models/settings/app_settings.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../utils/platform.dart';
import '../../../../app/view_models/app_settings_view_model.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/dimens.dart';
import '../../../../core/ui/app_blur.dart';
import '../../../../core/ui/buttons/text_button.dart';
import '../../../../core/ui/phone/buttons/back_button.dart';
import '../../../../core/ui/phone/buttons/back_like_button.dart';
import '../../../../core/ui/phone/buttons/icon_button.dart';
import '../../../../core/ui/phone/loading_scaffold.dart';
import '../../../../core/ui/phone/shimmer/song_shimmer.dart';
import '../../../../core/ui/phone/sticky_header_delegate.dart';
import '../../../../core/ui/space.dart';
import '../../../../player/view_models/player_view_model.dart';
import '../../../../player/widgets/phone/alerts/halt_alert.dart';
import '../../../../playlists/view_models/open_playlist.dart';
import '../../../../shell/view_models/shell_view_model.dart';
import '../../../view_models/locals_view_model.dart';
import 'downloaded_alert.dart';
import 'locals_body_phone.dart';
import 'play_shuffle_halt_locals.dart';

class LocalsPhone extends StatefulWidget {
  const LocalsPhone({super.key});

  @override
  State<LocalsPhone> createState() => _LocalsPhoneState();
}

class _LocalsPhoneState extends State<LocalsPhone> {
  late final LocalsViewModel localsDataManager;
  final scrollController = ScrollController();
  final focusNode = FocusNode();
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    localsDataManager = LocalsViewModel(
      downloads: context.read(),
      settings: context.read(),
      player: context.read(),
    );
  }

  @override
  void dispose() {
    localsDataManager.dispose();
    scrollController.dispose();
    focusNode.dispose();
    searchController.dispose();
    super.dispose();
  }

  void newTracks() {
    context.shell.navigationBarIndex.value = 0;
    context.shell.searchFocusNode.requestFocus();
  }

  Future<void> startEdit() async {
    var halt = false;
    if (localsDataManager.isPlaying) {
      final CustomButton ok = await haltAlert(context);
      if (ok != CustomButton.positiveButton || !mounted) return;
      context.shell.currentTrackHeight.value = 0;
      halt = true;
    }
    await localsDataManager.startEdit(haltPlayback: halt);
  }

  Future<void> remove() async {
    if (localsDataManager.selectedTracks.isEmpty) return;
    final CustomButton ok = await removeDownloadedAlert(context);
    if (ok == CustomButton.positiveButton) {
      await localsDataManager.removeSelected();
    }
  }

  void addToPlaylist() {
    final handler = localsDataManager.addSelectedToPlaylist();
    if (handler != null) OpenPlaylist().show(context, handler);
  }

  void clearSearch() {
    searchController.text = '';
    localsDataManager.onSearched('');
  }

  void sort() {
    final l10n = AppLocalizations.of(context);
    String title(LocalsSort sort) => switch (sort) {
      LocalsSort.titleAscending ||
      LocalsSort.titleDescending => sort.storageValue,
      LocalsSort.firstAdded => l10n.firstadded,
      LocalsSort.lastAdded => l10n.lastadded,
    };
    showPullDownMenu(
      context: context,
      items: [
        for (final sort in LocalsSort.values) ...[
          if (sort != LocalsSort.values.first) const PullDownMenuDivider(),
          PullDownMenuItem(
            onTap: () => localsDataManager.sort(sort),
            title: title(sort),
          ),
        ],
      ],
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width,
        kToolbarHeight * 2,
        0,
        0,
      ),
      topWidget: const SizedBox(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final player = context.player;

    return ListenableBuilder(
      listenable: localsDataManager,
      builder: (context, child) {
        return AnimatedSwitcher(
          key: ValueKey(localsDataManager.showBody),
          duration: const Duration(milliseconds: 400),
          child: localsDataManager.showBody
              ? Container(
                  key: const ValueKey(true),
                  width: size.width,
                  height: size.height,
                  decoration: context.colors.backgroundBoxDecoration,
                  child: Scaffold(
                    resizeToAvoidBottomInset: false,
                    extendBodyBehindAppBar: true,
                    extendBody: true,
                    body: Scrollbar(
                      controller: scrollController,
                      child: CustomScrollView(
                        controller: scrollController,
                        slivers: [
                          SliverAppBar(
                            //snap: true,
                            //floating: true,
                            pinned: true,
                            stretch: true,
                            backgroundColor: context.readSettings.useBlur
                                ? Col.transp
                                : context.colors.realBackground.withAlpha(
                                    Dimens.noBlur,
                                  ),
                            automaticallyImplyLeading: false,
                            expandedHeight: kIsApple
                                ? size.height / 5
                                : size.height / 4,
                            title: Row(
                              children: [
                                backButton(context),
                                Expanded(child: Container()),
                                StreamBuilder(
                                  stream: player.currentItemStream,
                                  builder: (context, mediaItemStream) {
                                    final bool showPlay =
                                        mediaItemStream.data == null
                                        ? true
                                        : 'library.locals' !=
                                              '${mediaItemStream.data!.id.split('.')[0]}.${mediaItemStream.data!.id.split('.')[1]}';
                                    return AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: showPlay
                                          ? SizedBox(
                                              key: const ValueKey(true),
                                              child: backLikeButton(
                                                context,
                                                CupertinoIcons
                                                    .line_horizontal_3_decrease,
                                                sort,
                                              ),
                                            )
                                          : const SizedBox(),
                                    );
                                  },
                                ),
                              ],
                            ),
                            flexibleSpace: ClipRRect(
                              child: BackdropFilter(
                                filter: appBlur(context, 10),
                                child: FlexibleSpaceBar(
                                  centerTitle: true,
                                  title: Text(
                                    AppLocalizations.of(context).offlinesongs,
                                    style: TextStyle(
                                      fontSize: kIsApple ? 25 : 30,
                                      fontWeight: kIsApple
                                          ? FontWeight.w700
                                          : FontWeight.w800,
                                      color: context.colors.text,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                  ),
                                  stretchModes: const [
                                    StretchMode.zoomBackground,
                                    StretchMode.blurBackground,
                                    StretchMode.fadeTitle,
                                  ],
                                ),
                              ),
                            ),
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
                                    borderRadius: BorderRadius.circular(60),
                                    color: context.readSettings.useBlur
                                        ? Col.transp
                                        : context.colors.realBackground
                                              .withAlpha(Dimens.noBlur),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: BackdropFilter(
                                      filter: appBlur(context, 10),
                                      child: PlayShuffleHaltLocals(
                                        missingTracks: const [],
                                        loadingShuffle: false,
                                        edit: localsDataManager.edit,
                                        allSelected:
                                            localsDataManager
                                                .selectedTracks
                                                .length ==
                                            localsDataManager.tracks.length,
                                        frontWidget: iconButton(
                                          AppIcons.blankTrack,
                                          context.colors.icon,
                                          newTracks,
                                          edgeInsets: EdgeInsets.zero,
                                        ),
                                        endWidget: iconButton(
                                          AppIcons.edit,
                                          context.colors.icon,
                                          startEdit,
                                          edgeInsets: EdgeInsets.zero,
                                        ),
                                        play: localsDataManager.play,
                                        shuffle: localsDataManager.shuffle,
                                        stopEdit: localsDataManager.stopEdit,
                                        remove: remove,
                                        addToPlaylist: addToPlaylist,
                                        selectAll: localsDataManager.selectAll,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 10,
                              ),
                              child: CupertinoSearchTextField(
                                controller: searchController,
                                focusNode: focusNode,
                                onChanged: localsDataManager.onSearched,
                                onSuffixTap: clearSearch,
                                placeholder: AppLocalizations.of(context)
                                    .search,
                                backgroundColor: context.colors.primaryCard
                                    .withAlpha(150),
                                style: TextStyle(color: context.colors.text),
                                itemColor: context.colors.icon,
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child:
                                  localsDataManager.tracksBackup.isNotEmpty ||
                                      localsDataManager.numOfTracks < 1
                                  ? SizedBox(
                                      key: const ValueKey(true),
                                      child: localsDataManager.tracks.isEmpty
                                          ? Column(
                                              children: [
                                                razh(100),
                                                iconButton(
                                                  AppIcons.musicAlbums,
                                                  context.colors.icon,
                                                  newTracks,
                                                  size: 60,
                                                ),
                                                textButton(
                                                  AppLocalizations.of(context)
                                                      .downloadtracksnow,
                                                  newTracks,
                                                  TextStyle(
                                                    color: context.colors.text,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : LocalsBodyPhone(
                                              localsDataManager:
                                                  localsDataManager,
                                            ),
                                    )
                                  : SingleChildScrollView(
                                      key: const ValueKey(false),
                                      child: Column(
                                        children: [
                                          ListView.builder(
                                            itemCount:
                                                localsDataManager.numOfTracks,
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
                                                    localsDataManager
                                                            .numOfTracks -
                                                        1,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : loadingScaffold(context, const ValueKey(false)),
        );
      },
    );
  }
}
