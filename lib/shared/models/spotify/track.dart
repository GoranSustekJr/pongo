import 'package:pongo/exports.dart';

enum TrackType { online, offline }

class Track {
  final String id;
  final String name;
  final List<ArtistTrack> artists;
  final AlbumTrack? album;
  final LocalImage? image;
  final TrackType type;
  String? audio;
  Track({
    required this.id,
    required this.name,
    required this.artists,
    required this.album,
    this.image,
    this.type = TrackType.online,
    this.audio,
  });

  /*  // Create a map of Artist
  static List<Map<String, dynamic>> toJsonArtist(Track track) {
    return track.artists.map((artist) => artist.toJson()).toList();
  } */

  // Creata a Track from a Map
  factory Track.fromMap(Map<String, dynamic> map) {
    return Track(
      id: map["id"],
      name: map["name"],
      artists: (map["artists"] as List<dynamic>)
          .map((artist) => ArtistTrack.fromMap(artist))
          .toList(),
      album: map["album"] != null ? AlbumTrack.fromMap(map["album"]) : null,
    );
  }

  // Convert a List of Maps to a List of Track objects
  static List<Track> fromMapList(List<dynamic> list) {
    return list
        .map((map) => Track.fromMap(map as Map<String, dynamic>))
        .toList();
  }

  // Convert local track to a Track object
  factory Track.fromMapLocal(Map<String, dynamic> map) {
    return Track(
      id: map["stid"],
      name: map["title"],
      artists: (jsonDecode(map["artists"]) as List<dynamic>)
          .map((artist) => ArtistTrack.fromMap(artist))
          .toList(),
      album: null,
      type: TrackType.offline,
      image: map["image"] != null ? LocalImage(path: map["image"]) : null,
      audio: map["audio"],
    );
  }

  // Convert a list of local tracks to List of Track objects
  static List<Track> fromMapListLocal(List<dynamic> list) {
    return list
        .map((map) => Track.fromMapLocal(map as Map<String, dynamic>))
        .toList();
  }
}

class ArtistTrack {
  final String id;
  final String name;

  ArtistTrack({
    required this.id,
    required this.name,
  });

  // Create ArtistTrack from a Map
  factory ArtistTrack.fromMap(Map<String, dynamic> map) {
    return ArtistTrack(
      id: map["id"],
      name: map["name"],
    );
  }

  // To json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
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

  // Create AlbumTrack from a Map
  factory AlbumTrack.fromMap(Map<String, dynamic> map) {
    return AlbumTrack(
      id: map["id"],
      name: map["name"],
      releaseDate: map["release_date"],
      images: (map["images"] as List<dynamic>)
          .map((image) => AlbumImagesTrack.fromMap(image))
          .toList(),
    );
  }
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

  // Create AlbumImagesTrack from a Map
  factory AlbumImagesTrack.fromMap(Map<String, dynamic> map) {
    return AlbumImagesTrack(
      url: map["url"],
      height: map["height"],
      width: map["width"],
    );
  }
}

class LocalImage {
  final String path;

  LocalImage({
    required this.path,
  });
}
