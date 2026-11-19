import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Reports whether the device has a network connection.
class ConnectivityService {
  /// Creates a service backed by [connectivity].
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isConnected = false;

  /// Whether the device was connected at the last check.
  bool get isConnected => _isConnected;

  /// Emits the connection state whenever it changes.
  Stream<bool> get onConnectionChanged => _controller.stream;

  /// Reads the current state and starts listening for changes.
  Future<void> start() async {
    _update(await _connectivity.checkConnectivity());
    _subscription = _connectivity.onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    _isConnected = !results.contains(ConnectivityResult.none);
    _controller.add(_isConnected);
  }

  /// Stops listening for changes.
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
