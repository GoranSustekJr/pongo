import 'dart:async';

import 'package:flutter/services.dart';
import 'package:real_volume/real_volume.dart';
import 'package:volume_controller/volume_controller.dart';

import '../../../utils/platform.dart';

/// Reads and changes the device's music volume.
class VolumeService {
  final _controller = StreamController<double>.broadcast();

  double _volume = 0;
  StreamSubscription<double>? _appleChanges;

  // Observes the volume natively on iOS (see DeviceVolumeObserver in
  // AppDelegate.swift): volume_controller would make Pongo's audio mix with
  // other apps, which also keeps it off the lock screen and Control Center.
  static const _appleVolume = EventChannel('pongo/device_volume');

  /// The latest known device volume, from 0 to 1.
  double get volume => _volume;

  /// Emits the device volume whenever it changes.
  Stream<double> get onVolumeChanged => _controller.stream;

  /// Reads the current volume and starts listening for changes.
  Future<void> start() async {
    if (kIsIOS) {
      _appleChanges = _appleVolume
          .receiveBroadcastStream()
          .map((volume) => (volume as num).toDouble())
          .listen(_update);
    } else {
      VolumeController.instance.addListener(_update);
    }
    _update(await RealVolume.getCurrentVol(StreamType.MUSIC) ?? 0);
  }

  /// Sets the device volume to [volume], without showing the system UI.
  Future<void> setVolume(double volume) async {
    await RealVolume.setVolume(
      volume,
      showUI: false,
      streamType: StreamType.MUSIC,
    );
    _update(volume);
  }

  void _update(double volume) {
    _volume = volume;
    _controller.add(volume);
  }

  /// Stops listening for changes.
  Future<void> dispose() async {
    if (kIsIOS) {
      await _appleChanges?.cancel();
    } else {
      await VolumeController.instance.removeListener();
    }
    await _controller.close();
  }
}
