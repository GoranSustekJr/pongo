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
