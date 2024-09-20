import 'dart:ui';

import 'package:blurhash_ffi/blurhash.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/album/play_shuffle_halt_album.dart';
import 'package:pongo/phone/components/shared/other/sticky_header_delegate.dart';
import 'package:pongo/shared/utils/API%20requests/album_tracks.dart';
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
  List missingTracks = [];
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
    final data = await AlbumSpotify().get(context, widget.album.id);

    final blurHash = widget.album.image != ""
        ? await BlurhashFFI.encode(
            NetworkImage(
              widget.album.image,
            ),
            componentX: 3,
            componentY: 3,
          )
        : AppConstants().BLURHASH;
    setState(() {
      blurhash = blurHash;
      final List<dynamic> dta = data["items"];
      existingTracks = {
        for (var item in data["durations"]) item[0] as String: item[1] as double
      };
      tracks = dta
          .map<Track>(
            (track) => Track(
              id: track["id"],
              name: track["name"],
              artists: (track["artists"] as List<dynamic>)
                  .map((artist) => ArtistTrack(
                        id: artist["id"] as String,
                        name: artist["name"] as String,
                      ))
                  .toList(),
              album: AlbumTrack(
                name: widget.album.name,
                releaseDate: widget.album.name,
                images: [
                  AlbumImagesTrack(
                    url: widget.album.image,
                    height: null,
                    width: null,
                  )
                ],
              ),
            ),
          )
          .toList();
      missingTracks = data["missing_tracks"];
      showBody = true;
    });
  }

  play({int? index}) async {
    if (!loadingShuffle) {
      final audioServiceHandler =
          Provider.of<AudioHandler>(context, listen: false)
              as AudioServiceHandler;
      await audioServiceHandler.setShuffleMode(AudioServiceShuffleMode.none);
      if (missingTracks.isNotEmpty) {
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
          TrackPlay().playConcenating(
            widget.context,
            widget.album.id,
            tracks,
            existingTracks,
            "search.album:${widget.album.id}.",
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
              print("YEAAH; $i");
              if (i == 0) {
                print("HMMM; $i");
                await audioServiceHandler.initSongs(songs: [mediaItem]);
                audioServiceHandler.play();
              } else {
                print("HMMMAAAAAAAA; $i");
                audioServiceHandler.queue.value.add(mediaItem);
                print("AAAAAAAAA");
                await audioServiceHandler.playlist
                    .add(audioServiceHandler.createAudioSource(mediaItem));
                print("BBBBBBBBBBBB");
              }
            },
          );
        });
      } else {
        final data = await AlbumSpotify().getShuffle(context, widget.album.id);
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

        for (int i = 0; i < tracks.length; i++) {
          final MediaItem mediaItem = MediaItem(
            id: "search.album:${widget.album.id}.${tracks[i].id}",
            title: tracks[i].name,
            artist: tracks[i].artists.map((artist) => artist.name).join(', '),
            album: tracks[i].album != null ? tracks[i].album!.name : "",
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
    }
  }

  playShuffle() async {
    if (!loadingShuffle && missingTracks.isEmpty) {
      setState(() {
        loadingShuffle = true;
      });

      final data = await AlbumSpotify().getShuffle(context, widget.album.id);
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

      for (int i = 0; i < tracks.length; i++) {
        final MediaItem mediaItem = MediaItem(
          id: "search.album:${widget.album.id}.${tracks[i].id}",
          title: tracks[i].name,
          artist: tracks[i].artists.map((artist) => artist.name).join(', '),
          album: tracks[i].album != null ? tracks[i].album!.name : "",
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
                                      child: marquee(
                                        widget.album.name,
                                        const TextStyle(
                                          fontSize: 23,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        1,
                                        null,
                                      ),
                                    ),
                                  ],
                                ),
                                flexibleSpace: Opacity(
                                  opacity: MediaQuery.of(context).size.height /
                                              2 <=
                                          scrollControllerOffset
                                      ? 1
                                      : scrollControllerOffset /
                                          (MediaQuery.of(context).size.height /
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
                                      width: MediaQuery.of(context).size.width -
                                          60,
                                      height:
                                          MediaQuery.of(context).size.width -
                                              60,
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
                                            child: CachedNetworkImage(
                                              imageUrl: widget.album.image,
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
