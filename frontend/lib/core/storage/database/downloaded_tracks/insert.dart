import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:pongo/core/storage/database/database_helper.dart';
import 'package:pongo/core/storage/database/downloaded_tracks/query.dart';

Future<void> insertDownloadedTrck(
  DatabaseHelper dbHelper,
  String stid,
  String audio,
  List<Map<String, dynamic>> artists,
  String title,
  int duration,
  String? image,
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
      'image': image,
    };

    await db.insert('downloaded_tracks', trackData);
  }
}
