import 'package:pongo/shared/functions/image%20/calculate_image_resolution.dart';

class Playlist {
  final String id;
  final String name;
  final String? description;
  final String image;

  // Creata a Playlist from a Map
  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map["id"],
      name: map["name"],
      image: map["images"].isNotEmpty
          ? calculateWantedResolution(map["images"], 300, 300)
          : "",
      description: map["description"],
    );
  }

  // Convert a List of Maps to a List of Playlist objects
  static List<Playlist> fromMapList(List<dynamic> list) {
    for (var item in list) {
      if (item == null) {
      } else if (item is! Map<String, dynamic>) {}
    }

    return list
        .where((item) => item != null && item is Map<String, dynamic>)
        .map((map) => Playlist.fromMap(map as Map<String, dynamic>))
        .toList();
  }

  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.image,
  });
}
