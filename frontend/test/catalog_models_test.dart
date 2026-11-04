import 'package:flutter_test/flutter_test.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/shared/models/catalog/category.dart';

// The fixture is real API output: the models must keep parsing what the server sends.
void main() {
  final catalog =
      jsonDecode(File('test/fixtures/catalog.json').readAsStringSync());

  test('search results', () {
    final search = catalog['search'];
    final tracks = Track.fromMapList(search['tracks']['items']);
    expect(tracks.first.id, isNotEmpty);
    expect(tracks.first.artists.first.name, isNotNull);
    expect(tracks.first.album!.images, isNotEmpty);
    expect(Album.fromMapList(search['albums']['items']).first.image,
        startsWith('http'));
    expect(Artist.fromMapList(search['artists']['items']).first.image,
        startsWith('http'));
    expect(Playlist.fromMapList(search['playlists']['items']), isNotEmpty);
  });

  test('artist page', () {
    final artist = catalog['artist'];
    expect(Album.fromMapList(artist['albums']).first.type, isNotEmpty);
    expect(Track.fromMapList(artist['tracks']), isNotEmpty);
  });

  test('album tracks arrive without an album', () {
    final tracks = Track.fromMapList(catalog['album_tracks']);
    expect(tracks.first.album, isNull);
  });

  test('home screen', () {
    final categories =
        SpCategory.fromMapList(catalog['genres']['categories']['items']);
    expect(categories.first.categoryIcons.first.url, startsWith('http'));
    final album = catalog['releases']['albums']['items'][0];
    expect(calculateWantedResolution(album['images'], 300, 300),
        startsWith('http'));
    expect(album['album_type'], isNotNull);
  });

  test('mix tracks carry their own metadata', () {
    final track = Track.fromMap(catalog['mix'][0]);
    expect(track.album, isNotNull);
    expect(calculateBestImageForTrack(track.album!.images), startsWith('http'));
  });
}
