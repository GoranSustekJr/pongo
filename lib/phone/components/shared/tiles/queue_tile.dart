import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

class QueueTile extends StatelessWidget {
  final String title;
  final String artist;
  final String imageUrl;
  final Function() onTap;
  final Widget? trailing;
  const QueueTile({
    super.key,
    required this.onTap,
    this.trailing,
    required this.title,
    required this.artist,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return kIsApple
        ? SizedBox(
            height: 85,
            width: MediaQuery.of(context).size.width,
            child: CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                onPressed: onTap,
                child: Row(
                  children: [
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7.5),
                        color: Col.realBackground.withAlpha(150),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7.5),
                        child: imageUrl == ""
                            ? Center(
                                child: Icon(AppIcons.blankTrack,
                                    color: Colors.white),
                              )
                            : CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
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
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          razh(2.5),
                          Text(
                            artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withAlpha(200),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      child: trailing,
                    ),
                  ],
                )),
          )
        : InkWell(
            splashColor: Colors.white.withAlpha(200),
            highlightColor: Colors.white.withAlpha(150),
            onTap: onTap,
            child: SizedBox(
              height: 85,
              width: MediaQuery.of(context).size.width,
              child: ListTile(
                leading: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                    maxWidth: 66,
                    maxHeight: 66,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7.5),
                    child: imageUrl == ""
                        ? Center(
                            child: Icon(AppIcons.blankTrack),
                          )
                        : CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                title: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ),
            ),
          );
  }
}
