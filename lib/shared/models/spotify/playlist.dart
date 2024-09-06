class Playlist {
  final String id;
  final String name;
  final String? description;
  final String image;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.image,
  });
}
