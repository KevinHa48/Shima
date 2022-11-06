import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'utilities/gps.dart';
import 'utilities/connectivity.dart';
import 'notifications.dart';

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
  GPS gps = GPS();
  ConnectivityService connectionCheck = ConnectivityService();

  List<LatLng> polylineCoordinates = [];
  LatLng? currentLocation;
  Set<Marker>? markers;
  Set<Polyline> polylines = {};
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    Notifications.initialize(flutterLocalNotificationsPlugin);
    if (!gps.started) {
      gps.start();
      connectionCheck.start();
    }
    ValueNotifier<List<LatLng>> _locations =
        ValueNotifier<List<LatLng>>(gps.locations);
    ValueNotifier<bool> connection =
        ValueNotifier<bool>(connectionCheck.disconnected);
    gps.addListener = _locations;
    connectionCheck.connectionListener = connection;
    _locations.addListener(() async {
      currentLocation = gps.getLatestCoordinate();
      polylines = {};
      polylines.add(gps.generatePath());
      setState(() {});
    });
    connection.addListener(() async {
      if (connectionCheck.disconnected) {
        Notifications.showBigTextNotification(
            title: 'Shima',
            body: 'Connection lost, trail saved.',
            fln: flutterLocalNotificationsPlugin);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: currentLocation == null ||
              polylines ==
                  null // Ternary to check whether currentLocation variable exists
          ? const Center(
              child: Text("Loading...")) // If null, display loading text
          : GoogleMap(
              // Otherwise, display the map
              mapType: MapType
                  .satellite, // map types: [roadmap, hybrid, terrain, satellite]
              initialCameraPosition: CameraPosition(
                target: currentLocation!,
                zoom: 8.5, // Camera zoom
              ),
              // Our markers
              polylines: polylines),
    );
  }
}
