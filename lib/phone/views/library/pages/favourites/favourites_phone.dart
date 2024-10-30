import 'dart:ui';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/alerts/audio%20player/halt_alert.dart';
import 'package:pongo/phone/alerts/favourites/favourites.dart';
import 'package:pongo/phone/components/library/favourites/play_shuffle_halt_favourites.dart';
import 'package:pongo/phone/components/shared/shimmer/song_shimmer.dart';
import 'package:pongo/phone/views/library/pages/favourites/favourites_body_phone.dart';
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

  // length
  int lengthOfFavourites = 0;

  // Favourites
  List<sp.Track> favourites = [];
  List<Map> favouritesSTIDS = [];

  // Num of songs per page
  int numb = 150;

  // Edit
  bool edit = false;
  List<String> selectedTracks = [];

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
  }

  scrollControllerListener() {
    setState(() {
      if (scrollController.offset < 0) {
        scrollControllerOffset = 0;
      } else {
        scrollControllerOffset = scrollController.offset;
      }
      if (scrollController.position.maxScrollExtent ==
              scrollController.offset &&
          favouritesSTIDS.length > favourites.length) {
        fetchTracks((favourites.length / numb).floor() + 1);
      }
    });
  }

  void fetchTracks(int index) async {
    print("fetching index; $index");
    final start = numb * (index - 1);
    final end = (start + numb) <= favouritesSTIDS.length
        ? (start + numb)
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
    final List<sp.Track> newTracks =
        page.map((item) => sp.Track.fromJson(item)).toList();

    // Add tracks to favourites list and update
    setState(() {
      favourites.addAll(newTracks);
      existingTracks.addAll({
        for (var item in trackThatExist["durations"])
          item[0] as String: item[1] as double
      });
      missingTracks.addAll((trackThatExist["missing_tracks"] as List)
          .map((item) => item.toString()));
    });

    newMediaItems(newTracks);
  }

  void newMediaItems(List<sp.Track> newTracks) async {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;

    if (audioServiceHandler.mediaItem.value != null) {
      print("objectsssss");
      print(audioServiceHandler.mediaItem.value!.id.split('.')[0] +
          audioServiceHandler.mediaItem.value!.id.split('.')[1]);
      print("library.favourites");
      if ('${audioServiceHandler.mediaItem.value!.id.split('.')[0]}.${audioServiceHandler.mediaItem.value!.id.split('.')[1]}' ==
          "library.favourites") {
        bool reEnableShuffleMode =
            audioServiceHandler.audioPlayer.shuffleModeEnabled;
        audioServiceHandler.setShuffleMode(AudioServiceShuffleMode.none);
        if (missingTracks.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            //  op:${widget.opid}.$stid
            TrackPlay().playConcenatingTrack(
              context,
              "",
              newTracks,
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
                await audioServiceHandler.playlist
                    .add(audioServiceHandler.createAudioSource(mediaItem));
                audioServiceHandler.queue.value.add(mediaItem);
              },
            );
          });
        } else {
          final data = await Tracks().getDurations(
              context, newTracks.map((track) => track.id).toList());

          if (data["durations"] != null) {
            setState(() {
              existingTracks.addAll({
                for (var item in data["durations"])
                  item[0] as String: item[1] as double
              });
            });
          }
          final List<MediaItem> mediaItems = [];

          for (int i = 0; i < newTracks.length; i++) {
            print("object; $i");
            final MediaItem mediaItem = MediaItem(
              id: "library.newTracks.${newTracks[i].id}",
              title: newTracks[i].name,
              artist:
                  newTracks[i].artists.map((artist) => artist.name).join(', '),
              album: newTracks[i].album != null
                  ? "${newTracks[i].album!.id}..Ææ..${newTracks[i].album!.name}"
                  : "..Ææ..",
              duration: Duration(
                  milliseconds:
                      (existingTracks[newTracks[i].id]! * 1000).toInt()),
              artUri: Uri.parse(
                newTracks[i].album != null
                    ? calculateBestImageForTrack(newTracks[i].album!.images)
                    : '',
              ),
              extras: {
                //"blurhash": blurHash,
                "released": newTracks[i].album != null
                    ? newTracks[i].album!.releaseDate
                    : "",
              },
            );
            mediaItems.add(mediaItem);
          }

          audioServiceHandler.queue.value.addAll(mediaItems);
          audioServiceHandler.playlist.addAll(
              mediaItems.map(audioServiceHandler.createAudioSource).toList());
        }
        if (reEnableShuffleMode) {
          audioServiceHandler.setShuffleMode(AudioServiceShuffleMode.all);
        }
      }
    }
  }

  void initFavourites() async {
    final int length = await DatabaseHelper().queryFavouritesLength();

    setState(() {
      lengthOfFavourites = length;
      showBody = true;
    });

    final stids = await DatabaseHelper().queryAllFavouriteTracks();
    setState(() {
      favouritesSTIDS = stids;
    });
    fetchTracks(1);
  }

  play({int? index}) async {
    if (!edit) {
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
  }

  playShuffle() async {
    if (!loadingShuffle && missingTracks.isEmpty && !edit) {
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
                            child: Padding(
                              padding: EdgeInsets.only(top: size.height / 9),
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
                                  edit: edit,
                                  frontWidget: iconButton(
                                    AppIcons.heart,
                                    Colors.white,
                                    () {
                                      navigationBarIndex.value = 0;
                                      searchFocusNode.value.requestFocus();
                                    },
                                    edgeInsets: EdgeInsets.zero,
                                  ),
                                  endWidget: iconButton(
                                    AppIcons.edit,
                                    Colors.white,
                                    () async {
                                      final audioServiceHandler =
                                          Provider.of<AudioHandler>(context,
                                                  listen: false)
                                              as AudioServiceHandler;
                                      if (audioServiceHandler.mediaItem.value !=
                                          null) {
                                        if ("library.favourites" ==
                                            '${audioServiceHandler.mediaItem.value!.id.split('.')[0]}.${audioServiceHandler.mediaItem.value!.id.split('.')[1]}') {
                                          CustomButton ok =
                                              await haltAlert(context);
                                          if (ok ==
                                              CustomButton.positiveButton) {
                                            currentTrackHeight.value = 0;
                                            final audioServiceHandler =
                                                Provider.of<AudioHandler>(
                                                        context,
                                                        listen: false)
                                                    as AudioServiceHandler;

                                            await audioServiceHandler.halt();
                                            setState(() {
                                              edit = true;
                                            });
                                          }
                                        } else {
                                          setState(() {
                                            edit = true;
                                          });
                                        }
                                      } else {
                                        setState(() {
                                          edit = true;
                                        });
                                      }
                                    },
                                    edgeInsets: EdgeInsets.zero,
                                  ),
                                  play: () {
                                    play(index: 0);
                                  },
                                  shuffle: playShuffle,
                                  stopEdit: () {
                                    setState(() {
                                      edit = false;
                                      selectedTracks.clear();
                                    });
                                  },
                                  unfavourite: () async {
                                    if (selectedTracks.isNotEmpty) {
                                      CustomButton ok =
                                          await removeFavouriteAlert(context);
                                      if (ok == CustomButton.positiveButton) {
                                        await DatabaseHelper()
                                            .removeFavouriteTracks(
                                                selectedTracks);

                                        setState(() {
                                          favourites.clear();
                                          selectedTracks.clear();
                                        });

                                        initFavourites();
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                          child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: favourites.isNotEmpty
                                  ? SizedBox(
                                      key: const ValueKey(true),
                                      child: favouritesSTIDS.isEmpty
                                          ? Column(
                                              children: [
                                                razh(size.height / 3),
                                                const Text("Empty"),
                                              ],
                                            )
                                          : FavouritesBodyPhone(
                                              favourites: favourites,
                                              numberOfSTIDS:
                                                  favouritesSTIDS.length,
                                              missingTracks: missingTracks,
                                              loading: loading,
                                              edit: edit,
                                              play: (index) {
                                                play(index: index);
                                              },
                                              selectedTracks: selectedTracks,
                                              select: (stid) {
                                                setState(() {
                                                  if (selectedTracks
                                                      .contains(stid)) {
                                                    selectedTracks.remove(stid);
                                                  } else {
                                                    selectedTracks.add(stid);
                                                  }
                                                });
                                              },
                                            ),
                                    )
                                  : SingleChildScrollView(
                                      key: const ValueKey(false),
                                      child: Column(
                                        children: [
                                          ListView.builder(
                                            itemCount: lengthOfFavourites,
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemBuilder: (context, index) {
                                              return songTileSchimmer(
                                                  context,
                                                  index == 0,
                                                  index ==
                                                      lengthOfFavourites--);
                                            },
                                          ),
                                        ],
                                      ),
                                    ))),
                    ],
                  ),
                ),
              ),
            )
          : loadingScaffold(context, const ValueKey(false)),
    );
  }
}
