import 'dart:ui';
import 'package:blurhash_ffi/blurhash.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/shared/sliver/sliver_app_bar.dart';

class PlaylistPhone extends StatefulWidget {
  final BuildContext context;
  final Playlist playlist;
  const PlaylistPhone(
      {super.key, required this.playlist, required this.context});

  @override
  State<PlaylistPhone> createState() => _PlaylistPhoneState();
}

class _PlaylistPhoneState extends State<PlaylistPhone> {
  // Show body
  bool showBody = false;

  // Tracks
  List<Track> tracks = [];
  List<String> missingTracks = [];
  Map<String, double> existingTracks = {};

  // Blurhash
  String blurhash = "";

  // Scroll controller
  late ScrollController scrollController;

  // Offset
  double scrollControllerOffset = 0;

  // Manage Tracks That Do Not Exist
  List<String> loading = [];

  // Cancel play function
  bool cancel = false;

  // Loading shuffle boolean
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
    // Get the album tracks, missing tracks and durations
    final data = await PlaylistSpotify().get(context, widget.playlist.id);

    // Get the blurhash from the cover image
    final blurHash = widget.playlist.image != ""
        ? await BlurhashFFI.encode(
            NetworkImage(
              widget.playlist.image,
            ),
            componentX: 3,
            componentY: 3,
          )
        : AppConstants().BLURHASH;

    // init track list - data
    final List<dynamic> dta = [];

    // Add tracks to dta var
    for (var track in data["items"]) {
      dta.add(track["track"]);
    }

    // Set state for the statefullwidget
    setState(() {
      blurhash = blurHash;

      existingTracks = {
        for (var item in data["durations"]) item[0] as String: item[1] as double
      }; // existing tracks durations, runtimetype Map<String, double>

      tracks = Track.fromMapList(dta); // Tracks, runntimetype List<Track>

      missingTracks = (data["missing_tracks"] as List<dynamic>)
          .cast<String>(); // Missing tracks stids

      showBody = true; // Show the body
    });
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
        "online.playlist:${widget.playlist.id}",
        tracks,
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
        "online.playlist:${widget.playlist.id}",
        tracks,
        missingTracks,
        existingTracks,
        addLoading,
        removeLoading,
        addDuration,
        shuffle: true,
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: showBody
          ? Stack(
              key: ValueKey(blurhash),
              children: [
                BlurHash(
                  hash: blurhash,
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
                        slivers: <Widget>[
                          SliverAppBarPhone(
                              name: widget.playlist.name,
                              tracks: tracks,
                              scrollControllerOffset: scrollControllerOffset,
                              image: widget.playlist.image),
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
                                    child: PlayShuffleHaltPlaylist(
                                      playlist: widget.playlist,
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
                            child: PlaylistBodyPhone(
                              playlist: widget.playlist,
                              tracks: tracks,
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
                ),
              ],
            )
          : loadingScaffold(context, const ValueKey(false)),
    );
  }
}
