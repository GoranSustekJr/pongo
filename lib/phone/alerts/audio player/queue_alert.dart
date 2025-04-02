import 'package:pongo/exports.dart';

Future<CustomButton> queueAlert(context) async {
  final ok = await FlutterPlatformAlert.showCustomAlert(
    windowTitle: AppLocalizations.of(context).clearqueue,
    text: AppLocalizations.of(context).clearqueuebody,
    negativeButtonTitle: AppLocalizations.of(context).cancel,
    positiveButtonTitle: AppLocalizations.of(context).okey,
    windowPosition: AlertWindowPosition.screenCenter,
  );
  return ok;
}
