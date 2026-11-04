import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

class LocalsPhone extends StatelessWidget {
  const LocalsPhone({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;

    return ChangeNotifierProvider(
      create: (_) => LocalsDataManager(
        context,
      ),
      child: Consumer<LocalsDataManager>(
        builder: (context, localsDataManager, child) {
          return AnimatedSwitcher(
            key: ValueKey(localsDataManager.showBody),
            duration: const Duration(milliseconds: 400),
            child: localsDataManager.showBody
                ? Container(
                    key: const ValueKey(true),
                    width: size.width,
                    height: size.height,
                    decoration: AppConstants().backgroundBoxDecoration,
                    child: Scaffold(
                      resizeToAvoidBottomInset: false,
                      extendBodyBehindAppBar: true,
                      extendBody: true,
                      body: Scrollbar(
                          controller: localsDataManager.scrollController,
                          child: CustomScrollView(
                            controller: localsDataManager.scrollController,
                            slivers: [
                              SliverAppBar(
                                //snap: true,
                                //floating: true,
                                pinned: true,
                                stretch: true,
                                backgroundColor: useBlur.value
                                    ? Col.transp
                                    : Col.realBackground
                                        .withAlpha(AppConstants().noBlur),
                                automaticallyImplyLeading: false,
                                expandedHeight: kIsApple
                                    ? size.height / 5
                                    : size.height / 4,
                                title: Row(
                                  children: [
                                    backButton(context),
                                    Expanded(
                                      child: Container(),
                                    ),
                                    StreamBuilder(
                                        stream: audioServiceHandler
                                            .mediaItem.stream,
                                        builder: (context, mediaItemStream) {
                                          bool showPlay = mediaItemStream
                                                      .data ==
                                                  null
                                              ? true
                                              : "library.locals" !=
                                                  '${mediaItemStream.data!.id.split('.')[0]}.${mediaItemStream.data!.id.split('.')[1]}';
                                          return AnimatedSwitcher(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              child: showPlay
                                                  ? SizedBox(
                                                      key: const ValueKey(true),
                                                      child: backLikeButton(
                                                        context,
                                                        CupertinoIcons
                                                            .line_horizontal_3_decrease,
                                                        localsDataManager.sort,
                                                      ),
                                                    )
                                                  : const SizedBox());
                                        }),
                                  ],
                                ),
                                flexibleSpace: ClipRRect(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: useBlur.value ? 10 : 0,
                                        sigmaY: useBlur.value ? 10 : 0),
                                    child: FlexibleSpaceBar(
                                      centerTitle: true,
                                      title: Text(
                                        AppLocalizations.of(context)
                                            .offlinesongs,
                                        style: TextStyle(
                                            fontSize: kIsApple ? 25 : 30,
                                            fontWeight: kIsApple
                                                ? FontWeight.w700
                                                : FontWeight.w800,
                                            color: Col.text),
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
                                        left: 15, right: 15, top: 5),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(60),
                                          color: useBlur.value
                                              ? Col.transp
                                              : Col.realBackground.withAlpha(
                                                  AppConstants().noBlur)),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(60),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                              sigmaX: useBlur.value ? 10 : 0,
                                              sigmaY: useBlur.value ? 10 : 0),
                                          child: PlayShuffleHaltLocals(
                                            missingTracks: const [],
                                            loadingShuffle: false,
                                            edit: localsDataManager.edit,
                                            allSelected: localsDataManager
                                                    .selectedTracks.length ==
                                                localsDataManager.tracks.length,
                                            frontWidget: iconButton(
                                              AppIcons.blankTrack,
                                              Col.icon,
                                              localsDataManager.newTracks,
                                              edgeInsets: EdgeInsets.zero,
                                            ),
                                            endWidget: iconButton(
                                              AppIcons.edit,
                                              Col.icon,
                                              localsDataManager.startEdit,
                                              edgeInsets: EdgeInsets.zero,
                                            ),
                                            play: localsDataManager.play,
                                            shuffle: localsDataManager.shuffle,
                                            stopEdit:
                                                localsDataManager.stopEdit,
                                            remove: localsDataManager.remove,
                                            addToPlaylist:
                                                localsDataManager.addToPlaylist,
                                            selectAll:
                                                localsDataManager.selectAll,
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
                                      horizontal: 15, vertical: 10),
                                  child: CupertinoSearchTextField(
                                    controller:
                                        localsDataManager.searchController,
                                    focusNode: localsDataManager.focusNode,
                                    onChanged: localsDataManager.onSearched,
                                    onSuffixTap: localsDataManager.clearSearch,
                                    placeholder:
                                        AppLocalizations.of(context).search,
                                    backgroundColor:
                                        Col.primaryCard.withAlpha(150),
                                    style: TextStyle(color: Col.text),
                                    itemColor: Col.icon,
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: localsDataManager
                                              .tracksBackup.isNotEmpty ||
                                          localsDataManager.numOfTracks < 1
                                      ? SizedBox(
                                          key: const ValueKey(true),
                                          child: localsDataManager
                                                  .tracks.isEmpty
                                              ? Column(
                                                  children: [
                                                    razh(100),
                                                    iconButton(
                                                        AppIcons.musicAlbums,
                                                        Col.icon,
                                                        localsDataManager
                                                            .newTracks,
                                                        size: 60),
                                                    textButton(
                                                        AppLocalizations.of(
                                                                context)
                                                            .downloadtracksnow,
                                                        localsDataManager
                                                            .newTracks,
                                                        TextStyle(
                                                            color: Col.text))
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
                                                itemCount: localsDataManager
                                                    .numOfTracks,
                                                padding: EdgeInsets.only(
                                                  top: 35,
                                                  bottom: MediaQuery.of(context)
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
                                                              .numOfTracks--);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          )),
                    ),
                  )
                : loadingScaffold(context, const ValueKey(false)),
          );
        },
      ),
    );
  }
}
