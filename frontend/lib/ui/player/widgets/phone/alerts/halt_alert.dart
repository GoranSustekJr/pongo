import 'package:flutter/widgets.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';

import '../../../../../l10n/app_localizations.dart';

Future<CustomButton> haltAlert(BuildContext context) async {
  final ok = await FlutterPlatformAlert.showCustomAlert(
    windowTitle: AppLocalizations.of(context).haltmusicplayer,
    text: AppLocalizations.of(context).haltmusicplayerbody,
    negativeButtonTitle: AppLocalizations.of(context).cancel,
    positiveButtonTitle: AppLocalizations.of(context).halt,
    windowPosition: AlertWindowPosition.screenCenter,
  );
  return ok;
}
