import 'dart:convert';

import 'package:pongo/shared/models/spotify/track.dart';

class OnlinePlaylistTrack {
  final int opid;
  final String stid;
  final String title;
  final List<ArtistTrack> artistTrack;
  final AlbumTrack? albumTrack;
  final String? image;
  final int orderNumber;
  final bool hidden;

  OnlinePlaylistTrack({
    required this.opid,
    required this.stid,
    required this.title,
    required this.artistTrack,
    required this.albumTrack,
    required this.image,
    required this.orderNumber,
    required this.hidden,
  });

  factory OnlinePlaylistTrack.fromMap(Map<String, dynamic> map) {
    return OnlinePlaylistTrack(
      opid: map['opid'],
      stid: map['stid'],
      title: map['title'],
      artistTrack: (jsonDecode(map['artists']) as List)
          .map((artist) => ArtistTrack.fromMap(artist as Map<String, dynamic>))
          .toList(),
      albumTrack: map['album'] != null
          ? AlbumTrack.fromMap(jsonDecode(map['album']) as Map<String, dynamic>)
          : null,
      image: map['image'],
      orderNumber: map['order_number'],
      hidden: map['hidden'] == 1,
    );
  }
}
