import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class InternetConnectivityHandler {
  final Connectivity connectivity = Connectivity();
  final StreamController<bool> connectivityStreamController =
      StreamController<bool>.broadcast();
  bool isConnected = false;

  InternetConnectivityHandler() {
    init();
  }

  void init() async {
    // Check the current connectivity status
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());

    isConnected = !connectivityResult.contains(ConnectivityResult.none);

    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      updateConnectionStatus(result);
    });
    print(connectivityResult);
  }

  void updateConnectionStatus(List<ConnectivityResult> result) {
    isConnected = !result.contains(ConnectivityResult.none);
    connectivityStreamController.add(isConnected);
  }

  Stream<bool> get connectivityStream => connectivityStreamController.stream;

  void dispose() {
    connectivityStreamController.close();
  }
}
