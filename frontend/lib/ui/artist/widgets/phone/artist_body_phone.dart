import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../domain/models/catalog/album.dart';
import '../../../../domain/models/catalog/artist.dart';
import '../../../../domain/models/catalog/track.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/navigation.dart';
import '../../../../utils/platform.dart';
import '../../../album/widgets/phone/album_phone.dart';
import '../../../core/ui/space.dart';
import '../../../player/view_models/player_view_model.dart';
import '../../../search/widgets/phone/search_result_text.dart';
import '../../../search/widgets/phone/search_result_tile.dart';
import 'artist_phone.dart';

class ArtistBodyPhone extends StatefulWidget {
  final BuildContext context;
  final Artist artist;
  final List<Track> tracks;
  final List<Album> albums;
  final List<Album> otherAlbums;
  final List<Artist> artists;
  final List<String> loading;
  const ArtistBodyPhone({
    super.key,
    required this.artist,
    required this.tracks,
    required this.albums,
    required this.artists,
    required this.loading,
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
    final player = context.player;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.albums.isNotEmpty)
              searchResultText(
                AppLocalizations.of(context).albums,
                suggestionHeader,
              ),
            if (widget.albums.isNotEmpty) razh(10),
            if (widget.albums.isNotEmpty)
              ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: widget.albums.length > 15
                    ? 15
                    : widget.albums.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return SearchResultTile(
                    key: ValueKey('album.${widget.albums[index].id}'),
                    pushWhite: true,
                    data: widget.albums[index],
                    type: TileType.album,
                    onTap: () {
                      Navigator.pop(context);
                      /*  Navigations().nextScreen(
                          context,
                          AlbumPhone(
                            album: widget.albums[index],
                            context: widget.context,
                          )); */
                      if (kIsMobile) {
                        Navigations().nextScreen(
                          context,
                          AlbumPhone(
                            context: context,
                            album: widget.albums[index],
                          ),
                        );
                      } else {
                        showMacosSheet(
                          context: context,
                          builder: (contextt) => AlbumPhone(
                            context: context,
                            album: widget.albums[index],
                          ),
                          routeSettings: const RouteSettings(),
                        );
                      }
                    },
                  );
                },
              ),
            if (widget.albums.isNotEmpty) razh(50),
            if (widget.otherAlbums.isNotEmpty)
              searchResultText(
                AppLocalizations.of(context).singlesandcompilations,
                suggestionHeader,
              ),
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
                    key: ValueKey('album.${widget.otherAlbums[index].id}'),
                    pushWhite: true,
                    data: widget.otherAlbums[index],
                    type: TileType.album,
                    onTap: () {
                      Navigator.pop(context);
                      if (kIsMobile) {
                        Navigations().nextScreen(
                          context,
                          AlbumPhone(
                            context: context,
                            album: widget.otherAlbums[index],
                          ),
                        );
                      } else {
                        showMacosSheet(
                          context: context,
                          builder: (contextt) => AlbumPhone(
                            context: context,
                            album: widget.otherAlbums[index],
                          ),
                          routeSettings: const RouteSettings(),
                        );
                      }
                    },
                  );
                },
              ),
            if (widget.tracks.isNotEmpty) razh(50),
            if (widget.tracks.isNotEmpty) razh(15),
            if (widget.tracks.isNotEmpty)
              searchResultText(
                AppLocalizations.of(context).topten,
                suggestionHeader,
              ),
            if (widget.tracks.isNotEmpty) razh(10),
            if (widget.tracks.isNotEmpty)
              ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: widget.tracks.length > 50
                    ? 50
                    : widget.tracks.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return SearchResultTile(
                    key: ValueKey('album.${widget.tracks[index].id}'),
                    pushWhite: true,
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
                                stream: player.currentItemStream,
                                builder: (context, snapshot) {
                                  final String id = snapshot.data != null
                                      ? snapshot.data!.id.split('.')[2]
                                      : '';

                                  return id == widget.tracks[index].id
                                      ? StreamBuilder(
                                          stream: player.playingStream,
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
                                          },
                                        )
                                      : const SizedBox();
                                },
                              ),
                      ),
                    ),
                    onTap: () => player.playSingle(
                      widget.tracks[index],
                      collectionId: 'search.single',
                    ),
                  );
                },
              ),
            if (widget.artists.isNotEmpty) razh(50),
            if (widget.artists.isNotEmpty)
              searchResultText(
                AppLocalizations.of(context).relatedartists,
                suggestionHeader,
              ),
            if (widget.artists.isNotEmpty) razh(10),
            if (widget.artists.isNotEmpty)
              ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: widget.artists.length > 10
                    ? 10
                    : widget.artists.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return SearchResultTile(
                    key: ValueKey('album.${widget.artists[index].id}'),
                    pushWhite: true,
                    data: widget.artists[index],
                    type: TileType.artist,
                    onTap: () {
                      Navigator.pop(context);
                      Navigations().nextScreen(
                        widget.context,
                        ArtistPhone(
                          context: widget.context,
                          artist: widget.artists[index],
                        ),
                      );
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
