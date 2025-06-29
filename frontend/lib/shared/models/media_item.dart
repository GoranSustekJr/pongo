import 'package:pongo/exports.dart';

class MediaItemObject {
  MediaItem create(String id, String name, Track track, Duration duration,
      {bool online = true, bool mix = false}) {
    return MediaItem(
      id: id,
      title: name,
      artist: track.artists.map((artist) => artist.name).join(', '),
      album: track.album?.name, //TODO: Remove
      duration: duration,
      artUri: track.album != null
          ? Uri.parse(calculateBestImageForTrack(track.album!.images))
          : null,
      extras: {
        "artists": jsonEncode(track.artists
            .map((artist) => {"id": artist.id, "name": artist.name})
            .toList()),
        "released": track.album != null ? track.album!.releaseDate : "",
        "online": online,
        "mix": mix,
        "album": track.album != null
            ? "${track.album!.id}..Ææ..${track.album!.name}"
            : "..Ææ..",
      },
    );
  }
}
