import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GPS {
  List<LatLng> locations;
  static const int maxDistance = 5;
  LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best, distanceFilter: maxDistance);
  late StreamSubscription<Position> positionStream;
  late LocationPermission permission;
  late Timer pingTimer;
  bool started = false;
  int pingTime;
  late ValueNotifier<List<LatLng>>? addListener;

  GPS({this.locations = const [], this.pingTime = 30});

  LatLng getLatestCoordinate() {
    return locations.last;
  }

  Future<void> _checkLocationServiceEnabled() async {
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      return Future.error("Location service not enabled.");
    }
  }

  Future<void> _checkPermission() async {
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          "Location permissions are permanently denied. Cannot request permissions.");
    } else if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location permissions are denied");
      }
    } else if (permission == LocationPermission.whileInUse) {
      return Future.error(
          "Location permissions are only enabled when app is in use. Set permissions to 'always'");
    }
  }

  Future<void> stop() async {
    await positionStream.cancel();
    pingTimer.cancel();
    started = false;
  }

  addLocation(double lat, double lon) {
    LatLng newLocation = LatLng(lat, lon);
    if (locations.isEmpty ||
        (locations.last.latitude != newLocation.latitude &&
            locations.last.longitude != newLocation.longitude)) {
      locations = [...locations, newLocation];
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
        color: Colors.red,
        width: 4,
        points: locations);
    return polyline;
  }

  Future<void> ping() async {
    Position? position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    //TODO check if there's connection
    addLocation(position.latitude, position.longitude);
  }

  Future<bool> start() async {
    await _checkPermission();
    await _checkLocationServiceEnabled();
    //Get first position and add to path
    await ping();

    //Path event listener
    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) async {
      if (position != null) {
        addLocation(position.latitude, position.longitude);
      }
    });

    //Startup timer
    // pingTimer = Timer.periodic(
    //     Duration(seconds: pingTime), (Timer t) async => {ping()});

    started = true;
    return true;
  }
}
