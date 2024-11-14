import 'dart:ui';
import 'package:blurhash_ffi/blurhash.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/library/online%20playlist/play_shuffle_halt_online_playlist.dart';
import 'package:pongo/phone/views/library/pages/online%20playlists/change_online_playlist_name_phone.dart';
import 'package:pongo/phone/views/library/pages/online%20playlists/online_playlist_app_bar_phone.dart';
import 'package:pongo/phone/views/library/pages/online%20playlists/online_playlist_body_phone.dart';
import 'package:spotify_api/spotify_api.dart' as sp;

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
  // Track stids
  List<String> stids = [];

  // Playlist data
  MemoryImage? cover;
  String title = "";
  String blurhash = "";

  // Hidden songs
  Map<String, bool> hidden = {};

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
    cover = widget.cover;
    title = widget.title;
    blurhash = widget.blurhash;
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
    Map<String, bool> hiddn = {};

    for (var stid in stidss) {
      stidList.add(stid['track_id']);
      hiddn[stid['track_id']] = (stid['hidden'] == 1);
    }
    setState(() {
      stids = stidList;
      hidden = hiddn;
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

      // Not hiddent tracks
      List<sp.Track> shownTracks =
          tracks.where((track) => hidden[track.id] != true).toList();

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
            shownTracks,
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
              if (i == shownTracks.length - 1) {
                queueAllowShuffle.value = true;
              }
            },
          );
        });
      } else {
        final List<MediaItem> mediaItems = [];

        final audioServiceHandler =
            Provider.of<AudioHandler>(context, listen: false)
                as AudioServiceHandler;

        for (int i = 0; i < shownTracks.length; i++) {
          final MediaItem mediaItem = MediaItem(
            id: "library.onlineplaylist:${widget.opid}.${shownTracks[i].id}",
            title: shownTracks[i].name,
            artist:
                shownTracks[i].artists.map((artist) => artist.name).join(', '),
            album: shownTracks[i].album != null
                ? "${shownTracks[i].album!.id}..Ææ..${shownTracks[i].album!.name}"
                : "..Ææ..",
            duration: Duration(
                milliseconds:
                    (existingTracks[shownTracks[i].id]! * 1000).toInt()),
            artUri: Uri.parse(
              shownTracks[i].album != null
                  ? calculateBestImageForTrack(shownTracks[i].album!.images)
                  : '',
            ),
            extras: {
              //"blurhash": blurHash,
              "released": shownTracks[i].album != null
                  ? shownTracks[i].album!.releaseDate
                  : "",
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

      // Not hiddent tracks
      List<sp.Track> shownTracks =
          tracks.where((track) => hidden[track.id] != true).toList();

      // Set global id of the album
      currentAlbumPlaylistId.value = "onlineplaylist:${widget.opid}";

      final List<MediaItem> mediaItems = [];

      final audioServiceHandler =
          Provider.of<AudioHandler>(context, listen: false)
              as AudioServiceHandler;

      await audioServiceHandler.setShuffleMode(AudioServiceShuffleMode.all);

      for (int i = 0; i < shownTracks.length; i++) {
        final MediaItem mediaItem = MediaItem(
          id: "library.onlineplaylist:${widget.opid}.${shownTracks[i].id}",
          title: shownTracks[i].name,
          artist:
              shownTracks[i].artists.map((artist) => artist.name).join(', '),
          album: shownTracks[i].album != null
              ? "${shownTracks[i].album!.id}..Ææ..${shownTracks[i].album!.name}"
              : "..Ææ..",
          duration: Duration(
              milliseconds:
                  (existingTracks[shownTracks[i].id]! * 1000).toInt()),
          artUri: Uri.parse(
            shownTracks[i].album != null
                ? calculateBestImageForTrack(shownTracks[i].album!.images)
                : '',
          ),
          extras: {
            "released": shownTracks[i].album != null
                ? shownTracks[i].album!.releaseDate
                : "",
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

  Future<void> move<T>(List<T> list, int currentIndex, int newIndex) async {
    if (currentIndex == newIndex) return;
    final item = list.removeAt(currentIndex);
    list.insert(newIndex, item);
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
                    blurhash: blurhash,
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
                            OnlinePlaylistAppBarPhone(
                              title: title,
                              cover: cover,
                              edit: edit,
                              scrollControllerOffset: scrollControllerOffset,
                              changeCover: () async {
                                if (edit) {
                                  XFile? pickedFile;

                                  try {
                                    pickedFile = await ImagePicker().pickImage(
                                      source: ImageSource.gallery,
                                      requestFullMetadata: false,
                                    );
                                  } catch (e) {
                                    if (e
                                        .toString()
                                        .contains("access_denied")) {
                                      Notifications().showWarningNotification(
                                        context,
                                        AppLocalizations.of(context)!
                                            .pleaseallowaccesstophotogalery,
                                      );
                                      return;
                                    }
                                  }
                                  Uint8List? bytes;

                                  if (pickedFile != null) {
                                    // Crop the image to a square
                                    CroppedFile? croppedFile =
                                        await ImageCropper().cropImage(
                                      sourcePath: pickedFile.path,
                                      maxHeight: 500,
                                      maxWidth: 500,
                                      aspectRatio: const CropAspectRatio(
                                        ratioX: 1,
                                        ratioY: 1,
                                      ), // Square aspect ratio

                                      uiSettings: [
                                        AndroidUiSettings(
                                          toolbarTitle:
                                              AppLocalizations.of(context)!
                                                  .cropimage,
                                          toolbarColor: Colors.black,
                                          toolbarWidgetColor: Colors.white,
                                          hideBottomControls: true,
                                        ),
                                        IOSUiSettings(
                                          title: AppLocalizations.of(context)!
                                              .cropimage,
                                          cancelButtonTitle:
                                              AppLocalizations.of(context)!
                                                  .cancel,
                                          doneButtonTitle:
                                              AppLocalizations.of(context)!
                                                  .okey,
                                        ),
                                      ],
                                    );

                                    if (croppedFile != null) {
                                      bytes = await File(croppedFile.path)
                                          .readAsBytes();
                                      if (bytes.isNotEmpty) {
                                        await DatabaseHelper()
                                            .updateOnlinePlaylistCover(
                                                widget.opid, bytes);
                                        final String blurHash =
                                            await BlurhashFFI.encode(
                                          MemoryImage(bytes),
                                          componentX: 3,
                                          componentY: 3,
                                        );
                                        setState(() {
                                          cover = MemoryImage(bytes!);
                                          blurhash = blurHash;
                                        });
                                        widget.updateCover(MemoryImage(bytes));
                                      }
                                    }
                                  }
                                } else {
                                  final audioServiceHandler =
                                      Provider.of<AudioHandler>(context,
                                          listen: false) as AudioServiceHandler;
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
                                }
                              },
                              changeTitle: () async {
                                newPlaylistTitle(
                                  context,
                                  widget.opid,
                                  (newTitle) {
                                    setState(() {
                                      title = newTitle;
                                    });
                                    widget.updateTitle(newTitle);
                                  },
                                );
                              },
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
                                                hidden.clear();
                                                edit = false;
                                              });

                                              getTracks();
                                            }
                                          }
                                        },
                                        addToPlaylist: () {
                                          OpenPlaylist().show(
                                              context,
                                              PlaylistHandler(
                                                  type: PlaylistHandlerType
                                                      .online,
                                                  function:
                                                      PlaylistHandlerFunction
                                                          .addToPlaylist,
                                                  track:
                                                      selectedStids.map((stid) {
                                                    final track = tracks
                                                        .where((track) =>
                                                            track.id == stid)
                                                        .toList()[0];
                                                    return PlaylistHandlerOnlineTrack(
                                                      id: track.id,
                                                      name: track.name,
                                                      artist: track.artists
                                                          .map((artist) =>
                                                              artist.name)
                                                          .toList()
                                                          .join(', '),
                                                      cover:
                                                          calculateWantedResolutionForTrack(
                                                              track.album !=
                                                                      null
                                                                  ? track.album!
                                                                      .images
                                                                  : track.album!
                                                                      .images,
                                                              150,
                                                              150),
                                                      playlistHandlerCoverType:
                                                          PlaylistHandlerCoverType
                                                              .url,
                                                    );
                                                  }).toList()));
                                        },
                                        show: () async {
                                          await DatabaseHelper()
                                              .updateOnlinePlaylistShow(
                                                  widget.opid, selectedStids);
                                          setState(() {
                                            // Remove from hidden
                                            for (var key in hidden.keys) {
                                              if (selectedStids.contains(key)) {
                                                hidden[key] = false;
                                              }
                                            }
                                            selectedStids.clear();
                                            edit = false;
                                          });
                                        },
                                        hide: () async {
                                          await DatabaseHelper()
                                              .updateOnlinePlaylistHide(
                                                  widget.opid, selectedStids);
                                          setState(() {
                                            // Remove from hidden

                                            for (var key in hidden.keys) {
                                              if (selectedStids.contains(key)) {
                                                hidden[key] = true;
                                              }
                                            }
                                            selectedStids.clear();
                                            edit = false;
                                          });
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
                                                hidden: hidden,
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
                                                move: (oldIndex, newIndex) {
                                                  if (oldIndex == newIndex ||
                                                      !edit) return;
                                                  setState(() {
                                                    final item = tracks
                                                        .removeAt(oldIndex);
                                                    tracks.insert(
                                                      oldIndex < newIndex
                                                          ? newIndex - 1
                                                          : newIndex,
                                                      item,
                                                    );

                                                    final stid = stids
                                                        .removeAt(oldIndex);
                                                    stids.insert(
                                                      oldIndex < newIndex
                                                          ? newIndex - 1
                                                          : newIndex,
                                                      stid,
                                                    );
                                                    DatabaseHelper()
                                                        .updateOnlinePlaylistOrder(
                                                            widget.opid, stids);
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
