import 'dart:ui';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/library/online%20playlist/play_shuffle_halt_online_playlist.dart';
import 'package:pongo/phone/components/shared/buttons/back_like_button.dart';
import 'package:pongo/phone/views/library/pages/online%20playlists/online_playlist_body_phone.dart';
import 'package:spotify_api/spotify_api.dart' as sp;

class OnlinePlaylistPhone extends StatefulWidget {
  final int opid;
  final String title;
  final MemoryImage? cover;
  final String blurhash;
  const OnlinePlaylistPhone({
    super.key,
    required this.opid,
    required this.title,
    this.cover,
    required this.blurhash,
  });

  @override
  State<OnlinePlaylistPhone> createState() => _OnlinePlaylistPhoneState();
}

class _OnlinePlaylistPhoneState extends State<OnlinePlaylistPhone> {
  // Track stids
  List<String> stids = [];

  // Show body
  bool showBody = false;

  // Tracks
  List<sp.Track> tracks = [];

  // Edit
  bool edit = false;

  // Cover image for background
  List<MemoryImage> coverImages = [];

  // Player
  List<MediaItem> mediaItem = [];

  // Length of item list
  int listLength = 0;

  // Selected tracks for editing
  List<String> selectedStids = [];

  // Manage Tracks That Do Not Exist
  List<String> loading = [];

  // Scroll controller
  late ScrollController scrollController;

  // Cancel play function
  bool cancel = false;

  // Offset
  double scrollControllerOffset = 0;

  // Tracks
  List<String> missingTracks = [];
  Map<String, double> existingTracks = {};

  // Loading shuffle
  bool loadingShuffle = false;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(scrollControllerListener);
    getTracks();
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

  void getTracks() async {
    int len = await DatabaseHelper()
        .queryOnlineTrackIdsLengthForPlaylist(widget.opid);
    setState(() {
      listLength = len;
    });
    List<Map<String, dynamic>> stidss =
        await DatabaseHelper().queryOnlineTrackIdsForPlaylist(widget.opid);
    List<String> stidList = [];

    for (var stid in stidss) {
      stidList.add(stid['track_id']);
    }
    setState(() {
      stids = stidList;
      showBody = true;
    });

    // Get every track data
    getTrackData();
  }

  getTrackData() async {
    final trackData = await SearializedData().tracks(
      context,
      stids,
    );
    print(stids);
    final List<dynamic> trackss = trackData["tracks"];

    final tracksThatExist = await Tracks().getDurations(
      context,
      stids,
    );

    final List<sp.Track> newTracks =
        trackss.map((item) => sp.Track.fromJson(item)).toList();

    setState(() {
      tracks = newTracks;
      existingTracks = ({
        for (var item in tracksThatExist["durations"])
          item[0] as String: item[1] as double
      });
      missingTracks = ((tracksThatExist["missing_tracks"] as List)
          .map((item) => item.toString())).toList();
    });
  }

