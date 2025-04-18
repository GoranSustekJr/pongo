import 'dart:ui';
import 'package:pongo/exports.dart';

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
  List<Track> tracks = [];

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

  // Playlist functions
  late PlaylistFunctions playlistFunctions;

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
    // Get tracks count in the playlist
    int len =
        await DatabaseHelper().queryOnlineTracksLengthForPlaylist(widget.opid);

    // Set tracks length in order to show shimmer
    setState(() {
      listLength = len;
    });

    // get the stid list
    List<OnlinePlaylistTrack> onlinePlaylistTrackss =
        await DatabaseHelper().queryOnlineTracksForPlaylist(widget.opid);

    // init the help variables
    List<String> stidList = [];
    Map<String, bool> hiddn = {};

    // get the stid list from the stidss list and set the hidden status in the help variables
    for (OnlinePlaylistTrack onlinePlaylistTrack in onlinePlaylistTrackss) {
      stidList.add(onlinePlaylistTrack.stid);
      hiddn[onlinePlaylistTrack.stid] = (onlinePlaylistTrack.hidden);
    }

    // Set states
    setState(() {
      stids = stidList;
      hidden = hiddn;
      tracks = onlinePlaylistTrackss
          .map((onlinePlaylistTrack) => Track(
                id: onlinePlaylistTrack.stid,
                name: onlinePlaylistTrack.title,
                artists: onlinePlaylistTrack.artistTrack,
                album: onlinePlaylistTrack.albumTrack,
              ))
          .toList();
      showBody = true;
    });

    // Get every track data
    getTrackData();
  }

  getTrackData() async {
    if (stids.isNotEmpty) {
      // Get the tracks data
      final trackThatExist = await Tracks().getDurations(context, stids);

      setState(() {
        existingTracks = {
          for (var item in trackThatExist["durations"])
            item[0] as String: item[1] as double
        }; // existing tracks durations, runtimetype Map<String, double>

        missingTracks = (trackThatExist["missing_tracks"] as List<dynamic>)
            .cast<String>(); // Missing tracks stids
      });
    }
  }

  void addLoading(String stid) {
    if (mounted) {
      setState(() {
        loading.add(stid);
      });
    }
  }

  void removeLoading(String stid) {
    if (mounted) {
      setState(() {
        loading.remove(stid);
      });
    }
  }

  void addDuration(String stid, double duration) {
    if (mounted) {
      setState(() {
        missingTracks.remove(stid);
        existingTracks[stid] = duration;
      });
    }
  }

  play({int index = 0}) async {
    if (!loadingShuffle) {
      PlayMultiple().onlineTrack(
        "online.playlist:${widget.opid}",
        tracks.where((track) => hidden[track.id] == false).toList(),
        missingTracks,
        existingTracks,
        addLoading,
        removeLoading,
        addDuration,
        index: index,
      );
    }
  }

  void playShuffle() {
    if (!loadingShuffle && missingTracks.isEmpty) {
      PlayMultiple().onlineTrack(
        "online.playlist:${widget.opid}",
        tracks.where((track) => hidden[track.id] == false).toList(),
        missingTracks,
        existingTracks,
        addLoading,
        removeLoading,
        addDuration,
        shuffle: true,
      );
    }
  }

  Future<void> move<T>(List<T> list, int currentIndex, int newIndex) async {
    if (currentIndex == newIndex) return;
    final item = list.removeAt(currentIndex);
    list.insert(newIndex, item);
  }

  void showSelected() async {
    if (selectedStids.isNotEmpty) {
      await DatabaseHelper()
          .updateOnlinePlaylistShow(widget.opid, selectedStids);
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
    }
  }

  void hideSelected() async {
    if (selectedStids.isNotEmpty) {
      await DatabaseHelper()
          .updateOnlinePlaylistHide(widget.opid, selectedStids);
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
    }
  }

  void changeTitle() async {
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
  }

  void changeCover() async {
    if (edit) {
      XFile? pickedFile;

      try {
        pickedFile = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          requestFullMetadata: false,
        );
      } catch (e) {
        if (e.toString().contains("access_denied")) {
          Notifications().showWarningNotification(
            context,
            AppLocalizations.of(context).pleaseallowaccesstophotogalery,
          );
          return;
        }
      }
      Uint8List? bytes;

      if (pickedFile != null) {
        // Crop the image to a square
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          maxHeight: 600,
          maxWidth: 600,
          aspectRatio: const CropAspectRatio(
            ratioX: 1,
            ratioY: 1,
          ), // Square aspect ratio

          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: AppLocalizations.of(context).cropimage,
              toolbarColor: Colors.black,
              toolbarWidgetColor: Colors.white,
              hideBottomControls: true,
            ),
            IOSUiSettings(
              title: AppLocalizations.of(context).cropimage,
              cancelButtonTitle: AppLocalizations.of(context).cancel,
              doneButtonTitle: AppLocalizations.of(context).okey,
            ),
          ],
        );

        if (croppedFile != null) {
          bytes = await File(croppedFile.path).readAsBytes();
          if (bytes.isNotEmpty) {
            await DatabaseHelper()
                .updateOnlinePlaylistCover(widget.opid, bytes);
            final String blurHash = await BlurhashFFI.encode(
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
          Provider.of<AudioHandler>(context, listen: false)
              as AudioServiceHandler;
      if (audioServiceHandler.mediaItem.value != null) {
        if ("online.playlist:${widget.opid}" ==
            '${audioServiceHandler.mediaItem.value!.id.split('.')[0]}.${audioServiceHandler.mediaItem.value!.id.split('.')[1]}') {
          CustomButton ok = await haltAlert(context);
          if (ok == CustomButton.positiveButton) {
            currentTrackHeight.value = 0;
            final audioServiceHandler =
                Provider.of<AudioHandler>(context, listen: false)
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
  }

  void stopEdit() {
    setState(() {
      edit = false;
      selectedStids.clear();
    });
  }

  void remove() async {
    // Rremove tracks from playlist
    if (selectedStids.isNotEmpty) {
      CustomButton ok = await removeTrackFromPlaylistAlert(context);
      if (ok == CustomButton.positiveButton) {
        await DatabaseHelper()
            .removeTracksFromOnlinePlaylist(widget.opid, selectedStids);

        setState(() {
          tracks.clear();
          selectedStids.clear();
          hidden.clear();
          edit = false;
        });

        getTracks();
      }
    }
  }

  void addToPlaylist() {
    if (selectedStids.isNotEmpty) {
      OpenPlaylist().show(
          context,
          PlaylistHandler(
              type: PlaylistHandlerType.online,
              function: PlaylistHandlerFunction.addToPlaylist,
              track: selectedStids.map((stid) {
                final track =
                    tracks.where((track) => track.id == stid).toList()[0];
                return PlaylistHandlerOnlineTrack(
                  id: track.id,
                  name: track.name,
                  artist: track.artists
                      .map((artist) => {"id": artist.id, "name": artist.name})
                      .toList(),
                  cover: calculateWantedResolutionForTrack(
                      track.album != null
                          ? track.album!.images
                          : track.album!.images,
                      150,
                      150),
                  albumTrack: track.album,
                  playlistHandlerCoverType: PlaylistHandlerCoverType.url,
                );
              }).toList()));
    }
  }

  void select(stid) {
    // Select track
    setState(() {
      if (selectedStids.contains(stid)) {
        selectedStids.remove(stid);
      } else {
        selectedStids.add(stid);
      }
    });
  }

  void moveTrack(oldIndex, newIndex) async {
    if (oldIndex == newIndex) return;
    setState(() {
      final item = tracks.removeAt(oldIndex);
      tracks.insert(
        oldIndex < newIndex ? newIndex - 1 : newIndex,
        item,
      );

      final stid = stids.removeAt(oldIndex);
      stids.insert(
        oldIndex < newIndex ? newIndex - 1 : newIndex,
        stid,
      );

      // Get the new order
      Map<String, Track> trackMap = {for (var track in tracks) track.id: track};
      List<Track> newTrack = stids.map((stid) => trackMap[stid]!).toList();

      DatabaseHelper().updateOnlinePlaylistOrder(
        widget.opid,
        newTrack
            .map(
              (track) => OnlinePlaylistTrack(
                opid: widget.opid,
                stid: track.id,
                title: track.name,
                artistTrack: track.artists,
                albumTrack: track.album,
                image: calculateWantedResolutionForTrack(
                    track.album != null
                        ? track.album!.images
                        : track.album!.images,
                    150,
                    150),
                orderNumber: -1,
                hidden: hidden[track.id] ?? false,
              ),
            )
            .toList(),
      );
    });
  }

  // Select all stids
  selectAll() {
    setState(() {
      if (selectedStids.length != tracks.length) {
        selectedStids.clear();
        selectedStids.addAll(tracks.map((track) => track.id));
      } else {
        selectedStids.clear();
      }
    });
  }

  // Download the tracks/playlist
  void download() async {
    if (selectedStids.isNotEmpty) {
      // Get the tracks that need to be downloaded
      List<String> toDownload =
          await DatabaseHelper().queryMissingStids(selectedStids);

      // Open playlist helper and add them to a playlist or create a new playlist
      OpenPlaylist().show(
        context,
        PlaylistHandler(
          toDownload: toDownload,
          type: PlaylistHandlerType.offline,
          function: PlaylistHandlerFunction.addToPlaylist,
          track: tracks.where((track) => selectedStids.contains(track.id)).map(
            (track) {
              return PlaylistHandlerOnlineTrack(
                id: track.id,
                name: track.name,
                artist: track.artists
                    .map((artist) => {"id": artist.id, "name": artist.name})
                    .toList(),
                cover: calculateBestImageForTrack(
                  track.album!.images,
                ),
                albumTrack: track.album,
                playlistHandlerCoverType: PlaylistHandlerCoverType.url,
              );
            },
          ).toList(),
        ),
      );
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
                    blurhash: blurhash,
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
                        controller: scrollController,
                        child: CustomScrollView(
                          controller: scrollController,
                          slivers: [
                            OnlinePlaylistAppBarPhone(
                              title: title,
                              cover: cover,
                              edit: edit,
                              scrollControllerOffset: scrollControllerOffset,
                              changeCover: changeCover,
                              changeTitle: changeTitle,
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
                                        child: PlayShuffleHaltOnlinePlaylist(
                                          opid: widget.opid,
                                          missingTracks: missingTracks,
                                          loadingShuffle: loadingShuffle,
                                          edit: edit,
                                          allSelected: selectedStids.length ==
                                              tracks.length,
                                          frontWidget: const SizedBox(),
                                          endWidget: const SizedBox(),
                                          play: () {
                                            play(index: 0);
                                          },
                                          shuffle: playShuffle,
                                          stopEdit: stopEdit,
                                          remove: remove,
                                          addToPlaylist: addToPlaylist,
                                          show: showSelected,
                                          hide: hideSelected,
                                          selectAll: selectAll,
                                          download: download,
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
                                child: tracks.isNotEmpty || listLength < 1
                                    ? SizedBox(
                                        key: const ValueKey(true),
                                        child: stids.isEmpty
                                            ? Column(
                                                children: [
                                                  razh(50),
                                                  iconButton(
                                                      AppIcons.blankTrack,
                                                      Colors.white, () {
                                                    navigationBarIndex.value =
                                                        0;
                                                    searchFocusNode.value
                                                        .requestFocus();
                                                  }, size: 60),
                                                  textButton(
                                                      AppLocalizations.of(
                                                              context)
                                                          .addtrackstoyoutplaylist,
                                                      () {
                                                    navigationBarIndex.value =
                                                        0;
                                                    searchFocusNode.value
                                                        .requestFocus();
                                                  },
                                                      const TextStyle(
                                                          color: Colors.white),
                                                      edgeInsets:
                                                          EdgeInsets.zero)
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
                                                select: select,
                                                move: moveTrack,
                                              ),
                                      )
                                    : Column(
                                        key: const ValueKey(false),
                                        children: [
                                          ListView.builder(
                                            padding: EdgeInsets.only(
                                              top: 35,
                                              bottom: MediaQuery.of(context)
                                                      .padding
                                                      .bottom +
                                                  15,
                                            ),
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
