import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pongo/data/repositories/catalog/catalog_repository.dart';
import 'package:pongo/data/repositories/history/history_repository.dart';
import 'package:pongo/data/repositories/library/downloads_repository.dart';
import 'package:pongo/data/repositories/library/favourites_repository.dart';
import 'package:pongo/data/repositories/player/player_repository.dart';
import 'package:pongo/data/repositories/playlists/playlist_repository.dart';
import 'package:pongo/data/repositories/settings/settings_repository.dart';
import 'package:pongo/data/repositories/sleep_alarm/sleep_alarm_repository.dart';
import 'package:pongo/domain/models/catalog/catalog_results.dart';
import 'package:pongo/domain/models/catalog/track.dart';
import 'package:pongo/domain/models/library/favourite.dart';
import 'package:pongo/domain/models/playlists/user_playlist.dart';
import 'package:pongo/domain/models/settings/app_settings.dart';
import 'package:pongo/domain/models/sleep_alarm/sleep_alarm.dart';
import 'package:pongo/utils/result.dart';

/// A track with [id] by one artist.
Track fakeTrack(String id, {String? name, String artist = 'Đorđe Čović'}) =>
    Track(
      id: id,
      name: name ?? 'Track $id',
      artists: [ArtistTrack(id: 'a$id', name: artist)],
      album: null,
    );

/// Settings kept in memory.
class FakeSettingsRepository extends SettingsRepository {
  FakeSettingsRepository([this._settings = const AppSettings()]);

  AppSettings _settings;

  @override
  AppSettings get settings => _settings;

  @override
  Future<void> load() async {}

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
    notifyListeners();
  }
}

/// A catalog that answers the home feed with [feed].
class FakeCatalogRepository extends Fake implements CatalogRepository {
  /// The feed returned, or an error when `null`.
  HomeFeed? feed = const HomeFeed();

  /// The arguments of the last [homeFeed] call.
  ({
    List<String> history,
    String market,
    bool includeHistory,
    bool includeCategories,
  })?
  lastHomeFeed;

  @override
  Future<Result<HomeFeed>> homeFeed({
    required List<String> history,
    required String market,
    required String locale,
    required int categoryCount,
    required bool includeHistory,
    required bool includeCategories,
  }) async {
    lastHomeFeed = (
      history: history,
      market: market,
      includeHistory: includeHistory,
      includeCategories: includeCategories,
    );
    final feed = this.feed;
    return feed == null ? Result.error(Exception('offline')) : Result.ok(feed);
  }
}

/// History kept in memory, newest first.
class FakeHistoryRepository implements HistoryRepository {
  final searchList = <String>[];
  final played = <String>[];
  final artists = <String>[];

  @override
  Future<List<String>> searches() async => [...searchList];

  @override
  Future<void> addSearch(String query) async {
    searchList
      ..remove(query)
      ..insert(0, query);
  }

  @override
  Future<void> removeSearch(String query) async => searchList.remove(query);

  @override
  Future<void> clearSearches() async => searchList.clear();

  @override
  Future<List<String>> playedTracks({int? limit}) async =>
      played.take(limit ?? played.length).toList();

  @override
  Future<void> addPlayedTrack(String stid) async => played.insert(0, stid);

  @override
  Future<List<String>> viewedArtists({int? limit}) async =>
      artists.take(limit ?? artists.length).toList();

  @override
  Future<void> addViewedArtist(String said) async => artists.insert(0, said);
}

/// Favourites kept in memory.
class FakeFavouritesRepository implements FavouritesRepository {
  final items = <Favourite>[];

  @override
  Future<List<Favourite>> favourites() async => [...items];

  @override
  Future<int> count() async => items.length;

  @override
  Future<bool> isFavourite(String stid) async =>
      items.any((item) => item.stid == stid);

  @override
  Future<bool> toggle(Favourite favourite) async {
    if (await isFavourite(favourite.stid)) {
      items.removeWhere((item) => item.stid == favourite.stid);
      return false;
    }
    items.add(favourite);
    return true;
  }

  @override
  Future<void> remove(List<String> stids) async =>
      items.removeWhere((item) => stids.contains(item.stid));
}

/// Downloads kept in memory.
class FakeDownloadsRepository extends Fake implements DownloadsRepository {
  final items = <DownloadedTrack>[];

