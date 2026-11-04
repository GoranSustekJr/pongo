import 'package:pongo/exports.dart';

Future<void> updateOnPlaylistOrder(DatabaseHelper dbHelper, int opid,
    List<OnlinePlaylistTrack> newTrackOrder) async {
  Database db = await dbHelper.database;

  // Start a transaction to ensure atomicity
  await db.transaction((txn) async {
    // Delete all existing order numbers for the given opid
    await txn.rawDelete(
      "DELETE FROM opid_stid WHERE opid = ?",
      [opid],
    );

    // Insert the tracks with the new order
    for (int i = 0; i < newTrackOrder.length; i++) {
      await txn.rawInsert(
        "INSERT INTO opid_stid (opid, stid, title, artists, image, album, order_number) VALUES (?, ?, ?, ?, ?, ?, ?)",
        [
          opid,
          newTrackOrder[i].stid,
          newTrackOrder[i].title,
          jsonEncode(newTrackOrder[i].artistTrack),
          newTrackOrder[i].image,
          newTrackOrder[i].albumTrack != null
              ? jsonEncode({
                  "id": newTrackOrder[i].albumTrack!.id,
                  "name": newTrackOrder[i].albumTrack!.name,
                  "images": newTrackOrder[i]
                      .albumTrack!
                      .images
                      .map((albumImagesTrack) => {
                            "url": albumImagesTrack.url,
                            "height": albumImagesTrack.height,
                            "width": albumImagesTrack.width,
                          })
                      .toList(),
                })
              : null,
          i + 1
        ], // `i + 1` to set the order starting from 1
      );
    }
  });

/*  
  print(await DatabaseHelper().queryOnlineTrackIdsForPlaylist(opid)); */
}

Future<void> updateOnPlaylistName(
    DatabaseHelper dbHelper, int opid, String title) async {
  Database db = await dbHelper.database;
  await db.update(
    'online_playlist',
    {'title': title},
    where: 'opid = ?',
    whereArgs: [opid],
  );
}

Future<void> updateOnPlaylistCover(
    DatabaseHelper dbHelper, int opid, Uint8List cover) async {
  Database db = await dbHelper.database;
  await db.update(
    'online_playlist',
    {'cover': cover},
    where: 'opid = ?',
    whereArgs: [opid],
  );
}

Future<void> updateOnPlaylistShow(
    DatabaseHelper dHelper, int opid, List<String> stids) async {
  Database db = await dHelper.database;
  final placeholders = List.filled(stids.length, '?').join(', ');

  await db.rawUpdate(
    'UPDATE opid_stid SET hidden = ? WHERE opid = ? AND stid IN ($placeholders)',
    [false, opid, ...stids],
  );
}

Future<void> updateOnPlaylistHide(
    DatabaseHelper dHelper, int opid, List<String> stids) async {
  Database db = await dHelper.database;
  final placeholders = List.filled(stids.length, '?').join(', ');

  await db.rawUpdate(
      'UPDATE opid_stid SET hidden = ? WHERE opid = ? AND stid IN ($placeholders)',
      [true, opid, ...stids]);
}
