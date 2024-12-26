import '../../../exports.dart';

Future<CustomButton> removeTrackFromPlaylistAlert(context) async {
  final ok = await FlutterPlatformAlert.showCustomAlert(
    windowTitle: AppLocalizations.of(context)!.removefromplaylist,
    text: AppLocalizations.of(context)!.removeselectedfromplaylist,
    negativeButtonTitle: AppLocalizations.of(context)!.cancel,
    positiveButtonTitle: AppLocalizations.of(context)!.okey,
    windowPosition: AlertWindowPosition.screenCenter,
  );
  return ok;
}
