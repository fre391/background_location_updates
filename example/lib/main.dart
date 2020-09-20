import 'dart:core';

import 'package:flutter/material.dart';
import 'package:background_location_updates/background_location_updates.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String title = "Background Location";

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: title,
      theme: ThemeData.dark(),
      home: MyHomePage(title: title),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BackgroundLocationUpdates locationUpdates = new BackgroundLocationUpdates();
  MapController mapController;

  List<String> logArray = List();
  int logLength = 60;
  DateTime lastUpdate = DateTime.now();
  bool soundOn = true;
  bool isRunning = false;
  List<LatLng> locations = List();
  LatLng lastLocation;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    locations = List();
    init();
  }

  init() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.locationAlways,
      Permission.locationWhenInUse,
      Permission.notification
    ].request();
    print(statuses[Permission.location]);

    locationUpdates.configureSettings(
        accuracy: LocationAccuracy.high,
        intervalMilliSecondsAndroid: 1000,
        distanceFilterMeter: 0,
        mockUpDetection: false);

    locationUpdates.setCallback((method, args) {
      updateState(method, args);
    });
  }

  updateState(String method, dynamic args) async {
    isRunning = await locationUpdates.isRunning();

    switch (method) {
      case "onStatus":
        isRunning = args;
        print("Running:" + isRunning.toString());
        break;
      case "onLocation":
        Location location = args;
        lastLocation = LatLng(location.latitude, location.longitude);
        if (lastLocation != null) {
          locations.add(lastLocation);
          if (mapController.ready) mapController.move(lastLocation, 15.0);
        }
        var now = DateTime.now();
        String time =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

        print("$time - ${location.latitude} / ${location.longitude}");
        break;
      case "onData":
        if (soundOn) FlutterBeep.beep();
        String msg = args.toString();

        var now = DateTime.now();
        String time =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

        Duration diff = now.difference(lastUpdate);

        lastUpdate = now;
        if (diff.inSeconds > 1) {
          msg += "\n\n";
        }

        logArray = logArray.reversed.toList();
        if (logArray.length > logLength) logArray = logArray.sublist(1);
        logArray.add("$time - $msg\n"); //$log";
        logArray = logArray.reversed.toList();
        print("$time - $msg");
        break;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Padding(
            padding: EdgeInsets.all(5),
            child: Center(
                child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
                  (!isRunning)
                      ? RaisedButton(
                          onPressed: () async {
                            /* start service via forgroundChannel */
                            isRunning = await locationUpdates.start();
                            setState(() {});
                          },
                          child: Icon(Icons.play_arrow),
                          padding: EdgeInsets.all(15),
                        )
                      : RaisedButton(
                          onPressed: () async {
                            /* stop service via forgroundChannel */
                            isRunning = await locationUpdates.stop();
                            setState(() {});
                          },
                          child: Icon(Icons.stop),
                          padding: EdgeInsets.all(15),
                        ),
                  RaisedButton(
                    onPressed: () async {
                      /* request data via forgroundChannel */
                      locationUpdates.getLocation();
                      locationUpdates.getValue();
                    },
                    child: Icon(Icons.location_searching),
                    padding: EdgeInsets.all(15),
                  ),
                  RaisedButton(
                    onPressed: () async {
                      /* toogle sound (Flutter beep) */
                      setState(() {
                        soundOn = !soundOn;
                      });
                    },
                    child: Icon((soundOn) ? Icons.volume_mute : Icons.volume_off),
                    padding: EdgeInsets.all(15),
                  ),
                ]),
                (isRunning) ? Text("\nSTARTED\n") : Text("\nSTOPPED\n"),
                Expanded(
                    child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      (locations.length > 0)
                          ? Container(
                              height: 450,
                              child: FlutterMap(
                                mapController: mapController,
                                options: MapOptions(
                                  center: LatLng(lastLocation.latitude, lastLocation.longitude),
                                  zoom: 10.0,
                                ),
                                layers: [
                                  TileLayerOptions(
                                    urlTemplate:
                                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    subdomains: ['a', 'b', 'c'],
                                    tileProvider: NonCachingNetworkTileProvider(),
                                  ),
                                  PolylineLayerOptions(
                                    polylines: [
                                      Polyline(
                                          points: locations,
                                          strokeWidth: 4.0,
                                          color: Colors.purple),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              height: 0,
                            ),
                      Text("\n" + logArray.join("")),
                    ],
                  ),
                )),
              ],
            ))));
  }
}
