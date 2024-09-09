import 'package:blurhash_ffi/blurhash_ffi.dart';
import 'package:mini_music_visualizer/mini_music_visualizer.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/views/playlist/playlist_phone.dart';
import 'package:pongo/shared/utils/API%20requests/search.dart';
import 'package:pongo/shared/utils/API%20requests/track_metadata.dart';
import 'package:spotify_api/spotify_api.dart' as sp;

class SearchPhone extends StatefulWidget {
  final String query;
  const SearchPhone({super.key, required this.query});

  @override
  State<SearchPhone> createState() => _SearchPhoneState();
}

class _SearchPhoneState extends State<SearchPhone> {
// Query
  String query = "";

  // Tracks
  List<sp.Track> tracks = [];

  // Artist
  List<Artist> artists = [];

  // Albums
  List<Album> albums = [];

  // Playlistst
  List<Playlist> playlists = [];

  // Manage Tracks That Do Not Exist
  List<String> loading = [];

  // Scroll controller
  final ScrollController scrollController = ScrollController();

  // Search result header text style
  final TextStyle suggestionHeader = TextStyle(
    fontSize: kIsDesktop
        ? 24
        : kIsApple
            ? 17
            : 19,
    fontWeight: kIsDesktop
        ? FontWeight.w800
        : kIsApple
            ? FontWeight.w600
            : FontWeight.w700,
    color: Colors.white,
  );

  // Search Spotify Tracks
  void search() async {
    final result = await SearchSpotify().search(context, query);

    setState(() {
      // Track
      final List<dynamic> trackItems = result["tracks"]["items"];
      tracks = trackItems.map((item) => sp.Track.fromJson(item)).toList();

      // Artist
      final List<dynamic> artistItems = result["artists"]["items"];

      // Playlists
      final List<dynamic> playlistsItems = result["playlists"]["items"];

      artists = artistItems.isNotEmpty
          ? artistItems.map((item) {
              return Artist(
                id: item["id"],
                name: item["name"],
                image: item["images"].isNotEmpty
                    ? calculateWantedResolution(item["images"], 300, 300)
                    : "",
              );
            }).toList()
          : [];

      // Albums
      final List<dynamic> albumItems = result["albums"]["items"];
      albums = albumItems.isNotEmpty
          ? albumItems.map((item) {
              return Album(
                id: item["id"],
                name: item["name"],
                type: item["album_type"],
                artists: item["artists"].map((artist) {
                  return artist["name"]; //{artist["id"]: artist["name"]};
                }).toList(),
                image: calculateWantedResolution(item["images"], 300, 300),
              );
            }).toList()
          : [];

      playlists = playlistsItems.isNotEmpty
          ? playlistsItems.map((item) {
              return Playlist(
                id: item["id"],
                name: item["name"],
                image: item["images"].isNotEmpty
                    ? calculateWantedResolution(item["images"], 300, 300)
                    : "",
                description: item["description"],
              );
            }).toList()
          : [];
    });
  }

