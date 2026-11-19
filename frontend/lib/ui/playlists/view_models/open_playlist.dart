import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';

import 'package:pongo/core/audio/audio_service_handler.dart';
import 'package:pongo/core/state/globals.dart';
import 'package:pongo/features/playlists/models/playlist_handler.dart';

class OpenPlaylist {
  void open(
    context, {
    String? id,
    String? cover,
    String? title,
    String? artist,
    List<Map>? tracks,
    List<String>? playlist,
  }) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    final MediaItem? mediaItem = audioServiceHandler.mediaItem.value;
    showPlaylistHandler.value = true;
    playlistTrackToAddData.value = playlist != null
        ? {
            "playlist": playlist,
            "title": title,
            "cover": cover,
          }
        : tracks != null
            ? {"tracks": tracks}
            : (id != null && cover != null && title != null && artist != null)
                ? {
                    "id": id,
                    "cover": cover,
                    "title": title,
                    "artist": artist,
                  }
                : mediaItem != null
                    ? {
                        "id": mediaItem.id.split('.')[2],
                        "cover": mediaItem.artUri,
                        "title": mediaItem.title,
                        "artist": mediaItem.artist,
                      }
                    : null;
  }

  void show(
    context,
    PlaylistHandler playlistHandlers,
  ) {
    playlistHandler.value = playlistHandlers;
  }
}
