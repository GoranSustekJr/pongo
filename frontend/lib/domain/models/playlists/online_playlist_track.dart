import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../catalog/track.dart';

part 'online_playlist_track.freezed.dart';

/// A catalog track saved in one of the user's online playlists.
@freezed
abstract class OnlinePlaylistTrack with _$OnlinePlaylistTrack {
  /// Creates a playlist entry.
  const factory OnlinePlaylistTrack({
    required int opid,
    required String stid,
    required String title,
    required List<ArtistTrack> artistTrack,
    required AlbumTrack? albumTrack,
    required String? image,
    required int orderNumber,
    required bool hidden,
  }) = _OnlinePlaylistTrack;

  const OnlinePlaylistTrack._();

  /// Creates an entry from a row of the playlist tracks table.
  factory OnlinePlaylistTrack.fromMap(Map<String, dynamic> map) =>
      OnlinePlaylistTrack(
        opid: map['opid'] as int,
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
        orderNumber: map['order_number'] as int,
        hidden: map['hidden'] == 1,
      );

  /// The entry as a playable track.
  Track toTrack() =>
      Track(id: stid, name: title, artists: artistTrack, album: albumTrack);
}
