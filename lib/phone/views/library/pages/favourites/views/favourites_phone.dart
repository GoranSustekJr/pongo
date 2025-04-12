import 'dart:ui';
import 'package:pongo/exports.dart';

import '../data/favourites_data_manager.dart';

class FavouritesPhone extends StatefulWidget {
  const FavouritesPhone({super.key});

  @override
  State<FavouritesPhone> createState() => _FavouritesPhoneState();
}

class _FavouritesPhoneState extends State<FavouritesPhone> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return ChangeNotifierProvider(
      create: (_) => FavouritesDataManager(
        context,
      ),
      child: Consumer<FavouritesDataManager>(
          builder: (context, favouritesItemManager, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: favouritesItemManager.showBody
              ? Container(
                  key: const ValueKey(true),
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  decoration: AppConstants().backgroundBoxDecoration,
                  child: Scaffold(
                    extendBodyBehindAppBar: true,
                    extendBody: true,
                    body: Scrollbar(
                      controller: favouritesItemManager.scrollController,
                      child: CustomScrollView(
                        controller: favouritesItemManager.scrollController,
                        slivers: [
                          SliverAppBar(
                            snap: true,
                            floating: true,
                            pinned: true,
                            stretch: true,
                            backgroundColor: useBlur.value
                                ? Col.transp
                                : Col.realBackground.withAlpha(((MediaQuery.of(
                                                            context)
                                                        .size
                                                        .height /
                                                    2 <=
                                                favouritesItemManager
                                                    .scrollControllerOffset
                                            ? 1
                                            : favouritesItemManager
                                                    .scrollControllerOffset /
                                                (MediaQuery.of(context)
                                                        .size
                                                        .height /
                                                    2)) *
                                        150)
                                    .toInt()),
                            automaticallyImplyLeading: false,
                            expandedHeight:
                                kIsApple ? size.height / 5 : size.height / 4,
                            title: Row(
                              children: [
                                backButton(context),
                                Expanded(
                                  child: Container(),
                                ),
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
                                    AppLocalizations.of(context).favouritesongs,
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
                                      borderRadius: BorderRadius.circular(60),
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
                                      child: PlayShuffleHaltFavourites(
                                        missingTracks:
                                            favouritesItemManager.missingTracks,
                                        loadingShuffle: favouritesItemManager
                                            .loadingShuffle,
                                        edit: favouritesItemManager.edit,
                                        frontWidget: iconButton(
                                          AppIcons.heart,
                                          Col.icon,
                                          () {
                                            navigationBarIndex.value = 0;
                                            searchFocusNode.value
                                                .requestFocus();
                                          },
                                          edgeInsets: EdgeInsets.zero,
                                        ),
                                        endWidget: iconButton(
                                          AppIcons.edit,
                                          Col.icon,
                                          () async {
                                            final audioServiceHandler =
                                                Provider.of<AudioHandler>(
                                                        context,
                                                        listen: false)
                                                    as AudioServiceHandler;
                                            if (audioServiceHandler
                                                    .mediaItem.value !=
                                                null) {
                                              if ("library.favourites" ==
                                                  '${audioServiceHandler.mediaItem.value!.id.split('.')[0]}.${audioServiceHandler.mediaItem.value!.id.split('.')[1]}') {
                                                CustomButton ok =
                                                    await haltAlert(context);
                                                if (ok ==
                                                    CustomButton
                                                        .positiveButton) {
                                                  currentTrackHeight.value = 0;
                                                  final audioServiceHandler =
                                                      Provider.of<AudioHandler>(
                                                              context,
                                                              listen: false)
                                                          as AudioServiceHandler;

                                                  await audioServiceHandler
                                                      .halt();
                                                  favouritesItemManager
                                                      .changeEdit(true);
                                                }
                                              } else {
                                                favouritesItemManager
                                                    .changeEdit(true);
                                              }
                                            } else {
                                              favouritesItemManager
                                                  .changeEdit(true);
                                            }
                                          },
                                          edgeInsets: EdgeInsets.zero,
                                        ),
                                        play: () {
                                          favouritesItemManager.play(index: 0);
                                        },
                                        shuffle:
                                            favouritesItemManager.playShuffle,
                                        stopEdit: () {
                                          favouritesItemManager
                                              .changeEdit(false);
                                          favouritesItemManager
                                              .clearSelectedTrack();
                                        },
                                        download:
                                            favouritesItemManager.download,
                                        unfavourite: () async {
                                          if (favouritesItemManager
                                              .selectedTracks.isNotEmpty) {
                                            CustomButton ok =
                                                await removeFavouriteAlert(
                                                    context);
                                            if (ok ==
                                                CustomButton.positiveButton) {
                                              await DatabaseHelper()
                                                  .removeFavouriteTracks(
                                                      favouritesItemManager
                                                          .selectedTracks);

                                              favouritesItemManager.favourites
                                                  .clear();
                                              favouritesItemManager
                                                  .selectedTracks
                                                  .clear();

                                              favouritesItemManager
                                                  .initFavourites();
                                            }
                                          }
                                        },
                                        addToPlaylist: () {
                                          if (favouritesItemManager
                                              .selectedTracks.isNotEmpty) {
                                            OpenPlaylist().show(
                                              context,
                                              PlaylistHandler(
                                                  type: PlaylistHandlerType
                                                      .online,
                                                  function:
                                                      PlaylistHandlerFunction
                                                          .addToPlaylist,
                                                  track: favouritesItemManager
                                                      .selectedTracks
                                                      .map((stid) {
                                                    final favourite =
                                                        favouritesItemManager
                                                            .favourites
                                                            .where(
                                                                (favourite) =>
                                                                    favourite
                                                                        .id ==
                                                                    stid)
                                                            .toList()[0];
                                                    return PlaylistHandlerOnlineTrack(
                                                      id: favourite.id,
                                                      name: favourite.name,
                                                      artist: favourite.artists
                                                          .map((artist) => {
                                                                "id": artist.id,
                                                                "name":
                                                                    artist.name
                                                              })
                                                          .toList(),
                                                      cover:
                                                          calculateWantedResolutionForTrack(
                                                              favourite.album !=
                                                                      null
                                                                  ? favourite
                                                                      .album!
                                                                      .images
                                                                  : favourite
                                                                      .album!
                                                                      .images,
                                                              150,
                                                              150),
                                                      albumTrack:
                                                          favourite.album,
                                                      playlistHandlerCoverType:
                                                          PlaylistHandlerCoverType
                                                              .url,
                                                    );
                                                  }).toList()),
                                            );
                                          }
                                        },
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
                              child: favouritesItemManager
                                          .favourites.isNotEmpty ||
                                      favouritesItemManager.lengthOfFavourites <
                                          1
                                  ? SizedBox(
                                      key: const ValueKey(true),
                                      child: favouritesItemManager
                                              .favouritesSTIDS.isEmpty
                                          ? Center(
                                              child: Column(
                                                children: [
                                                  razh(150),
                                                  iconButton(AppIcons.heartFill,
                                                      Col.icon, () {
                                                    navigationBarIndex.value =
                                                        0;
                                                    searchFocusNode.value
                                                        .requestFocus();
                                                  }, size: 60),
                                                  textButton(
                                                      AppLocalizations.of(
                                                              context)
                                                          .findyourfavouritesongsnow,
                                                      () {
                                                    navigationBarIndex.value =
                                                        0;
                                                    searchFocusNode.value
                                                        .requestFocus();
                                                  }, TextStyle(color: Col.text),
                                                      edgeInsets:
                                                          EdgeInsets.zero)
                                                ],
                                              ),
                                            )
                                          : FavouritesBodyPhone(
                                              favourites: favouritesItemManager
                                                  .favourites,
                                              numberOfSTIDS:
                                                  favouritesItemManager
                                                      .favouritesSTIDS.length,
                                              missingTracks:
                                                  favouritesItemManager
                                                      .missingTracks,
                                              loading:
                                                  favouritesItemManager.loading,
                                              edit: favouritesItemManager.edit,
                                              play: (index) {
                                                favouritesItemManager.play(
                                                    index: index);
                                              },
                                              selectedTracks:
                                                  favouritesItemManager
                                                      .selectedTracks,
                                              select:
                                                  favouritesItemManager.select,
                                            ),
                                    )
                                  : SingleChildScrollView(
                                      key: const ValueKey(false),
                                      child: Column(
                                        children: [
                                          ListView.builder(
                                            itemCount: favouritesItemManager
                                                .lengthOfFavourites,
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemBuilder: (context, index) {
                                              return songTileSchimmer(
                                                  context,
                                                  index == 0,
                                                  index ==
                                                      favouritesItemManager
                                                          .lengthOfFavourites--);
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
      }),
    );
  }
}
