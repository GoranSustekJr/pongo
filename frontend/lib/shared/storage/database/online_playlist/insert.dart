import 'package:pongo/exports.dart';

Future<int> insertOnPlaylist(
    DatabaseHelper dbHelper, String title, Uint8List? cover) async {
  Database db = await dbHelper.database;
  Map<String, dynamic> row = {
    'title': title,
    'cover': cover,
  };
  return await db.insert('online_playlist', row);
}

Future<int?> insertOnTrackId(
    DatabaseHelper dbHelper, OnlinePlaylistTrack onlinePlaylistTrack) async {
  Database db = await dbHelper.database;

  // Check the current number of tracks in the playlist
  /* int trackCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM opid_track_id WHERE opid = ?',
        [opid],
      )) ??
      0;

  // Ensure the playlist has fewer than 150 tracks
   if (trackCount >= 150) {
    Notifications().showWarningNotification(searchScreenContext.value!,
        "Playlist has exceeded the maximum number of tracks, 150");
    return null; // Or return a value indicating the insertion was skipped
  } */

  final List<Map<String, dynamic>> existingRows = await db.query(
    'opid_stid',
    where: 'opid = ? AND stid = ?',
    whereArgs: [onlinePlaylistTrack.opid, onlinePlaylistTrack.stid],
  );

  // Ensure that the playlist does not contains this track
  if (existingRows.isNotEmpty) {
    return null;
  }

  // Get the current order count for the given opid
  int currentOrder =
      await queryOrderForOpid(dbHelper, onlinePlaylistTrack.opid);

  Map<String, dynamic> row = {
    'opid': onlinePlaylistTrack.opid,
    'stid': onlinePlaylistTrack.stid,
    'title': onlinePlaylistTrack.title,
    'artists': jsonEncode(onlinePlaylistTrack.artistTrack),
    'image': onlinePlaylistTrack.image,
    'album': onlinePlaylistTrack.albumTrack != null
        ? jsonEncode({
            "id": onlinePlaylistTrack.albumTrack!.id,
            "name": onlinePlaylistTrack.albumTrack!.name,
            "images": onlinePlaylistTrack.albumTrack!.images
                .map((albumImagesTrack) => {
                      "url": albumImagesTrack.url,
                      "height": albumImagesTrack.height,
                      "width": albumImagesTrack.width,
                    })
                .toList(),
          })
        : null,
    'order_number': currentOrder + 1, // Increment order by 1
  };

  return await db.insert('opid_stid', row);
}
