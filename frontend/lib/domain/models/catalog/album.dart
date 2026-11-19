import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../utils/image_resolution.dart';
import 'track.dart';

part 'album.freezed.dart';

/// An album, single or compilation in the catalog.
@freezed
abstract class Album with _$Album {
  /// Creates an album.
  const factory Album({
    required String id,
    required String name,

    /// The release type, such as `album` or `single`.
    required String type,
    required List<String> artists,

    /// URL of the cover image.
    required String image,
  }) = _Album;

  /// Creates an album from the API's JSON, using its largest cover.
  factory Album.fromMap(Map<String, dynamic> map) => Album(
    id: map['id'] as String,
    type: (map['album_group'] ?? map['album_type']) as String,
    name: map['name'] as String,
    artists: _artistNames(map),
    image: bestImageUrl(AlbumImagesTrack.fromMapList(map['images'] as List)),
  );

  /// Creates an album from the API's JSON, using a cover of about 300 pixels.
  factory Album.fromMapWithThumbnail(Map<String, dynamic> map) => Album(
    id: map['id'] as String,
    type: map['album_type'] as String,
    name: map['name'] as String,
    artists: _artistNames(map),
    image: imageUrlForSize(
      AlbumImagesTrack.fromMapList(map['images'] as List),
      300,
      300,
    ),
  );

  /// Creates albums from a JSON list.
  static List<Album> fromMapList(List<dynamic> list) => [
    for (final map in list) Album.fromMap(map as Map<String, dynamic>),
  ];
}

List<String> _artistNames(Map<String, dynamic> map) => [
  for (final artist in (map['artists'] as List).cast<Map<String, dynamic>>())
    artist['name'] as String,
];
