import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  bool hasConnection = false;
  bool disconnected = false;
  Connectivity connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> subscription;

  void start() {
    subscription = connectivity.onConnectivityChanged
        .listen((ConnectivityResult result) async {
      if (result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile) {
        disconnected = false;
        hasConnection = true;
        print('Has connection');
      }
      if (result == ConnectivityResult.none) {
        disconnected = true;
        await checkForDisconnection();
        print('User disconnected, running timer.');
      }
    });
  }

  Future<void> checkForDisconnection() async {
    const oneSec = Duration(seconds: 5);
    Future.delayed(oneSec, (() {
      if (disconnected) {
        print('User is off the grid.');
        hasConnection = false;
      }
    }));
  }

  dispose() {
    subscription.cancel();
  }
}
