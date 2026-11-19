import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../utils/platform.dart';
import '../../../core/app_icons.dart';
import '../../../core/themes/colors.dart';

Widget searchHistoryTile(
  String txt,
  bool last,
  Function() function,

  /// Called to forget `txt`.
  Function() removeFunction,
) => Builder(
  builder: (context) =>
      _searchHistoryTile(context, txt, last, function, removeFunction),
);

Widget _searchHistoryTile(
  BuildContext context,
  String txt,
  bool last,
  Function() function,
  Function() removeFunction,
) {
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
                        color: context.colors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.all(2.5),
                    onPressed: () {
                      removeFunction();
                    },
                    child: Icon(AppIcons.cancel, color: context.colors.icon),
                  ),
                ],
              ),
            ],
          ),
        )
      : InkWell(
          splashFactory: InkRipple.splashFactory,
          overlayColor: WidgetStateProperty.all<Color>(Colors.white),
          onTap: function,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  txt,
                  style: TextStyle(
                    color: context.colors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () {
                  removeFunction();
                },
                icon: Icon(AppIcons.cancel, color: context.colors.icon),
              ),
            ],
          ),
        );
}
