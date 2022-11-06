import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'utilities/colors.dart';
import 'utilities/gps.dart';
import 'utilities/connectivity.dart';
import 'notifications.dart';

import 'package:flutter_compass/flutter_compass.dart';

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
        canvasColor: ColorSelect().shimaGreen,
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        fontFamily: 'Quicksand',
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
  Compass compass = const Compass();
  ConnectivityService connectionCheck = ConnectivityService();

  List<LatLng> polylineCoordinates = [];
  LatLng? currentLocation;
  Set<Polyline> polylines = {};
  double distance = 0;
  String time = "00:00:00";
  int breadCrumbs = 0;
  late Timer getTimeTimer;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  startHandler() {
    gps.start();
    getTimeTimer = Timer.periodic(
        //TODO when gps.stop is called, stop this timer as well.
        //TODO implement this into front end
        const Duration(seconds: 1),
        (Timer t) => {
              time = gps.getDuration(),
              setState(() {})
            }); //TODO test if this causes lag
  }

  stopHandler() {
    gps.stop();
    getTimeTimer.cancel();
    setState(() {});
  }

  @override
  void initState() {
    gps.ping();
    connectionCheck.start();
    Notifications.initialize(flutterLocalNotificationsPlugin);
    ValueNotifier<List<LatLng>> _locations =
        ValueNotifier<List<LatLng>>(gps.locations);
    ValueNotifier<bool> connection =
        ValueNotifier<bool>(connectionCheck.disconnected);
    gps.addListener = _locations;
    connectionCheck.connectionListener = connection;
    _locations.addListener(() async {
      currentLocation = gps.getLatestCoordinate();
      Position position = await gps.getHeading();
      mapController
          ?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: currentLocation!,
        zoom: 25,
        bearing: position.heading,
      )
              //17 is new zoom level
              ));
      polylines = {};
      polylines.add(await gps.generatePath());
      distance = gps.getDistance(); //TODO implement this into front end
      breadCrumbs = gps.locations.length; //TODO implement this into front end
      setState(() {});
    });
    connection.addListener(() async {
      if (connectionCheck.disconnected) {
        await Notifications.showBigTextNotification(
            title: 'Shima',
            body: 'Connection lost, trail saved.',
            fln: flutterLocalNotificationsPlugin);
      }
    });
  }

  GoogleMapController? mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Shima", style: TextStyle(fontFamily: "LucidaFax")),
        backgroundColor: Colors.transparent,
      ),
      body: SizedBox.expand(
        child: Stack(
          children: <Widget>[
            Align(
              child: currentLocation == null ||
                      polylines ==
                          null // Ternary to check whether currentLocation variable exists
                  ? const Center(
                      child:
                          Text("Loading...")) // If null, display loading text
                  : GoogleMap(
                      // Otherwise, display the map
                      mapType: MapType
                          .satellite, // map types: [roadmap, hybrid, terrain, satellite]
                      initialCameraPosition: CameraPosition(
                        target: currentLocation!,
                        zoom: 18, // Camera zoom
                      ),
                      // Our markers
                      polylines: polylines,
                      myLocationEnabled: true,
                      onMapCreated: (controller) {
                        setState(() {
                          mapController = controller;
                        });
                      },
                    ),
            ),
            SizedBox.expand(
              child: DraggableScrollableSheet(
                initialChildSize: 0.17,
                minChildSize: 0.17,
                maxChildSize: 0.4,
                builder: (BuildContext c, s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 0,
                    ),
                    decoration: BoxDecoration(
                      color: ColorSelect().darkGrey,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: ListView(
                      controller: s,
                      children: <Widget>[
                        Transform.translate(
                          offset: const Offset(0.0, -50.0),
                          child: Container(
                            child: Column(
                              children: <Widget>[
                                Center(
                                  child: Container(
                                    height: 3,
                                    width: 50,
                                    color: ColorSelect().shimaBlue,
                                  ),
                                ),
                                Center(
                                  child: Container(
                                    height: 40,
                                    width: 150,
                                    margin: const EdgeInsets.only(top: 20),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: gps.started == false
                                            ? ColorSelect().shimaBlue
                                            : ColorSelect().shimaRed,
                                      ),
                                      onPressed: gps.started == false
                                          ? startHandler
                                          : stopHandler,
                                      child: Center(
                                        child: gps.started == false
                                            ? Text("Start")
                                            : Text("End Route"),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 70),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          time,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        const Text("Time",
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                    SizedBox(width: 30),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${distance.roundToDouble()}m",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        const Text("Distance Away",
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                    SizedBox(width: 30),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          breadCrumbs.toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        const Text("Crumbs",
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            compass,
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.close),
                color: Colors.black,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
                title: const Text('History', style: TextStyle(fontSize: 20)),
                onTap: () {
                  Navigator.pop(context);
                }),
            ListTile(
              title: const Text('Settings', style: TextStyle(fontSize: 20)),
              onTap: () {
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
    );
  }
}

class CompassState extends State<Compass> {
  double? direction;
  bool maximized = false;
  double xPosScale = 0.76;
  double yPosScale = 0.12;
  double widthScale = 0.2;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double xPos = screenWidth * xPosScale;
    double yPos = screenHeight * yPosScale;
    double width = screenWidth * widthScale;

    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error reading heading: ${snapshot.error}');
        }

        // if loading, show loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Positioned(
              left: xPos,
              top: yPos,
              width: width,
              height: width,
              child: const CircularProgressIndicator());
        }

        double? direction = snapshot.data!.heading;

        // if direction is null, show error text
        if (direction == null) {
          return Positioned(
            left: xPos,
            top: yPos,
            width: width,
            height: width,
            child: const Text("Compass not found"),
          );
        }

        // show the compass
        return Positioned(
            left: xPos,
            top: yPos,
            width: width,
            height: width,
            child: Material(
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              color: ColorSelect().shimaBeige,
              elevation: 4.0,
              child: Container(
                padding: const EdgeInsets.all(2.0),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Transform.rotate(
                  angle: (direction * (math.pi / 180) * -1),
                  child: Image.asset('assets/images/compass.png'),
                ),
              ),
            ));
      },
    );
  }
}

class Compass extends StatefulWidget {
  const Compass({super.key});

  @override
  State<Compass> createState() => CompassState();
}
