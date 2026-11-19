import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:kr_pull_down_button/pull_down_button.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/app_icons.dart';
import '../../../../shell/view_models/shell_view_model.dart';
import '../../../view_models/player_view_model.dart';
import '../alerts/halt_alert.dart';

List<PullDownMenuEntry> queueMorePullDownMenuItems(
  BuildContext context,
  Function() edit,
  Function() saveAsPlaylist,
  Function() download,
) {
  return [
    PullDownMenuItem(
      onTap: edit,
      title: AppLocalizations.of(context).edit,
      icon: AppIcons.edit,
    ),
    const PullDownMenuDivider.large(),
    /* PullDownMenuItem(
            onTap: () async {
              await ClearQueue().clear(context);
            },
            title: AppLocalizations.of(context)!.clear,
            icon: AppIcons.trash,
            itemTheme: const PullDownMenuItemTheme(
              textStyle: TextStyle(
                overflow: TextOverflow.ellipsis,
                height: 1,
              ),
            ),
          ),
          const PullDownMenuDivider.large(), */
    PullDownMenuItem(
      onTap: saveAsPlaylist,
      title: AppLocalizations.of(context).saveasplaylist,
      icon: AppIcons.playlist,
      itemTheme: const PullDownMenuItemTheme(
        textStyle: TextStyle(overflow: TextOverflow.ellipsis, height: 1),
      ),
    ),
    const PullDownMenuDivider(),
    PullDownMenuItem(
      onTap: download,
      title: AppLocalizations.of(context).download,
      icon: AppIcons.download,
      itemTheme: const PullDownMenuItemTheme(
        textStyle: TextStyle(overflow: TextOverflow.ellipsis, height: 1),
      ),
    ),
    const PullDownMenuDivider.large(),
    PullDownMenuItem(
      onTap: () async {
        final CustomButton ok = await haltAlert(context);
        if (ok == CustomButton.positiveButton && context.mounted) {
          context.shell.currentTrackHeight.value = 0;
          final player = context.player;

          await player.halt();
        }
      },
      title: AppLocalizations.of(context).halt,
      icon: AppIcons.halt,
      itemTheme: const PullDownMenuItemTheme(
        textStyle: TextStyle(overflow: TextOverflow.ellipsis, height: 1),
      ),
    ),
  ];
}
