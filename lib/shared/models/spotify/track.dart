class Track {
  final String id;
  final String name;
  final List<ArtistTrack> artists;
  final AlbumTrack? album;
  Track({
    required this.id,
    required this.name,
    required this.artists,
    required this.album,
  });
}

class ArtistTrack {
  final String id;
  final String name;

  ArtistTrack({
    required this.id,
    required this.name,
  });
}

class AlbumTrack {
  final String id;
  final String name;
  final String releaseDate;
  final List<AlbumImagesTrack> images;

  AlbumTrack({
    required this.id,
    required this.name,
    required this.images,
    required this.releaseDate,
  });
}

class AlbumImagesTrack {
  final String url;
  final int? height;
  final int? width;
  AlbumImagesTrack({
    required this.url,
    required this.height,
    required this.width,
  });
}
