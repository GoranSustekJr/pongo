import '../../../exports.dart';

Future<CustomButton> removeDownloadedAlert(context) async {
  final ok = await FlutterPlatformAlert.showCustomAlert(
    windowTitle: AppLocalizations.of(context)!.removefromdownloaded,
    text: AppLocalizations.of(context)!.removefromdownloadedbody,
    negativeButtonTitle: AppLocalizations.of(context)!.cancel,
    positiveButtonTitle: AppLocalizations.of(context)!.okey,
    windowPosition: AlertWindowPosition.screenCenter,
  );
  return ok;
}
