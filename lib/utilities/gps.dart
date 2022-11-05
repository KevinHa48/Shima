import 'dart:async';
import 'dart:html';

import 'package:geolocator/geolocator.dart';
import 'package:tuple/tuple.dart';

class GPS {
  List<Tuple2<double, double>> locations;
  LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best, distanceFilter: 100);
  late StreamSubscription<Position> positionStream;
  late LocationPermission permission;

  GPS({this.locations = const []});

  double getLatestLatitude() {
    return locations.last.item1;
  }

  double getLatestLongitude() {
    return locations.last.item2;
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
    }
  }

  Future<void> stop() async {
    await positionStream.cancel();
  }

  Future<bool> addLocation(double lat, double lon) async {
    Tuple2<double, double> newLocation = Tuple2<double, double>(lat, lon);
    if (locations.isEmpty || locations.last != newLocation) {
      locations.add(newLocation);
      return true;
    }
    return false;
  }

  Future<void> start() async {
    await _checkPermission();
    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) async {
      if (position != null) {
        await addLocation(position.latitude, position.longitude);
      }
    });
  }
}
