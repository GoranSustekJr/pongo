import 'dart:ui';
import 'package:blurhash_ffi/blurhash.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:pongo/shared/utils/API%20requests/artist.dart';
import '../../../exports.dart';
import 'artist_body_phone.dart';

class ArtistPhone extends StatefulWidget {
  final BuildContext context;
  final Artist artist;
  const ArtistPhone({super.key, required this.artist, required this.context});

  @override
  State<ArtistPhone> createState() => _ArtistPhoneState();
}

class _ArtistPhoneState extends State<ArtistPhone> {
  // Show body
  bool showBody = false;

  // Albums
  List<Album> albums = [];

  // Compilations and appears on
  List<Album> otherAlbums = [];

  // Top tracks
  List<Track> tracks = [];

  // Related artists
  List<Artist> artists = [];

  // Loading list
  List<String> loading = [];

  // Blurhash
  String blurhash = "";

  // Scroll controller
  late ScrollController scrollController;

  // Offset
  double scrollControllerOffset = 0;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(scrollControllerListener);

    initArtist();
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

  void initArtist() async {
    final data = await ArtistSpotify().get(context, widget.artist.id);

    final blurHash = widget.artist.image != ""
        ? await BlurhashFFI.encode(
            NetworkImage(
              widget.artist.image,
            ),
            componentX: 3,
            componentY: 3,
          )
        : AppConstants().BLURHASH;

    final List<Album> allAlbums = (data["albums"] as List<dynamic>)
        .map((album) => Album(
              id: album["id"],
              type: album["album_group"],
              name: album["name"],
              artists: (album["artists"] as List<dynamic>)
                  .map((artist) => artist["name"])
                  .toList(),
              image: calculateWantedResolution(album["images"], 300, 300),
            ))
        .toList();

    print("All albums length; ${allAlbums.length}");

    setState(() {
      blurhash = blurHash;
      albums = allAlbums.where((album) => album.type == "album").toList();
      otherAlbums = allAlbums.where((album) => album.type != "album").toList();
      tracks = (data["tracks"] as List<dynamic>)
          .map(
            (track) => Track(
              album: AlbumTrack(
                id: track["album"]["id"],
                name: track["album"]["name"],
                images: (track["album"]["images"] as List<dynamic>)
                    .map((image) => AlbumImagesTrack(
                        url: image["url"],
                        height: image["height"],
                        width: image["width"]))
                    .toList(),
                releaseDate: track["album"]["release_date"],
              ),
              id: track["id"],
              name: track["name"],
              artists: (track["artists"] as List<dynamic>)
                  .map((artist) =>
                      ArtistTrack(id: artist["id"], name: artist["name"]))
                  .toList(),
            ),
          )
          .toList();
      artists = (data["artists"] as List<dynamic>)
          .map((artist) => Artist(
                id: artist["id"],
                name: artist["name"],
                image: calculateBestImageForTrack(
                    (artist["images"] as List<dynamic>)
                        .map((image) => AlbumImagesTrack(
                            url: image["url"],
                            height: image["height"],
                            width: image["width"]))
                        .toList()),
              ))
          .toList();
      showBody = true;
    });

    await DatabaseHelper().insertLFHArtists(widget.artist.id);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: showBody
          ? Stack(
              children: [
                BlurHash(key: ValueKey(blurhash), hash: blurhash),
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
                                        widget.artist.name,
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
                                            child: widget.artist.image != ""
                                                ? CachedNetworkImage(
                                                    imageUrl:
                                                        widget.artist.image,
                                                  )
                                                : Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width -
                                                            60,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width -
                                                            60,
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15),
                                                        color: Col.primaryCard),
                                                    child: Center(
                                                      child: Icon(
                                                        AppIcons.blankArtist,
                                                        size: 70,
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
                          SliverToBoxAdapter(
                            child: ArtistBodyPhone(
                              context: widget.context,
                              artist: widget.artist,
                              tracks: tracks,
                              albums: albums,
                              otherAlbums: otherAlbums,
                              artists: artists,
                              loading: loading,
                              loadingAdd: (stid) {
                                if (!loading.contains(stid)) {
                                  setState(() {
                                    loading.add(stid);
                                  });
                                }
                              },
                              loadingRemove: (stid) {
                                setState(() {
                                  loading.remove(stid);
                                });
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
