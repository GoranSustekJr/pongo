// ignore_for_file: depend_on_referenced_packages

import 'package:path/path.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/shared/storage/database/lyrics_sync_time_delay/insert.dart';
import 'package:pongo/shared/storage/database/lyrics_sync_time_delay/query.dart';
import 'package:pongo/shared/storage/database/sleep/insert.dart';
import 'package:pongo/shared/storage/database/sleep/query.dart';
import 'package:pongo/shared/storage/database/sleep/remove.dart';
import 'package:pongo/shared/storage/database/sleep/update.dart';

class DatabaseHelper {
  static final DatabaseHelper databaseHelper = DatabaseHelper.internal();
  factory DatabaseHelper() => databaseHelper;
  static Database? db;

  DatabaseHelper.internal();

  Future<Database> get database async {
    if (db != null) return db!;

    db = await initDatabase();
    return db!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'pongify.db');
    return await openDatabase(
      path,
      version: 30,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );
  }

  Future<void> onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE online_playlist (
        opid INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        cover BLOB
      )''');
    await db.execute('''
      CREATE TABLE opid_track_id (
        opid INTEGER,
        track_id TEXT,
        order_number INT,
        hidden BOOLEAN,
        FOREIGN KEY(opid) REFERENCES online_playlist(opid)
      )
    ''');
    await db.execute('''
      CREATE TABLE favourites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stid TEXT
      )
    ''');
    await db.execute('''
        CREATE TABLE search_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          query TEXT
        )
      ''');

    // Last 500 artists, tracks
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
          lyrics_plain TEXT        )
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
  }

  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    //print("JEEEEEEEE; $oldVersion");
    /*   await db.execute('''
      ALTER TABLE opid_track_id ADD COLUMN hidden BOOLEAN DEFAULT FALSE;
    ''');

    await db.execute('''
      UPDATE opid_track_id SET hidden = false;
    ''');

    await db.execute('''
      ALTER TABLE lpid_track_id ADD COLUMN hidden BOOLEAN DEFAULT FALSE;
    '''); */
    /* await db.execute('''
      ALTER TABLE favourites DROP COLUMN time_added;
    '''); */
    /* await db.execute('''
      ALTER TABLE downloaded_tracks ADD COLUMN time_added TEXT;
    '''); */
    /* await db.execute('''
      DELETE FROM lfh_tracks
