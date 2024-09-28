import 'package:pongo/exports.dart';

Future<void> insertFavouriteTrck(
  DatabaseHelper dbHelper,
  String stid,
) async {
  Database db = await dbHelper.database;

  bool alreadyExists = await downloadedTrckAlreadyExists(dbHelper, stid);

  if (!alreadyExists) {
    Map<String, dynamic> trackData = {
      'stid': stid,
    };

    await db.insert('favourites', trackData);
  }
}
