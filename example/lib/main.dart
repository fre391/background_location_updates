import 'dart:async';
import 'dart:core';
import 'dart:convert';

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
  BackgroundLocationUpdates geoUpdates = new BackgroundLocationUpdates();

  List<String> logArray = List();
  int logLength = 60;
  DateTime lastUpdate = DateTime.now();
  String status = "";
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

    geoUpdates.init(callback);
    geoUpdates.setLocationSettings(
        accuracy: LocationAccuracy.high, intervalMilliSeconds: 1000, distanceFilterMeter: 0);
  }

  Future<dynamic> callback(call) {
    var args = jsonDecode(call.arguments);
    switch (call.method) {
      case "onMessage":
        onMessage(args);
        break;
      case "onLocation":
        onLocation(args);
        break;
      case "onData":
        onData(args[0]);
        break;
      case "onStatus":
        onStatus(args[0]);
        break;
    }
  }

  void onMessage(String message) {
    setState(() {
      status = message;
      print(message);
    });
  }

  void onLocation(Map l) {
    setState(() {
      location = l["latitude"].toString() + " / " + l["longitude"].toString();
      var point = LatLng(l["latitude"], l["longitude"]);
      points.add(point);
      print(location);
    });
  }

  void onData(int value) {
    if (soundOn) FlutterBeep.beep();
    updateState(value.toString());
  }

  void onStatus(bool value) {
    setState(() {
      isRunning = value;
    });
  }

  updateState(String msg) {
    setState(() {
      var now = DateTime.now();
      Duration diff = now.difference(lastUpdate);
      lastUpdate = now;

      String time =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      if (diff.inSeconds > 1) {
        msg += "\n\n";
      }

      logArray = logArray.reversed.toList();
      if (logArray.length > logLength) logArray = logArray.sublist(1);
      logArray.add("$time - $msg\n"); //$log";
      logArray = logArray.reversed.toList();

      print("Data received: $time - $msg");
    });
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
                            await geoUpdates.start();
                            status = "STARTED";
                            setState(() {});
                          },
                          child: Icon(Icons.play_arrow),
                          padding: EdgeInsets.all(15),
                        )
                      : RaisedButton(
                          onPressed: () async {
                            /* stop service via forgroundChannel */
                            await geoUpdates.stop();
                            status = "STOPPED";
                            setState(() {});
                          },
                          child: Icon(Icons.stop),
                          padding: EdgeInsets.all(15),
                        ),
                  RaisedButton(
                    onPressed: () async {
                      /* request data via forgroundChannel */
                      await geoUpdates.get();
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
                Text("\n" + status + "\n"),
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
