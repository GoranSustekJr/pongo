import 'package:flutter/cupertino.dart';

import 'package:pongo/core/constants/app_icons.dart';
import 'package:pongo/core/notifications/notifications.dart';
import 'package:pongo/core/state/globals.dart';
import 'package:pongo/core/storage/database/database_helper.dart';
import 'package:pongo/features/library/models/favourite.dart';
import 'package:pongo/l10n/app_localizations.dart';

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
