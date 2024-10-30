import 'package:flutter/cupertino.dart';

import '../../../exports.dart';

libraryTile(
  context,
  bool first,
  bool last,
  IconData icon,
  IconData trailingIcon,
  String title,
  String? subtitle,
  Function() function,
) {
  const double radius = 15;
  BorderRadius borderRadius = BorderRadius.only(
    topLeft: first ? const Radius.circular(radius) : Radius.zero,
    topRight: first ? const Radius.circular(radius) : Radius.zero,
    bottomLeft: last ? const Radius.circular(radius) : Radius.zero,
    bottomRight: last ? const Radius.circular(radius) : Radius.zero,
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
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (!first)
                      Container(
                        height: 1,
                        width: MediaQuery.of(context).size.width - 70,
                        color: Col.onIcon.withAlpha(50),
                      ),
                    const Expanded(
                      child: SizedBox(),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Container(
                            height: 25,
                            width: 1,
                            color: Col.onIcon.withAlpha(200),
                          ),
                        ),
                        SizedBox(
                          width: 28,
                          height: 40,
                          child: Icon(
                            trailingIcon,
                            size: 22.5,
                            color: Col.onIcon,
                          ),
                        ),
                        const SizedBox(
                          width: 15,
                        )
                      ],
                    ),
                    const Expanded(
                      child: SizedBox(),
                    ),
                  ],
                ),
              ),
            )
          : InkWell(
              onTap: () {
                function();
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
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (!first)
                      Container(
                        height: 1,
                        width: MediaQuery.of(context).size.width - 70,
                        color: Col.onIcon.withAlpha(50),
                      ),
                    const Expanded(
                      child: SizedBox(),
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
                                  fontSize: 2.5,
                                  color: Colors.white.withAlpha(150),
                                ),
                              ),
                          ],
                        )),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Container(
                            height: 25,
                            width: 1,
                            color: Col.onIcon.withAlpha(200),
                          ),
                        ),
                        SizedBox(
                            width: 28,
                            height: kIsApple ? 40 : 58,
                            child: Icon(
                              trailingIcon,
                              size: kIsApple ? 22.5 : 27.5,
                            )),
                        const SizedBox(
                          width: 30,
                        )
                      ],
                    ),
                    const Expanded(
                      child: SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
    ),
  );
}
