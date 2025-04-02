import 'package:flutter/cupertino.dart';
import '../../../exports.dart';

class Favourites {
  Future<void> add(context, Favourite favourite) async {
    final isAlreadyFavourite =
        await DatabaseHelper().favouriteTrackAlreadyExists(favourite.stid);

    if (isAlreadyFavourite) {
      await DatabaseHelper().removeFavouriteTrack(favourite);
      Notifications().showSpecialNotification(
          notificationsContext.value!,
          AppLocalizations.of(notificationsContext.value!).successful,
          AppLocalizations.of(notificationsContext.value!)
              .trackremovedfromfavourites,
          CupertinoIcons.heart_slash);
    } else {
      await DatabaseHelper().insertFavouriteTrack(favourite);
      Notifications().showSpecialNotification(
          notificationsContext.value!,
          AppLocalizations.of(notificationsContext.value!).successful,
          AppLocalizations.of(notificationsContext.value!).trackisnowafavourite,
          AppIcons.heartFill);
    }
  }
}
