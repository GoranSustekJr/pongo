import 'dart:ui';

import 'package:pongo/exports.dart';
import 'package:pongo/phone/views/library/pages/sleep%20alarm/data/sleep_alarm_data_manager.dart';
import 'package:pongo/phone/widgets/settings/tiles/sleep_alarm_tile.dart';

class SleepAlarmPhone extends StatelessWidget {
  const SleepAlarmPhone({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return ChangeNotifierProvider(
      create: (_) => SleepAlarmDataManager(
        context,
      ),
      child: Consumer<SleepAlarmDataManager>(
          builder: (context, sleepAlarmDataManager, child) {
        return Container(
          key: const ValueKey(true),
          width: size.width,
          height: size.height,
          decoration: AppConstants().backgroundBoxDecoration,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  snap: true,
                  floating: true,
                  pinned: true,
                  stretch: true,
                  backgroundColor: useBlur.value
                      ? Col.transp
                      : Col.realBackground.withAlpha(AppConstants().noBlur),
                  automaticallyImplyLeading: false,
                  expandedHeight: kIsApple ? size.height / 5 : size.height / 4,
                  title: Row(
                    children: [
                      backButton(context),
                      Expanded(
                        child: Container(),
                      ),
                      backLikeButton(context, AppIcons.add,
                          sleepAlarmDataManager.createNewSleepAlarm),
                    ],
                  ),
                  flexibleSpace: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                          sigmaX: useBlur.value ? 10 : 0,
                          sigmaY: useBlur.value ? 10 : 0),
                      child: FlexibleSpaceBar(
                        centerTitle: true,
                        title: Text(
                          AppLocalizations.of(context)!.sleep,
                          style: TextStyle(
                            fontSize: kIsApple ? 25 : 30,
                            fontWeight:
                                kIsApple ? FontWeight.w700 : FontWeight.w800,
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
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: sleepAlarmDataManager.showBody
                      ? sleepAlarmDataManager.sleepAlarms.isNotEmpty
                          ? ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount:
                                  sleepAlarmDataManager.sleepAlarms.length,
                              itemBuilder: (context, index) {
                                return sleepAlarmTile(
                                  context,
                                  index == 0,
                                  index ==
                                      sleepAlarmDataManager.sleepAlarms.length -
                                          1,
                                  sleepAlarmDataManager.sleepAlarms[index],
                                  () {},
                                  sleepAlarmDataManager.activeAlarm ==
                                      sleepAlarmDataManager
                                          .sleepAlarms[index].id,
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
                                    sleepAlarmDataManager
                                        .removeSleepAlarm(index);
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
                                    Colors.white,
                                    sleepAlarmDataManager.createNewSleepAlarm,
                                    size: 50,
                                  ),
                                  const Text(
                                    "Create new sleep alarm",
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                      : const SizedBox(),
                )
              ],
            ),
          ),
        );
      }),
    );
  }
}
