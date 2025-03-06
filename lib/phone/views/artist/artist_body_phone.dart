import 'package:pongo/exports.dart';

class ArtistBodyPhone extends StatefulWidget {
  final BuildContext context;
  final Artist artist;
  final List<Track> tracks;
  final List<Album> albums;
  final List<Album> otherAlbums;
  final List<Artist> artists;
  final List<String> loading;
  final Function(String) loadingAdd;
  final Function(String) loadingRemove;
  const ArtistBodyPhone({
    super.key,
    required this.artist,
    required this.tracks,
    required this.albums,
    required this.artists,
    required this.loading,
    required this.loadingAdd,
    required this.loadingRemove,
    required this.context,
    required this.otherAlbums,
  });

  @override
  State<ArtistBodyPhone> createState() => _ArtistBodyPhoneState();
}

class _ArtistBodyPhoneState extends State<ArtistBodyPhone> {
  // Text style
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

  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.albums.isNotEmpty) razh(15),
            if (widget.albums.isNotEmpty)
              searchResultText(
                  AppLocalizations.of(context)!.albums, suggestionHeader),
            if (widget.albums.isNotEmpty) razh(10),
            if (widget.albums.isNotEmpty)
              ListView.builder(
                padding: EdgeInsets.zero,
                itemCount:
                    widget.albums.length > 15 ? 15 : widget.albums.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return SearchResultTile(
                    key: ValueKey("album.${widget.albums[index].id}"),
                    data: widget.albums[index],
                    type: TileType.album,
                    onTap: () {
                      Navigator.pop(context);
                      Navigations().nextScreen(
                          context,
                          AlbumPhone(
                            album: widget.albums[index],
                            context: widget.context,
                          ));
                    },
                  );
                },
              ),
            if (widget.albums.isNotEmpty) razh(50),
            if (widget.albums.isNotEmpty) razh(15),
            if (widget.albums.isNotEmpty)
              searchResultText(
                  AppLocalizations.of(context)!.singlesandcompilations,
                  suggestionHeader),
            if (widget.otherAlbums.isNotEmpty) razh(10),
            if (widget.otherAlbums.isNotEmpty)
              ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: widget.otherAlbums.length > 15
                    ? 15
                    : widget.otherAlbums.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return SearchResultTile(
                    key: ValueKey("album.${widget.otherAlbums[index].id}"),
                    data: widget.otherAlbums[index],
                    type: TileType.album,
                    onTap: () {
                      Navigator.pop(context);
                      Navigations().nextScreen(
                          context,
                          AlbumPhone(
                            album: widget.otherAlbums[index],
                            context: widget.context,
                          ));
                    },
                  );
                },
              ),
            if (widget.tracks.isNotEmpty) razh(50),
            if (widget.tracks.isNotEmpty) razh(15),
            if (widget.tracks.isNotEmpty)
              searchResultText(
                  AppLocalizations.of(context)!.topten, suggestionHeader),
            if (widget.tracks.isNotEmpty) razh(10),
            if (widget.tracks.isNotEmpty)
              ListView.builder(
                padding: EdgeInsets.zero,
                itemCount:
                    widget.tracks.length > 50 ? 50 : widget.tracks.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return SearchResultTile(
                    key: ValueKey("album.${widget.tracks[index].id}"),
                    data: widget.tracks[index],
                    type: TileType.track,
                    trailing: SizedBox(
                      height: 40,
                      width: 20,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: widget.loading.contains(widget.tracks[index].id)
                            ? const CircularProgressIndicator.adaptive(
                                key: ValueKey(true),
                              )
                            : StreamBuilder(
                                key: const ValueKey(false),
                                stream: audioServiceHandler.mediaItem.stream,
                                builder: (context, snapshot) {
                                  final String id = snapshot.data != null
                                      ? snapshot.data!.id.split(".")[2]
                                      : "";

                                  return id == widget.tracks[index].id
                                      ? StreamBuilder(
                                          stream: audioServiceHandler
                                              .audioPlayer.playingStream,
                                          builder: (context, playingStream) {
                                            return const SizedBox(
                                              width: 20,
                                              height: 40,
                                              /*    child: MiniMusicVisualizer(
                                                color: Colors.white,
                                                radius: 60,
                                                animate:
                                                    playingStream.data ?? false,
                                              ), */
                                            );
                                          })
                                      : const SizedBox();
                                },
                              ),
                      ),
                    ),
                    onTap: () async {
                      PlaySingle().onlineTrack(
                          context,
                          audioServiceHandler,
                          "search.single.",
                          widget.tracks[index],
                          widget.loadingAdd,
                          widget.loadingRemove);
                      if (useMix.value) {
                        Mix().getMix(context, widget.tracks[index]);
                      }
                    },
                  );
                },
              ),
            if (widget.artists.isNotEmpty) razh(50),
            if (widget.artists.isNotEmpty)
              searchResultText(AppLocalizations.of(context)!.relatedartists,
                  suggestionHeader),
            if (widget.artists.isNotEmpty) razh(10),
            if (widget.artists.isNotEmpty)
              ListView.builder(
                padding: EdgeInsets.zero,
                itemCount:
                    widget.artists.length > 10 ? 10 : widget.artists.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return SearchResultTile(
                    key: ValueKey("album.${widget.artists[index].id}"),
                    data: widget.artists[index],
                    type: TileType.artist,
                    onTap: () {
                      Navigator.pop(context);
                      Navigations().nextScreen(
                          widget.context,
                          ArtistPhone(
                            context: widget.context,
                            artist: widget.artists[index],
                          ));
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
