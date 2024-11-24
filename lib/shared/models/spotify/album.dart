import 'package:pongo/exports.dart';

class Album {
  final String id;
  final String name;
  final String type;
  final List<dynamic> artists;
  final String image;

  // Creata a Album from a Map
  factory Album.fromMap(Map<String, dynamic> map) {
    print(map.keys);
    return Album(
      id: map["id"],
      type: map.keys.contains("album_group")
          ? map["album_group"]
          : map["album_type"],
      name: map["name"],
      artists: (map["artists"] as List<dynamic>)
          .map((artist) => artist["name"])
          .toList(),
      image: calculateBestImage(map["images"]),
    );
  }

  // Convert a List of Maps to a List of Album objects
  static List<Album> fromMapList(List<dynamic> list) {
    return list
        .map((map) => Album.fromMap(map as Map<String, dynamic>))
        .toList();
  }

  Album({
    required this.id,
    required this.name,
    required this.type,
    required this.artists,
    required this.image,
  });
}
