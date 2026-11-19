import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'track.freezed.dart';

/// Where a track's audio comes from.
enum TrackType { online, offline }

/// A song from the catalog or from the downloaded library.
@freezed
abstract class Track with _$Track {
  /// Creates a track.
  const factory Track({
    required String id,
    required String name,
    required List<ArtistTrack> artists,
    required AlbumTrack? album,
    LocalImage? image,
    @Default(TrackType.online) TrackType type,

    /// Path of the downloaded audio file, for offline tracks.
    String? audio,
  }) = _Track;

  const Track._();

  /// Creates a track from the API's JSON representation.
  factory Track.fromMap(Map<String, dynamic> map) => Track(
    id: map['id'] as String,
    name: map['name'] as String,
    artists: [
      for (final artist in map['artists'] as List)
        ArtistTrack.fromMap(artist as Map<String, dynamic>),
    ],
    album: switch (map['album']) {
      final Map<String, dynamic> album when album['id'] != null =>
        AlbumTrack.fromMap(album),
      _ => null,
    },
  );

  /// Creates a track from a row of the downloaded tracks table.
  factory Track.fromLocalRow(Map<String, dynamic> row) => Track(
    id: row['stid'] as String,
    name: row['title'] as String,
    artists: [
      for (final artist in jsonDecode(row['artists'] as String) as List)
        ArtistTrack.fromMap(artist as Map<String, dynamic>),
    ],
    album: null,
    type: TrackType.offline,
    image: row['image'] != null
        ? LocalImage(path: row['image'] as String)
        : null,
    audio: row['audio'] as String?,
  );

  /// Creates tracks from a list of API maps.
  static List<Track> fromMapList(List<dynamic> list) => [
    for (final map in list) Track.fromMap(map as Map<String, dynamic>),
  ];

  /// Creates tracks from rows of the downloaded tracks table.
  static List<Track> fromLocalRows(List<dynamic> rows) => [
    for (final row in rows) Track.fromLocalRow(row as Map<String, dynamic>),
  ];

  /// The artist names joined for display.
  String get artistNames => artists.map((artist) => artist.name).join(', ');
}

/// An artist credited on a track.
@freezed
abstract class ArtistTrack with _$ArtistTrack {
  /// Creates a credited artist.
  const factory ArtistTrack({required String id, required String? name}) =
      _ArtistTrack;

  const ArtistTrack._();

  /// Creates an artist from its JSON representation.
  factory ArtistTrack.fromMap(Map<String, dynamic> map) =>
      ArtistTrack(id: map['id'] as String, name: map['name'] as String?);

  /// The JSON representation stored with tracks.
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

/// The album a track belongs to.
@freezed
abstract class AlbumTrack with _$AlbumTrack {
  /// Creates an album reference.
  const factory AlbumTrack({
    required String id,
    required String name,
    required List<AlbumImagesTrack> images,
    required String? releaseDate,
  }) = _AlbumTrack;

  const AlbumTrack._();

  /// Creates an album from its JSON representation.
  factory AlbumTrack.fromMap(Map<String, dynamic> map) => AlbumTrack(
    id: map['id'] as String,
    name: map['name'] as String,
    releaseDate: map['release_date'] as String?,
    images: AlbumImagesTrack.fromMapList(map['images'] as List),
  );

  /// The JSON representation stored with favourites and playlists.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'images': [for (final image in images) image.toJson()],
  };
}

/// One size of a cover image.
@freezed
abstract class AlbumImagesTrack with _$AlbumImagesTrack {
  /// Creates an image reference.
  const factory AlbumImagesTrack({
    required String url,
    required int? height,
    required int? width,
  }) = _AlbumImagesTrack;

  const AlbumImagesTrack._();

  /// Creates an image from its JSON representation.
  factory AlbumImagesTrack.fromMap(Map<String, dynamic> map) =>
      AlbumImagesTrack(
        url: map['url'] as String,
        height: map['height'] as int?,
        width: map['width'] as int?,
      );

  /// Creates images from a JSON list.
  static List<AlbumImagesTrack> fromMapList(List<dynamic> list) => [
    for (final map in list)
      AlbumImagesTrack.fromMap(map as Map<String, dynamic>),
  ];

  /// The JSON representation.
  Map<String, dynamic> toJson() => {
    'url': url,
    'height': height,
    'width': width,
  };
}

/// A cover image stored on the device.
@freezed
abstract class LocalImage with _$LocalImage {
  /// Creates a reference to the image at [path].
  const factory LocalImage({required String path}) = _LocalImage;
}
