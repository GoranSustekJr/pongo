// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:pongo/app/theme/colors.dart';
import 'package:pongo/core/constants/app_icons.dart';
import 'package:pongo/core/constants/platform.dart';
import 'package:pongo/core/storage/database/database_helper.dart';

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
                      style: TextStyle(
                        color: Col.text,
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
                      color: Col.icon,
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
                  style: TextStyle(
                    color: Col.text,
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
                  color: Col.icon,
                ),
              ),
            ],
          ),
        );
}
