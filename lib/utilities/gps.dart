import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import './connectivity.dart';

class GPS {
  List<LatLng> locations;
  LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best, distanceFilter: 100);
  late StreamSubscription<Position> positionStream;
  late LocationPermission permission;
  late Timer pingTimer;
  bool started = false;
  int pingTime;
  late ValueNotifier<List<LatLng>>? addListener;
  ConnectivityService connectionChecker = ConnectivityService();

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
    if (locations.isEmpty || locations.last != newLocation) {
      locations = [...locations, newLocation];
      if (addListener != null) {
        addListener!
            .notifyListeners(); //https://github.com/flutter/flutter/issues/29958
      }
      return true;
    }
    return false;
  }

  Polyline generatePath() {
    PolylineId id = const PolylineId("breadcrumb-trail");
    Polyline polyline =
        Polyline(polylineId: id, color: Colors.red, points: locations);
    return polyline;
    // Set<Marker> markers = {};
    // for (var i = 0; i < locations.length; i++) {
    //   markers.add(Marker(markerId: MarkerId("$i"), position: locations[i]));
    // }
    // return markers;
  }

  Future<void> ping() async {
    // If connection is OK, continue with ping logic
    Position? position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
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
