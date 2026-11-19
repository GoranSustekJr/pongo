import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../utils/image_resolution.dart';
import 'track.dart';

part 'artist.freezed.dart';

/// An artist in the catalog.
@freezed
abstract class Artist with _$Artist {
  /// Creates an artist.
  const factory Artist({
    required String id,
    required String name,

    /// URL of the profile image.
    required String image,
  }) = _Artist;

  /// Creates an artist from the API's JSON, using its largest image.
  factory Artist.fromMap(Map<String, dynamic> map) => Artist(
    id: map['id'] as String,
    name: map['name'] as String,
    image: bestImageUrl(AlbumImagesTrack.fromMapList(map['images'] as List)),
  );

  /// Creates artists from a JSON list.
  static List<Artist> fromMapList(List<dynamic> list) => [
    for (final map in list) Artist.fromMap(map as Map<String, dynamic>),
  ];
}
