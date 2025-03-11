import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/views/library/pages/sleep%20alarm/views/sleep_alarm_add_phone.dart';

class SleepAlarmDataManager with ChangeNotifier {
  final BuildContext context;

  // List of the sleep alarms
  List<SleepAlarm> sleepAlarms = [];

  // num of all sleep alarms
  int numSleepAlarms = 0;

  // Active alarm
  int activeAlarm = -1;

  // Show body
  bool showBody = false;

  SleepAlarmDataManager(this.context) {
    init();
  }

  void init() async {
    // Get the num of sleep alarms
    int len = await DatabaseHelper().querySleepAlarmsLength();
    numSleepAlarms = len;
    showBody = true;
    notifyListeners();

    // Get the sleep alarms
    List<SleepAlarm> sleepAlrms = await DatabaseHelper().querySleepAlarms();
    sleepAlarms = sleepAlrms;
    AudioServiceHandler audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    activeAlarm = audioServiceHandler.activeSleepAlarm;

    notifyListeners();
  }

  void createNewSleepAlarm() async {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => SleepAlarmAddPhone(
        insertSleepAlarm: (
          sleepAlarm,
        ) {
          sleepAlarms.add(sleepAlarm);
          notifyListeners();
        },
      ),
    );
  }

  changeActiveSleepAlarm(int index) {
    AudioServiceHandler audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    if (index != -1) {
      List<MediaItem> queue = audioServiceHandler.queue.value;
      if (queue.isEmpty) {
        Notifications().showErrorNotification(context, "Cannot start the alarm",
            "The queue must not be empty in order to start the alarm");
      } else {
        activeAlarm = sleepAlarms[index].id;
        audioServiceHandler.activeSleepAlarm = sleepAlarms[index].id;

        audioServiceHandler.sleep(sleepAlarms[index]);
      }
    } else {
      activeAlarm = -1;
      audioServiceHandler.activeSleepAlarm = -1;
      AudioServiceHandler().stopSleep();
    }
    notifyListeners();
  }

  void removeSleepAlarm(index) {
    AudioServiceHandler audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    if (audioServiceHandler.activeSleepAlarm == sleepAlarms[index].id) {
      audioServiceHandler.stopSleep();
      activeAlarm = -1;
      audioServiceHandler.activeSleepAlarm = -1;
    }
    DatabaseHelper().removeSleepAlarm(sleepAlarms[index].id);
    sleepAlarms.removeAt(index);
    notifyListeners();
  }
}
