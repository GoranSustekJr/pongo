import '../../../exports.dart';

class OpenPlaylist {
  void open(context,
      {String? id, String? cover, String? title, String? artist}) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    final MediaItem? mediaItem = audioServiceHandler.mediaItem.value;
    showPlaylistHandler.value = true;
    playlistTrackToAddData.value = {
      "id": id ?? mediaItem?.id.split('.')[2],
      "cover": cover ?? mediaItem?.artUri,
      "title": title ?? mediaItem?.title,
      "artist": artist ?? mediaItem?.artist,
    };
  }
}
