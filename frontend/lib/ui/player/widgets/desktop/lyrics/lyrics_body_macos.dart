import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../../data/repositories/player/media_items.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../utils/result.dart';
import '../../../../album/widgets/phone/album_phone.dart';
import '../../../../artist/widgets/phone/artist_phone.dart';
import '../../../../core/ui/image/image_desktop.dart';
import '../../../../core/ui/phone/buttons/icon_button.dart';
import '../../../../core/ui/space.dart';
import '../../../../shell/view_models/shell_view_model.dart';
import '../../../view_models/now_playing_view_model.dart';
import '../../../view_models/player_view_model.dart';
import 'lyrics_desktop.dart';
import 'play_control_desktop.dart';
import 'track_progress_desktop.dart';

class LyricsBodyMacos extends StatelessWidget {
  final NowPlayingViewModel nowPlaying;
  final MediaItem mediaItem;
  final PlayerViewModel player;
  final String artistJson;
  final bool mix;
  final Size size;
  const LyricsBodyMacos({
    super.key,
    required this.mediaItem,
    required this.player,
    required this.artistJson,
    required this.nowPlaying,
    required this.size,
    required this.mix,
  });

  @override
  Widget build(BuildContext context) {
    final artists = decodeArtistRefs(artistJson);
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            width: (size.width - 200) / 2,
            height: size.height - 60,
            child: Column(
              children: [
                SizedBox(
                  height: size.height > 685
                      ? (size.height - 60) - 190 < (size.width - 200) / 2
                            ? (size.height - 60) - 190
                            : null
                      : (size.height - 60) - 130 < (size.width - 200) / 2
                      ? (size.height - 60) - 130
                      : null,
                  child: TrackImageDesktop(
                    lyricsOn: false,
                    fullscreenPlay: false,
                    image: (mediaItem.artUri?.toString() ?? ''),
                    stid: context.player.currentStid.value,
                    player: player,
                  ),
                ),
                Expanded(child: Container()),
                StreamBuilder(
                  key: ValueKey(mediaItem.id),
                  stream: player.playbackState,
                  builder: (context, playbackState) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              SizedBox(
                                width: size.width - 30,
                                child: AnimatedAlign(
                                  alignment: playbackState.data != null
                                      ? playbackState.data!.playing
                                            ? Alignment.center
                                            : Alignment.centerLeft
                                      : Alignment.centerLeft,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.fastEaseInToSlowEaseOut,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        Text(
                                          mediaItem.title,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: size.width - 30,
                                height: 22,
                                child: AnimatedAlign(
                                  alignment: playbackState.data != null
                                      ? playbackState.data!.playing
                                            ? Alignment.center
                                            : Alignment.centerLeft
                                      : Alignment.centerLeft,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.fastEaseInToSlowEaseOut,
                                  child: SingleChildScrollView(
                                    scrollDirection:
                                        Axis.horizontal, // Prevents wrapping
                                    child: Row(
                                      children: List.generate(artists.length, (
                                        index,
                                      ) {
                                        final artist = artists[index];
                                        return CupertinoButton(
                                          padding: EdgeInsets.zero,
                                          onPressed: () async {
                                            final result = await context.shell
                                                .artist(
                                                  id: artist.id,
                                                  name: artist.name ?? '',
                                                );
                                            if (result case Ok(:final value)
                                                when context.mounted) {
                                              await showMacosSheet(
                                                context: context,
                                                builder: (_) => ArtistPhone(
                                                  artist: value,
                                                  context: context,
                                                ),
                                              );
                                            }
                                          },
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                artist.name ?? '',
                                                style: const TextStyle(
                                                  fontSize: 18.5,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              if (index != artists.length - 1)
                                                const Text(
                                                  ', ',
                                                  style: TextStyle(
                                                    fontSize: 18.5,
                                                    fontWeight: FontWeight.w400,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Row(
                              children: [
                                Tooltip(
                                  message: 'Shazam',
                                  child: Container(
                                    width: mix ? 25 : 0,
                                    height: mix ? 25 : 0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(60),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(200),
                                          spreadRadius: 3,
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        await context.shell.shazam(
                                          mediaItem.id.split('.')[2],
                                        );
                                      },
                                      child: Image.asset(
                                        'assets/icons/shazam.png',
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                razw(10),
                                Tooltip(
                                  message: AppLocalizations.of(context)
                                      .fullscreen,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(60),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(200),
                                          spreadRadius: 3,
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: iconButton(
                                      CupertinoIcons.fullscreen,
                                      Colors.white,
                                      () {
                                        context.shell.fullscreenPlaying.value =
                                            true;
                                      },
                                      edgeInsets: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: DesktopTrackProgress(
                    fullscreen: false,
                    album: mediaItem.album ?? '',
                    duration: mediaItem.duration,
                    showAlbum: (_) async {
                      if (mediaItem.album != null) {
                        final result = await context.shell.album(
                          mediaItem.albumId,
                        );
                        if (result case Ok(:final value) when context.mounted) {
                          await showMacosSheet(
                            context: context,
                            builder: (_) =>
                                AlbumPhone(album: value, context: context),
                          );
                        }
                      }
                    },
                  ),
                ),
                if (size.height >= 685)
                  StreamBuilder(
                    stream: player.playbackState,
                    builder: (context, playbackState) {
                      return PlayControl(
                        mediaItem: mediaItem,
                        onTap: (_) {},
                        thisTrackPlaying:
                            context.player.currentStid.value ==
                            mediaItem.id.split('.')[2],
                        playbackState: playbackState,
                      );
                    },
                  ),
                Expanded(child: Container()),
              ],
            ),
          ),
        ),
        Flexible(
          child: SizedBox(
            width: (size.width - 200) / 2,
            height: size.height - 60,
            child: Column(
              children: [
                LyricsDesktop(
                  plainLyrics: nowPlaying.plainLyrics.split('\n'),
                  syncedLyrics: [...nowPlaying.syncedLyrics.split('\n')],
                  lyricsOn: nowPlaying.lyricsOn,
                  useSyncedLyrics: nowPlaying.useSyncedLyric,
                  syncTimeDelay: nowPlaying.syncTimeDelay,
                  stid: mediaItem.id.split('.')[2],
                  fullscreenPlaying: false,
                  onChangeUseSyncedLyrics: nowPlaying.toggleUseSyncedLyrics,
                  plus: nowPlaying.increaseSyncTimeDelay,
                  minus: nowPlaying.decreaseSyncTimeDelay,
                  resetSyncTimeDelay: nowPlaying.resetSyncTimeDelay,
                  saveSyncTimeDelay: nowPlaying.saveSyncTimeDelay,
                ),
                if (size.height < 685)
                  StreamBuilder(
                    stream: player.playbackState,
                    builder: (context, playbackState) {
                      return PlayControl(
                        mediaItem: mediaItem,
                        onTap: (_) {},
                        thisTrackPlaying:
                            context.player.currentStid.value ==
                            mediaItem.id.split('.')[2],
                        playbackState: playbackState,
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
