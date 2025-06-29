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

  // Scroll controller
  late ScrollController scrollController;

  // Offset
  double scrollControllerOffset = 0;

  // Device volume
  final StreamController<double> volumeController =
      StreamController<double>.broadcast();
  Stream<double> get volumeStream => volumeController.stream;

  SleepAlarmDataManager(this.context) {
    init();
  }

  void init() async {
    scrollController = ScrollController();
    scrollController.addListener(scrollControllerListener);

    // Get the prefered device volume
    double devVolume = await Storage().getSleepAlarmDeviceVolume();
    volumeController.add(devVolume);

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

  scrollControllerListener() {
    if (scrollController.offset < 0) {
      scrollControllerOffset = 0;
    } else {
      scrollControllerOffset = scrollController.offset;
    }
    notifyListeners();
  }

  void createNewSleepAlarm() async {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => SleepAlarmAddPhone(
        sleepAlarm: null,
        insertSleepAlarm: (sleepAlarm) {
          sleepAlarms.insert(0, sleepAlarm);
          notifyListeners();
        },
      ),
    );
  }

  void updateSleepAlarm(SleepAlarm sleepAlarm) async {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => SleepAlarmAddPhone(
        sleepAlarm: sleepAlarm,
        insertSleepAlarm: (sleepAlarm) {
          final index =
              sleepAlarms.indexWhere((alarm) => alarm.id == sleepAlarm.id);
          if (index != -1) {
            sleepAlarms[index] = sleepAlarm;
          }
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
        Notifications().showErrorNotification(
            context,
            AppLocalizations.of(context).cannotstartalarm,
            AppLocalizations.of(context)
                .thequeuemustnotbeemptyinordertostartthealarm);
      } else {
        activeAlarm = sleepAlarms[index].id;
        audioServiceHandler.activeSleepAlarm = sleepAlarms[index].id;

        audioServiceHandler.sleep(sleepAlarms[index]);
      }
    } else {
      activeAlarm = -1;
      audioServiceHandler.activeSleepAlarm = -1;
      audioServiceHandler.stopSleep();
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

  // Update sleep alarm device volume
  void updateSleepAlarmDeviceVolume(double volume) async {
    volumeController.add(volume);
    sleepAlarmDevVolume = volume;
    await Storage().writeSleepAlarmDeviceVolume(volume);
    notifyListeners();
  }
}
