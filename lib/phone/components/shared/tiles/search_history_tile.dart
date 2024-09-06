import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

Widget searchHistoryTile(
    String txt, bool last, Function() function, Function() removeFunction) {
  return kIsApple
      ? CupertinoButton(
          padding: const EdgeInsets.all(2.5),
          onPressed: function,
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Text(
                      txt,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.all(2.5),
                    onPressed: () async {
                      await DatabaseHelper().removeSearchHistoryEntry(txt);
                      removeFunction();
                    },
                    child: Icon(
                      AppIcons.cancel,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
      : InkWell(
          splashFactory: InkRipple.splashFactory,
          overlayColor: MaterialStateProperty.all<Color>(Colors.white),
          onTap: function,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  txt,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () async {
                  await DatabaseHelper().removeSearchHistoryEntry(txt);
                  removeFunction();
                },
                icon: Icon(
                  AppIcons.cancel,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
}
