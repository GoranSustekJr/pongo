import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

settingsTile(
    context,
    bool first,
    bool last,
    IconData icon,
    IconData? trailingIcon,
    String title,
    String? subtitle,
    Function() function) {
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
                color: Col.primaryCard.withAlpha(200),
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  function();
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
                        if (trailingIcon != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Container(
                              height: 25,
                              width: 1,
                              color: Col.onIcon.withAlpha(200),
                            ),
                          ),
                        if (trailingIcon != null)
                          SizedBox(
                              width: 28,
                              height: 48,
                              child: Icon(trailingIcon,
                                  color: Col.onIcon.withAlpha(200), size: 20)),
                        const SizedBox(
                          width: 15,
                        )
                      ],
                    ),
                  ],
                ),
              ),
            )
          : InkWell(
              onTap: () {
                function();
              },
              splashColor: Colors.white.withAlpha(100),
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
                              style: const TextStyle(
                                fontSize: 17.5,
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white.withAlpha(150),
                                ),
                              ),
                          ],
                        )),
                        if (trailingIcon != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Container(
                              height: 25,
                              width: 1,
                              color: Col.onIcon.withAlpha(200),
                            ),
                          ),
                        if (trailingIcon != null)
                          SizedBox(
                              width: 28,
                              height: 58,
                              child: Icon(trailingIcon,
                                  color: Col.onIcon.withAlpha(200), size: 20)),
                        const SizedBox(
                          width: 15,
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
