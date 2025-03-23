import 'dart:ui';
import '../../../exports.dart';
import 'artist_body_phone.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

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

    final List<Album> allAlbums =
        Album.fromMapList(data["albums"] as List<dynamic>);

    setState(() {
      blurhash = blurHash;
      albums = allAlbums.where((album) => album.type == "album").toList();
      otherAlbums = allAlbums.where((album) => album.type != "album").toList();
      tracks = Track.fromMapList(data["tracks"] as List<dynamic>);
      //artists = Artist.fromMapList(data["artists"] as List<dynamic>);
      showBody = true;
    });

    await DatabaseHelper().insertLFHArtists(widget.artist.id);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return ClipRRect(
      borderRadius: kIsDesktop ? BorderRadius.circular(15) : BorderRadius.zero,
      child: SizedBox(
        width: kIsDesktop ? 800 : size.width,
        height: kIsDesktop ? 500 : size.height,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: showBody
              ? Stack(
                  children: [
                    SizedBox(
                        width: kIsDesktop ? 800 : size.width,
                        height: kIsDesktop ? 500 : size.height,
                        child: ClipRRect(
                            borderRadius: kIsDesktop
                                ? BorderRadius.circular(15)
                                : BorderRadius.zero,
                            child: BlurHash(
                                key: ValueKey(blurhash), hash: blurhash))),
                    Container(
                      width: kIsDesktop ? 800 : size.width,
                      height: kIsDesktop ? 500 : size.height,
                      decoration: BoxDecoration(
                          color: Colors.black.withAlpha(50),
                          borderRadius:
                              kIsDesktop ? BorderRadius.circular(15) : null),
                      child: Scaffold(
                        extendBodyBehindAppBar: true,
                        extendBody: true,
                        backgroundColor: Col.transp,
                        body: Theme(
                          data: ThemeData(
                              scrollbarTheme: kIsDesktop
                                  ? ScrollbarThemeData(
                                      thumbColor: MaterialStateProperty.all(
                                          Colors.white.withAlpha(100)),
                                    )
                                  : null),
                          child: Scrollbar(
                            controller: scrollController,
                            child: CustomScrollView(
                              controller: scrollController,
                              slivers: [
                                SliverAppBar(
                                  snap: false,
                                  collapsedHeight: kToolbarHeight,
                                  expandedHeight: kIsMacOS
                                      ? 400
                                      : MediaQuery.of(context).size.height / 2,
                                  floating: false,
                                  pinned: true,
                                  stretch: true,
                                  backgroundColor: Col.transp,
                                  surfaceTintColor: Col.transp,
                                  automaticallyImplyLeading: false,
                                  title: Row(
                                    children: [
                                      backButton(context),
                                      razw(15),
                                      Expanded(
                                        child: Text(
                                          widget.artist.name,
                                          style: const TextStyle(
                                            fontSize: 23,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  flexibleSpace: ClipRRect(
                                    borderRadius: kIsDesktop
                                        ? BorderRadius.circular(15)
                                        : BorderRadius.zero,
                                    child: FlexibleSpaceBar(
                                      titlePadding: EdgeInsets.zero,
                                      centerTitle: true,
                                      title: AppBar(
                                        surfaceTintColor: Col.transp,
                                        backgroundColor: useBlur.value
                                            ? Col.transp
                                            : Col.realBackground.withAlpha(((MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height /
                                                                2 <=
                                                            scrollControllerOffset
                                                        ? 1
                                                        : scrollControllerOffset /
                                                            (MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height /
                                                                2)) *
                                                    150)
                                                .toInt()),
                                        automaticallyImplyLeading: false,
                                        flexibleSpace: Opacity(
                                          opacity: size.height / 2 <=
                                                  scrollControllerOffset
                                              ? 1
                                              : scrollControllerOffset /
                                                  (size.height / 2),
                                          child: ClipRRect(
                                            borderRadius: kIsDesktop
                                                ? BorderRadius.circular(15)
                                                : BorderRadius.zero,
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                sigmaX: useBlur.value ? 10 : 0,
                                                sigmaY: useBlur.value ? 10 : 0,
                                              ),
                                              child: Container(),
                                            ),
                                          ),
                                        ),
                                      ),
                                      background: Stack(
                                        children: [
                                          Center(
                                            child: SizedBox(
                                              width: kIsMacOS
                                                  ? 300
                                                  : MediaQuery.of(context)
                                                          .size
                                                          .width -
                                                      60,
                                              height: kIsMacOS
                                                  ? 300
                                                  : MediaQuery.of(context)
                                                          .size
                                                          .width -
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
                                                        BorderRadius.circular(
                                                            15),
                                                    child:
                                                        widget.artist.image !=
                                                                ""
                                                            ? ImageCompatible(
                                                                image: widget
                                                                    .artist
                                                                    .image,
                                                              )
                                                            : Container(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width -
                                                                    60,
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width -
                                                                    60,
                                                                decoration: BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            15),
                                                                    color: Col
                                                                        .primaryCard),
                                                                child: Center(
                                                                  child: Icon(
                                                                    AppIcons
                                                                        .blankArtist,
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
                    ),
                  ],
                )
              : loadingScaffold(context, const ValueKey(false)),
        ),
      ),
    );
  }
}
