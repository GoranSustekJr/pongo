import 'dart:ui';

import 'package:pongo/exports.dart';

class SleepPhone extends StatelessWidget {
  const SleepPhone({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
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
                  backLikeButton(context, AppIcons.add, () {
                    AudioServiceHandler audioServiceHandler =
                        Provider.of<AudioHandler>(context, listen: false)
                            as AudioServiceHandler;
                    /* audioServiceHandler.sleep(
                        sleep: true, sleepDuration: 5, sleepLinear: false); */
                    audioServiceHandler.sleep(
                        sleepDuration: 1,
                        sleepLinear: true,
                        alarmClock: true,
                        beforeEndTimeMin: 1,
                        wakeTime: const TimeOfDay(hour: 22, minute: 28));
                  }),
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
            const SliverToBoxAdapter(
              child: Column(
                children: [Text("data")],
              ),
            )
          ],
        ),
      ),
    );
  }
}