  // Listen For Query Parameter Change
  @override
  void didUpdateWidget(covariant SearchPhone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      // If Query Parameter Changed Do Search Function
      setState(() {
        query = widget.query;
      });
      search();
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: true) as AudioServiceHandler;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: tracks.isEmpty
          ? SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              key: const ValueKey(true), // TODO: Shimmer
            )
          : Scrollbar(
              controller: scrollController,
              child: SingleChildScrollView(
                key: const ValueKey(false),
                controller: scrollController,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: Scaffold.of(context).appBarMaxHeight == null
                        ? MediaQuery.of(context).padding.top +
                            AppBar().preferredSize.height +
                            20
                        : Scaffold.of(context).appBarMaxHeight! + 20,
                    // bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    children: [
                      if (artists.isNotEmpty)
                        searchResultText(AppLocalizations.of(context)!.artists,
                            suggestionHeader),
                      if (artists.isNotEmpty) razh(10),
                      if (artists.isNotEmpty)
                        ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: artists.length > 3 ? 3 : artists.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return SearchResultTile(
                              data: artists[index],
                              type: TileType.artist,
                              onTap: () {
                                // TODO: something
                              },
                            );
                          },
                        ),
                      if (albums.isNotEmpty) razh(15),
                      if (albums.isNotEmpty)
                        searchResultText(AppLocalizations.of(context)!.albums,
                            suggestionHeader),
                      if (albums.isNotEmpty) razh(10),
                      if (albums.isNotEmpty)
                        ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: albums.length > 3 ? 3 : albums.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return SearchResultTile(
                              data: albums[index],
                              type: TileType.album,
                              onTap: () {
                                //TODO: something
                              },
                            );
                          },
                        ),
                      if (tracks.isNotEmpty) razh(15),
                      if (tracks.isNotEmpty)
                        searchResultText(AppLocalizations.of(context)!.tracks,
                            suggestionHeader),
                      if (tracks.isNotEmpty) razh(10),
                      if (tracks.isNotEmpty)
                        ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: tracks.length > 50 ? 50 : tracks.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return SearchResultTile(
                              data: tracks[index],
                              type: TileType.track,
                              trailing: SizedBox(
                                height: 40,
                                width: 20,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: loading.contains(tracks[index].id)
                                      ? const CircularProgressIndicator
                                          .adaptive(
                                          key: ValueKey(true),
                                        )
                                      : StreamBuilder(
                                          key: const ValueKey(false),
                                          stream: audioServiceHandler
                                              .mediaItem.stream,
                                          builder: (context, snapshot) {
                                            final String id =
                                                snapshot.data != null
                                                    ? snapshot.data!.id
                                                        .split(".")[2]
                                                    : "";

                                            return id == tracks[index].id
                                                ? StreamBuilder(
                                                    stream: audioServiceHandler
                                                        .audioPlayer
                                                        .playingStream,
                                                    builder: (context,
                                                        playingStream) {
                                                      return SizedBox(
                                                        width: 20,
                                                        height: 40,
                                                        child:
                                                            MiniMusicVisualizer(
                                                          color: Colors.white,
                                                          radius: 60,
                                                          animate: playingStream
                                                                  .data ??
                                                              false,
                                                        ),
                                                      );
                                                    })
                                                : const SizedBox();
                                          },
                                        ),
                                ),
                              ),
                              onTap: () async {
                                final playNew =
                                    audioServiceHandler.mediaItem.value != null
                                        ? audioServiceHandler
                                                .mediaItem.value!.id
                                                .split(".")[2] !=
                                            tracks[index].id
                                        : true;
                                if (playNew) {
                                  await TrackMetadata().checkTrackExists(
                                    context,
                                    tracks[index].id,
                                    (stid) {
                                      setState(() {
                                        if (!loading.contains(stid)) {
                                          loading.add(stid);
                                        }
                                      });
                                    },
                                    (stid) {
                                      setState(() {
                                        loading.remove(stid);
                                      });
                                    },
                                    (duration) async {
                                      await TrackMetadata().getLyrics(
                                        context,
                                        tracks[index].name,
                                        tracks[index]
                                            .artists
                                            .map((artist) => artist.name)
                                            .join(', '),
                                        duration,
                                        tracks[index].album != null
                                            ? tracks[index].album!.name
                                            : "",
                                        (lyrics, duration) async {
                                          print(lyrics["plainLyrics"]);

                                          final String blurHash =
                                              tracks[index].album != null
                                                  ? await BlurhashFFI.encode(
                                                      NetworkImage(
                                                        calculateBestImageForTrack(
                                                            tracks[index]
                                                                .album!
                                                                .images),
                                                      ),
                                                      componentX: 3,
                                                      componentY: 3,
                                                    )
                                                  : AppConstants().BLURHASH;

                                          UriAudioSource source =
                                              AudioSource.uri(
                                            Uri.parse(
                                                "${AppConstants.SERVER_URL}play_song/${tracks[index].id}"),
                                            tag: MediaItem(
                                                id:
                                                    "search.online.${tracks[index].id}",
                                                title: tracks[index].name,
                                                artist: tracks[index]
                                                    .artists
                                                    .map(
                                                        (artist) => artist.name)
                                                    .join(', '),
                                                album: tracks[index].album != null
                                                    ? tracks[index].album!.name
                                                    : "",
                                                duration: Duration(
                                                    milliseconds:
                                                        (duration * 1000)
                                                            .toInt()),
                                                artUri: Uri.parse(tracks[index]
                                                            .album !=
                                                        null
                                                    ? calculateBestImageForTrack(
                                                        tracks[index]
                                                            .album!
                                                            .images)
                                                    : ''),
                                                artHeaders: {
                                                  "blurhash": blurHash,
                                                  "released":
                                                      tracks[index].album !=
                                                              null
                                                          ? tracks[index]
                                                              .album!
                                                              .releaseDate
                                                          : "",
                                                  "plainLyrics":
                                                      lyrics["plainLyrics"] ??
                                                          "",
                                                  "syncedLyrics":
                                                      lyrics["syncedLyrics"] ??
                                                          "",
                                                }),
                                          );

                                          await audioServiceHandler.initSongs(
                                              songs: [source.tag as MediaItem]);
                                          audioServiceHandler.play();
                                        },
                                      );
                                    },
                                  );
                                } else {
                                  if (audioServiceHandler.audioPlayer.playing) {
                                    await audioServiceHandler.pause();
                                  } else {
                                    await audioServiceHandler.play();
                                  }
                                }
                              },
                            );
                          },
                        ),
                      if (playlists.isNotEmpty) razh(15),
                      if (playlists.isNotEmpty)
                        searchResultText(
                            AppLocalizations.of(context)!.playlists,
                            suggestionHeader),
                      if (playlists.isNotEmpty) razh(10),
                      if (playlists.isNotEmpty)
                        ListView.builder(
                          padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).padding.bottom),
                          itemCount:
                              playlists.length > 25 ? 25 : playlists.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return SearchResultTile(
                              data: playlists[index],
                              type: TileType.playlist,
                              onTap: () {
                                print(playlists[index].id);
                                Navigations().nextScreen(
                                    context,
                                    PlaylistPhone(
                                      playlist: playlists[index],
                                    ));
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
