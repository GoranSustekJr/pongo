import 'dart:ui';
import 'package:blurhash_ffi/blurhash.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/shared/sliver/sliver_app_bar.dart';
import 'album_body_phone.dart';

class AlbumPhone extends StatefulWidget {
  final BuildContext context;
  final Album album;
  const AlbumPhone({super.key, required this.album, required this.context});

  @override
  State<AlbumPhone> createState() => _AlbumPhoneState();
}

class _AlbumPhoneState extends State<AlbumPhone> {
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
    final data = await AlbumSpotify().getTracks(context, widget.album.id);

    // Get the blurhash from the cover image
    final blurHash = widget.album.image != ""
        ? await BlurhashFFI.encode(
            NetworkImage(
              widget.album.image,
            ),
            componentX: 3,
            componentY: 3,
          )
        : AppConstants().BLURHASH;

    // init track list - data
    final List<dynamic> dta = [];

    // Add tracks to dta var
    for (var track in data["items"]) {
      track["album"] = {
        "id": widget.album.id,
        "name": widget.album.name,
        "images": [
          {"url": widget.album.image, "height": null, "width": null}
        ],
        "release_date": "",
      };

      dta.add(track);
    }

    // Set state for the statefullwidget
    setState(() {
      blurhash = blurHash;

      existingTracks = {
        for (var item in data["durations"]) item[0] as String: item[1] as double
      }; // existing tracks durations, runtimetype Map<String, double>

      tracks = Track.fromMapList(dta); // Tracks, runntimetype List<Track>

      print(data["missing_tracks"].runtimeType);
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
        "online.album:${widget.album.id}",
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
        "online.album:${widget.album.id}",
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
                              name: widget.album.name,
                              tracks: tracks,
                              scrollControllerOffset: scrollControllerOffset,
                              image: widget.album.image),
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
                                    child: PlayShuffleHaltAlbum(
                                      album: widget.album,
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
                            child: AlbumBodyPhone(
                              album: widget.album,
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
