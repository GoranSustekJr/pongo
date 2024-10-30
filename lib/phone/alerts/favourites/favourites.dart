import '../../../exports.dart';

Future<CustomButton> removeFavouriteAlert(context) async {
  final ok = await FlutterPlatformAlert.showCustomAlert(
    windowTitle: AppLocalizations.of(context)!.removefromfavourites,
    text: AppLocalizations.of(context)!.removefromfavouritesbody,
    negativeButtonTitle: AppLocalizations.of(context)!.cancel,
    positiveButtonTitle: AppLocalizations.of(context)!.okey,
    windowPosition: AlertWindowPosition.screenCenter,
  );
  return ok;
}
