import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:kr_pull_down_button/pull_down_button.dart';
import 'package:provider/provider.dart';

import 'package:pongo/core/audio/audio_service_handler.dart';
import 'package:pongo/core/constants/app_icons.dart';
import 'package:pongo/core/state/globals.dart';
import 'package:pongo/features/player/presentation/phone/alerts/halt_alert.dart';
import 'package:pongo/l10n/app_localizations.dart';

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
        textStyle: TextStyle(
          overflow: TextOverflow.ellipsis,
          height: 1,
        ),
      ),
    ),
    const PullDownMenuDivider(),
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
    const PullDownMenuDivider.large(),
    PullDownMenuItem(
      onTap: () async {
        CustomButton ok = await haltAlert(context);
        if (ok == CustomButton.positiveButton) {
          currentTrackHeight.value = 0;
          final audioServiceHandler =
              Provider.of<AudioHandler>(context, listen: false)
                  as AudioServiceHandler;

          await audioServiceHandler.halt();
        }
      },
      title: AppLocalizations.of(context).halt,
      icon: AppIcons.halt,
      itemTheme: const PullDownMenuItemTheme(
        textStyle: TextStyle(
          overflow: TextOverflow.ellipsis,
          height: 1,
        ),
      ),
    ),
  ];
}
