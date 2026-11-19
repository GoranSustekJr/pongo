import 'dart:convert';

import 'package:audio_service/audio_service.dart';

import '../../../domain/models/catalog/track.dart';
import '../../../utils/image_resolution.dart';

const _albumSeparator = '..Ææ..';

/// Creates the queue entry that plays [track].
///
/// [collectionId] names where the track was started from, such as
/// `online.album:<id>`; the entry's ID is `<collectionId>.<track ID>`.
MediaItem mediaItemFor(
  Track track, {
  required String collectionId,
  required Duration duration,
  bool mix = false,
}) {
  final album = track.album;
  final offline = track.type == TrackType.offline;
  return MediaItem(
    id: '$collectionId.${track.id}',
    title: track.name,
    artist: track.artistNames,
    album: album?.name,
    duration: duration,
    artUri: offline
        ? (track.image == null ? null : Uri.file(track.image!.path))
        : (album == null ? null : Uri.parse(bestImageUrl(album.images))),
    extras: {
      'artists': jsonEncode([for (final a in track.artists) a.toJson()]),
      'released': album?.releaseDate ?? '',
      'album': album == null
          ? _albumSeparator
          : '${album.id}$_albumSeparator${album.name}',
      if (offline) ...{
        'audio': track.audio,
        'downloaded': 'true',
      } else ...{
        'online': true,
        'mix': mix,
      },
    },
  );
}

/// Typed access to the data the app keeps in a [MediaItem].
extension PongoMediaItem on MediaItem {
  List<String> get _idParts => id.split('.');

  /// The ID of the track this entry plays.
  String get stid => _idParts[2];

  /// Where the track was started from, such as `online.album:<id>`.
  String get collectionId => '${_idParts[0]}.${_idParts[1]}';

  /// Whether the server added this entry to a mix.
  bool get isMix => extras?['mix'] == true;

  /// Whether this entry plays a downloaded file.
  bool get isDownloaded => extras?['downloaded'] == 'true';

  /// The path of the downloaded audio file.
  String? get audioPath => extras?['audio'] as String?;

  /// The ID of the track's album, or an empty string.
  String get albumId => (extras?['album'] as String? ?? _albumSeparator).split(
    _albumSeparator,
  )[0];

  /// The name of the track's album, or an empty string.
  String get albumName {
    final parts = (extras?['album'] as String? ?? _albumSeparator).split(
      _albumSeparator,
    );
    return parts.length > 1 ? parts[1] : '';
  }

  /// The album's release date, or an empty string.
  String get releaseDate => extras?['released'] as String? ?? '';

  /// The artists credited on the track.
  List<ArtistTrack> get artistRefs =>
      decodeArtistRefs(extras?['artists'] as String?);

  /// The entry as a catalog track, for actions such as adding it to a
  /// playlist.
  Track toTrack() => Track(
    id: stid,
    name: title,
    artists: artistRefs,
    album: albumId.isEmpty
        ? null
        : AlbumTrack(
            id: albumId,
            name: albumName,
            images: [
              if (artUri != null)
                AlbumImagesTrack(
                  url: artUri.toString(),
                  height: null,
                  width: null,
                ),
            ],
            releaseDate: releaseDate,
          ),
  );
}

/// Converts [item] to JSON for saving the queue.
Map<String, dynamic> mediaItemToJson(MediaItem item) => {
  'id': item.id,
  'title': item.title,
  'album': item.album,
  'artist': item.artist,
  'duration': item.duration?.inMilliseconds,
  'artUri': item.artUri?.toString(),
  'extras': item.extras,
};

/// Restores a [MediaItem] saved by [mediaItemToJson].
MediaItem mediaItemFromJson(Map<String, dynamic> json) => MediaItem(
  id: json['id'] as String,
  title: json['title'] as String,
  album: json['album'] as String?,
  artist: json['artist'] as String?,
  duration: json['duration'] == null
      ? null
      : Duration(milliseconds: json['duration'] as int),
  artUri: json['artUri'] == null ? null : Uri.parse(json['artUri'] as String),
  extras: (json['extras'] as Map?)?.cast<String, dynamic>(),
);

/// The artists in [encoded], the JSON list kept in a media item's extras.
List<ArtistTrack> decodeArtistRefs(String? encoded) {
  if (encoded == null || encoded.isEmpty) return const [];
  return [
    for (final artist in jsonDecode(encoded) as List)
      ArtistTrack.fromMap(artist as Map<String, dynamic>),
  ];
}
