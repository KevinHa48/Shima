import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  bool hasConnection = false;
  bool disconnected = false;
  Connectivity connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> subscription;
  late ValueNotifier<bool> connectionListener;

  void start() {
    subscription = connectivity.onConnectivityChanged
        .listen((ConnectivityResult result) async {
      if (result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile) {
        disconnected = false;
        hasConnection = true;
      }
      if (result == ConnectivityResult.none) {
        disconnected = true;
        await checkForDisconnection();
      }
    });
  }

  bool getConnectionStatus() {
    // Getter for alive or not alive
    return disconnected;
  }

  Future<void> checkForDisconnection() async {
    const oneSec = Duration(seconds: 5);
    Future.delayed(oneSec, (() {
      if (disconnected) {
        print('User is off the grid.');
        hasConnection = false;
        connectionListener.notifyListeners();
      }
    }));
  }

  dispose() {
    subscription.cancel();
  }
}
