import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'downloaded_tracks_table.dart';
import 'favourites_table.dart';
import 'local_playlists_table.dart';
import 'lyrics_sync_delays_table.dart';
import 'online_playlists_table.dart';
import 'play_history_table.dart';
import 'search_history_table.dart';
import 'sleep_alarms_table.dart';
import 'sync_table.dart';
import 'track_gains_table.dart';

/// The app's SQLite database and its tables.
///
/// Call [open] once before using any table.
class DatabaseService {
  /// Creates a service for the database file named [fileName].
  DatabaseService({this.fileName = 'pongify.db'});

  /// The database file name inside the platform's databases directory.
  final String fileName;

  static const _version = 41;

  late final Database _database;

  /// Tracks the user marked as favourites.
  late final FavouritesTable favourites = FavouritesTable(_database);

  /// Tracks downloaded to the device.
  late final DownloadedTracksTable downloadedTracks = DownloadedTracksTable(
    _database,
  );

  /// Playlists of downloaded tracks.
  late final LocalPlaylistsTable localPlaylists = LocalPlaylistsTable(
    _database,
  );

  /// Playlists of catalog tracks.
  late final OnlinePlaylistsTable onlinePlaylists = OnlinePlaylistsTable(
    _database,
  );

  /// Recently searched queries.
  late final SearchHistoryTable searchHistory = SearchHistoryTable(_database);

  /// Recently played tracks and artists.
  late final PlayHistoryTable playHistory = PlayHistoryTable(_database);

  /// Manual lyrics sync offsets per track.
  late final LyricsSyncDelaysTable lyricsSyncDelays = LyricsSyncDelaysTable(
    _database,
  );

  /// Sleep timers and alarms.
  late final SleepAlarmsTable sleepAlarms = SleepAlarmsTable(_database);

  /// Loudness gains per track.
  late final TrackGainsTable trackGains = TrackGainsTable(_database);

  /// The library as it's synced with the server.
  late final SyncTable sync = SyncTable(_database);

  /// Opens the database, creating or migrating it as needed.
  Future<void> open() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), fileName),
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE online_playlist (
        opid INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        cover BLOB
      )''');
    await db.execute('''
      CREATE TABLE opid_stid (
        opid INTEGER,
        stid TEXT,
        title TEXT,
        artists TEXT,
        image TEXT,
        album TEXT,
        order_number INT,
        hidden BOOLEAN,
        FOREIGN KEY(opid) REFERENCES online_playlist(opid)
      )
    ''');
    await db.execute('''
      CREATE TABLE favourites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stid TEXT,
        title TEXT,
        artists TEXT,
        image TEXT,
        album TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE lfh_artists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        said TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE lfh_tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stid TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE downloaded_tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stid TEXT,
        audio TEXT,
        artists TEXT,
        title TEXT,
        duration INT,
        image TEXT,
        lyrics_sync TEXT,
        lyrics_plain TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE local_playlist (
        lpid INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        cover BLOB
      )''');
    await db.execute('''
      CREATE TABLE lpid_track_id (
        lpid INTEGER,
        track_id TEXT,
        order_number INT,
        hidden BOOLEAN,
        FOREIGN KEY(lpid) REFERENCES local_playlist(lpid)
      )
    ''');
    await db.execute('''
      CREATE TABLE lyrics_sync_time_delay (
        stid TEXT,
        sync_time_delay INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE sleep (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sleep BOOLEAN,
        sleep_duration INTEGER,
        sleep_linear BOOLEAN,
        alarm_clock BOOLEAN,
        wake_time INTEGER,
        before_end_time_min INTEGER,
        alarm_clock_linear BOOLEAN
      )
    ''');
    await TrackGainsTable.create(db);
    await SyncTable.create(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 39) {
      // Track IDs shorter than 21 characters are left over from the old
      // catalog.
      await db.execute('DELETE FROM lfh_tracks WHERE LENGTH(stid) < 21');
    }
    if (oldVersion < 40) await TrackGainsTable.create(db);
    if (oldVersion < 41) await SyncTable.create(db);
  }
}

/// SQL placeholders for an `IN` clause with [count] values.
String placeholders(int count) => List.filled(count, '?').join(', ');
