import 'dart:ui';

import 'package:blurhash_ffi/blurhash.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/playlist/play_shuffle_halt_playlist.dart';
import 'package:pongo/phone/views/playlist/playlist_body_phone.dart';
import 'package:pongo/shared/utils/API%20requests/playlist_tracks.dart';

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
    final data = await PlaylistSpotify().get(context, widget.playlist.id);

    print("durations; ${data["durations"]}");

    final blurHash = widget.playlist.image != ""
        ? await BlurhashFFI.encode(
            NetworkImage(
              widget.playlist.image,
            ),
            componentX: 3,
            componentY: 3,
          )
        : AppConstants().BLURHASH;
    setState(() {
      print(data);
      final List<dynamic> dta = data["items"];
      existingTracks = {
        for (var item in data["durations"]) item[0] as String: item[1] as double
      };
      tracks = dta
          .map<Track>(
            (track) => Track(
              id: track["track"]["id"],
              name: track["track"]["name"],
              artists: (track["track"]["artists"] as List<dynamic>)
                  .map((artist) => ArtistTrack(
                        id: artist["id"] as String,
                        name: artist["name"] as String,
                      ))
                  .toList(),
              album: track["track"]["album"] != null
                  ? AlbumTrack(
                      id: track["track"]["album"]["id"],
                      name: track["track"]["album"]["name"] as String,
                      releaseDate:
                          track["track"]["album"]["release_date"] as String,
                      images:
                          (track["track"]["album"]["images"] as List<dynamic>)
                              .map((image) => AlbumImagesTrack(
                                    url: image["url"] as String,
                                    height: image["height"] as int?,
                                    width: image["width"] as int?,
                                  ))
                              .toList(),
                    )
                  : null,
            ),
          )
          .toList();
      missingTracks = data["missing_tracks"];
      blurhash = blurHash;
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
      currentAlbumPlaylistId.value = "playlist:${widget.playlist.id}";

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
            widget.context,
            widget.playlist.id,
            tracks,
            existingTracks,
            "search.playlist:${widget.playlist.id}.",
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
              if (i == tracks.length - 1) {
                queueAllowShuffle.value = true;
              }
            },
          );
        });
      } else {
        print("NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN");

        final data =
            await PlaylistSpotify().getShuffle(context, widget.playlist.id);
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
            id: "search.playlist:${widget.playlist.id}.${tracks[i].id}",
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
      final data =
          await PlaylistSpotify().getShuffle(context, widget.playlist.id);

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
          id: "search.playlist:${widget.playlist.id}.${tracks[i].id}",
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
            "released":
                tracks[i].album != null ? tracks[i].album!.releaseDate : "",
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
                                      widget.playlist.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ) /* marquee(
                                        widget.playlist.name,
                                        const TextStyle(
                                          fontSize: 23,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        1,
                                        null,
                                      ), */
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
                              background: Center(
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width - 60,
                                  height:
                                      MediaQuery.of(context).size.width - 60,
                                  child: Center(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        top: MediaQuery.of(context).padding.top,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: CachedNetworkImage(
                                          imageUrl: widget.playlist.image,
                                        ),
                                      ),
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
                                print("object");
                                print("Index, $index");
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
