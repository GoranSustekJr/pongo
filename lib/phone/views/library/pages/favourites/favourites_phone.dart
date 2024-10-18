import 'dart:ui';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/library/favourites/play_shuffle_halt_favourites.dart';
import 'package:pongo/phone/views/library/pages/favourites/favourites_body_phone.dart';
import 'package:pongo/phone/widgets/library/favourites/favourites_tile.dart';
import 'package:pongo/shared/utils/API%20requests/playlist_tracks.dart';
import 'package:pongo/shared/utils/API%20requests/searialized_data.dart';
import 'package:pongo/shared/utils/API%20requests/tracks.dart';
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
  List<String> missingTracks = [];
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
    initFavourites();
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

  void fetchTracks(int index) async {
    final start = 50 * (index - 1);
    final end = (start + 50) <= favouritesSTIDS.length
        ? (start + 50)
        : favouritesSTIDS.length;

    // Ensure the indices are within valid bounds
    if (start < 0 || start >= favouritesSTIDS.length) return;

    List<String> tempStids = favouritesSTIDS
        .map((entry) => entry["stid"].toString())
        .toList()
        .sublist(start, end);

    final trackData = await SearializedData().tracks(
      context,
      tempStids,
    );

    final List<dynamic> page = trackData["tracks"];

    final trackThatExist = await Tracks().getDurations(
      context,
      favouritesSTIDS
          .map((entry) => entry["stid"].toString())
          .toList()
          .sublist(start, end),
    );

    print(trackThatExist["durations"]);

    // Add tracks to favourites list and update the PagingController
    setState(() {
      favourites.addAll(page.map((item) => sp.Track.fromJson(item)));
      existingTracks.addAll({
        for (var item in trackThatExist["durations"])
          item[0] as String: item[1] as double
      });
      missingTracks.addAll((trackThatExist["missing_tracks"] as List)
          .map((item) => item.toString()));
    });

    print("missing tracks; $missingTracks");

    final isLastPage = page.length < 50;
    if (isLastPage) {
      pagingController
          .appendLastPage(page.map((item) => sp.Track.fromJson(item)).toList());
    } else {
      pagingController.appendPage(
          page.map((item) => sp.Track.fromJson(item)).toList(), index + 1);
    }
  }

  void initFavourites() async {
    final stids = await DatabaseHelper().queryAllFavouriteTracks();

    setState(() {
      favouritesSTIDS = stids;
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
      currentAlbumPlaylistId.value = "library.favourites.";

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
          TrackPlay().playConcenatingTrack(
            context,
            "",
            favourites,
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
        final data = await Tracks().getDurations(context, missingTracks);

        if (data["durations"] != null) {
          setState(() {
            existingTracks.addAll({
              for (var item in data["durations"])
                item[0] as String: item[1] as double
            });
          });
        }

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
      final data = await Tracks().getDurations(context, missingTracks);
      if (data["durations"] != null) {
        setState(() {
          existingTracks.addAll({
            for (var item in data["durations"])
              item[0] as String: item[1] as double
          });
        });
      }

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
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
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
                                child: PlayShuffleHaltFavourites(
                                  missingTracks: missingTracks,
                                  loadingShuffle: loadingShuffle,
                                  play: () {
                                    play(index: 0);
                                  },
                                  shuffle: playShuffle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: favouritesSTIDS.isEmpty
                            ? Column(
                                children: [
                                  razh(size.height / 3),
                                  const Text("Empty"),
                                ],
                              )
                            : FavouritesBodyPhone(
                                pagingController: pagingController,
                                favourites: favourites,
                                missingTracks: missingTracks,
                                loading: loading,
                                play: (index) {
                                  play(index: index);
                                },
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
