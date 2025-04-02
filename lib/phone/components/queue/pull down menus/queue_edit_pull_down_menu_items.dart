import 'package:pongo/exports.dart';

List<PullDownMenuEntry> queueEditPullDownMenuItems(
  BuildContext context,
  Function() edit,
  Function() remove,
  Function() download,
) {
  return kIsApple
      ? [
          PullDownMenuItem(
            onTap: edit,
            title: AppLocalizations.of(context).cancel,
            icon: AppIcons.cancel,
          ),
          const PullDownMenuDivider.large(),
          PullDownMenuItem(
            onTap: remove,
            title: AppLocalizations.of(context).clear,
            icon: AppIcons.trash,
            itemTheme: const PullDownMenuItemTheme(
              textStyle: TextStyle(
                overflow: TextOverflow.ellipsis,
                height: 1,
              ),
            ),
          ),
          const PullDownMenuDivider.large(),
          PullDownMenuItem(
            onTap: download,
            title: AppLocalizations.of(context).download,
            icon: AppIcons.download,
            itemTheme: const PullDownMenuItemTheme(
              textStyle: TextStyle(
                overflow: TextOverflow.ellipsis,
                height: 1,
              ),
            ),
          ),
        ]
      : [];
}
