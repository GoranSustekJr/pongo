class Artist {
  final String id;
  final String name;
  final String image;

  Artist({
    required this.id,
    required this.name,
    required this.image,
  });
}

class ArtistFull {
  final String id;
  final String name;
  final String image;
  final String genres;
  final int followers;

  ArtistFull({
    required this.id,
    required this.name,
    required this.image,
    required this.genres,
    required this.followers,
  });
}
