import '../../../data/services/device/volume_service.dart';

/// The device's media volume, for the volume slider.
class VolumeViewModel {
  /// Creates a view model over [_volume].
  const VolumeViewModel({required this._volume});

  final VolumeService _volume;

  /// The volume from 0 to 1.
  double get volume => _volume.volume;

  /// Emits the volume when it changes.
  Stream<double> get volumeStream => _volume.onVolumeChanged;

  /// Sets the volume to [volume], from 0 to 1.
  Future<void> setVolume(double volume) => _volume.setVolume(volume);
}
