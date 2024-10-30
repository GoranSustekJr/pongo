import 'package:flutter/cupertino.dart';
import '../../../exports.dart';

class Favourites {
  Future<void> add(context, String stid) async {
    final isAlreadyFavourite =
        await DatabaseHelper().favouriteTrackAlreadyExists(stid);

    if (isAlreadyFavourite) {
      await DatabaseHelper().removeFavouriteTrack(stid);
      Notifications().showSpecialNotification(
          context,
          AppLocalizations.of(context)!.successful,
          AppLocalizations.of(context)!.trackremovedfromfavourites,
          CupertinoIcons.heart_slash);
    } else {
      await DatabaseHelper().insertFavouriteTrack(stid);
      Notifications().showSpecialNotification(
          context,
          AppLocalizations.of(context)!.successful,
          AppLocalizations.of(context)!.trackisnowafavourite,
          AppIcons.heartFill);
    }
  }
}
