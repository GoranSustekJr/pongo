import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pongo/domain/models/catalog/album.dart';
import 'package:pongo/domain/models/catalog/artist.dart';
import 'package:pongo/domain/models/catalog/category.dart';
import 'package:pongo/domain/models/catalog/playlist.dart';
import 'package:pongo/domain/models/catalog/track.dart';
import 'package:pongo/utils/image_resolution.dart';
import 'package:pongo/utils/json.dart';

// The fixture is real API output: the models must keep parsing what the server
// sends.
void main() {
  final catalog = jsonDecode(
    File('test/fixtures/catalog.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  List<dynamic> listAt(List<String> path) => catalog.listAt(path)!;

  test('search results', () {
    final tracks = Track.fromMapList(listAt(['search', 'tracks', 'items']));
    expect(tracks.first.id, isNotEmpty);
    expect(tracks.first.artists.first.name, isNotNull);
    expect(tracks.first.album!.images, isNotEmpty);
    expect(
      Album.fromMapList(listAt(['search', 'albums', 'items'])).first.image,
      startsWith('http'),
    );
    expect(
      Artist.fromMapList(listAt(['search', 'artists', 'items'])).first.image,
      startsWith('http'),
    );
    expect(
      Playlist.fromMapList(listAt(['search', 'playlists', 'items'])),
      isNotEmpty,
    );
  });

  test('artist page', () {
    expect(
      Album.fromMapList(listAt(['artist', 'albums'])).first.type,
      isNotEmpty,
    );
    expect(Track.fromMapList(listAt(['artist', 'tracks'])), isNotEmpty);
  });

  test('album tracks arrive without an album', () {
    final tracks = Track.fromMapList(listAt(['album_tracks']));
    expect(tracks.first.album, isNull);
  });

  test('home screen', () {
    final categories = SpCategory.fromMapList(
      listAt(['genres', 'categories', 'items']),
    );
    expect(categories.first.categoryIcons.first.url, startsWith('http'));
    final album =
        listAt(['releases', 'albums', 'items']).first as Map<String, dynamic>;
    expect(
      imageUrlForSize(
        AlbumImagesTrack.fromMapList(album['images'] as List),
        300,
        300,
      ),
      startsWith('http'),
    );
    expect(album['album_type'], isNotNull);
  });

  test('mix tracks carry their own metadata', () {
    final track = Track.fromMap(listAt(['mix']).first as Map<String, dynamic>);
    expect(track.album, isNotNull);
    expect(bestImageUrl(track.album!.images), startsWith('http'));
  });
}
