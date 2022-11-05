import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GPS {
  List<LatLng> locations;
  LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best, distanceFilter: 100);
  late StreamSubscription<Position> positionStream;
  late LocationPermission permission;
  late Timer pingTimer;
  int pingTime;

  GPS({this.locations = const [], this.pingTime = 30});

  double getLatestLatitude() {
    return locations.last.latitude;
  }

  double getLatestLongitude() {
    return locations.last.longitude;
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
  }

  Future<bool> addLocation(double lat, double lon) async {
    LatLng newLocation = LatLng(lat, lon);
    if (locations.isEmpty || locations.last != newLocation) {
      locations = [...locations, newLocation];
      return true;
    }
    return false;
  }

  Set<Marker> generatePath() {
    Set<Marker> markers = {};
    for (var i = 0; i < locations.length; i++) {
      markers.add(Marker(markerId: MarkerId("$i"), position: locations[i]));
    }
    return markers;
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
    pingTimer = Timer.periodic(
        Duration(seconds: pingTime), (Timer t) async => {ping())});

    return true;
  }
}
