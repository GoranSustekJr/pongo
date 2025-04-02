import 'package:flutter/cupertino.dart';

import '../../../../../../../exports.dart';

newPlaylistTitle(context, int opid, Function(String) function) {
  final TextEditingController titleController = TextEditingController();
  kIsApple
      ? showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              content: Column(
                children: [
                  Text(
                    AppLocalizations.of(context).changeplaylisttile,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  razh(2),
                  Text(
                    AppLocalizations.of(context).changeplaylisttilebody,
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 13,
                    ),
                  ),
                  razh(15),
                  CupertinoTextField(
                    style: const TextStyle(color: Colors.white),
                    controller: titleController,
                  ),
                ],
              ),
              actions: [
                CupertinoButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty) {
                      await DatabaseHelper()
                          .updateOnlinePlaylistName(opid, titleController.text);
                      function(titleController.text);
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(
                    AppLocalizations.of(context).change,
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
                CupertinoButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    AppLocalizations.of(context).cancel,
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            );
          },
        )
      : showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context).changeplaylisttile,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  razh(2),
                  Text(
                    AppLocalizations.of(context).changeplaylisttilebody,
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 13,
                    ),
                  ),
                  razh(15),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    controller: titleController,
                  ),
                ],
              ),
              actions: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        AppLocalizations.of(context).cancel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    Expanded(
                      child: Container(),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (titleController.text.isNotEmpty) {
                          await DatabaseHelper().updateOnlinePlaylistName(
                              opid, titleController.text);
                          function(titleController.text);

                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(
                        AppLocalizations.of(context).change,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            );
          },
        );
}
