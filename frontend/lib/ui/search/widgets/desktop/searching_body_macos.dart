import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kr_pull_down_button/pull_down_button.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/catalog/album.dart';
import '../../../../domain/models/catalog/artist.dart';
import '../../../../domain/models/catalog/playlist.dart';
import '../../../../domain/models/catalog/track.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/navigation.dart';
import '../../../../utils/platform.dart';
import '../../../album/widgets/phone/album_phone.dart';
import '../../../app/view_models/app_settings_view_model.dart';
import '../../../artist/widgets/phone/artist_phone.dart';
import '../../../core/app_icons.dart';
import '../../../core/ui/phone/trailing.dart';
import '../../../core/ui/space.dart';
import '../../../core/view_models/track_actions_view_model.dart';
import '../../../player/view_models/player_view_model.dart';
import '../../../playlists/widgets/phone/catalog/playlist_phone.dart';
import '../phone/search_result_text.dart';
import '../phone/search_result_tile.dart';
import '../phone/search_track_pulldown_menu_items.dart';
import 'search_track_pulldown_menu_items_macos.dart';

class SearchingBodyMacos extends StatelessWidget {
  final List<Track> tracks;
  final List<Artist> artists;
  final List<Album> albums;
  final List<Playlist> playlists;
  final List<String> loading;
  final ScrollController scrollController;
  final TextStyle suggestionHeader;
  const SearchingBodyMacos({
    super.key,
    required this.tracks,
    required this.artists,
    required this.albums,
    required this.playlists,
    required this.loading,
    required this.scrollController,
    required this.suggestionHeader,
  });

