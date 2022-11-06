import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'utilities/colors.dart';
import 'utilities/gps.dart';

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

  List<LatLng> polylineCoordinates = [];
  LatLng? currentLocation;
  Set<Polyline> polylines = {};
  double distance = 0;
  String time = "";
  int breadCrumbs = 0;
  late Timer getTimeTimer;

  @override
  void initState() {
    if (!gps.started) {
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
    ValueNotifier<List<LatLng>> _locations =
        ValueNotifier<List<LatLng>>(gps.locations);
    gps.addListener = _locations;
    _locations.addListener(() async {
      currentLocation = gps.getLatestCoordinate();
      polylines = {};
      polylines.add(gps.generatePath());
      distance = gps.getDistance(); //TODO implement this into front end
      breadCrumbs = gps.locations.length; //TODO implement this into front end
      setState(() {});
    });
  }

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
        child: Stack(children: <Widget>[
          Align(
            child: currentLocation == null ||
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
                      zoom: 18, // Camera zoom
                    ),
                    // Our markers
                    polylines: polylines,
                    myLocationEnabled: true,
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
                    Container(
                        transform: Matrix4.translationValues(0.0, -50.0, 0.0),
                        child: Stack(children: <Widget>[
                          Center(
                            child: Container(
                              height: 40,
                              width: 150,
                              margin: const EdgeInsets.only(top: 20),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorSelect().shimaBlue,
                                ),
                                onPressed: initState,
                                child: const Center(
                                  child: Text("Start"),
                                ),
                              ),
                            ),
                          ),
                        ]))
                  ],
                ),
              );
            },
          )),
          compass
        ]),
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
                )),
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
  double xPosScale = 0.75;
  double yPosScale = 0.8;
  double widthScale = 0.2;
  double heightScale = 0.2;

  void min() {
    maximized = false;
    xPosScale = 0.75;
    yPosScale = 0.6;
    widthScale = 0.2;
    heightScale = 0.2;
  }

  void max() {
    maximized = true;
    xPosScale = 0;
    yPosScale = 0;
    widthScale = 1;
    heightScale = 1;
  }

  @override
  initState() {
    super.initState();
    min();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double xPos = screenWidth * xPosScale;
    double yPos = screenHeight * yPosScale;
    double width = screenWidth * widthScale;
    double height = screenHeight * heightScale;

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
            height: height,
            child: const CircularProgressIndicator()
          );
        }

        double? direction = snapshot.data!.heading;

        // if direction is null, show error text
        if (direction == null) {
          return Positioned(
            left: xPos,
            top: yPos,
            width: width,
            height: height,
            child: const Text("Compass not found"), // make sure this looks right
          );
        }

        // show the compass
        return Positioned(
          left: xPos,
          top: yPos,
          width: width,
          height: height,
          child: Material(
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            elevation: 4.0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Transform.rotate(
                angle: (direction * (math.pi / 180) * -1),
                child: Image.asset('assets/images/compass.jpg'),
              ),
            ),
          )
        );
      },
    );
  }

}

class Compass extends StatefulWidget {
  const Compass({super.key});

  @override
  State<Compass> createState() => CompassState();
}
