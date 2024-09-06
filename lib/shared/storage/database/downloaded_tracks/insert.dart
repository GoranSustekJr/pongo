import 'package:pongo/exports.dart';

Future<void> insertDownloadedTrck(
  DatabaseHelper dbHelper,
  String stid,
  String audio,
  List<Map<String, dynamic>> artists,
  String title,
  int duration,
  String blurhash,
  Uint8List? image,
) async {
  Database db = await dbHelper.database;

  bool alreadyExists = await downloadedTrckAlreadyExists(dbHelper, stid);

  if (!alreadyExists) {
    Map<String, dynamic> trackData = {
      'stid': stid,
      'audio': audio,
      'artists': jsonEncode(artists),
      'title': title,
      'duration': duration,
      'blurhash': blurhash,
      'image': image,
    };

    await db.insert('downloaded_tracks', trackData);
  }
}
