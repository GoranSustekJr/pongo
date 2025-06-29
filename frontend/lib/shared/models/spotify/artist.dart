import 'package:pongo/exports.dart';

class Artist {
  final String id;
  final String name;
  final String image;

  // Creata a Artist from a Map
  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map["id"],
      name: map["name"],
      image: calculateBestImageForTrack((map["images"] as List<dynamic>)
          .map((image) => AlbumImagesTrack(
              url: image["url"],
              height: image["height"],
              width: image["width"]))
          .toList()),
    );
  }

  // Convert a List of Maps to a List of Artist objects
  static List<Artist> fromMapList(List<dynamic> list) {
    return list
        .map((map) => Artist.fromMap(map as Map<String, dynamic>))
        .toList();
  }

  Artist({
    required this.id,
    required this.name,
    required this.image,
  });
}

class ArtistFull extends Artist {
  final String genres;
  final int followers;

  ArtistFull({
    required super.id,
    required super.name,
    required super.image,
    required this.genres,
    required this.followers,
  });
}
