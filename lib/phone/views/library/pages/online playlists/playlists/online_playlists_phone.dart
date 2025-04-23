import 'dart:ui';
import 'package:pongo/exports.dart';

class OnlinePlaylistsPhone extends StatefulWidget {
  const OnlinePlaylistsPhone({super.key});

  @override
  State<OnlinePlaylistsPhone> createState() => _OnlinePlaylistsPhoneState();
}

class _OnlinePlaylistsPhoneState extends State<OnlinePlaylistsPhone> {
  // Playlists
  List<Map<String, dynamic>> playlists = [];

  // Playlists length
  int playlistsLength = 0;

  // Show body
  bool showBody = false;

  // Memory images
  List<MemoryImage?> coverImages = [];

  @override
  void initState() {
    super.initState();
    initPlaylists();
  }

  initPlaylists() async {
    // First get length
    int length = await DatabaseHelper().queryOnlinePlaylistsLength();
    setState(() {
      playlistsLength = length;
    });

    // Then get all playlists
    List<Map<String, dynamic>> temp =
        await DatabaseHelper().queryAllOnlinePlaylists();

    List<MemoryImage?> coverImges = [];
    for (Map playlist in temp) {
      if (playlist["cover"] != null) {
        coverImges.add(MemoryImage(playlist["cover"]));
      } else {
        coverImges.add(null);
      }
    }

    setState(() {
      playlists = temp.toList();
      coverImages = coverImges;
      showBody = true;
    });
  }

  removePlaylist(int index) {
    setState(() {
      playlists.removeAt(index);
    });
  }

  void newPlaylist() {
    OpenPlaylist().show(
      context,
      PlaylistHandler(
        type: PlaylistHandlerType.online,
        function: PlaylistHandlerFunction.createPlaylist,
        track: null,
      ),
    );
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
              child: Scaffold(
                extendBodyBehindAppBar: true,
                extendBody: true,
                body: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      snap: true,
                      floating: true,
                      pinned: true,
                      stretch: true,
                      backgroundColor: useBlur.value
                          ? Col.transp
                          : Col.realBackground.withAlpha(AppConstants().noBlur),
                      automaticallyImplyLeading: false,
                      expandedHeight:
                          kIsApple ? size.height / 5 : size.height / 4,
                      title: Row(
                        children: [
                          backButton(context),
                          Expanded(
                            child: Container(),
                          ),
                          backLikeButton(
                            context,
                            AppIcons.add,
                            newPlaylist,
                          ),
                        ],
                      ),
                      flexibleSpace: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                              sigmaX: useBlur.value ? 10 : 0,
                              sigmaY: useBlur.value ? 10 : 0),
                          child: FlexibleSpaceBar(
                            centerTitle: true,
                            title: Text(
                              AppLocalizations.of(context).onlineplaylists,
                              style: TextStyle(
                                  fontSize: kIsApple ? 25 : 30,
                                  fontWeight: kIsApple
                                      ? FontWeight.w700
                                      : FontWeight.w800,
                                  color: Col.text),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                            ),
                            stretchModes: const [
                              StretchMode.zoomBackground,
                              StretchMode.blurBackground,
                              StretchMode.fadeTitle,
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: playlists.isNotEmpty
                          ? Column(
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: playlists.length,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        top: index == 0
                                            ? AppBar().preferredSize.height *
                                                1.5
                                            : 0,
                                        bottom: index == playlists.length - 1
                                            ? MediaQuery.of(context)
                                                    .padding
                                                    .bottom +
                                                10
                                            : 0,
                                      ),
                                      child: PlaylistTile(
                                        first: index == 0,
                                        last: index == playlists.length - 1,
                                        cover: coverImages[index]?.bytes,
                                        title: playlists[index]["title"],
                                        subtitle: AppLocalizations.of(context)
                                            .onlineplaylist,
                                        function: () async {
                                          final String blurHash =
                                              coverImages[index] != null
                                                  ? await BlurhashFFI.encode(
                                                      coverImages[index]!,
                                                      componentX: 2,
                                                      componentY: 2,
                                                    )
                                                  : AppConstants().BLURHASH;

                                          Navigations().nextScreen(
                                              context,
                                              OnlinePlaylistPhone(
                                                opid: playlists[index]["opid"],
                                                title: playlists[index]
                                                    ["title"],
                                                cover: coverImages[index],
                                                blurhash: blurHash,
                                                updateCover: (playlistCover) {
                                                  setState(() {
                                                    coverImages[index] =
                                                        playlistCover;
                                                  });
                                                },
                                                updateTitle: (newTitle) {
                                                  initPlaylists();
                                                },
                                              ));
                                        },
                                        removePlaylist: () {
                                          continueCancelActionSheet(
                                              context,
                                              AppLocalizations.of(context)
                                                  .areyousure,
                                              AppLocalizations.of(context)
                                                  .removeplaylist, () async {
                                            await DatabaseHelper()
                                                .removeOnlinePlaylist(
                                                    playlists[index]["opid"]);
                                            setState(() {
                                              playlistsLength--;
                                              playlists.removeAt(index);
                                              coverImages.removeAt(index);
                                            });
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                razh(100),
                                iconButton(AppIcons.add, Col.icon, newPlaylist,
                                    size: 60),
                                textButton(
                                    AppLocalizations.of(context)
                                        .createnewplaylistnow,
                                    newPlaylist,
                                    TextStyle(color: Col.text),
                                    edgeInsets: EdgeInsets.zero)
                              ],
                            ),
                    )
                  ],
                ),
              ),
            )
          : loadingScaffold(context, const ValueKey(false)),
    );
  }
}
