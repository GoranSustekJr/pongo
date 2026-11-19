import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../catalog/track.dart';

part 'favourite.freezed.dart';

/// A track the user marked as a favourite.
@freezed
abstract class Favourite with _$Favourite {
  /// Creates a favourite.
  const factory Favourite({
    required int id,
    required String stid,
    required String title,
    required List<ArtistTrack> artistTrack,
    required AlbumTrack? albumTrack,
    required String? image,
  }) = _Favourite;

  const Favourite._();

  /// Creates a favourite from a row of the favourites table.
  factory Favourite.fromMap(Map<String, dynamic> map) => Favourite(
    id: map['id'] as int,
    stid: map['stid'] as String,
    title: map['title'] as String,
    artistTrack: [
      for (final artist in jsonDecode(map['artists'] as String) as List)
        ArtistTrack.fromMap(artist as Map<String, dynamic>),
    ],
    albumTrack: map['album'] != null
        ? AlbumTrack.fromMap(
            jsonDecode(map['album'] as String) as Map<String, dynamic>,
          )
        : null,
    image: map['image'] as String?,
  );

  /// The favourite as a playable track.
  Track toTrack() =>
      Track(id: stid, name: title, artists: artistTrack, album: albumTrack);
}
