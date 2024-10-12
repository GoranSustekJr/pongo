import 'package:flutter/cupertino.dart';
import 'package:interactive_slider/interactive_slider.dart';
import 'package:pongo/exports.dart';

class VolumeControlPhone extends StatefulWidget {
  const VolumeControlPhone({
    super.key,
  });

  @override
  State<VolumeControlPhone> createState() => _VolumeControlPhoneState();
}

class _VolumeControlPhoneState extends State<VolumeControlPhone> {
  // Volume controller
  InteractiveSliderController volumeController =
      InteractiveSliderController(VolumeManager().currentVolume);

  // Volume icon
  int iconKey = 0;

  @override
  void initState() {
    super.initState();
    updateVolume(
        Provider.of<VolumeManager>(context, listen: false).currentVolume);
  }

  void updateVolume(double volume) {
    /*  final volumeManager = Provider.of<VolumeManager>(context, listen: false);
    volumeManager.setVolume(volume);
    setState(() {
      volumeController.value = volume;
      if (volume == 0) {
        iconKey = 0;
      } else if (volume > 0 && volume <= 0.33) {
        iconKey = 1;
      } else if (volume > 0.33 && volume <= 0.67) {
        iconKey = 2;
      } else {
        iconKey = 3;
      }
    }); */

    setState(() {
      volumeController = InteractiveSliderController(volume);
      volumeController.value = volume;
      if (volume == 0) {
        iconKey = 0;
      } else if (volume > 0 && volume <= 0.33) {
        iconKey = 1;
      } else if (volume > 0.33 && volume <= 0.67) {
        iconKey = 2;
      } else {
        iconKey = 3;
      }
    });
  }

  @override
  void dispose() {
    volumeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final volumeManager = Provider.of<VolumeManager>(context);
    return StreamBuilder<double>(
        stream: volumeManager.volumeStream,
        initialData: volumeManager.currentVolume,
        builder: (context, snapshot) {
          double volume = snapshot.data ?? 0.0;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            updateVolume(volume);
          });

          return SizedBox(
            width: size.width - 20,
            height: 54,
            child: InteractiveSlider(
              controller: volumeController,
              focusedHeight: 15,
              startIcon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: Icon(
                  key: ValueKey<int>(iconKey),
                  iconKey == 0
                      ? CupertinoIcons.volume_off
                      : iconKey == 1
                          ? CupertinoIcons.speaker_1_fill
                          : iconKey == 2
                              ? CupertinoIcons.speaker_2_fill
                              : CupertinoIcons.speaker_3_fill,
                ),
              ),
              endIcon: const Icon(CupertinoIcons.volume_up),
              onChanged: (volume) {
                updateVolume(volume);
                final volumeManager =
                    Provider.of<VolumeManager>(context, listen: false);
                volumeManager.setVolume(volume);
                setState(() {
                  volumeController.value = volume;
                  if (volume == 0) {
                    iconKey = 0;
                  } else if (volume > 0 && volume <= 0.33) {
                    iconKey = 1;
                  } else if (volume > 0.33 && volume <= 0.67) {
                    iconKey = 2;
                  } else {
                    iconKey = 3;
                  }
                });
              },
            ),
          );
        });
  }
}
