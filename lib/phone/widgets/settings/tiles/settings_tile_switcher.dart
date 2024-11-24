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

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: ClipRRect(
      child: kIsApple
          ? Container(
              height: 50,
              width: MediaQuery.of(context).size.width - 20,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                color: Col.primaryCard.withAlpha(150),
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  function(!boolean);
                },
                child: Column(
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
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white.withAlpha(150),
                                ),
                              ),
                          ],
                        )),
                        SizedBox(
                            width: 28,
                            height: 48,
                            child: CupertinoSwitch(
                                value: boolean,
                                activeColor: Col.onIcon,
                                trackColor: Col.realBackground,
                                /*    activeTrackColor: Col.onIcon,
                                inactiveThumbColor: Col.onIcon,
                                inactiveTrackColor: Col.realBackground,
                                trackOutlineColor:
                                    MaterialStateProperty.resolveWith<Color?>(
                                        (states) => Col.realBackground), */
                                onChanged: (value) {
                                  function(value);
                                })),
                        const SizedBox(
                          width: 30,
                        )
                      ],
                    ),
                  ],
                ),
              ),
            )
          : InkWell(
              onTap: () {
                function(!boolean);
              },
              borderRadius: borderRadius,
              child: Container(
                height: 60,
                width: MediaQuery.of(context).size.width - 20,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  color: Col.primaryCard.withAlpha(200),
                ),
                child: Column(
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
                            height: 58,
                            child: Icon(icon, color: Col.onIcon, size: 27.5)),
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 17.5),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.white.withAlpha(150),
                                    fontSize: 12.5),
                              ),
                          ],
                        )),
                        SizedBox(
                            width: 28,
                            height: 58,
                            child: Switch(
                                value: boolean,
                                activeColor: Col.primary,
                                inactiveThumbColor: Col.primary,
                                inactiveTrackColor: Col.realBackground,
                                activeTrackColor: Col.primary.withAlpha(100),
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
                ),
              ),
            ),
    ),
  );
}
