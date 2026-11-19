import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../utils/image_resolution.dart';
import 'track.dart';

part 'playlist.freezed.dart';

/// A playlist in the catalog.
@freezed
abstract class Playlist with _$Playlist {
  /// Creates a playlist.
  const factory Playlist({
    required String id,
    required String name,
    String? description,

    /// URL of the cover image, or an empty string if there is none.
    required String image,
  }) = _Playlist;

  /// Creates a playlist from the API's JSON, using a cover of about 300
  /// pixels.
  factory Playlist.fromMap(Map<String, dynamic> map) => Playlist(
    id: map['id'] as String,
    name: map['name'] as String,
    image: imageUrlForSize(
      AlbumImagesTrack.fromMapList(map['images'] as List),
      300,
      300,
    ),
    description: map['description'] as String?,
  );

  /// Creates playlists from a JSON list, skipping entries that aren't maps.
  static List<Playlist> fromMapList(List<dynamic> list) => [
    for (final map in list.whereType<Map<String, dynamic>>())
      Playlist.fromMap(map),
  ];
}
