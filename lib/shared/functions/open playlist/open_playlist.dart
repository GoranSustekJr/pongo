import '../../../exports.dart';

class OpenPlaylist {
  void open(context,
      {String? id, String? cover, String? title, String? artist}) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    final MediaItem? mediaItem = audioServiceHandler.mediaItem.value;
    showPlaylistHandler.value = true;
    playlistTrackToAddData.value =
        (id != null && cover != null && title != null && artist != null)
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
}
