import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Completer<GoogleMapController> _controller = Completer();
  // @TODO: get user's current location and put that into LatLng
  static const LatLng sourceLocation = LatLng(40.7429149, -74.1782508);

  List<LatLng> polylineCoordinates = [];
  LocationData? currentLocation;

  // Updates our current location
  void getCurrentLocation() {
    Location location = Location();

    location.getLocation().then(
      (location) {
        currentLocation = location;
      },
    );

    location.onLocationChanged.listen((newLoc) {
      currentLocation = newLoc;

      setState(() {});
    });
  }

  @override
  void initState() {
    getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SizedBox.expand(
      child: Stack(children: <Widget>[
        Align(
          child: currentLocation ==
                  null // Ternary to check whether currentLocation variable exists
              ? const Center(
                  child: Text("Loading...")) // If null, display loading text
              : GoogleMap(
                  padding: EdgeInsets.only(bottom: 100, left: 15),
                  // Otherwise, display the map
                  mapType: MapType
                      .satellite, // map types: [roadmap, hybrid, terrain, satellite]
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                        // (currentLat, currentLong)
                        currentLocation!.latitude!,
                        currentLocation!.longitude!),
                    zoom: 16, // Camera zoom
                  ),
                  // Our markers
                  markers: {
                      Marker(
                        markerId: const MarkerId("currentLocation"),
                        position: LatLng(currentLocation!.latitude!,
                            currentLocation!.longitude!),
                      )
                    }),
        ),
        SizedBox.expand(
            child: DraggableScrollableSheet(
          initialChildSize: 0.25,
          minChildSize: 0.17,
          maxChildSize: 0.4,
          builder: (BuildContext c, s) {
            return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 0,
                ),
                decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                      )
                    ]),
                child: ListView(
                  controller: s,
                  children: <Widget>[
                    Center(
                      child: Container(
                        height: 3,
                        width: 50,
                        decoration: BoxDecoration(
                            color: const Color(0xFF68869E),
                            borderRadius: BorderRadius.circular(5)),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF68869E),
                        ),
                        onPressed: getCurrentLocation,
                        child: const Center(
                          child: Text("Start"),
                        ),
                      ),
                    ),
                  ],
                ));
          },
        ))
      ]),
    ));
  }
}
