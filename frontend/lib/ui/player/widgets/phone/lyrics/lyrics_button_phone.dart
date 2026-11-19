import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../../utils/platform.dart';
import '../../../../app/view_models/app_settings_view_model.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/dimens.dart';
import '../../../../core/ui/app_blur.dart';
import '../../../../core/ui/phone/buttons/icon_button.dart';
import '../../../../core/ui/phone/liquid_glass_background.dart';
import '../../../../core/ui/phone/liquid_glass_render.dart';

class LyricsButtonPhone extends StatelessWidget {
  final String stid;
  final int syncTimeDelay;
  final bool lyricsOn;
  final bool useSynced;
  final Function() changeLyricsOn;
  final Function() changeUseSynced;
  final Function() plus;
  final Function() minus;
  final Function() resetSyncTimeDelay;
  final Future<void> Function() saveSyncTimeDelay;
  const LyricsButtonPhone({
    super.key,
    required this.stid,
    required this.syncTimeDelay,
    required this.plus,
    required this.minus,
    required this.lyricsOn,
    required this.changeLyricsOn,
    required this.useSynced,
    required this.changeUseSynced,
    required this.resetSyncTimeDelay,
    required this.saveSyncTimeDelay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.decelerate,
      top: lyricsOn ? MediaQuery.of(context).padding.top + 12.5 : -50,
      child: liquidGlassLayer(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              liquidGlassBackground(
                enabled: context.readSettings.useLiquidGlass,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: liquidGlass(
                    radius: 360,
                    child: BackdropFilter(
                      filter: nonAppleBlur(context, 10),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(60),
                          color: kIsDesktop
                              ? const MacosColor.fromRGBO(
                                  40,
                                  40,
                                  40,
                                  0.8,
                                ) // Add transparency here
                              : context.readSettings.useBlur
                              ? Col.transp
                              : context.colors.realBackground.withAlpha(
                                  Dimens.noBlur,
                                ),
                        ),
                        child: iconButton(
                          lyricsOn ? AppIcons.lyricsFill : AppIcons.lyrics,
                          Colors.white,
                          changeLyricsOn,
                          edgeInsets: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              liquidGlassBackground(
                enabled: context.readSettings.useLiquidGlass,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: liquidGlass(
                    radius: 360,
                    child: BackdropFilter(
                      filter: nonAppleBlur(context, 10),
                      child: Container(
                        height: 40,
                        width: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(60),
                          color: kIsDesktop
                              ? const MacosColor.fromRGBO(
                                  40,
                                  40,
                                  40,
                                  0.8,
                                ) // Add transparency here
                              : context.readSettings.useBlur
                              ? Col.transp
                              : context.colors.realBackground.withAlpha(
                                  Dimens.noBlur,
                                ),
                        ),
                        child: Row(
                          children: [
                            if (kIsApple)
                              GestureDetector(
                                child: CupertinoButton(
                                  padding: const EdgeInsets.only(),
                                  onPressed: minus,
                                  child: const Icon(
                                    CupertinoIcons.minus,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            if (!kIsApple)
                              IconButton(
                                onPressed: minus,
                                icon: const Icon(CupertinoIcons.minus),
                              ),
                            Expanded(child: Container()),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: GestureDetector(
                                onLongPress: saveSyncTimeDelay,
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: resetSyncTimeDelay,
                                  child: Text(
                                    '${syncTimeDelay / 1000} s',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.fade,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(child: Container()),
                            if (!kIsApple)
                              IconButton(
                                onPressed: plus,
                                icon: const Icon(CupertinoIcons.plus),
                              ),
                            if (kIsApple)
                              CupertinoButton(
                                padding: const EdgeInsets.only(),
                                onPressed: plus,
                                child: const Icon(
                                  CupertinoIcons.plus,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              liquidGlassBackground(
                enabled: context.readSettings.useLiquidGlass,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: liquidGlass(
                    radius: 360,
                    child: BackdropFilter(
                      filter: nonAppleBlur(context, 10),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(60),
                          color: kIsDesktop
                              ? const MacosColor.fromRGBO(
                                  40,
                                  40,
                                  40,
                                  0.8,
                                ) // Add transparency here
                              : context.readSettings.useBlur
                              ? Col.transp
                              : context.colors.realBackground.withAlpha(
                                  Dimens.noBlur,
                                ),
                        ),
                        child: iconButton(
                          useSynced
                              ? CupertinoIcons.hourglass_tophalf_fill
                              : CupertinoIcons.hourglass_bottomhalf_fill,
                          Colors.white,
                          changeUseSynced,
                          edgeInsets: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
