import 'dart:convert';

import 'package:pongo/shared/models/spotify/track.dart';

class Favourite {
  final int id;
  final String stid;
  final String title;
  final List<ArtistTrack> artistTrack;
  final AlbumTrack? albumTrack;
  final String? image;

  Favourite({
    required this.id,
    required this.stid,
    required this.title,
    required this.artistTrack,
    required this.albumTrack,
    required this.image,
  });

  factory Favourite.fromMap(Map<String, dynamic> map) {
    return Favourite(
      id: map['id'],
      stid: map['stid'],
      title: map['title'],
      artistTrack: (jsonDecode(map['artists']) as List)
          .map((artist) => ArtistTrack.fromMap(artist as Map<String, dynamic>))
          .toList(),
      albumTrack: map['album'] != null
          ? AlbumTrack.fromMap(jsonDecode(map['album']) as Map<String, dynamic>)
          : null,
      image: map['image'],
    );
  }
}
