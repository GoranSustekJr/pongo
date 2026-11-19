import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:interactive_slider/interactive_slider.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/sleep_alarm/sleep_alarm.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/platform.dart';
import '../../../app/view_models/app_settings_view_model.dart';
import '../../../core/app_icons.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimens.dart';
import '../../../core/ui/app_blur.dart';
import '../../../core/ui/phone/buttons/back_button.dart';
import '../../../core/ui/phone/buttons/back_like_button.dart';
import '../../../core/ui/phone/buttons/icon_button.dart';
import '../../../core/ui/phone/liquid_glass_background.dart';
import '../../../core/ui/phone/sticky_header_delegate.dart';
import '../../view_models/sleep_alarm_view_model.dart';
import 'sleep_alarm_add_phone.dart';
import 'sleep_alarm_tile.dart';

class SleepAlarmPhone extends StatefulWidget {
  const SleepAlarmPhone({super.key});

  @override
  State<SleepAlarmPhone> createState() => _SleepAlarmPhoneState();
}

class _SleepAlarmPhoneState extends State<SleepAlarmPhone> {
  late final SleepAlarmViewModel viewModel;
  final scrollController = ScrollController();
  double scrollControllerOffset = 0;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      setState(() {
        scrollControllerOffset = scrollController.offset < 0
            ? 0
            : scrollController.offset;
      });
    });
    viewModel = SleepAlarmViewModel(
      alarms: context.read(),
      player: context.read(),
      settings: context.read(),
      messages: context.read(),
    );
  }

  @override
  void dispose() {
    viewModel.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void createNewSleepAlarm() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) =>
          SleepAlarmAddPhone(sleepAlarm: null, insertSleepAlarm: viewModel.add),
    );
  }

  void updateSleepAlarm(SleepAlarm sleepAlarm) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => SleepAlarmAddPhone(
        sleepAlarm: sleepAlarm,
        insertSleepAlarm: viewModel.update,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final sleepAlarmDataManager = viewModel;
        return Container(
          key: const ValueKey(true),
          width: size.width,
          height: size.height,
          decoration: context.colors.backgroundBoxDecoration,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            body: Scrollbar(
              controller: scrollController,
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverAppBar(
                    //snap: true,
                    //floating: true,
                    pinned: true,
                    stretch: true,
                    backgroundColor: context.readSettings.useBlur
                        ? Col.transp
                        : context.colors.realBackground.withAlpha(
                            Dimens.noBlur,
                          ),
                    automaticallyImplyLeading: false,
                    expandedHeight: kIsApple
                        ? size.height / 5
                        : size.height / 4,
                    title: Row(
                      children: [
                        backButton(context),
                        Expanded(child: Container()),
                        backLikeButton(
                          context,
                          AppIcons.add,
                          createNewSleepAlarm,
                        ),
                      ],
                    ),
                    flexibleSpace: ClipRRect(
                      child: Stack(
                        children: [
                          Opacity(
                            opacity:
                                MediaQuery.of(context).size.height / 3 <=
                                    scrollControllerOffset
                                ? 1
                                : scrollControllerOffset /
                                      (MediaQuery.of(context).size.height / 3),
                            child: liquidGlassBackground(
                              child: BackdropFilter(
                                filter: nonAppleBlur(context, 10),
                                child: Container(),
                              ),
                            ),
                          ),
                          FlexibleSpaceBar(
                            centerTitle: true,
                            title: Text(
                              AppLocalizations.of(context).sleep,
                              style: TextStyle(
                                fontSize: kIsApple ? 25 : 30,
                                fontWeight: kIsApple
                                    ? FontWeight.w700
                                    : FontWeight.w800,
                                color: context.colors.text,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                            ),
                            stretchModes: const [
                              StretchMode.zoomBackground,
                              StretchMode.blurBackground,
                              StretchMode.fadeTitle,
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: StickyHeaderDelegate(
                      minHeight: 75,
                      maxHeight: 75,
                      padding: EdgeInsets.only(top: kIsApple ? 5 : 0),
                      child: ClipRRect(
                        child: liquidGlassBackground(
                          child: BackdropFilter(
                            filter: nonAppleBlur(context, 10),
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              height: 75,
                              color: context.readSettings.useBlur
                                  ? Col.transp
                                  : context.colors.realBackground.withAlpha(
                                      Dimens.noBlur,
                                    ),
                              child: Column(
                                children: [
                                  Builder(
                                    builder: (context) {
                                      final double volume =
                                          sleepAlarmDataManager.deviceVolume;

                                      return InteractiveSlider(
                                        padding: const EdgeInsets.only(
                                          top: 20,
                                          left: 10,
                                          right: 10,
                                        ),
                                        initialProgress: volume,
                                        iconColor: context.colors.icon,
                                        foregroundColor: context.colors.icon,
                                        backgroundColor: context.colors.icon
                                            .withAlpha(30),
                                        focusedHeight: 10,
                                        startIcon: const Icon(
                                          CupertinoIcons.speaker_1_fill,
                                        ),
                                        endIcon: const Icon(
                                          CupertinoIcons.speaker_3_fill,
                                        ),
                                        onChanged: sleepAlarmDataManager
                                            .updateSleepAlarmDeviceVolume,
                                      );
                                    },
                                  ),
                                  Text(
                                    AppLocalizations.of(context)
                                        .maximumvolumeofthealarm,
                                    style: TextStyle(
                                      color: context.colors.text,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: sleepAlarmDataManager.showBody
                        ? sleepAlarmDataManager.sleepAlarms.isNotEmpty
                              ? ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  padding: EdgeInsets.only(
                                    top: 35,
                                    bottom:
                                        MediaQuery.of(context).padding.bottom +
                                        15,
                                  ),
                                  itemCount:
                                      sleepAlarmDataManager.sleepAlarms.length,
                                  itemBuilder: (context, index) {
                                    return sleepAlarmTile(
                                      context,
                                      index == 0,
                                      index ==
                                          sleepAlarmDataManager
                                                  .sleepAlarms
                                                  .length -
                                              1,
                                      sleepAlarmDataManager.sleepAlarms[index],
                                      () {
                                        updateSleepAlarm(
                                          sleepAlarmDataManager
                                              .sleepAlarms[index],
                                        );
                                      },
                                      sleepAlarmDataManager.activeAlarm ==
                                          sleepAlarmDataManager
                                              .sleepAlarms[index]
                                              .id,
                                      (val) {
                                        if (val) {
                                          sleepAlarmDataManager
                                              .changeActiveSleepAlarm(index);
                                        } else {
                                          sleepAlarmDataManager
                                              .changeActiveSleepAlarm(-1);
                                        }
                                      },
                                      () {
                                        sleepAlarmDataManager.removeSleepAlarm(
                                          index,
                                        );
                                      },
                                    );
                                  },
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      iconButton(
                                        AppIcons.add,
                                        context.colors.icon,
                                        createNewSleepAlarm,
                                        size: 50,
                                      ),
                                      Text(
                                        AppLocalizations.of(context)
                                            .createnewsleepalarm,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: context.colors.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