  play({int? index}) async {
    if (!loadingShuffle) {
      final audioServiceHandler =
          Provider.of<AudioHandler>(context, listen: false)
              as AudioServiceHandler;
      // Set shuffle mode
      await audioServiceHandler.setShuffleMode(AudioServiceShuffleMode.none);

      // Set global id of the album
      currentAlbumPlaylistId.value = "onlineplaylist:${widget.opid}";
      if (missingTracks.isNotEmpty) {
        queueAllowShuffle.value = false;
        setState(() {
          cancel = true;
        });
        await audioServiceHandler.halt();
        setState(() {
          cancel = false;
        });
        await audioServiceHandler.setShuffleMode(AudioServiceShuffleMode.none);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          //  op:${widget.opid}.$stid
          TrackPlay().playConcenatingTrack(
            context,
            tracks,
            existingTracks,
            "library.onlineplaylist:${widget.opid}.",
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
                audioServiceHandler.queue.value.add(mediaItem);
                await audioServiceHandler.playlist
                    .add(audioServiceHandler.createAudioSource(mediaItem));
              }
              if (i == tracks.length - 1) {
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

        for (int i = 0; i < tracks.length; i++) {
          final MediaItem mediaItem = MediaItem(
            id: "library.onlineplaylist:${widget.opid}.${tracks[i].id}",
            title: tracks[i].name,
            artist: tracks[i].artists.map((artist) => artist.name).join(', '),
            album: tracks[i].album != null
                ? "${tracks[i].album!.id}..Ææ..${tracks[i].album!.name}"
                : "..Ææ..",
            duration: Duration(
                milliseconds: (existingTracks[tracks[i].id]! * 1000).toInt()),
            artUri: Uri.parse(
              tracks[i].album != null
                  ? calculateBestImageForTrack(tracks[i].album!.images)
                  : '',
            ),
            extras: {
              //"blurhash": blurHash,
              "released":
                  tracks[i].album != null ? tracks[i].album!.releaseDate : "",
            },
          );
          mediaItems.add(mediaItem);
        }

        await audioServiceHandler.initSongs(songs: mediaItems);
        await audioServiceHandler.skipToQueueItem(index!);
        audioServiceHandler.play();
      }
      queueAllowShuffle.value = true;
    }
  }

  playShuffle() async {
    if (!loadingShuffle && missingTracks.isEmpty) {
      queueAllowShuffle.value = true;

      setState(() {
        loadingShuffle = true;
      });

      // Set global id of the album
      currentAlbumPlaylistId.value = "onlineplaylist:${widget.opid}";

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

      for (int i = 0; i < tracks.length; i++) {
        final MediaItem mediaItem = MediaItem(
          id: "library.onlineplaylist:${widget.opid}.${tracks[i].id}",
          title: tracks[i].name,
          artist: tracks[i].artists.map((artist) => artist.name).join(', '),
          album: tracks[i].album != null
              ? "${tracks[i].album!.id}..Ææ..${tracks[i].album!.name}"
              : "..Ææ..",
          duration: Duration(
              milliseconds: (existingTracks[tracks[i].id]! * 1000).toInt()),
          artUri: Uri.parse(
            tracks[i].album != null
                ? calculateBestImageForTrack(tracks[i].album!.images)
                : '',
          ),
          extras: {
            //"blurhash": blurHash,
            "released":
                tracks[i].album != null ? tracks[i].album!.releaseDate : "",
          },
        );
        mediaItems.add(mediaItem);
      }

      await audioServiceHandler.initSongs(songs: mediaItems);
      await audioServiceHandler
          .skipToQueueItem(audioServiceHandler.audioPlayer.shuffleIndices![0]);
      //audioServiceHandler.play();
      setState(() {
        loadingShuffle = false;
      });
    }
  }

  @override
  void dispose() {
    cancel = true;
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
              width: size.width,
              height: size.height,
              decoration: AppConstants().backgroundBoxDecoration,
              child: Stack(
                children: [
                  Blurhash(
                    blurhash: widget.blurhash,
                    sigmaX: 10,
                    sigmaY: 10,
                    child: Container(),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    color: Colors.black.withAlpha(50),
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
                              expandedHeight:
                                  MediaQuery.of(context).size.height / 2,
                              floating: false,
                              pinned: true,
                              stretch: true,
                              automaticallyImplyLeading: false,
                              title: Row(
                                children: [
                                  backButton(context),
                                  Expanded(
                                    child: Container(),
                                  ),
                                  backLikeButton(context, AppIcons.edit,
                                      () async {
                                    final audioServiceHandler =
                                        Provider.of<AudioHandler>(context,
                                                listen: false)
                                            as AudioServiceHandler;
                                    if (audioServiceHandler.mediaItem.value !=
                                        null) {
                                      if ("library.onlineplaylist:${widget.opid}" ==
                                          '${audioServiceHandler.mediaItem.value!.id.split('.')[0]}.${audioServiceHandler.mediaItem.value!.id.split('.')[1]}') {
                                        CustomButton ok =
                                            await haltAlert(context);
                                        if (ok == CustomButton.positiveButton) {
                                          currentTrackHeight.value = 0;
                                          final audioServiceHandler =
                                              Provider.of<AudioHandler>(context,
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
                                  }),
                                ],
                              ),
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
                                        widget.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                    ],
                                  ),
                                  flexibleSpace: Opacity(
                                    opacity:
                                        MediaQuery.of(context).size.height /
                                                    2 <=
                                                scrollControllerOffset
                                            ? 1
                                            : scrollControllerOffset /
                                                (MediaQuery.of(context)
                                                        .size
                                                        .height /
                                                    2),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Container(),
                                    ),
                                  ),
                                ),
                                background: Stack(
                                  children: [
                                    Center(
                                      child: SizedBox(
                                        width: size.width - 60,
                                        height: size.width - 60,
                                        child: Center(
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              top: MediaQuery.of(context)
                                                  .padding
                                                  .top,
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              child: widget.cover != null
                                                  ? Image.memory(
                                                      widget.cover!.bytes)
                                                  : Container(
                                                      width: size.width - 60,
                                                      height: size.width - 60,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15),
                                                        color: Col.primaryCard
                                                            .withAlpha(200),
                                                      ),
                                                      child: const Center(
                                                        child: Icon(
                                                          AppIcons.blankAlbum,
                                                          size: 50,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
                                      filter: ImageFilter.blur(
                                          sigmaX: 10, sigmaY: 10),
                                      child: PlayShuffleHaltOnlinePlaylist(
                                        opid: widget.opid,
                                        missingTracks: missingTracks,
                                        loadingShuffle: loadingShuffle,
                                        edit: edit,
                                        frontWidget: const SizedBox(),
                                        endWidget: const SizedBox(),
                                        play: () {
                                          play(index: 0);
                                        },
                                        shuffle: playShuffle,
                                        stopEdit: () {
                                          setState(() {
                                            edit = false;
                                            selectedStids.clear();
                                          });
                                        },
                                        remove: () async {
                                          if (selectedStids.isNotEmpty) {
                                            CustomButton ok =
                                                await removeFavouriteAlert(
                                                    context);
                                            if (ok ==
                                                CustomButton.positiveButton) {
                                              await DatabaseHelper()
                                                  .removeTracksFromOnlinePlaylist(
                                                      selectedStids);

                                              setState(() {
                                                tracks.clear();
                                                selectedStids.clear();
                                                edit = false;
                                              });

                                              getTracks();
                                            }
                                          }
                                        },
                                        addToPlaylist: () {
                                          OpenPlaylist().open(context,
                                              tracks: selectedStids.map(
                                                (stid) {
                                                  final track = tracks
                                                      .where((favourite) =>
                                                          favourite.id == stid)
                                                      .toList()[0];
                                                  return {
                                                    "id": track.id,
                                                    "cover":
                                                        calculateWantedResolutionForTrack(
                                                            track.album != null
                                                                ? track.album!
                                                                    .images
                                                                : track.album!
                                                                    .images,
                                                            150,
                                                            150),
                                                    "title": track.name,
                                                    "artist": track.artists
                                                        .map((artist) =>
                                                            artist.name)
                                                        .toList()
                                                        .join(', '),
                                                  };
                                                },
                                              ).toList());
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
                                child: tracks.isNotEmpty
                                    ? SizedBox(
                                        key: const ValueKey(true),
                                        child: stids.isEmpty
                                            ? Column(
                                                children: [
                                                  razh(50),
                                                  const Text("Empty"),
                                                ],
                                              )
                                            : OnlinePlaylistBodyPhone(
                                                opid: widget.opid,
                                                tracks: tracks,
                                                missingTracks: missingTracks,
                                                loading: loading,
                                                numberOfSTIDS: stids.length,
                                                edit: edit,
                                                play: (index) {
                                                  play(index: index);
                                                },
                                                selectedTracks: selectedStids,
                                                select: (stid) {
                                                  setState(() {
                                                    if (selectedStids
                                                        .contains(stid)) {
                                                      selectedStids
                                                          .remove(stid);
                                                    } else {
                                                      selectedStids.add(stid);
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
                                              itemCount: listLength,
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemBuilder: (context, index) {
                                                return songTileSchimmer(
                                                  context,
                                                  index == 0,
                                                  index == listLength--,
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
                ],
              ),
            )
          : loadingScaffold(context, const ValueKey(false)),
    );
  }
}
