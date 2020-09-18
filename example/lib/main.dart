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

  List<String> logArray = List();
  int logLength = 60;
  DateTime lastUpdate = DateTime.now();
  String location = "";
  bool soundOn = true;
  bool isRunning = false;
  List<LatLng> points = List();

  @override
  void initState() {
    init();
    super.initState();
  }

  init() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.locationAlways,
      Permission.locationWhenInUse,
      Permission.notification
    ].request();
    print(statuses[Permission.location]);

    locationUpdates.setCallback((method, args) {
      updateState(method, args);
    });
    locationUpdates.configureSettings(
        accuracy: LocationAccuracy.high,
        intervalMilliSecondsAndroid: 1000,
        distanceFilterMeter: 0,
        mockUpDetection: true);
  }

  updateState(String method, dynamic args) async {
    isRunning = await locationUpdates.isRunning();

    switch (method) {
      case "onStatus":
        setState(() {
          isRunning = args;
        });
        break;
      case "onLocation":
        setState(() {
          Location location = args;
          var point = LatLng(location.latitude, location.longitude);
          points.add(point);
          print("New Location: ${location.latitude} / ${location.longitude}");
        });
        break;
      case "onData":
        if (soundOn) FlutterBeep.beep();
        String msg = args.toString();

        var now = DateTime.now();
        String time =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

        Duration diff = now.difference(lastUpdate);

        setState(() {
          lastUpdate = now;
          if (diff.inSeconds > 1) {
            msg += "\n\n";
          }

          logArray = logArray.reversed.toList();
          if (logArray.length > logLength) logArray = logArray.sublist(1);
          logArray.add("$time - $msg\n"); //$log";
          logArray = logArray.reversed.toList();
        });
        print("Data received: $time - $msg");
        break;
    }
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
                      locationUpdates.getData();
                    },
                    child: Icon(Icons.autorenew),
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
                      (points.length > 0)
                          ? Container(
                              height: 450,
                              child: FlutterMap(
                                options: MapOptions(
                                  center: LatLng(51.9, 8.4),
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
                                          points: points, strokeWidth: 4.0, color: Colors.purple),
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
