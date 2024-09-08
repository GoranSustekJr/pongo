import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

trackInfoButton(context, String trackId, Function() download) {
  GlobalKey key = GlobalKey();
  return kIsApple
      ? PullDownButton(
          itemBuilder: (context) => [
            PullDownMenuItem(
              title: AppLocalizations.of(context)!.download,
              icon: CupertinoIcons.cloud_download,
              onTap: () {
                download();
              },
            ),
            const PullDownMenuDivider(),
            PullDownMenuItem(
              title: AppLocalizations.of(context)!.addtoplaylist,
              icon: AppIcons.musicAlbums,
              onTap: () {
                // addSongToOnlinePlaylist(context, trackId);
              },
            ),
            const PullDownMenuDivider(),
            PullDownMenuItem(
              title: AppLocalizations.of(context)!.like,
              icon: AppIcons.heart,
              onTap: () {},
            ),
          ],
          position: PullDownMenuPosition.above,
          buttonBuilder: (context, showMenu) => CupertinoButton(
            onPressed: showMenu,
            padding: EdgeInsets.zero,
            child: Icon(
              AppIcons.info,
              color: Colors.white,
            ),
          ),
        )
      : SizedBox(
          key: key,
          width: 50,
          height: 50,
          child: IconButton(
            splashColor: Col.primary,
            icon: const Icon(AppIcons.info),
            onPressed: () {
              PopupMenu(
                context: context,
                config: MenuConfig(
                  itemWidth: 150,
                  backgroundColor: Col.primaryCard,
                  lineColor: Colors.greenAccent,
                  highlightColor: Colors.lightGreenAccent,
                  type: MenuType.list,
                ),
                items: [
                  PopUpMenuItem(
                      title: AppLocalizations.of(context)!.download,
                      image: Icon(
                        AppIcons.download,
                        color: Colors.white,
                      )),
                  PopUpMenuItem(
                      title: AppLocalizations.of(context)!.addtoplaylist,
                      image: Icon(
                        AppIcons.musicAlbums,
                        color: Colors.white,
                      )),
                  PopUpMenuItem(
                      title: AppLocalizations.of(context)!.like,
                      image: Icon(
                        AppIcons.heart,
                        color: Colors.white,
                      )),
                ],
              ).show(widgetKey: key);
            },
          ),
        );
}
