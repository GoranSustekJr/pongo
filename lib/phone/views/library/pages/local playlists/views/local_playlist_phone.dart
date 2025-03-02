import 'dart:ui';
import 'package:pongo/exports.dart';

class LocalPlaylistPhone extends StatelessWidget {
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
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return ChangeNotifierProvider(
      create: (_) => LocalPlaylistDataManager(
        context,
        lpid,
        title,
        cover,
        blurhash,
        updateCover,
        updateTitle,
      ),
      child: Consumer<LocalPlaylistDataManager>(
        builder: (context, localPlaylistDataManager, child) {
          return AnimatedSwitcher(
            key: ValueKey(localPlaylistDataManager),
            duration: const Duration(milliseconds: 400),
            child: localPlaylistDataManager.showBody
                ? Container(
                    key: const ValueKey(true),
                    width: size.width,
                    height: size.height,
                    decoration: AppConstants().backgroundBoxDecoration,
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
                                  controller:
                                      localPlaylistDataManager.scrollController,
                                  slivers: [
                                    LocalPlaylistAppBarPhone(
                                      title: localPlaylistDataManager.title,
                                      cover: localPlaylistDataManager.cover,
                                      edit: localPlaylistDataManager.edit,
                                      scrollControllerOffset:
                                          localPlaylistDataManager
                                              .scrollControllerOffset,
                                      changeCover:
                                          localPlaylistDataManager.changeCover,
                                      changeTitle:
                                          localPlaylistDataManager.changeTitle,
                                    ),
                                    SliverPersistentHeader(
                                      pinned: true,
                                      delegate: StickyHeaderDelegate(
                                        minHeight: 40,
                                        maxHeight: 40,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              left: 15, right: 15, top: 5),
                                          child: Container(
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(60),
                                                color: useBlur.value
                                                    ? Col.transp
                                                    : Col.realBackground
                                                        .withAlpha(
                                                            AppConstants()
                                                                .noBlur)),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(60),
                                              child: BackdropFilter(
                                                filter: ImageFilter.blur(
                                                    sigmaX:
                                                        useBlur.value ? 10 : 0,
                                                    sigmaY:
                                                        useBlur.value ? 10 : 0),
                                                child:
                                                    PlayShuffleHaltLocalPlaylist(
                                                  lpid: lpid,
                                                  allSelected:
                                                      localPlaylistDataManager
                                                              .selectedStids
                                                              .length ==
                                                          localPlaylistDataManager
                                                              .tracks.length,
                                                  missingTracks:
                                                      localPlaylistDataManager
                                                          .missingTracks,
                                                  loadingShuffle:
                                                      localPlaylistDataManager
                                                          .loadingShuffle,
                                                  edit: localPlaylistDataManager
                                                      .edit,
                                                  frontWidget: const SizedBox(),
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
                                                  remove:
                                                      localPlaylistDataManager
                                                          .remove,
                                                  addToPlaylist:
                                                      localPlaylistDataManager
                                                          .addToPlaylist,
                                                  show: localPlaylistDataManager
                                                      .showSelected,
                                                  hide: localPlaylistDataManager
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
                                        duration:
                                            const Duration(milliseconds: 300),
                                        child: localPlaylistDataManager
                                                    .tracks.isNotEmpty ||
                                                localPlaylistDataManager
                                                        .listLength <
                                                    1
                                            ? SizedBox(
                                                key: const ValueKey(true),
                                                child: localPlaylistDataManager
                                                        .stids.isEmpty
                                                    ? Column(
                                                        children: [
                                                          razh(50),
                                                          iconButton(
                                                              AppIcons
                                                                  .blankTrack,
                                                              Colors.white, () {
                                                            navigationBarIndex
                                                                .value = 0;
                                                            searchFocusNode
                                                                .value
                                                                .requestFocus();
                                                          }, size: 60),
                                                          textButton(
                                                              AppLocalizations.of(
                                                                      context)!
                                                                  .addtrackstoyoutplaylist,
                                                              () {
                                                            navigationBarIndex
                                                                .value = 0;
                                                            searchFocusNode
                                                                .value
                                                                .requestFocus();
                                                          },
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                              edgeInsets:
                                                                  EdgeInsets
                                                                      .zero)
                                                        ],
                                                      )
                                                    : LocalPlaylistBodyPhone(
                                                        lpid: lpid,
                                                        tracks:
                                                            localPlaylistDataManager
                                                                .tracks,
                                                        missingTracks:
                                                            localPlaylistDataManager
                                                                .missingTracks,
                                                        loading:
                                                            localPlaylistDataManager
                                                                .loading,
                                                        numberOfSTIDS:
                                                            localPlaylistDataManager
                                                                .stids.length,
                                                        hidden:
                                                            localPlaylistDataManager
                                                                .hidden,
                                                        edit:
                                                            localPlaylistDataManager
                                                                .edit,
                                                        play: (index) {
                                                          localPlaylistDataManager
                                                              .play(
                                                                  index: index);
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
                                                    itemBuilder:
                                                        (context, index) {
                                                      return songTileSchimmer(
                                                        context,
                                                        index == 0,
                                                        index ==
                                                            localPlaylistDataManager
                                                                .listLength--,
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
                        )
                      ],
                    ))
                : const Text("ddddd"),
          );
        },
      ),
    );
  }
}
