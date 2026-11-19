import 'package:flutter/widgets.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';

import '../../../../../l10n/app_localizations.dart';

Future<CustomButton> deleteAccountAlert(BuildContext context) async {
  final ok = await FlutterPlatformAlert.showCustomAlert(
    windowTitle: AppLocalizations.of(context).deleteyouraccount,
    text: AppLocalizations.of(context)
        .bydeletingyouraccountyouwilldeleteallyourprivilegesifpayingpremium,
    negativeButtonTitle: AppLocalizations.of(context).cancel,
    positiveButtonTitle: AppLocalizations.of(context).okey,
    windowPosition: AlertWindowPosition.screenCenter,
  );
  if (ok != CustomButton.positiveButton || !context.mounted) return ok;
  return areYouSureAlert(context);
}

Future<CustomButton> areYouSureAlert(BuildContext context) async {
  final ok = await FlutterPlatformAlert.showCustomAlert(
    windowTitle: AppLocalizations.of(context).deleteaccount,
    text: AppLocalizations.of(context).areyousurezouwanttodeleteyouraccount,
    negativeButtonTitle: AppLocalizations.of(context).cancel,
    positiveButtonTitle: AppLocalizations.of(context).delete,
    windowPosition: AlertWindowPosition.screenCenter,
  );
  return ok;
}
