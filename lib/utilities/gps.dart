import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'colors.dart';
import './connectivity.dart';
import 'package:permission_handler/permission_handler.dart';

class GPS {
  List<LatLng> locations;
  static const int maxDistance = 5;
  LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best, distanceFilter: maxDistance);
  late StreamSubscription<Position> positionStream;
  late LocationPermission permission;
  late Timer pingTimer;
  LatLng? srcPoint;
  bool started = false;
  int pingTime;
  int? startTime;
  late ValueNotifier<List<LatLng>>? addListener;
  ConnectivityService connectionChecker = ConnectivityService();

  GPS({this.locations = const [], this.pingTime = 30});

  LatLng getLatestCoordinate() {
    return locations.last;
  }

  Future<Position> getHeading() async {
    return await Geolocator.getCurrentPosition();
    ;
  }

  Future<void> _checkLocationServiceEnabled() async {
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      return Future.error("Location service not enabled.");
    }
  }

  Future<void> _checkPermission() async {
    // var status = await Permission.locationWhenInUse.status;
    // if (!status.isGranted) {
    //   var inUse = await Permission.locationWhenInUse.request();
    //   if (inUse.isGranted) {
    //     var locationAlways = await Permission.locationAlways.request();
    //     if (locationAlways.isGranted) {
    //     } else {}
    //   } else {}
    //   if (status.isPermanentlyDenied) {
    //     //When the user previously rejected the permission and select never ask again
    //     //Open the screen of settings
    //     bool res = await openAppSettings();
    //   }
    // } else {
    //   //In use is available, check the always in use
    //   var status = await Permission.locationAlways.status;
    //   if (!status.isGranted) {
    //     var status = await Permission.locationAlways.request();
    //     if (status.isGranted) {
    //       //Do some stuff
    //     } else {
    //       //Do another stuff
    //     }
    //   } else {
    //     //previously available, do some stuff or nothing
    //   }
    // }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          "Location permissions are permanently denied. Cannot request permissions.");
    } else if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location permissions are denied");
      }
    }
  }

  Future<Map<dynamic, dynamic>> stop() async {
    await positionStream.cancel();
    // pingTimer.cancel();
    started = false;
    return {
      "breadCrumbs": locations.length,
      "distance": getDistance(),
      "duration": getDuration(),
    };
  }

  String getDuration() {
    Duration currentTime = Duration(
        milliseconds: DateTime.now().millisecondsSinceEpoch - startTime!);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(currentTime.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(currentTime.inSeconds.remainder(60));
    return "${twoDigits(currentTime.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  double getDistance() {
    double total = 0;
    for (int i = 0; i < locations.length - 1; i++) {
      total += Geolocator.distanceBetween(
          locations[i].latitude,
          locations[i].longitude,
          locations[i + 1].latitude,
          locations[i + 1].longitude);
    }
    return total;
  }

  addLocation(double lat, double lon) {
    LatLng newLocation = LatLng(lat, lon);
    if (locations.isEmpty ||
        (locations.last.latitude != newLocation.latitude &&
            locations.last.longitude != newLocation.longitude)) {
      locations = [...locations, newLocation];
      if (srcPoint == null && locations.isNotEmpty) {
        srcPoint = locations.first;
      }
      if (addListener != null) {
        addListener!
            .notifyListeners(); //https://github.com/flutter/flutter/issues/29958
      }
      return true;
    }
    return false;
  }

  bool isNear(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(
            a.latitude, a.longitude, b.latitude, b.longitude) <=
        maxDistance;
  }

  void optimizePath() {
    List<LatLng> newPath = [];
    int lastCycle = 0;
    for (int i = 3; i < locations.length; i++) {
      for (int j = 0; j < i; j++) {
        if (isNear(locations[i], locations[j])) {
          if (j > lastCycle) {
            newPath.addAll(locations.sublist(lastCycle, j));
          }
          lastCycle = i;
        }
      }
    }
    newPath.addAll(locations.sublist(lastCycle, locations.length));
    if (locations.isEmpty) {
      locations.add(srcPoint!);
    }
    locations = newPath;
  }

  Polyline generatePath() {
    optimizePath();
    PolylineId id = const PolylineId("breadcrumb-trail");
    Polyline polyline = Polyline(
        startCap: Cap.customCapFromBitmap(BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed)), //TODO make custom start point
        endCap: Cap.roundCap,
        polylineId: id,
        color: ColorSelect().shimaRed,
        width: 4,
        points: locations);
    return polyline;
  }

  Future<void> ping() async {
    // If connection is OK, continue with ping logic
    Position? position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    addLocation(position.latitude, position.longitude);
  }

  Future<bool> start() async {
    startTime = DateTime.now().millisecondsSinceEpoch;
    locations = [];
    await _checkPermission();
    await _checkLocationServiceEnabled();
    //Get first position and add to path
    await ping();

    //Path event listener
    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) async {
      if (position != null) {
        print(position.latitude);
        addLocation(position.latitude, position.longitude);
        // } else {
        //   // Connection is potentially dead here, begin manually pinging
        //   pingTimer = Timer.periodic(
        //       Duration(seconds: pingTime),
        //       (Timer t) async => {
        //             if (!connectionChecker.getConnectionStatus())
        //               {
        //                 // Connection is dead
        //                 print('Im dead'),
        //                 await stop(),
        //                 t.cancel()
        //               }
        //             else
        //               {print("Connection is still alive"), await ping()}
        //           });
        // }
      }
    });

    started = true;
    return true;
  }
}