  @override
  Future<List<DownloadedTrack>> downloads() async => [...items];

  @override
  Future<int> count() async => items.length;

  @override
  Future<List<String>> missing(List<String> stids) async => [
    for (final stid in stids)
      if (!items.any((item) => item.track.id == stid)) stid,
  ];

  @override
  Future<void> remove(List<String> stids) async =>
      items.removeWhere((item) => stids.contains(item.track.id));
}

/// User playlists kept in memory.
class FakePlaylistRepository extends Fake implements PlaylistRepository {
  final online = <UserPlaylist>[];
  final local = <UserPlaylist>[];

  @override
  Future<List<UserPlaylist>> onlinePlaylists() async => [...online];

  @override
  Future<int> onlinePlaylistCount() async => online.length;

  @override
  Future<void> deleteOnlinePlaylist(int opid) async =>
      online.removeWhere((playlist) => playlist.id == opid);

  @override
  Future<List<UserPlaylist>> localPlaylists() async => [...local];

  @override
  Future<int> localPlaylistCount() async => local.length;

  @override
  Future<void> deleteLocalPlaylist(int lpid) async =>
      local.removeWhere((playlist) => playlist.id == lpid);
}

/// Sleep alarms kept in memory.
class FakeSleepAlarmRepository implements SleepAlarmRepository {
  final items = <SleepAlarm>[];
  var _nextId = 1;

  @override
  Future<List<SleepAlarm>> alarms() async => [...items];

  @override
  Future<int> count() async => items.length;

  @override
  Future<SleepAlarm> add(SleepAlarm alarm) async {
    final saved = alarm.copyWith(id: _nextId++);
    items.insert(0, saved);
    return saved;
  }

  @override
  Future<void> update(SleepAlarm alarm) async {
    final index = items.indexWhere((saved) => saved.id == alarm.id);
    if (index != -1) items[index] = alarm;
  }

  @override
  Future<void> remove(int id) async =>
      items.removeWhere((alarm) => alarm.id == id);
}

/// A player that records what it was asked to play.
class FakePlayerRepository extends Fake implements PlayerRepository {
  @override
  final ValueNotifier<MediaItem?> currentItem = ValueNotifier(null);

  @override
  final ValueNotifier<List<MediaItem>> queue = ValueNotifier(const []);

  @override
  final ValueNotifier<Set<String>> fetchingTracks = ValueNotifier(const {});

  final _messages = StreamController<PlayerMessage>.broadcast();
  final _fetched = StreamController<FetchedTrack>.broadcast();

  /// The collection and tracks of each play request.
  final plays = <({String collectionId, List<String> stids, bool shuffle})>[];

  /// The alarms started, or `null` for each stop.
  final alarms = <SleepAlarm?>[];

  int _activeSleepAlarm = -1;

  @override
  Stream<MediaItem?> get currentItemStream => Stream.value(currentItem.value);

  @override
  Stream<PlayerMessage> get messages => _messages.stream;

  @override
  Stream<FetchedTrack> get onTrackFetched => _fetched.stream;

  @override
  Stream<bool> get playingStream => Stream.value(false);

  @override
  bool get shuffleEnabled => false;

  @override
  int get activeSleepAlarm => _activeSleepAlarm;

  @override
  Future<void> playOffline(
    String collectionId,
    List<Track> tracks, {
    required Map<String, int> durations,
    int? index,
    bool shuffle = false,
  }) async {
    plays.add((
      collectionId: collectionId,
      stids: [for (final track in tracks) track.id],
      shuffle: shuffle,
    ));
  }

  @override
  Future<void> playOnline(
    String collectionId,
    List<Track> tracks, {
    required Map<String, double> durations,
    int? index,
    bool shuffle = false,
  }) async {
    plays.add((
      collectionId: collectionId,
      stids: [for (final track in tracks) track.id],
      shuffle: shuffle,
    ));
  }

  @override
  Future<void> startSleepAlarm(SleepAlarm alarm) async {
    _activeSleepAlarm = alarm.id;
    alarms.add(alarm);
  }

  @override
  Future<void> stopSleepAlarm() async {
    _activeSleepAlarm = -1;
    alarms.add(null);
  }

  @override
  Future<bool> halt() async => true;
}
