import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

continueCancelActionSheet(
    context, String title, String message, Function() function) {
  kIsApple
      ? showCupertinoModalPopup(
          context: context,
          builder: (context) => CupertinoActionSheet(
            title: Text(title),
            message: Text(message),
            actions: [
              CupertinoActionSheetAction(
                isDefaultAction: true,
                onPressed: () {
                  function();
                  Navigator.pop(context);
                },
                child: Text(
                  AppLocalizations.of(context)!.continuee,
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        )
      : showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: <Widget>[
                Row(
                  children: [
                    textButton(
                      AppLocalizations.of(context)!.cancel,
                      () {
                        Navigator.of(context).pop();
                      },
                      const TextStyle(color: Colors.red),
                    ),
                    Expanded(
                      child: Container(),
                    ),
                    textButton(
                      AppLocalizations.of(context)!.continuee,
                      () {
                        function();
                        Navigator.of(context).pop();
                      },
                      const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ],
            );
          },
        );
}
