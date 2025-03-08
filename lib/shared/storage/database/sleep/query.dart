// Artists
import 'package:pongo/exports.dart';

Future<List<String>> queryArtistHistNum(
    DatabaseHelper dbHelper, int num) async {
  Database db = await dbHelper.database;

  // Query the max order for the given opid
  final List<Map<String, dynamic>> maps =
      await db.query('lfh_artists', columns: ['said'], orderBy: 'id DESC');

  // Convert the results to a list of strings
  return List.generate(maps.length < num ? maps.length : num, (i) {
    return maps[i]['said'] as String;
  });
}
