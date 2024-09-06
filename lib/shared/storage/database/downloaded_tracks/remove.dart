import 'package:pongo/exports.dart';

// Track
Future<void> removeDownloadedTrck(
    DatabaseHelper dbHelper, String stid, int id) async {
  Database db = await dbHelper.database;

  await db.delete(
    'downloaded_tracks',
    where: 'stid = ? AND id = ?',
    whereArgs: [stid, id],
  );

  List<Map<String, dynamic>> playlists = await db.query(
    'lpid_track_id',
    columns: ['lpid', 'order_number'],
    where: 'track_id = ?',
    whereArgs: [stid],
  );

  // Prepare a map to store the results
  Map<String, List<Map<String, dynamic>>> playlistTracksMap = {};

  for (var playlist in playlists) {
    String lpid = playlist['lpid'].toString();

    // Query tracks in the current playlist ordered by order_number
    List<Map<String, dynamic>> tracksInPlaylist = await db.query(
      'lpid_track_id',
      where: 'lpid = ?',
      whereArgs: [lpid],
      orderBy: 'order_number ASC',
    );

    // Store the tracks in the map
    playlistTracksMap[lpid] = tracksInPlaylist;
  }
/*   List<Map<String, dynamic>> playlists = await db.query(
    'lpid_track_id',
    columns: ['lpid', 'order_number'],
    where: 'track_id = ?',
    whereArgs: [stid],
  );
 */

  for (var entry in playlistTracksMap.entries) {
    String lpid = entry.key;
    List<Map<String, dynamic>> tracks = entry.value;

    // Remove the track from the playlist
    for (var track in tracks) {
      if (track['track_id'] == stid) {
        await db.delete(
          'lpid_track_id',
          where: 'lpid = ? AND track_id = ? AND order_number = ?',
          whereArgs: [lpid, stid, track['order_number']],
        );
      }
    }

    // Step 2: Reorder remaining tracks
    int order = 1;
    for (var track in tracks) {
      if (track['track_id'] != stid) {
        await db.update(
          'lpid_track_id',
          {'order_number': order},
          where: 'lpid = ? AND track_id = ? AND order_number = ?',
          whereArgs: [lpid, track['track_id'], track['order_number']],
        );
        order++;
      }
    }
  }
}
