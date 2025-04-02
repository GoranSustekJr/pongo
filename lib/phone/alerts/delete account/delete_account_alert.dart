import '../../../exports.dart';

Future<CustomButton> deleteAccountAlert(context) async {
  final ok = await FlutterPlatformAlert.showCustomAlert(
    windowTitle: AppLocalizations.of(context).deleteyouraccount,
    text: AppLocalizations.of(context)
        .bydeletingyouraccountyouwilldeleteallyourprivilegesifpayingpremium,
    negativeButtonTitle: AppLocalizations.of(context).cancel,
    positiveButtonTitle: AppLocalizations.of(context).okey,
    windowPosition: AlertWindowPosition.screenCenter,
  );
  if (ok == CustomButton.positiveButton) {
    return await areYouSureAlert(context);
  } else {
    return ok;
  }
}

Future<CustomButton> areYouSureAlert(context) async {
  final ok = await FlutterPlatformAlert.showCustomAlert(
    windowTitle: AppLocalizations.of(context).deleteaccount,
    text: AppLocalizations.of(context).areyousurezouwanttodeleteyouraccount,
    negativeButtonTitle: AppLocalizations.of(context).cancel,
    positiveButtonTitle: AppLocalizations.of(context).delete,
    windowPosition: AlertWindowPosition.screenCenter,
  );
  return ok;
}