  @override
  Widget build(BuildContext context) {
    final player = context.player;
    return Scrollbar(
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
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (artists.isNotEmpty &&
                  context.readSettings.searchArtistCount > 0)
                searchResultText(
                  AppLocalizations.of(context).artists,
                  suggestionHeader,
                ),
              if (artists.isNotEmpty &&
                  context.readSettings.searchArtistCount > 0)
                razh(10),
              if (artists.isNotEmpty &&
                  context.readSettings.searchArtistCount > 0)
                ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount:
                      artists.length > context.readSettings.searchArtistCount
                      ? context.readSettings.searchArtistCount
                      : artists.length,
                  shrinkWrap: true,
                  addAutomaticKeepAlives: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return SearchResultTile(
                      key: ValueKey('artist.${artists[index].id}'),
                      pushWhite: false,
                      data: artists[index],
                      type: TileType.artist,
                      onTap: () {
                        if (kIsMobile) {
                          Navigations().nextScreen(
                            context,
                            ArtistPhone(
                              context: context,
                              artist: artists[index],
                            ),
                          );
                        } else {
                          showMacosSheet(
                            context: context,
                            builder: (contextt) => ArtistPhone(
                              context: context,
                              artist: artists[index],
                            ),
                            routeSettings: const RouteSettings(),
                          );
                        }
                      },
                    );
                  },
                ),
              if (artists.isNotEmpty &&
                  context.readSettings.searchArtistCount > 0)
                razh(50),
              if (albums.isNotEmpty &&
                  context.readSettings.searchAlbumCount > 0)
                searchResultText(
                  AppLocalizations.of(context).albums,
                  suggestionHeader,
                ),
              if (albums.isNotEmpty &&
                  context.readSettings.searchAlbumCount > 0)
                razh(10),
              if (albums.isNotEmpty &&
                  context.readSettings.searchAlbumCount > 0)
                ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount:
                      albums.length > context.readSettings.searchAlbumCount
                      ? context.readSettings.searchAlbumCount
                      : albums.length,
                  shrinkWrap: true,
                  addAutomaticKeepAlives: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return SearchResultTile(
                      key: ValueKey('album.${albums[index].id}'),
                      pushWhite: false,
                      data: albums[index],
                      type: TileType.album,
                      onTap: () {
                        if (kIsMobile) {
                          Navigations().nextScreen(
                            context,
                            AlbumPhone(album: albums[index], context: context),
                          );
                        } else {
                          showMacosSheet(
                            context: context,
                            builder: (contextt) => AlbumPhone(
                              album: albums[index],
                              context: contextt,
                            ),
                            routeSettings: const RouteSettings(),
                          );
                        }
                      },
                    );
                  },
                ),
              if (albums.isNotEmpty &&
                  context.readSettings.searchAlbumCount > 0)
                razh(50),
              if (tracks.isNotEmpty &&
                  context.readSettings.searchTrackCount > 0)
                searchResultText(
                  AppLocalizations.of(context).tracks,
                  suggestionHeader,
                ),
              if (tracks.isNotEmpty &&
                  context.readSettings.searchTrackCount > 0)
                razh(10),
              if (tracks.isNotEmpty &&
                  context.readSettings.searchTrackCount > 0)
                StreamBuilder(
                  stream: player.playingStream,
                  builder: (context, playingStream) {
                    return StreamBuilder(
                      key: const ValueKey(false),
                      stream: player.currentItemStream,
                      builder: (context, snapshot) {
                        final String id = snapshot.data != null
                            ? snapshot.data!.id.split('.')[2]
                            : '';

                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount:
                              tracks.length >
                                  context.readSettings.searchTrackCount
                              ? context.readSettings.searchTrackCount
                              : tracks.length,
                          shrinkWrap: true,
                          addAutomaticKeepAlives: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return SearchResultTile(
                              key: ValueKey('track.${tracks[index].id}'),
                              pushWhite: false,
                              data: tracks[index],
                              type: TileType.track,
                              trailing: Row(
                                children: [
                                  SizedBox(
                                    height: 40,
                                    width: 20,
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: loading.contains(tracks[index].id)
                                          ? const CircularProgressIndicator.adaptive(
                                              key: ValueKey(true),
                                            )
                                          : id == tracks[index].id
                                          ? Trailing(
                                              show: !loading.contains(
                                                tracks[index].id,
                                              ),
                                              forceWhite: false,
                                              showThis: id == tracks[index].id,
                                              trailing: const Padding(
                                                padding: EdgeInsets.only(
                                                  right: 10,
                                                ),
                                                child:
                                                    CircularProgressIndicator.adaptive(
                                                      key: ValueKey(true),
                                                    ),
                                              ),
                                            )
                                          : const SizedBox(),
                                    ),
                                  ),
                                  FutureBuilder<bool>(
                                    future: context
                                        .watch<TrackActionsViewModel>()
                                        .isFavourite(tracks[index].id),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return const SizedBox(
                                          width: 50,
                                          height: 20,
                                          child: Center(
                                            child: Icon(
                                              CupertinoIcons
                                                  .exclamationmark_circle,
                                            ),
                                          ),
                                        );
                                      } else {
                                        final bool isFavourite =
                                            snapshot.data ?? false;

                                        return SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: kIsMobile
                                              ? PullDownButton(
                                                  offset: const Offset(30, 30),
                                                  position: PullDownMenuPosition
                                                      .automatic,
                                                  itemBuilder: (context) =>
                                                      searchTrackPulldownMenuItemsApple(
                                                        //TODO: Android
                                                        context,
                                                        tracks[index],
                                                        'search.single',
                                                        isFavourite,
                                                      ),
                                                  buttonBuilder:
                                                      (context, showMenu) =>
                                                          CupertinoButton(
                                                            onPressed: showMenu,
                                                            padding:
                                                                EdgeInsets.zero,
                                                            child: const Icon(
                                                              CupertinoIcons
                                                                  .ellipsis,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                )
                                              : MacosPulldownButton(
                                                  icon: AppIcons.more,
                                                  itemHeight: 30,
                                                  items:
                                                      searchTrackPulldownMenuItemsMacos(
                                                        context,
                                                        tracks[index],
                                                        'search.single',
                                                        isFavourite,
                                                      ),
                                                ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              onTap: () async {
                                await player.playSingle(
                                  tracks[index],
                                  collectionId: 'search.single',
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              if (tracks.isNotEmpty &&
                  context.readSettings.searchTrackCount > 0)
                razh(50),
              if (playlists.isNotEmpty &&
                  context.readSettings.searchPlaylistCount > 0)
                searchResultText(
                  AppLocalizations.of(context).playlists,
                  suggestionHeader,
                ),
              if (playlists.isNotEmpty &&
                  context.readSettings.searchPlaylistCount > 0)
                razh(10),
              if (playlists.isNotEmpty &&
                  context.readSettings.searchPlaylistCount > 0)
                ListView.builder(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  itemCount:
                      playlists.length >
                          context.readSettings.searchPlaylistCount
                      ? context.readSettings.searchPlaylistCount
                      : playlists.length,
                  shrinkWrap: true,
                  addAutomaticKeepAlives: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return SearchResultTile(
                      key: ValueKey('playlist.${playlists[index].id}'),
                      pushWhite: false,
                      data: playlists[index],
                      type: TileType.playlist,
                      onTap: () {
                        if (kIsMobile) {
                          Navigations().nextScreen(
                            context,
                            PlaylistPhone(
                              playlist: playlists[index],
                              context: context,
                            ),
                          );
                        } else {
                          showMacosSheet(
                            context: context,
                            builder: (_) => PlaylistPhone(
                              playlist: playlists[index],
                              context: context,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
