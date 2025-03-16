import 'package:pongo/exports.dart';

Future<void> insertFavouriteTrck(
  DatabaseHelper dbHelper,
  Favourite favourite,
) async {
  Database db = await dbHelper.database;

  bool alreadyExists =
      await favouriteTrckAlreadyExists(dbHelper, favourite.stid);

  if (!alreadyExists) {
    Map<String, dynamic> trackData = {
      'stid': favourite.stid,
      'title': favourite.title,
      'artists': jsonEncode(favourite.artistTrack),
      'image': favourite.image,
      'album': favourite.albumTrack != null
          ? jsonEncode({
              "id": favourite.albumTrack!.id,
              "name": favourite.albumTrack!.name,
              "images": favourite.albumTrack!.images
                  .map((albumImagesTrack) => {
                        "url": albumImagesTrack.url,
                        "height": albumImagesTrack.height,
                        "width": albumImagesTrack.width,
                      })
                  .toList(),
            })
          : null,
    };

    await db.insert('favourites', trackData);
  }
}
