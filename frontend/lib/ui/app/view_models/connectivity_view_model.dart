import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/services/device/connectivity_service.dart';

/// Whether the device is online, for the parts of the app that show it.
class ConnectivityViewModel extends ChangeNotifier {
  /// Creates a view model that follows [_connectivity].
  ConnectivityViewModel({required this._connectivity}) {
    _changes = _connectivity.onConnectionChanged.listen(
      (_) => notifyListeners(),
    );
  }

  final ConnectivityService _connectivity;
  late final StreamSubscription<bool> _changes;

  /// Whether the device has a network connection.
  bool get isConnected => _connectivity.isConnected;

  @override
  void dispose() {
    unawaited(_changes.cancel());
    super.dispose();
  }
}
