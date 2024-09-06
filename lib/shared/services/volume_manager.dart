import '../../exports.dart';

class VolumeManager {
  double _currentVolume = 0.0;
  final StreamController<double> _volumeController =
      StreamController<double>.broadcast();

  // Volume getter
  double get currentVolume => _currentVolume;

  // Volume stream
  Stream<double> get volumeStream => _volumeController.stream;

  // Initialize volume control
  Future<void> initializeVolume() async {
    final vol = await RealVolume.getCurrentVol(StreamType.MUSIC) ?? 0.0;
    addListener();
    _currentVolume = vol;
    _volumeController.add(_currentVolume);
  }

  // Set volume
  Future<void> setVolume(double value) async {
    await RealVolume.setVolume(value,
        showUI: false, streamType: StreamType.MUSIC);
    _currentVolume = value;
    _volumeController.add(_currentVolume);
  }

  // Add listener
  addListener() {
    VolumeController().listener((volume) {
      _currentVolume = volume;
      _volumeController.add(_currentVolume);
      print('Volume changed to: $volume');
    });
  }

  // Remove listener
  removeListener() {
    VolumeController().removeListener();
  }
}