WHERE id IN (
  SELECT id FROM lfh_tracks
  ORDER BY id DESC
  LIMIT 1
);

    '''); */

    /* await db.execute('''
      DELETE FROM lpid_track_id;
    '''); */

    // print(newVersion);
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
  }

  // Insert online playlist
  Future<int> insertOnlinePlaylist(String title, Uint8List? cover) async {
    return insertOnPlaylist(this, title, cover);
  }

  // Insert track id into online playlist
  Future insertOnlineTrackId(int opid, String stid) async {
    return insertOnTrackId(
      this,
      opid,
      stid,
    );
  }

  Future<List<Map<String, dynamic>>> queryAllOnlinePlaylists() async {
    return queryAllOnPlaylists(this);
  }

  Future<List<Map<String, dynamic>>> queryAllOnlinePlaylistsTitles() async {
    return queryAllOnPlaylistsTitles(this);
  }

  Future<List<Map<String, dynamic>>> queryOnlineTrackIdsForPlaylist(
      int opid) async {
    return queryOnTrackIdsForPlaylist(this, opid);
  }

  Future<int> queryOnlineTrackIdsLengthForPlaylist(int opid) async {
    return queryOnTrackIdsForPlaylistLength(this, opid);
  }

  Future<int> queryOnlinePlaylistsLength() async {
    return queryOnPlaylistsLength(this);
  }

  // Remove Online Playlist track
  Future<void> removeTrackFromOnlinePlaylist(
      int opid, String trackId, int ordNum) async {
    removeTrackFromOnPlaylist(this, opid, trackId, ordNum);
  }

  Future<void> removeTracksFromOnlinePlaylist(
      int opid, List<String> stid) async {
    await removeTracksFromOnPlaylist(this, opid, stid);
  }

  Future<void> removeOnlinePlaylist(int opid) async {
    await removeOnPlaylist(this, opid);
  }

  // Update online playlist

  Future<void> updateOnlinePlaylistOrder(
      int opid, List<String> newTrackOrder) async {
    await updateOnPlaylistOrder(this, opid, newTrackOrder);
  }

  Future<void> updateOnlinePlaylistName(int opid, String title) async {
    await updateOnPlaylistName(this, opid, title);
  }

  Future<void> updateOnlinePlaylistCover(int opid, Uint8List cover) async {
    await updateOnPlaylistCover(this, opid, cover);
  }

  Future<void> updateOnlinePlaylistShow(int opid, List<String> stids) async {
    await updateOnPlaylistShow(this, opid, stids);
  }

  Future<void> updateOnlinePlaylistHide(int opid, List<String> stids) async {
    await updateOnPlaylistHide(this, opid, stids);
  }

  Future<void> insertSearchHistorySearch(String query) async {
    await insertSearchHistorySrch(this, query);
  }

  Future<List<String>> querySearchHistorySearch() async {
    return await querySearchHistorySrch(this);
  }

  Future<void> removeSearchHistoryEntry(String qry) async {
    await removeSearchHistoryEtry(this, qry);
  }

  Future<void> clearSearchHistory() async {
    await clearSearchHistry(this);
  }

  Future<void> removeTrackHistoryEntry(String stid) async {
    await removeTrackHistoryEtry(this, stid);
  }

  Future<void> removeArtistHistoryEntry(String said) async {
    await removeArtistHistoryEtry(this, said);
  }

  Future<List<String>> queryTrackHistory() async {
    return await queryTrackHist(this);
  }

  Future<List<String>> queryTrackHistoryNum(int num) async {
    return await queryTrackHistNum(this, num);
  }

  Future<List<String>> queryArtistHistory() async {
    return await queryArtistHist(this);
  }

  Future<void> insertTrackPlayHistory(String stid) async {
    await insertTrackPlayHist(this, stid);
  }

  Future<void> insertArtistPlayHistory(String said) async {
    await insertArtistPlayHist(this, said);
  }

  Future<void> insertDownloadedTrack(
    String stid,
    String audio,
    List<Map<String, dynamic>> artists,
    String title,
    int duration,
    String? image,
  ) async {
    await insertDownloadedTrck(
        this, stid, audio, artists, title, duration, image);
  }

  Future<List<Map<String, dynamic>>> queryAllDownloadedTracks() async {
    return await queryAllDownloadedTrcks(this);
  }

  Future<int> queryAllDownloadedTracksLength() async {
    return await queryAllDownloadedTrcksLength(this);
  }

  Future<List<String>> queryMissingStids(List<String> stids) async {
    return await queryMssingStids(stids, this);
  }

  Future<bool> downloadedTrackAlreadyExists(String stid) async {
    return await downloadedTrckAlreadyExists(this, stid);
  }

  Future<void> removeDownloadedTrack(String stid, int id) async {
    await removeDownloadedTrck(this, stid, id);
  }

  Future<void> removeDownloadedTracks(List<String> stids) async {
    await removeDownloadedTrcks(this, stids);
  }

  // Downloaded playlist insert

  // Insert downloaded playlist
  Future<int> insertLocalPlaylist(String title, Uint8List? cover) async {
    return insertLoclPlaylist(this, title, cover);
  }

  // Insert track id into Local playlist
  Future<int?> insertLocalTrackId(int lpid, String stid) async {
    return insertLoclTrackId(
      this,
      lpid,
      stid,
    );
  }

  // Local playlist query

  Future<List<Map<String, dynamic>>> queryAllLocalPlaylists() async {
    return queryAllLoclPlaylists(this);
  }

  Future<List<Map<String, dynamic>>> queryAllLocalPlaylistsTitles() async {
    return queryAllLoclPlaylistsTitles(this);
  }

  Future<List<Map<String, dynamic>>> queryLocalTracksForPlaylist(
      int opid) async {
    return queryLoclTracksForPlaylist(this, opid);
  }

  Future<int> queryLocalPlaylistsLength() async {
    return queryLoclPlaylistsLength(this);
  }

  Future<int> queryLocalTrackIdsLengthForPlaylist(int lpid) async {
    return queryLoclTrackIdsForPlaylistLength(this, lpid);
  }

  Future<List<Map<String, dynamic>>> queryLocalTrackIdsForPlaylist(
      int opid) async {
    return queryLoclTrackIdsForPlaylist(this, opid);
  }

  // Local playlist remove
  Future<void> removeTrackFromLocalPlaylist(
      int lpid, String trackId, int ordNum) async {
    removeTrackFromLoclPlaylist(this, lpid, trackId, ordNum);
  }

  Future<void> removeTracksFromLocalPlaylist(
      int lpid, List<String> stids, int ordNum) async {
    removeTracksFromLoclPlaylist(this, lpid, stids);
  }

  // Local playlist update
  Future<void> removeLocalPlaylist(int lpid) async {
    await removeLoclPlaylist(this, lpid);
  }

  Future<void> updateLocalPlaylistOrder(
      int lpid, List<String> newTrackOrder) async {
    await updateLoclPlaylistOrder(this, lpid, newTrackOrder);
  }

  Future<void> updateLocalPlaylistName(int lpid, String title) async {
    await updateLoclPlaylistName(this, lpid, title);
  }

  Future<void> updateLocalPlaylistCover(int lpid, Uint8List cover) async {
    await updateLoclPlaylistCover(this, lpid, cover);
  }

  Future<void> updateLocalPlaylistShow(int opid, List<String> stids) async {
    await updateLoclPlaylistShow(this, opid, stids);
  }

  Future<void> updateLocalPlaylistHide(int opid, List<String> stids) async {
    await updateLoclPlaylistHide(this, opid, stids);
  }

  Future<void> insertLFHArtists(String said) async {
    await insertLFHArtsts(this, said);
  }

  Future<void> removeLFHArtists(String said) async {
    await removeLFHArtsts(this, said);
  }

  Future<void> clearLFHArtists() async {
    await clearLFHArtsts(this);
  }

  Future<List<String>> queryLFHArtistsBy50() async {
    return await queryLFHArtstsBy50(this);
  }

  Future<List<String>> queryLFHArtistsBy5() async {
    return await queryLFHArtstsBy5(this);
  }

  Future<void> insertLFHTracks(String stid) async {
    await insertLFHTrcks(this, stid);
  }

  Future<void> removeLFHTracks(String stid) async {
    await removeLFHTrcks(this, stid);
  }

  Future<void> clearLFHTracks() async {
    await clearLFHTrcks(this);
  }

  Future<List<String>> queryLFHTracksBy50() async {
    return await queryLFHTrcksBy50(this);
  }

  Future<List<String>> queryLFHTracksBy5() async {
    return await queryLFHTrcksBy5(this);
  }

  Future<void> insertFavouriteTrack(
    String stid,
  ) async {
    await insertFavouriteTrck(this, stid);
  }

  Future<List<Map<String, dynamic>>> queryAllFavouriteTracks() async {
    return await queryAllFavouriteTrcks(this);
  }

  Future<int> queryFavouritesLength() async {
    return queryFvouritesLength(this);
  }

  Future<int> queryAllFavouriteTracksLength() async {
    return await queryAllFavouriteTrcksLength(this);
  }

  Future<bool> favouriteTrackAlreadyExists(String stid) async {
    return await favouriteTrckAlreadyExists(this, stid);
  }

  Future<void> removeFavouriteTrack(String stid) async {
    await removeFavouriteTrck(this, stid);
  }

  Future<void> removeFavouriteTracks(List<String> stid) async {
    await removeFavouriteTrcks(this, stid);
  }

  Future<void> insertSyncTimeDelay(String stid, int syncTimeDelay) async {
    await insertSyncTimeDlay(this, stid, syncTimeDelay);
  }

  Future<int?> querySyncTimeDelay(String stid) async {
    return await querySyncTimeDlay(this, stid);
  }

  // Sleep alarm
  Future<int> insertSleepAlarm(SleepAlarm sleepAlarm) async {
    return await insertSleepAlrm(this, sleepAlarm);
  }

  Future<List<SleepAlarm>> querySleepAlarms() async {
    return await querySleepAlrms(this);
  }

  Future<int> querySleepAlarmsLength() async {
    return await querySleepAlrmsLength(this);
  }

  Future<void> updateSleepAlarm(SleepAlarm sleepAlarm) async {
    return await updateSleepAlrm(this, sleepAlarm);
  }

  Future<void> removeSleepAlarm(int id) async {
    return await removeSleepAlarmEtry(this, id);
  }
}
