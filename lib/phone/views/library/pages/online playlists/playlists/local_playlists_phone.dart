import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/views/library/pages/local%20playlists/views/local_playlist_phone.dart';

class LocalPlaylistsPhone extends StatefulWidget {
  const LocalPlaylistsPhone({super.key});

  @override
  State<LocalPlaylistsPhone> createState() => _LocalPlaylistsPhoneState();
}

class _LocalPlaylistsPhoneState extends State<LocalPlaylistsPhone> {
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
    int length = await DatabaseHelper().queryLocalPlaylistsLength();
    setState(() {
      playlistsLength = length;
    });

    // Then get all playlists
    List<Map<String, dynamic>> temp =
        await DatabaseHelper().queryAllLocalPlaylists();

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
        type: PlaylistHandlerType.offline,
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
                            CupertinoIcons.add,
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
                              AppLocalizations.of(context).offlineplaylists,
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
                                  itemCount: playlists.length,
                                  shrinkWrap: true,
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
                                            .offlineplaylist,
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
                                              LocalPlaylistPhone(
                                                lpid: playlists[index]["lpid"],
                                                title: playlists[index]
                                                    ["title"],
                                                cover: coverImages[index],
                                                blurhash: blurHash,
                                                updateCover:
                                                    (playlistCover) async {
                                                  await DatabaseHelper()
                                                      .updateLocalPlaylistCover(
                                                          playlists[index]
                                                              ["lpid"],
                                                          playlistCover.bytes);
                                                  setState(() {
                                                    coverImages[index] =
                                                        playlistCover;
                                                  });
                                                },
                                                updateTitle: (newTitle) async {
                                                  await DatabaseHelper()
                                                      .updateLocalPlaylistName(
                                                          playlists[index]
                                                              ["lpid"],
                                                          newTitle);
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
                                                .removeLocalPlaylist(
                                                    playlists[index]["lpid"]);
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
