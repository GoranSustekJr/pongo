import 'package:flutter/widgets.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';

import '../../../../../l10n/app_localizations.dart';

Future<CustomButton> removeFavouriteAlert(BuildContext context) async {
  final ok = await FlutterPlatformAlert.showCustomAlert(
    windowTitle: AppLocalizations.of(context).removefromfavourites,
    text: AppLocalizations.of(context).removefromfavouritesbody,
    negativeButtonTitle: AppLocalizations.of(context).cancel,
    positiveButtonTitle: AppLocalizations.of(context).okey,
    windowPosition: AlertWindowPosition.screenCenter,
  );
  return ok;
}
