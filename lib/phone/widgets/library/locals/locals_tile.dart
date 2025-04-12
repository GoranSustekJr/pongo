import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

class LocalsTile extends StatelessWidget {
  final Track track;
  final bool first;
  final bool last;
  final Function() function;
  final Widget? trailing;
  const LocalsTile({
    super.key,
    required this.track,
    required this.first,
    required this.last,
    required this.function,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    double radius = 15;
    BorderRadius borderRadius = BorderRadius.only(
      topLeft: first ? Radius.circular(radius) : Radius.zero,
      topRight: first ? Radius.circular(radius) : Radius.zero,
      bottomLeft: last ? Radius.circular(radius) : Radius.zero,
      bottomRight: last ? Radius.circular(radius) : Radius.zero,
    );

    final Widget child = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!first)
          Container(
            height: 1,
            width: MediaQuery.of(context).size.width - 75,
            color: Col.onIcon.withAlpha(50),
          ),
        Expanded(
          child: Container(),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7.5),
                  color: Col.realBackground.withAlpha(150),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7.5),
                  child: track.image ==
                          null //!track["track"].keys.contains("album")
                      ? Center(
                          child: Icon(AppIcons.blankTrack, color: Col.icon),
                        )
                      : FadeInImage(
                          width: 250,
                          fit: BoxFit.cover,
                          height: 250,
                          placeholder:
                              const AssetImage('assets/images/placeholder.png'),
                          fadeInDuration: const Duration(milliseconds: 200),
                          fadeOutDuration: const Duration(milliseconds: 200),
                          image: FileImage(
                            File(track.image!.path),
                          ),
                        ),
                ),
              ),
            ),
            razw(12.5),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                      color: Col.text,
                    ),
                  ),
                  razh(2.5),
                  Text(
                    (track.artists.map((artist) => artist.name).join(', ')),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: Col.text.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              child: trailing,
            ),
          ],
        ),
        Expanded(
          child: Container(),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: 1,
        child: ClipRRect(
          child: kIsApple
              ? Container(
                  height: 65,
                  width: MediaQuery.of(context).size.width - 20,
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    color: Col.transp,
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      function();
                    },
                    child: child,
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
                    child: child,
                  ),
                ),
        ),
      ),
    );
  }
}
