import 'dart:ui';
import 'package:pongo/exports.dart';
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
                        snap: true,
                        floating: true,
                        pinned: true,
                        stretch: true,
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
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: FlexibleSpaceBar(
                              centerTitle: true,
                              title: Text(
                                AppLocalizations.of(context)!.favouritesongs,
                                style: TextStyle(
                                  fontSize: kIsApple ? 25 : 30,
                                  fontWeight: kIsApple
                                      ? FontWeight.w700
                                      : FontWeight.w800,
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
                                  addToPlaylist: () {
                                    OpenPlaylist().show(
                                      context,
                                      PlaylistHandler(
                                          type: PlaylistHandlerType.online,
                                          function: PlaylistHandlerFunction
                                              .addToPlaylist,
                                          track: selectedTracks.map((stid) {
                                            final favourite = favourites
                                                .where((favourite) =>
                                                    favourite.id == stid)
                                                .toList()[0];
                                            return PlaylistHandlerOnlineTrack(
                                              id: favourite.id,
                                              name: favourite.name,
                                              artist: favourite.artists
                                                  .map((artist) => artist.name)
                                                  .toList()
                                                  .join(', '),
                                              cover:
                                                  calculateWantedResolutionForTrack(
                                                      favourite.album != null
                                                          ? favourite
                                                              .album!.images
                                                          : favourite
                                                              .album!.images,
                                                      150,
                                                      150),
                                              playlistHandlerCoverType:
                                                  PlaylistHandlerCoverType.url,
                                            );
                                          }).toList()),
                                    );
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
                                          numberOfSTIDS: favouritesSTIDS.length,
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
                                              index == lengthOfFavourites--);
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
  }
}







/* 

import 'package:blurhash_ffi/blurhash.dart';
import 'package:pongo/exports.dart';
import 'package:http/http.dart' as http;

class PlayingDetailsPhone extends StatefulWidget {
  final Function(String) showAlbum;
  const PlayingDetailsPhone({
    super.key,
    required this.showAlbum,
  });

  @override
  State<PlayingDetailsPhone> createState() => _PlayingDetailsPhoneState();
}

class _PlayingDetailsPhoneState extends State<PlayingDetailsPhone> {
  // Current media item
  MediaItem? currentMediaItem;

  // Current item id
  String? currentMediaItemId;

  // Sync lyrics manually
  int syncTimeDelay = 0;

  // Show lyrics
  bool lyricsOn = false;

  // Use Synced
  bool useSynced = false;

  // Show current song details | show queue
  bool showQueue = false;

  // Queue state key
  final GlobalKey<State<QueuePhone>> queueKey = GlobalKey<State<QueuePhone>>();

  // Blurhash
  String blurhash = AppConstants().BLURHASH;

  // Lyrics
  String syncedLyrics = "";
  String plainLyrics = "";

  // Volume controller
  InteractiveSliderController volumeController =
      InteractiveSliderController(VolumeManager().currentVolume);

  // Volume icon
  int iconKey = 0;

  // Experimental visualizer
  List freqs = [50, 120, 210, 320, 400, 480];
  List<dynamic> frequencies = [];

  @override
  void initState() {
    super.initState();
    useSynced = useSyncedLyrics.value;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;

    // Function to update the current media item safely
    void newMediaItem(String? stid, MediaItem? mediaItem) async {
      if (currentMediaItemId != stid) {
        final String blurHash = mediaItem!.artUri != null
            ? await BlurhashFFI.encode(
                NetworkImage(
                  mediaItem.artUri.toString(),
                ),
                componentX: 3,
                componentY: 3,
              )
            : AppConstants().BLURHASH;

        currentBlurhash.value = blurHash;
        if (enableLyrics.value) {
          final lyrics = await TrackMetadata().getLyrics(
            context,
            mediaItem.title,
            mediaItem.artist!.split(', ')[0],
            mediaItem.duration!.inSeconds.toDouble(),
            mediaItem.album!,
          );
          int? syncLyrDelay = await DatabaseHelper().querySyncTimeDelay(stid!);
          int syncDelay = 0;
          if (syncLyrDelay != null) {
            syncDelay = (syncLyrDelay / 1000).toInt();
          } else if (lyrics["duration"] != null && useSyncTimeDelay.value) {
            final int difference = ((lyrics["duration"]) -
                    mediaItem.duration!.inSeconds.toDouble())
                .toInt()
                .abs();
            syncDelay = difference > 2
                ? ((lyrics["duration"]) -
                        mediaItem.duration!.inSeconds.toDouble())
                    .toInt()
                : 0;
          }

          setState(() {
            syncTimeDelay = syncDelay * 1000;
            plainLyrics = lyrics["plainLyrics"] ?? "";
            syncedLyrics = lyrics["syncedLyrics"] ?? "";
          });
        } else {
          setState(() {
            plainLyrics = "";
            syncedLyrics = "";
          });
        }
        setState(() {
          currentMediaItemId = stid;
          currentMediaItem = mediaItem;

          blurhash = blurHash;
        });
      }
    }

    return Container(
      color: Colors.black,
      height: size.height,
      width: size.width,
      child: StreamBuilder<MediaItem?>(
        stream: audioServiceHandler.mediaItem.stream,
        builder: (context, snapshot) {
          // Check if data is available and if the media item has changed
          if (snapshot.hasData && snapshot.data != null) {
            String newId = snapshot.data!.id.split(".")[2];

            // Update the media item safely outside the build process
            WidgetsBinding.instance.addPostFrameCallback((_) {
              newMediaItem(newId, snapshot.data);
            });
          }

          return currentMediaItem != null
              ? Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.fastOutSlowIn,
                      switchOutCurve: Curves.fastEaseInToSlowEaseOut,
                      child: Blurhash(
                        key: ValueKey(currentMediaItemId),
                        blurhash: blurhash,
                        sigmaX: 10,
                        sigmaY: 10,
                        child: Container(),
                      ),
                    ),
                    Container(
                      color: Colors.black.withAlpha(45),
                    ),
                    LyricsPhone(
                      plainLyrics: plainLyrics.split('\n'),
                      syncedLyrics: [
                        ...syncedLyrics.split('\n'),
                      ],
                      lyricsOn: lyricsOn,
                      useSyncedLyrics: useSynced,
                      syncTimeDelay: syncTimeDelay,
                    ),
                    QueuePhone(
                      key: queueKey,
                      showQueue: showQueue,
                      lyricsOn: lyricsOn,
                      changeShowQueue: () {
                        setState(() {
                          showQueue = !showQueue;
                        });
                      },
                      changeLyricsOn: () {
                        setState(() {
                          lyricsOn = !lyricsOn;
                        });
                      },
                    ),
                    LyricsButtonPhone(
                      stid: currentMediaItem!.id.split('.')[2],
                      syncTimeDelay: syncTimeDelay,
                      lyricsOn: lyricsOn,
                      useSynced: useSynced,
                      changeLyricsOn: () {
                        setState(() {
                          lyricsOn = !lyricsOn;
                        });
                      },
                      changeUseSynced: () {
                        setState(() {
                          useSynced = !useSynced;
                        });
                      },
                      resetSyncTimeDelay: () {
                        setState(() {
                          syncTimeDelay = 0;
                        });
                      },
                      plus: () {
                        setState(() {
                          syncTimeDelay += 250;
                        });
                      },
                      minus: () {
                        setState(() {
                          syncTimeDelay -= 250;
                        });
                      },
                    ),
                    TrackControlsPhone(
                      currentMediaItem: currentMediaItem!,
                      lyricsOn: lyricsOn,
                      showQueue: showQueue,
                      syncLyrics: useSynced,
                      changeLyricsOn: () {
                        setState(() {
                          lyricsOn = !lyricsOn;
                        });
                      },
                      changeShowQueue: () {
                        setState(() {
                          showQueue = !showQueue;
                        });
                      },
                      showAlbum: widget.showAlbum,
                    ),
                    TrackImagePhone(
                      lyricsOn: lyricsOn,
                      showQueue: showQueue,
                      frequency: frequencies,
                      audioServiceHandler: audioServiceHandler,
                      image: currentMediaItem!.artUri.toString(),
                    ),
                   
                  ],
                )
              : const SizedBox();
        },
      ),
    );
  }
}



 */