import 'dart:ui';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/library/favourites/play_shuffle_halt_favourites.dart';
import 'package:pongo/phone/widgets/library/favourites/favourites_tile.dart';
import 'package:pongo/shared/utils/API%20requests/playlist_tracks.dart';
import 'package:pongo/shared/utils/API%20requests/searialized_data.dart';
import 'package:spotify_api/spotify_api.dart' as sp;

class FavouritesPhone extends StatefulWidget {
  const FavouritesPhone({super.key});

  @override
  State<FavouritesPhone> createState() => _FavouritesPhoneState();
}

class _FavouritesPhoneState extends State<FavouritesPhone> {
  // Show body
  bool showBody = false;

  // Favourites
  List<sp.Track> favourites = [];
  List<Map> favouritesSTIDS = [];

  // Pagination
  final PagingController<int, sp.Track> pagingController =
      PagingController(firstPageKey: 1);

  // Scroll controller
  late ScrollController scrollController;

  // Offset
  double scrollControllerOffset = 0;

  // Tracks
  List missingTracks = [];
  Map<String, double> existingTracks = {};

  // Loading shuffle
  bool loadingShuffle = false;

  // Cancel the getting songs
  bool cancel = false;

  // Current loading songs
  List<String> loading = [];

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(scrollControllerListener);
    initInfo();
    pagingController.addPageRequestListener(fetchTracks);
  }

  scrollControllerListener() {
    setState(() {
      if (scrollController.offset < 0) {
        scrollControllerOffset = 0;
      } else {
        scrollControllerOffset = scrollController.offset;
      }
    });
  }

  void fetchTracks(int index) async {}

  void initInfo() async {
    final stids = await DatabaseHelper().queryAllFavouriteTracks();

    final trackData = await SearializedData().tracks(context,
        stids.map((entry) => entry["stid"].toString()).take(50).toList());
    final List<dynamic> firstPage = trackData["tracks"];

    print(stids);
    setState(() {
      favouritesSTIDS = stids;
      favourites = firstPage.map((item) => sp.Track.fromJson(item)).toList();
      showBody = true;
    });
  }

  play({int? index}) async {
    if (!loadingShuffle) {
      final audioServiceHandler =
          Provider.of<AudioHandler>(context, listen: false)
              as AudioServiceHandler;
      // Set shuffle mode
      await audioServiceHandler.setShuffleMode(AudioServiceShuffleMode.none);

      // Set global id of the playlist
      currentAlbumPlaylistId.value = "favourites";

      if (missingTracks.isNotEmpty) {
        queueAllowShuffle.value = false;

        print("OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO");
        setState(() {
          cancel = true;
        });
        await audioServiceHandler.halt();
        setState(() {
          cancel = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          //  op:${widget.opid}.$stid
          TrackPlay().playConcenating(
            context,
            "",
            favourites as List<Track>,
            existingTracks,
            "library.favourites.",
            cancel,
            (stid) {
              if (mounted) {
                setState(() {
                  if (!loading.contains(stid)) {
                    loading.add(stid);
                  }
                });
              }
            },
            (stid) {
              if (mounted) {
                setState(() {
                  loading.remove(stid);
                  missingTracks.remove(stid);
                });
              }
            },
            (mediaItem, i) async {
              if (i == 0) {
                await audioServiceHandler.initSongs(songs: [mediaItem]);
                audioServiceHandler.play();
              } else {
                await audioServiceHandler.playlist
                    .add(audioServiceHandler.createAudioSource(mediaItem));
                audioServiceHandler.queue.value.add(mediaItem);
              }
              if (i == favourites.length - 1) {
                queueAllowShuffle.value = true;
              }
            },
          );
        });
      } else {
        final data = await SearializedData().getShuffle(
            context,
            favouritesSTIDS
                .map((entry) => entry["stid"].toString())
                .take(50)
                .toList());
        setState(() {
          existingTracks = {
            for (var item in data["durations"])
              item[0] as String: item[1] as double
          };
        });

        final List<MediaItem> mediaItems = [];

        final audioServiceHandler =
            Provider.of<AudioHandler>(context, listen: false)
                as AudioServiceHandler;

        for (int i = 0; i < favourites.length; i++) {
          print("object; $i");
          final MediaItem mediaItem = MediaItem(
            id: "library.favourites.${favourites[i].id}",
            title: favourites[i].name,
            artist:
                favourites[i].artists.map((artist) => artist.name).join(', '),
            album: favourites[i].album != null
                ? "${favourites[i].album!.id}..Ææ..${favourites[i].album!.name}"
                : "..Ææ..",
            duration: Duration(
                milliseconds:
                    (existingTracks[favourites[i].id]! * 1000).toInt()),
            artUri: Uri.parse(
              favourites[i].album != null
                  ? calculateBestImageForTrack(favourites[i].album!.images)
                  : '',
            ),
            extras: {
              //"blurhash": blurHash,
              "released": favourites[i].album != null
                  ? favourites[i].album!.releaseDate
                  : "",
            },
          );
          mediaItems.add(mediaItem);
        }

        await audioServiceHandler.initSongs(songs: mediaItems);
        print("INDEX; $index");
        await audioServiceHandler.skipToQueueItem(index!);
        audioServiceHandler.play();
      }
    }
  }

  playShuffle() async {
    if (!loadingShuffle && missingTracks.isEmpty) {
      queueAllowShuffle.value = true;

      setState(() {
        loadingShuffle = true;
      });

      // Set global id of the playlist
      final data = await SearializedData().getShuffle(
          context,
          favouritesSTIDS
              .map((entry) => entry["stid"].toString())
              .take(50)
              .toList());

      setState(() {
        existingTracks = {
          for (var item in data["durations"])
            item[0] as String: item[1] as double
        };
      });

      final List<MediaItem> mediaItems = [];

      final audioServiceHandler =
          Provider.of<AudioHandler>(context, listen: false)
              as AudioServiceHandler;
      await audioServiceHandler.setShuffleMode(AudioServiceShuffleMode.all);

      for (int i = 0; i < favourites.length; i++) {
        final MediaItem mediaItem = MediaItem(
          id: "library.favourites.${favourites[i].id}",
          title: favourites[i].name,
          artist: favourites[i].artists.map((artist) => artist.name).join(', '),
          album: favourites[i].album != null
              ? "${favourites[i].album!.id}..Ææ..${favourites[i].album!.name}"
              : "..Ææ..",
          duration: Duration(
              milliseconds: (existingTracks[favourites[i].id]! * 1000).toInt()),
          artUri: Uri.parse(
            favourites[i].album != null
                ? calculateBestImageForTrack(favourites[i].album!.images)
                : '',
          ),
          extras: {
            "released": favourites[i].album != null
                ? favourites[i].album!.releaseDate
                : "",
          },
        );
        mediaItems.add(mediaItem);
      }

      await audioServiceHandler.initSongs(songs: mediaItems);
      await audioServiceHandler
          .skipToQueueItem(audioServiceHandler.audioPlayer.shuffleIndices![0]);
      audioServiceHandler.play();
      setState(() {
        loadingShuffle = false;
      });
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(scrollControllerListener);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: showBody
          ? Container(
              key: const ValueKey(true),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: AppConstants().backgroundBoxDecoration,
              child: Scaffold(
                extendBodyBehindAppBar: true,
                extendBody: true,
                body: Scrollbar(
                  controller: scrollController,
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverAppBar(
                        snap: false,
                        collapsedHeight: kToolbarHeight,
                        expandedHeight: size.height / 3,
                        floating: false,
                        pinned: true,
                        stretch: true,
                        title: Row(
                          children: [
                            backButton(context),
                            Expanded(
                              child: Container(),
                            ),
                          ],
                        ),
                        automaticallyImplyLeading: false,
                        flexibleSpace: FlexibleSpaceBar(
                          titlePadding: EdgeInsets.zero,
                          centerTitle: true,
                          title: AppBar(
                            automaticallyImplyLeading: false,
                            title: Row(
                              children: [
                                backButton(context),
                                Expanded(
                                    child: Text(
                                  AppLocalizations.of(context)!.favouritesongs,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )),
                              ],
                            ),
                            flexibleSpace: Opacity(
                              opacity: size.height / 3 <= scrollControllerOffset
                                  ? 1
                                  : scrollControllerOffset / (size.height / 3),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: Container(),
                              ),
                            ),
                          ),
                          background: Center(
                            child: Text(
                              AppLocalizations.of(context)!.favouritesongs,
                              style: TextStyle(
                                fontSize: kIsApple ? 30 : 40,
                                fontWeight: kIsApple
                                    ? FontWeight.w700
                                    : FontWeight.w800,
                              ),
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
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: const Text("Play halt shuffle")),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: favourites.isEmpty
                            ? Column(
                                children: [
                                  razh(size.height / 3),
                                  const Text("Empty"),
                                ],
                              )
                            : Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: ListView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: favourites.length,
                                    shrinkWrap: true,
                                    itemBuilder: (context, index) {
                                      return FavouritesTile(
                                        track: favourites[index],
                                        first: index == 0,
                                        last: favourites.length - 1 == index,
                                        exists: !missingTracks
                                            .contains(favourites[index].id),
                                        trailing: const SizedBox(),
                                        function: () {},
                                      );
                                    }),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : loadingScaffold(context, const ValueKey(false)),
    );
  }
}
