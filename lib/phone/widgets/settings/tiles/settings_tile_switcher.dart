// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';

import '../../../../../exports.dart';

settingsTileSwitcher(
  context,
  bool first,
  bool last,
  IconData icon,
  bool boolean,
  String title,
  String? subtitle,
  Function(bool) function,
) {
  double radius = 15;
  BorderRadius borderRadius = BorderRadius.only(
    topLeft: first ? Radius.circular(radius) : Radius.zero,
    topRight: first ? Radius.circular(radius) : Radius.zero,
    bottomLeft: last ? Radius.circular(radius) : Radius.zero,
    bottomRight: last ? Radius.circular(radius) : Radius.zero,
  );

  Widget child = Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      if (!first)
        Container(
          height: 1,
          width: MediaQuery.of(context).size.width - 70,
          color: Col.onIcon.withAlpha(50),
        ),
      Row(
        children: [
          SizedBox(
              width: 58,
              height: 48,
              child: Icon(icon, color: Col.onIcon, size: 27.5)),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Col.text,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color: Col.text.withAlpha(150),
                  ),
                ),
            ],
          )),
          SizedBox(
              width: 28,
              height: 48,
              child: kIsApple
                  ? CupertinoSwitch(
                      value: boolean,
                      activeColor: Col.onIcon,
                      onChanged: (value) {
                        function(value);
                      })
                  : Switch(
                      value: boolean,
                      activeColor: Col.onIcon,
                      inactiveTrackColor: Col.icon.withAlpha(75),
                      thumbColor: MaterialStateProperty.resolveWith<Color?>(
                          (states) => Colors.white),
                      trackOutlineColor:
                          MaterialStateProperty.resolveWith<Color?>(
                              (states) => Col.realBackground),
                      onChanged: (value) {
                        function(value);
                      })),
          const SizedBox(
            width: 30,
          )
        ],
      ),
    ],
  );

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: ClipRRect(
        child: Container(
      height: 50,
      width: MediaQuery.of(context).size.width - 20,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: Col.primaryCard.withAlpha(150),
      ),
      child: kIsApple
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                function(!boolean);
              },
              child: child,
            )
          : ClipRRect(
              borderRadius: borderRadius,
              child: inkWell(child, () {
                function(!boolean);
              })),
    )),
  );
}
